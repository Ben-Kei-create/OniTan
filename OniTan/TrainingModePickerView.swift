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
    /// For categories backed by stageIDs, the curated stage questions are used.
    /// TrainingSessionBuilder applies the final exam-eligible filter before launch.
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
                    .padding(.vertical, 18)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(category.title.replacingOccurrences(of: "道場", with: ""))
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(OniTanTheme.textPrimary)

                Text("\(categoryPool.count) 問")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(OniTanTheme.accentWeak)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(OniTanTheme.accentWeak.opacity(0.12))
                            .overlay(Capsule().stroke(OniTanTheme.accentWeak.opacity(0.28), lineWidth: 1))
                    )
            }

            Text(category.description)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(OniTanTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Rectangle()
                .fill(OniTanTheme.goldGradient)
                .frame(width: 44, height: 2)
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [OniTanTheme.cardBackground.opacity(0.72), Color.black.opacity(0.02)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(OniTanTheme.accentWeak)
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
                .fill(OniTanTheme.cardBackground.opacity(0.76))
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(OniTanTheme.cardBorder, lineWidth: 1)
                )
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
            ZStack {
                RoundedRectangle(cornerRadius: 13)
                    .fill(iconGradient)
                    .overlay(
                        RoundedRectangle(cornerRadius: 13)
                            .stroke(iconStroke, lineWidth: 1)
                    )
                    .frame(width: 48, height: 48)
                    .opacity(enabled ? 1.0 : 0.38)

                Text(sealMark)
                    .font(.system(size: 20, weight: .black, design: .serif))
                    .foregroundColor(enabled ? markColor : OniTanTheme.textTertiary.opacity(0.55))
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(label)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(enabled ? OniTanTheme.textPrimary : OniTanTheme.textTertiary)

                    if enabled {
                        Text("\(questionCount) 問")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(OniTanTheme.accentWeak)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(OniTanTheme.accentWeak.opacity(0.10))
                                    .overlay(Capsule().stroke(OniTanTheme.accentWeak.opacity(0.22), lineWidth: 1))
                            )
                    } else {
                        Text("準備中")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(OniTanTheme.textTertiary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(OniTanTheme.cardBackgroundPressed.opacity(0.5))
                                    .overlay(Capsule().stroke(OniTanTheme.cardBorder.opacity(0.5), lineWidth: 1))
                            )
                    }
                }

                if let reason = disabledReason {
                    Text(reason)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(OniTanTheme.textTertiary.opacity(0.7))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(mode.description)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(enabled ? OniTanTheme.textSecondary : OniTanTheme.textTertiary.opacity(0.45))
                        .lineLimit(2)
                }
            }

            Spacer()

            if enabled {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(OniTanTheme.textTertiary)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(enabled ? OniTanTheme.cardBackground : OniTanTheme.cardBackground.opacity(0.46))
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(
                            enabled ? OniTanTheme.cardBorder : OniTanTheme.cardBorder.opacity(0.35),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: .black.opacity(enabled ? 0.24 : 0.08), radius: 9, y: 4)
        .scaleEffect(isPressed && enabled ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded   { _ in isPressed = false }
        )
    }

    private var sealMark: String {
        switch mode {
        case .quick10: return "十"
        case .categoryFocus: return "鍛"
        case .weakFocus: return "弱"
        case .mistakeReview: return "誤"
        case .masteryReview: return "定"
        case .examMini: return "試"
        default: return "修"
        }
    }

    private var markColor: Color {
        switch mode {
        case .quick10, .weakFocus: return OniTanTheme.accentWeak
        case .examMini: return OniTanTheme.textPrimary
        default: return OniTanTheme.textPrimary
        }
    }

    private var iconStroke: Color {
        switch mode {
        case .quick10, .weakFocus:
            return OniTanTheme.accentWeak.opacity(0.35)
        case .examMini:
            return OniTanTheme.accentPrimary.opacity(0.42)
        default:
            return OniTanTheme.cardBorder
        }
    }

    private var iconGradient: LinearGradient {
        switch mode {
        case .quick10:
            return LinearGradient(
                colors: [OniTanTheme.accentWeak.opacity(0.22), OniTanTheme.cardBackgroundPressed],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .categoryFocus:
            return LinearGradient(
                colors: [OniTanTheme.accentPrimary.opacity(0.28), OniTanTheme.cardBackgroundPressed],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .weakFocus:
            return LinearGradient(
                colors: [OniTanTheme.accentWeak.opacity(0.24), OniTanTheme.cardBackgroundPressed],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mistakeReview:
            return LinearGradient(
                colors: [OniTanTheme.accentPrimary.opacity(0.24), OniTanTheme.cardBackgroundPressed],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .masteryReview:
            return LinearGradient(
                colors: [OniTanTheme.accentWeak.opacity(0.18), OniTanTheme.cardBackgroundPressed],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        case .examMini:
            return LinearGradient(
                colors: [OniTanTheme.accentPrimary.opacity(0.52), OniTanTheme.cardBackgroundPressed],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(
                colors: [OniTanTheme.accentPrimary.opacity(0.24), OniTanTheme.cardBackgroundPressed],
                startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
