import SwiftUI

struct StatsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository

    private let stages = quizData.stages.sorted { $0.stage < $1.stage }

    var body: some View {
        List {
            ForEach(stages, id: \.stage) { stage in
                Section(header: stageHeader(stage)) {
                    stageStatsRows(stage)
                }
            }
        }
        .navigationTitle("学習統計")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Section Header

    private func stageHeader(_ stage: Stage) -> some View {
        HStack {
            Text("ステージ \(stage.stage)")
            Spacer()
            if appState.isCleared(stage.stage) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }

    // MARK: - Stats Rows

    @ViewBuilder
    private func stageStatsRows(_ stage: Stage) -> some View {
        if let stats = statsRepo.stageStats[stage.stage] {
            HStack {
                Text("正答率")
                Spacer()
                Text(String(format: "%.0f%%", stats.accuracy * 100))
                    .foregroundColor(stats.accuracy >= 0.8 ? .green : .orange)
                    .fontWeight(.semibold)
            }

            HStack {
                Text("解答回数")
                Spacer()
                Text("\(stats.totalAttempts) 回")
                    .foregroundColor(.secondary)
            }

            if !stats.wrongKanji.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("苦手な漢字")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(stats.wrongKanji.joined(separator: "  "))
                        .font(.title3)
                        .foregroundColor(.red)
                }
                .padding(.vertical, 4)
            }
        } else {
            Text("まだ学習していません")
                .foregroundColor(.secondary)
                .italic()
        }
    }
}
