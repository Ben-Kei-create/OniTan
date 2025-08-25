
import SwiftUI

struct StageSelectView: View {
    @EnvironmentObject var progressStore: ProgressStore
    @Environment(\.quizData) var quizData
    
    private var stages: [Stage] {
        quizData.stages.sorted { $0.stage < $1.stage }
    }

    var body: some View {
        List {
            ForEach(stages, id: \.stage) { stage in
                let isCleared = progressStore.clearedStages.contains(stage.stage)
                let isUnlocked = (stage.stage == 1) || progressStore.clearedStages.contains(stage.stage - 1)
                
                StageRowView(stage: stage, isCleared: isCleared, isUnlocked: isUnlocked)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("ステージ選択")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct StageRowView: View {
    let stage: Stage
    let isCleared: Bool
    let isUnlocked: Bool
    @EnvironmentObject var progressStore: ProgressStore
    @Environment(\.quizData) var quizData

    var body: some View {
        NavigationLink(destination: MainView(stage: stage, isReviewMode: false, progressStore: progressStore, quizData: quizData)) {
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
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 8)
        }
        .disabled(!isUnlocked)
        .listRowBackground(isUnlocked ? Color.clear : Color(.systemGray6).opacity(0.5))
    }
}

struct StageSelectView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StageSelectView()
        }
        .environmentObject(ProgressStore())
        .environment(\.quizData, QuizDataLoader().load())
    }
}
