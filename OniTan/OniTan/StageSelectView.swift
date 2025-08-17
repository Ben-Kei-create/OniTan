import SwiftUI

struct StageSelectView: View {
    @EnvironmentObject var appState: AppState // Access AppState
    
    // Access the global quiz data
    private let stages = quizData.stages.sorted { $0.stage < $1.stage }

    var body: some View {
        List(stages, id: \.stage) { stage in
            // Determine the status of the stage
            let isCleared = appState.clearedStages.contains(stage.stage)
            // A stage is unlocked if it's stage 1, or if the previous stage has been cleared.
            let isUnlocked = (stage.stage == 1) || appState.clearedStages.contains(stage.stage - 1)
            
            NavigationLink(destination: MainView(stage: stage)) {
                HStack(spacing: 15) {
                    // Icon logic based on status
                    if isCleared {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title)
                    } else {
                        Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                            .foregroundColor(isUnlocked ? .blue : .secondary)
                            .font(.title)
                    }
                    
                    Text("ステージ \(stage.stage)")
                        .font(.title2)
                        .strikethrough(!isUnlocked, color: .secondary)
                    
                    Spacer()
                }
                .padding(.vertical, 10)
            }
            .disabled(!isUnlocked)
        }
        .navigationTitle("ステージ選択")
        .onAppear {
            // Removed print statement
        }
    }
}
