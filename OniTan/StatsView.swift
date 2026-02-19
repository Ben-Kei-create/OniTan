import SwiftUI

struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository

    private let stages = quizData.stages.sorted { $0.stage < $1.stage }

    var body: some View {
        ZStack {
            OniTanTheme.backgroundGradientFallback
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Overall summary card
                    overallSummaryCard

                    // Per-stage cards
                    ForEach(stages, id: \.stage) { stage in
                        StageStatCard(
                            stage: stage,
                            stats: statsRepo.stageStats[stage.stage],
                            isCleared: appState.isCleared(stage.stage)
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle("学習統計")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Overall Summary

    private var overallSummaryCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 0) {
                summaryMetric(
                    value: "\(appState.clearedStages.count) / \(stages.count)",
                    label: "クリアステージ",
                    icon: "trophy.fill",
                    iconColor: OniTanTheme.accentCorrect
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.15))

                summaryMetric(
                    value: String(format: "%.0f%%", statsRepo.overallAccuracy * 100),
                    label: "総合正答率",
                    icon: "chart.bar.fill",
                    iconColor: OniTanTheme.accentPrimary
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.15))

                summaryMetric(
                    value: "\(statsRepo.totalCorrect)",
                    label: "総正解数",
                    icon: "bolt.fill",
                    iconColor: OniTanTheme.accentWeak
                )
            }

            // Overall progress bar
            VStack(spacing: 4) {
                let p = appState.overallProgress(totalStages: stages.count)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.15))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(OniTanTheme.primaryGradient)
                            .frame(width: geo.size.width * p, height: 6)
                            .animation(.easeInOut(duration: 0.5), value: p)
                    }
                }
                .frame(height: 6)

                HStack {
                    Text("全体進捗")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.45))
                    Spacer()
                    Text("\(Int(p * 100))%")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(Color.white.opacity(0.10))
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("総合統計: \(appState.clearedStages.count)/\(stages.count)ステージクリア 正答率\(Int(statsRepo.overallAccuracy * 100))% 総正解\(statsRepo.totalCorrect)問")
    }

    private func summaryMetric(value: String, label: String, icon: String, iconColor: Color) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(iconColor)

            Text(value)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.black)
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }
}

// MARK: - Stage Stat Card

private struct StageStatCard: View {
    let stage: Stage
    let stats: StageStats?
    let isCleared: Bool

    var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("ステージ \(stage.stage)")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.white)

                Spacer()

                if isCleared {
                    Label("クリア済み", systemImage: "checkmark.circle.fill")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(OniTanTheme.accentCorrect)
                        .accessibilityLabel("クリア済み")
                }
            }

            if let stats {
                // Accuracy bar
                VStack(spacing: 4) {
                    HStack {
                        Text("正答率")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.white.opacity(0.55))
                        Spacer()
                        Text(String(format: "%.0f%%", stats.accuracy * 100))
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(stats.accuracy >= 0.8 ? OniTanTheme.accentCorrect : OniTanTheme.accentWeak)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(stats.accuracy >= 0.8 ? OniTanTheme.correctGradient : OniTanTheme.primaryGradient)
                                .frame(width: geo.size.width * stats.accuracy, height: 6)
                                .animation(.easeInOut(duration: 0.5), value: stats.accuracy)
                        }
                    }
                    .frame(height: 6)
                }

                // Metrics row
                HStack(spacing: 0) {
                    miniMetric(value: "\(stats.totalAttempts)", label: "解答回数")
                    Divider().frame(height: 28).background(Color.white.opacity(0.15))
                    miniMetric(value: "\(stats.correctAttempts)", label: "正解")
                    Divider().frame(height: 28).background(Color.white.opacity(0.15))
                    miniMetric(value: "\(stats.wrongKanji.count)", label: "苦手漢字")
                }

                // Weak kanji display
                if !stats.wrongKanji.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("苦手な漢字")
                            .font(.system(.caption2, design: .rounded))
                            .foregroundColor(OniTanTheme.accentWeak)

                        FlowLayout(spacing: 8) {
                            ForEach(stats.wrongKanji, id: \.self) { kanji in
                                Text(kanji)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(OniTanTheme.wrongGradient)
                                    .cornerRadius(10)
                                    .accessibilityLabel("苦手漢字: \(kanji)")
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

            } else {
                HStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .foregroundColor(.white.opacity(0.3))
                    Text("まだ学習していません")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                        .italic()
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: OniTanTheme.radiusCard)
                        .stroke(isCleared ? OniTanTheme.accentCorrect.opacity(0.3) : Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.15), radius: 6, y: 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private func miniMetric(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.headline, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 9, design: .rounded))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private var accessibilityLabel: String {
        guard let s = stats else {
            return "ステージ\(stage.stage) 未学習"
        }
        return "ステージ\(stage.stage) 正答率\(Int(s.accuracy * 100))% 解答\(s.totalAttempts)回 苦手\(s.wrongKanji.count)漢字"
    }
}

// MARK: - Simple Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                y += lineHeight + spacing
                x = 0
                lineHeight = 0
            }
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            totalHeight = y + lineHeight
        }

        return CGSize(width: maxWidth, height: totalHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x: CGFloat = bounds.minX
        var y: CGFloat = bounds.minY
        var lineHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width - bounds.minX > maxWidth, x > bounds.minX {
                y += lineHeight + spacing
                x = bounds.minX
                lineHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
        }
    }
}
