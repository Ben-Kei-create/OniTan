import SwiftUI

struct StageSelectView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository

    private let stages = quizData.stages.sorted { $0.stage < $1.stage }
    private let stageManifest = (try? safeLoad("stages.json") as StageManifest)

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(stages, id: \.stage) { stage in
                        StageCard(
                            stage: stage,
                            manifest: stageManifest?.stages.first { $0.id == stage.stage },
                            appState: appState,
                            statsRepo: statsRepo
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("ステージ選択")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

// MARK: - Stage Card

private struct StageCard: View {
    let stage: Stage
    let manifest: StageEntry?
    @ObservedObject var appState: AppState
    @ObservedObject var statsRepo: StudyStatsRepository

    private var isCleared: Bool  { appState.isCleared(stage.stage) }
    private var isUnlocked: Bool { appState.isUnlocked(stage.stage) }
    private var weakCount: Int   { statsRepo.weakQuestions(for: stage).count }
    private var accuracy: Double { statsRepo.stageStats[stage.stage]?.accuracy ?? 0 }

    var body: some View {
        VStack(spacing: 0) {
            // Main stage row
            mainRow

            // Progress bar
            if isUnlocked {
                progressBar
            }

            // Mode selector (unlocked stages only)
            if isUnlocked {
                NavigationLink(destination: QuizModeSelectView(stage: stage)) {
                    modeSelectBadge
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityIdentifier("stage_mode_link_\(stage.stage)")
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
            // Progress ring
            StageProgressRing(
                stageNumber: stage.stage,
                cleared: isCleared,
                progress: accuracy
            )

            // Text info
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(manifest?.title ?? "ステージ \(stage.stage)")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    if let diff = manifest?.difficulty {
                        DifficultyBadge(level: diff)
                    }
                }

                subtitleText
            }

            Spacer()

            // Lock / chevron
            if !isUnlocked {
                Image(systemName: "lock.fill")
                    .foregroundColor(.white.opacity(0.5))
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
                .foregroundColor(.white.opacity(0.5))
        } else if weakCount > 0 {
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(OniTanTheme.accentWeak)
                Text("苦手 \(weakCount) 問")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(OniTanTheme.accentWeak)
            }
        } else if isCleared {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10))
                    .foregroundColor(OniTanTheme.accentCorrect)
                Text("クリア済み")
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(OniTanTheme.accentCorrect)
            }
        } else {
            Text("\(stage.questions.count) 問")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
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
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(isCleared ? OniTanTheme.correctGradient : OniTanTheme.primaryGradient)
                        .frame(width: geo.size.width * fraction, height: 6)
                        .animation(.easeInOut(duration: 0.4), value: fraction)
                }
            }
            .frame(height: 6)
            .padding(.horizontal, 16)

            HStack {
                Text("習得率: \(Int(fraction * 100))%")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
                Spacer()
                if let stats = statsRepo.stageStats[stage.stage] {
                    Text("正答率: \(Int(stats.accuracy * 100))%")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
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
            Image(systemName: "play.fill")
                .font(.system(size: 11, weight: .semibold))
            Text("モードを選んでスタート")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 11))
        }
        .foregroundColor(.white.opacity(0.85))
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.08))
        .cornerRadius(0)  // Bottom of card — inherits parent's corner radius via clipping
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
        if !isUnlocked { return Color.white.opacity(0.05) }
        if isCleared   { return Color(red: 0.10, green: 0.35, blue: 0.20).opacity(0.7) }
        return Color.white.opacity(0.10)
    }

    private var stageCardBorder: Color {
        if isCleared    { return OniTanTheme.accentCorrect.opacity(0.4) }
        if !isUnlocked  { return Color.white.opacity(0.10) }
        return Color.white.opacity(0.20)
    }

    private var accessibilityText: String {
        let base = manifest?.title ?? "ステージ \(stage.stage)"
        if !isUnlocked { return "\(base) ロック中" }
        if isCleared   { return "\(base) クリア済み 正答率\(Int(accuracy * 100))%" }
        if weakCount > 0 { return "\(base) 苦手\(weakCount)問あり" }
        return "\(base) \(stage.questions.count)問"
    }
}

// MARK: - Difficulty Badge

private struct DifficultyBadge: View {
    let level: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...3, id: \.self) { i in
                Image(systemName: i <= level ? "flame.fill" : "flame")
                    .font(.system(size: 8))
                    .foregroundColor(i <= level ? OniTanTheme.accentWeak : .white.opacity(0.3))
            }
        }
        .accessibilityLabel("難易度\(level)")
    }
}
