import SwiftUI

struct StageSelectView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository
    @EnvironmentObject var themeManager: ThemeManager
    private let stages = quizData.stages.sorted { $0.stage < $1.stage }
    private let stageManifest = (try? safeLoad("stages.json") as StageManifest)
    private var totalStages: Int { max(stages.map(\.stage).max() ?? stages.count, 1) }
    private var orderedStageIDs: [Int] { stages.map(\.stage) }

    private func displayNumber(for stageID: Int) -> Int {
        (stages.firstIndex(where: { $0.stage == stageID }) ?? 0) + 1
    }

    private func nextStage(after stageID: Int) -> Stage? {
        guard let idx = stages.firstIndex(where: { $0.stage == stageID }),
              idx + 1 < stages.count else { return nil }
        return stages[idx + 1]
    }

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                OniTanTheme.backgroundGradientFallback
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        stageOverview

                        ForEach(stages, id: \.stage) { stage in
                            StageCard(
                                stage: stage,
                                displayNumber: displayNumber(for: stage.stage),
                                nextStage: nextStage(after: stage.stage),
                                nextDisplayNumber: nextStage(after: stage.stage).map { displayNumber(for: $0.stage) },
                                manifest: stageManifest?.stages.first { $0.id == stage.stage },
                                totalStages: totalStages,
                                orderedStageIDs: orderedStageIDs,
                                appState: appState,
                                statsRepo: statsRepo
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 28)
                }
            }

        }
        .navigationTitle("ステージ選択")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var stageOverview: some View {
        let cleared = appState.clearedStages.count
        let progress = stages.isEmpty ? 0 : Double(cleared) / Double(stages.count)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("基礎ステージ")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(OniTanTheme.textPrimary)
                    Text("一段ずつ、読みの土台を固める。")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(OniTanTheme.textSecondary)
                }

                Spacer()

                Text("\(cleared)/\(stages.count)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundColor(OniTanTheme.accentWeak)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(OniTanTheme.cardBackgroundPressed.opacity(0.65))
                    Capsule()
                        .fill(OniTanTheme.goldGradient)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 5)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(OniTanTheme.cardBackground.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(OniTanTheme.cardBorder, lineWidth: 1)
                )
        )
    }
}

// MARK: - Stage Card

private struct StageCard: View {
    let stage: Stage
    let displayNumber: Int
    let nextStage: Stage?
    let nextDisplayNumber: Int?
    let manifest: StageEntry?
    let totalStages: Int
    let orderedStageIDs: [Int]
    @ObservedObject var appState: AppState
    @ObservedObject var statsRepo: StudyStatsRepository
    @EnvironmentObject var streakRepo: StreakRepository
    @EnvironmentObject var xpRepo: GamificationRepository
    @EnvironmentObject var masteryRepo: MasteryRepository

    private var isCleared: Bool  { appState.isCleared(stage.stage) }
    private var isUnlocked: Bool { appState.isUnlocked(stage.stage, orderedStageIDs: orderedStageIDs) }
    private var sessionTitle: String { "ステージ \(displayNumber)" }
    private var weakCount: Int   { statsRepo.weakQuestions(for: stage).count }
    private var accuracy: Double { statsRepo.stageStats[stage.stage]?.accuracy ?? 0 }
    private var nextStageTitle: String? { nextDisplayNumber.map { "ステージ \($0)" } }

    var body: some View {
        VStack(spacing: 0) {
            if isUnlocked {
                NavigationLink(
                    destination: MainView(
                        stage: stage,
                        appState: appState,
                        statsRepo: statsRepo,
                        streakRepo: streakRepo,
                        xpRepo: xpRepo,
                        masteryRepo: masteryRepo,
                        mode: weakCount > 0 ? .weakFocus : .normal,
                        clearTitle: "\(sessionTitle) クリア！",
                        sessionTitle: sessionTitle,
                        nextStage: nextStage,
                        nextStageTitle: nextStageTitle
                    )
                ) {
                    VStack(spacing: 0) {
                        mainRow
                        progressBar
                    }
                }
                .buttonStyle(PlainButtonStyle())

                NavigationLink(
                    destination: QuizModeSelectView(
                        stage: stage,
                        sessionTitle: sessionTitle,
                        nextStage: nextStage,
                        nextStageTitle: nextStageTitle
                    )
                ) {
                    modeSelectBadge
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityIdentifier("stage_mode_link_\(stage.stage)")
            } else {
                mainRow
            }
        }
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(stageCardColor)
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(stageCardBorder, lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.25), radius: 10, y: 5)
        .opacity(isUnlocked ? 1.0 : 0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityText)
        .accessibilityIdentifier("stage_card_\(stage.stage)")
    }

    // MARK: Main Row

