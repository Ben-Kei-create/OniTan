import SwiftUI

struct StageSelectView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var statsRepo: StudyStatsRepository

    private let stages = quizData.stages.sorted { $0.stage < $1.stage }

    var body: some View {
        List {
            ForEach(stages, id: \.stage) { stage in
                let isCleared = appState.isCleared(stage.stage)
                let isUnlocked = appState.isUnlocked(stage.stage)
                let weakQuestions = statsRepo.weakQuestions(for: stage)
                let weakCount = weakQuestions.count

                // 通常プレイ行
                NavigationLink(destination: MainView(stage: stage, appState: appState, statsRepo: statsRepo)) {
                    HStack(spacing: 20) {
                        if isCleared {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(isUnlocked ? .accentColor : .gray)
                        }

                        VStack(alignment: .leading) {
                            Text("ステージ \(stage.stage)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(isUnlocked ? .primary : .secondary)

                            if !isUnlocked {
                                Text("前のステージをクリアして解放")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            } else if weakCount > 0 {
                                Text("苦手: \(weakCount) 問")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                }
                .disabled(!isUnlocked)
                .listRowBackground(isUnlocked ? Color.clear : Color.gray.opacity(0.1))

                // 復習行（解放済み & 苦手問題あり の場合のみ）
                if isUnlocked && weakCount > 0 {
                    let reviewStage = Stage(stage: stage.stage, questions: weakQuestions)
                    NavigationLink(
                        destination: MainView(
                            stage: reviewStage,
                            appState: appState,
                            statsRepo: statsRepo,
                            clearTitle: "復習完了！"
                        )
                    ) {
                        HStack(spacing: 20) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .resizable()
                                .frame(width: 30, height: 30)
                                .foregroundColor(.orange)

                            VStack(alignment: .leading) {
                                Text("復習モード")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                                Text("苦手 \(weakCount) 問を集中練習")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                        .padding(.leading, 50)
                    }
                    .listRowBackground(Color.orange.opacity(0.06))
                }
            }
        }
        .navigationTitle("ステージ選択")
        .navigationBarTitleDisplayMode(.large)
    }
}
