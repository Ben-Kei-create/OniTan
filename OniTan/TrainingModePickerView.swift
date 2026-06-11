import SwiftUI

// MARK: - Training Mode Picker View

/// Shows available training modes for a chosen CategoryEntry.
/// Enabled modes launch directly into MainView via a pre-built Stage.
/// Disabled modes (Phase 3+) are shown with a "coming soon" note.
struct TrainingModePickerView: View {
    let category: CategoryEntry

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository
    @EnvironmentObject var masteryRepo: MasteryRepository
    @EnvironmentObject var streakRepo: StreakRepository
    @EnvironmentObject var xpRepo: GamificationRepository
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var examResultRepo: ExamResultRepository

    /// Pre-built stages keyed by mode so shuffles don't re-randomise on every render.
    @State private var builtStages: [TrainingMode: Stage] = [:]

    // Modes shown in Phase 2
    private static let displayModes: [TrainingMode] = [
        .quick10, .categoryFocus, .weakFocus, .mistakeReview, .masteryReview, .examMini
    ]

    // MARK: - Category question pool

    /// Questions belonging to this category.
    /// For categories backed by stageIDs the raw stage questions are used
    /// (preserving legacy .unknown-kind reading questions).
    /// For new-format categories the pool is filtered from allQuestions by kind.
    private var categoryPool: [Question] {
        if !category.stageIDs.isEmpty {
            let stageSet = Set(category.stageIDs)
            let stageQs = quizData.stages
                .filter { stageSet.contains($0.stage) }
                .flatMap(\.questions)
            // Also include explicitly-typed supplemental questions matching this category
            let kindSet = Set(category.questionKinds)
            let supplemental = supplementalQuestions.filter { kindSet.contains($0.kind) }
            return stageQs + supplemental
        }
        let kindSet = Set(category.questionKinds)
        return allQuestions.filter { kindSet.contains($0.kind) }
    }

    // MARK: - Mode helpers

    private func isEnabled(_ mode: TrainingMode) -> Bool {
        switch mode {
        case .quick10:       return !categoryPool.isEmpty
        case .categoryFocus: return !categoryPool.isEmpty
        case .examMini:      return categoryPool.count >= 10
        default:             return false   // Phase 3+
        }
    }

    private func disabledReason(for mode: TrainingMode) -> String? {
        switch mode {
        case .weakFocus:     return "弱点トレーニングは次フェーズで有効になります"
        case .mistakeReview: return "ミス復習は次フェーズで有効になります"
        case .masteryReview: return "定着復習は次フェーズで有効になります"
        default:             return nil
        }
    }

    private func japaneseLabel(for mode: TrainingMode) -> String {
        switch mode {
        case .quick10:       return "10問クイック"
        case .categoryFocus: return "道場集中"
        case .weakFocus:     return "弱点集中"
        case .mistakeReview: return "ミス復習"
        case .masteryReview: return "定着復習"
        case .examMini:      return "ミニ模試"
        default:             return mode.displayName
        }
    }

    private func sessionTitle(for mode: TrainingMode) -> String {
        "\(category.title) — \(japaneseLabel(for: mode))"
    }

