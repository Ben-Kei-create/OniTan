import SwiftUI

// MARK: - Training Stage Picker View

/// Shows category-specific stages for a chosen CategoryEntry.
/// Each stage launches directly into MainView; intermediate training modes are
/// intentionally omitted so the user can pick a focused block and start.
struct TrainingModePickerView: View {
    let category: CategoryEntry

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository
    @EnvironmentObject var masteryRepo: MasteryRepository
    @EnvironmentObject var streakRepo: StreakRepository
    @EnvironmentObject var xpRepo: GamificationRepository
    @EnvironmentObject var themeManager: ThemeManager

    private static let stageSize = 15

    private var categoryTitle: String {
        category.title.replacingOccurrences(of: "道場", with: "")
    }

    private var accentColor: Color {
        Color(hex: category.colorHex)
    }

    private var categoryQuestionPool: [Question] {
        let kindSet = Set(category.questionKinds)
        var seen = Set<String>()
        let filtered = allQuestions
            .filter { kindSet.contains($0.kind) && $0.kind.isExamEligible }
            .filter { seen.insert($0.id).inserted }

        // Sort by difficulty ascending so early stages start with easier
        // questions, keeping original relative order within the same difficulty.
        return filtered
            .enumerated()
            .sorted { lhs, rhs in
                let lhsDifficulty = lhs.element.difficulty ?? Int.max
                let rhsDifficulty = rhs.element.difficulty ?? Int.max
                if lhsDifficulty != rhsDifficulty { return lhsDifficulty < rhsDifficulty }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    private var stageEntries: [CategoryStageEntry] {
        guard !categoryQuestionPool.isEmpty else { return [] }

        return stride(from: 0, to: categoryQuestionPool.count, by: Self.stageSize)
            .enumerated()
            .map { index, start in
                let end = min(start + Self.stageSize, categoryQuestionPool.count)
                let questions = Array(categoryQuestionPool[start..<end])
                let stageNumber = syntheticStageBase + index + 1
                let displayNumber = index + 1

                return CategoryStageEntry(
                    id: stageNumber,
                    stage: Stage(stage: stageNumber, questions: questions),
                    title: "Stage \(displayNumber)",
                    detail: stageDetail(for: questions)
                )
            }
    }

    private var syntheticStageBase: Int {
        switch category.id {
        case "reading": return 10_000
        case "commonKanji": return 11_000
        case "errorCorrection": return 12_000
        case "yojijukugo": return 13_000
        case "synonym_antonym": return 14_000
        case "proverb": return 15_000
        case "passage": return 16_000
        default:
            let stableOffset = category.id.unicodeScalars.reduce(0) { $0 + Int($1.value) }
            return 20_000 + stableOffset
        }
    }

    private var totalQuestionCount: Int {
        categoryQuestionPool.count
    }

    private var clearedStageCount: Int {
        stageEntries.filter { appState.isCleared($0.stage.stage) }.count
    }

    private var totalStageCount: Int {
        stageEntries.count
    }

    private var stageProgress: Double {
        guard totalStageCount > 0 else { return 0 }
        return Double(clearedStageCount) / Double(totalStageCount)
    }

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback.ignoresSafeArea()

            VStack(spacing: 0) {
                poolHeader

                ScrollView {
                    LazyVStack(spacing: 12) {
                        if stageEntries.isEmpty {
                            emptyPoolNote
                        } else {
                            ForEach(Array(stageEntries.enumerated()), id: \.element.id) { index, entry in
                                stageRow(
                                    entry: entry,
                                    isUnlocked: isStageUnlocked(at: index)
                                )
                            }
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
        .toolbarColorScheme(themeManager.preferredColorScheme == .dark ? .dark : .light, for: .navigationBar)
    }

    // MARK: - Subviews

    private var poolHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(categoryTitle)
                    .font(.system(size: 24, weight: .black, design: .rounded))
                    .foregroundColor(OniTanTheme.textPrimary)

                Text("\(totalQuestionCount) 問")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.12))
                            .overlay(Capsule().stroke(accentColor.opacity(0.28), lineWidth: 1))
                    )
            }

            Text(category.description)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(OniTanTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            if totalStageCount > 0 {
                stageProgressView
            }

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

    private var stageProgressView: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Text("進捗")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(OniTanTheme.textSecondary)

                Text("Stage \(clearedStageCount)/\(totalStageCount) クリア")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(OniTanTheme.cardBackgroundPressed)

                    Capsule()
                        .fill(accentColor)
                        .frame(width: geometry.size.width * stageProgress)
                }
            }
            .frame(height: 6)
        }
    }

    @ViewBuilder
    private func stageRow(entry: CategoryStageEntry, isUnlocked: Bool) -> some View {
        if isUnlocked {
            NavigationLink(
                destination: MainView(
                    stage: entry.stage,
                    appState: appState,
                    statsRepo: statsRepo,
                    streakRepo: streakRepo,
                    xpRepo: xpRepo,
                    masteryRepo: masteryRepo,
                    mode: .normal,
                    clearTitle: "\(categoryTitle) \(entry.title) クリア！",
                    sessionTitle: "\(categoryTitle) \(entry.title)"
                )
            ) {
                CategoryStageCard(
                    title: entry.title,
                    detail: entry.detail,
                    questionCount: entry.stage.questions.count,
                    systemImage: category.iconName,
                    accentColor: accentColor,
                    isCleared: appState.isCleared(entry.stage.stage),
                    isLocked: false,
                    accuracy: accuracy(for: entry)
                )
            }
            .buttonStyle(OniPressScaleButtonStyle(pressedScale: 0.98, animationDuration: 0.1))
            .accessibilityLabel("\(categoryTitle) \(entry.title) \(entry.stage.questions.count)問")
            .accessibilityHint("タップして\(entry.title)を開始")
        } else {
            CategoryStageCard(
                title: entry.title,
                detail: entry.detail,
                questionCount: entry.stage.questions.count,
                systemImage: "lock.fill",
                accentColor: accentColor,
                isCleared: false,
                isLocked: true,
                accuracy: accuracy(for: entry)
            )
            .accessibilityLabel("\(categoryTitle) \(entry.title) ロック中")
            .accessibilityHint("前のStageをクリアすると解放されます")
        }
    }

    private var emptyPoolNote: some View {
        VStack(spacing: 8) {
            Image(systemName: "tray")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(accentColor)
                .accessibilityHidden(true)

            Text("この道場には問題データがまだありません")
                .font(.system(.subheadline, design: .rounded))
                .foregroundColor(OniTanTheme.textSecondary)
                .multilineTextAlignment(.center)

            Text("今後のアップデートで追加される予定です。他の道場で学習を進めましょう。")
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

    private func accuracy(for entry: CategoryStageEntry) -> Double? {
        guard let stats = statsRepo.stageStats[entry.stage.stage],
              stats.totalAttempts > 0 else { return nil }
        return stats.accuracy
    }

    private func isStageUnlocked(at index: Int) -> Bool {
        guard index > 0 else { return true }
        return appState.isCleared(stageEntries[index - 1].stage.stage)
    }

    private func stageDetail(for questions: [Question]) -> String {
        var seen = Set<String>()
        let names = questions
            .map(\.kind.displayName)
            .filter { seen.insert($0).inserted }

        if names.isEmpty {
            return category.description
        }
        return names.joined(separator: " / ")
    }
}

// MARK: - Category Stage Entry

private struct CategoryStageEntry: Identifiable {
    let id: Int
    let stage: Stage
    let title: String
    let detail: String
}

// MARK: - Category Stage Card

private struct CategoryStageCard: View {
    let title: String
    let detail: String
    let questionCount: Int
    let systemImage: String
    let accentColor: Color
    let isCleared: Bool
    let isLocked: Bool
    let accuracy: Double?

    var body: some View {
        HStack(spacing: 14) {
            OniSymbolMark(
                systemName: isLocked ? "lock.fill" : systemImage,
                size: 48,
                fontSize: isLocked ? 18 : 20,
                tint: isLocked ? OniTanTheme.textTertiary : accentColor,
                fillOpacity: isLocked ? 0.10 : 0.14
            )

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 17, weight: .black, design: .rounded))
                        .foregroundColor(isLocked ? OniTanTheme.textTertiary : OniTanTheme.textPrimary)

                    Text("\(questionCount) 問")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(isLocked ? OniTanTheme.textTertiary : accentColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill((isLocked ? OniTanTheme.textTertiary : accentColor).opacity(0.10))
                                .overlay(
                                    Capsule()
                                        .stroke((isLocked ? OniTanTheme.textTertiary : accentColor).opacity(0.22), lineWidth: 1)
                                )
                        )
                }

                Text(isLocked ? "前のStageをクリアすると解放されます" : detail)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(isLocked ? OniTanTheme.textTertiary : OniTanTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            if isLocked {
                Text("ロック")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(OniTanTheme.cardBackgroundPressed)
                            .overlay(Capsule().stroke(OniTanTheme.cardBorder, lineWidth: 1))
                    )
            } else if isCleared {
                Text("完了")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(OniTanTheme.cardBackground)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(OniTanTheme.accentCorrect))
            } else if let accuracy {
                Text("\(Int(accuracy * 100))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(OniTanTheme.cardBackgroundPressed)
                            .overlay(Capsule().stroke(OniTanTheme.cardBorder, lineWidth: 1))
                    )
            }

            if !isLocked {
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
                .fill(isLocked ? OniTanTheme.cardBackground.opacity(0.56) : OniTanTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(isLocked ? OniTanTheme.cardBorder.opacity(0.55) : OniTanTheme.cardBorder, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(isLocked ? 0.10 : 0.24), radius: 9, y: 4)
    }
}