    private var mainRow: some View {
        HStack(spacing: 14) {
            StageProgressRing(
                stageNumber: stage.stage,
                cleared: isCleared,
                progress: accuracy
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(sessionTitle)
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(OniTanTheme.textPrimary)

                    DifficultyBadge(stageNumber: stage.stage, totalStages: totalStages)
                }

                subtitleText
            }

            Spacer()

            if isUnlocked {
                Image(systemName: weakCount > 0 ? "exclamationmark.triangle.fill" : "chevron.right")
                    .font(.system(size: weakCount > 0 ? 18 : 14, weight: .semibold))
                    .foregroundColor(weakCount > 0 ? OniTanTheme.accentWrong : OniTanTheme.textTertiary)
                    .accessibilityHidden(true)
            } else {
                Image(systemName: "lock.fill")
                    .foregroundColor(OniTanTheme.textTertiary)
                    .font(.system(size: 18))
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, isUnlocked ? 8 : 16)
    }

    @ViewBuilder
    private var subtitleText: some View {
        if !isUnlocked {
            Text("前のステージをクリアして解放")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(OniTanTheme.textTertiary)
        } else if weakCount > 0 {
            HStack(spacing: 5) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(OniTanTheme.accentWrong)
                Text("苦手 \(weakCount) 問")
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(OniTanTheme.accentWrong)
                Text("→ 苦手モードで開始")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(OniTanTheme.accentWrong.opacity(0.10))
            .cornerRadius(6)
        } else if isCleared {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(OniTanTheme.accentWeak)
                Text("クリア済み")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(OniTanTheme.accentWeak)
            }
        } else {
            Text("\(stage.questions.count) 問")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(OniTanTheme.textTertiary)
        }
    }

    // MARK: Progress Bar

    private var progressBar: some View {
        let total = stage.questions.count
        let mastered = total - weakCount
        let fraction = total > 0 ? Double(mastered) / Double(total) : 0

        return VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(OniTanTheme.cardBorder)
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(OniTanTheme.goldGradient)
                        .frame(width: geo.size.width * fraction, height: 6)
                        .animation(.easeInOut(duration: 0.4), value: fraction)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 16)

            HStack {
                Text("習得率: \(Int(fraction * 100))%")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(OniTanTheme.textTertiary)
                Spacer()
                if let stats = statsRepo.stageStats[stage.stage] {
                    Text("正答率: \(Int(stats.accuracy * 100))%")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(OniTanTheme.textTertiary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 4)
        }
        .accessibilityHidden(true)
    }

    // MARK: Mode Select Badge

    private var modeSelectBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 10, weight: .semibold))
            Text("他のモードで学ぶ")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11))
        }
        .foregroundColor(OniTanTheme.textTertiary)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.16))
        .cornerRadius(0)
        .clipShape(
            .rect(
                topLeadingRadius: 0,
                bottomLeadingRadius: OniTanTheme.radiusCard,
                bottomTrailingRadius: OniTanTheme.radiusCard,
                topTrailingRadius: 0
            )
        )
    }

    // MARK: Colors

    private var stageCardColor: Color {
        if !isUnlocked { return OniTanTheme.cardBackground.opacity(0.5) }
        if isCleared   { return OniTanTheme.cardBackgroundPressed }
        return OniTanTheme.cardBackground
    }

    private var stageCardBorder: Color {
        if isCleared    { return OniTanTheme.accentWeak.opacity(0.34) }
        if !isUnlocked  { return OniTanTheme.cardBorder.opacity(0.5) }
        return OniTanTheme.cardBorder
    }

    private var accessibilityText: String {
        let base = sessionTitle
        if !isUnlocked { return "\(base) ロック中" }
        if isCleared   { return "\(base) クリア済み 正答率\(Int(accuracy * 100))%" }
        if weakCount > 0 { return "\(base) 苦手\(weakCount)問あり" }
        return "\(base) \(stage.questions.count)問"
    }
}

// MARK: - Difficulty Badge

private struct DifficultyBadge: View {
    let stageNumber: Int
    let totalStages: Int

    private var maxStage: CGFloat { CGFloat(max(totalStages, 1)) }
    private var firstThreshold: Int { max(1, Int(ceil(Double(totalStages) / 3.0))) }
    private var secondThreshold: Int { max(firstThreshold + 1, Int(ceil(Double(totalStages) * 2.0 / 3.0))) }

    /// Scale from 8pt (stage 1) to 16pt (final stage).
    private var flameSize: CGFloat {
        let progress = min(CGFloat(stageNumber), maxStage) / maxStage
        return 8 + progress * 8
    }

    /// Number of flames: 1 for the first third, 2 for the middle third, 3 for the final third.
    private var flameCount: Int {
        if stageNumber > secondThreshold { return 3 }
        if stageNumber > firstThreshold { return 2 }
        return 1
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<flameCount, id: \.self) { _ in
                Image(systemName: "flame.fill")
                    .font(.system(size: flameSize))
                    .foregroundColor(OniTanTheme.accentWeak.opacity(0.78))
            }
        }
        .accessibilityLabel("難易度レベル\(stageNumber)")
    }
}