    private func examBlueprintID(for mode: TrainingMode) -> String? {
        switch mode {
        case .examMini: return "mini"
        case .examFull: return "full"
        default:        return nil
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback.ignoresSafeArea()

            VStack(spacing: 0) {
                poolHeader

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(Self.displayModes) { mode in
                            modeRow(for: mode)
                        }

                        if categoryPool.isEmpty {
                            emptyPoolNote
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationTitle(category.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear { buildStages() }
    }

    // MARK: - Subviews

    private var poolHeader: some View {
        HStack(spacing: 16) {
            Label("\(categoryPool.count) 問", systemImage: "doc.text")
            Label(category.description, systemImage: "info.circle")
                .lineLimit(1)
        }
        .font(.system(.caption, design: .rounded))
        .foregroundColor(OniTanTheme.textTertiary)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(OniTanTheme.cardBackground.opacity(0.5))
    }

    @ViewBuilder
    private func modeRow(for mode: TrainingMode) -> some View {
        let enabled = isEnabled(mode)
        let stage = builtStages[mode]
        let count = stage?.questions.count ?? (enabled ? min(mode.questionLimit ?? categoryPool.count, categoryPool.count) : 0)

        if enabled, let stage = stage, !stage.questions.isEmpty {
            NavigationLink(
                destination: MainView(
                    stage: stage,
                    appState: appState,
                    statsRepo: statsRepo,
                    streakRepo: streakRepo,
                    xpRepo: xpRepo,
                    masteryRepo: masteryRepo,
                    examResultRepo: examResultRepo,
                    examBlueprintID: examBlueprintID(for: mode),
                    mode: mode.legacyQuizMode ?? .normal,
                    sessionTitle: sessionTitle(for: mode)
                )
            ) {
                TrainingModeCard(
                    mode: mode,
                    label: japaneseLabel(for: mode),
                    questionCount: count,
                    enabled: true,
                    disabledReason: nil
                )
            }
            .buttonStyle(PlainButtonStyle())
            .accessibilityLabel("\(japaneseLabel(for: mode)) \(count)問")
            .accessibilityHint("タップして\(japaneseLabel(for: mode))を開始")
        } else {
            TrainingModeCard(
                mode: mode,
                label: japaneseLabel(for: mode),
                questionCount: count,
                enabled: false,
                disabledReason: disabledReason(for: mode)
            )
            .accessibilityLabel("\(japaneseLabel(for: mode)) — 現在利用不可")
        }
    }

    private var emptyPoolNote: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundColor(OniTanTheme.textTertiary)
            Text("このカテゴリには問題データがまだありません")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(OniTanTheme.textSecondary)
                .multilineTextAlignment(.center)
            Text("今後のアップデートで追加される予定です")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(OniTanTheme.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(OniTanTheme.cardBackground.opacity(0.5))
        )
    }

    // MARK: - Stage Building

    private func buildStages() {
        let pool = categoryPool
        guard !pool.isEmpty else { return }
        for mode in Self.displayModes where isEnabled(mode) {
            builtStages[mode] = TrainingSessionBuilder.build(
                mode: mode,
                allQuestions: pool,
                masteryRepo: masteryRepo,
                statsRepo: statsRepo
            )
        }
    }
}

// MARK: - Training Mode Card

private struct TrainingModeCard: View {
    let mode: TrainingMode
    let label: String
    let questionCount: Int
    let enabled: Bool
    let disabledReason: String?

    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 14) {
            // Icon circle
            ZStack {
                Circle()
                    .fill(iconGradient)
                    .frame(width: 48, height: 48)
                    .opacity(enabled ? 1.0 : 0.35)
                Image(systemName: mode.systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .opacity(enabled ? 1.0 : 0.5)
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(label)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(enabled ? OniTanTheme.textPrimary : OniTanTheme.textTertiary)

                    if enabled {
                        Text("\(questionCount) 問")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(OniTanTheme.textTertiary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(OniTanTheme.cardBackground)
                            .cornerRadius(8)
                    } else {
                        Text("準備中")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(OniTanTheme.textTertiary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(OniTanTheme.cardBackground)
                            .cornerRadius(8)
                    }
                }

                if let reason = disabledReason {
                    Text(reason)
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(OniTanTheme.textTertiary.opacity(0.7))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(mode.description)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(enabled ? OniTanTheme.textTertiary : OniTanTheme.textTertiary.opacity(0.45))
                        .lineLimit(2)
                }
            }

            Spacer()

            if enabled {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13))
                    .foregroundColor(OniTanTheme.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(enabled ? OniTanTheme.cardBackground : OniTanTheme.cardBackground.opacity(0.45))
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(
                            enabled ? OniTanTheme.cardBorder : OniTanTheme.cardBorder.opacity(0.4),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(enabled ? 0.22 : 0.10), radius: 8, y: 4)
        .scaleEffect(isPressed && enabled ? 0.97 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }

    private var iconGradient: LinearGradient {
        switch mode {
        case .quick10:
            return LinearGradient(
                colors: [Color(red: 1.0, green: 0.50, blue: 0.0), Color(red: 0.90, green: 0.35, blue: 0.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .categoryFocus:
            return OniTanTheme.primaryGradient
        case .weakFocus:
            return LinearGradient(
                colors: [OniTanTheme.accentWeak, Color(red: 0.90, green: 0.40, blue: 0.0)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mistakeReview:
            return LinearGradient(
                colors: [Color(red: 0.55, green: 0.20, blue: 0.55), Color(red: 0.35, green: 0.08, blue: 0.38)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .masteryReview:
            return LinearGradient(
                colors: [Color(red: 0.20, green: 0.50, blue: 0.90), Color(red: 0.10, green: 0.35, blue: 0.70)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .examMini:
            return LinearGradient(
                colors: [Color(red: 0.70, green: 0.15, blue: 0.15), Color(red: 0.50, green: 0.05, blue: 0.05)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return OniTanTheme.primaryGradient
        }
    }
}
