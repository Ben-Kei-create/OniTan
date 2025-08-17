import SwiftUI

struct StageSelectView: View {
    @EnvironmentObject var appState: AppState // Access AppState
    
    // Access the global quiz data
    private let stages: [Stage] = {
        let sortedStages = quizData.stages.sorted { $0.stage < $1.stage }
        return sortedStages
    }()

    var body: some View {
        List { // Use a simple List for sections
            ForEach(stages, id: \.stage) { stage in
                // Determine the status of the stage
                let isCleared = appState.clearedStages.contains(stage.stage)
                // A stage is unlocked if it's stage 1, or if the previous stage has been cleared.
                let isUnlocked = (stage.stage == 1) || appState.clearedStages.contains(stage.stage - 1)
                
                StageRowView(stage: stage, isCleared: isCleared, isUnlocked: isUnlocked)
            }
        }
        .navigationTitle("ステージ選択")
        .navigationBarTitleDisplayMode(.large) // Ensure large title
        .onAppear {
            // Removed print statement
        }
    }
}

struct StageRowView: View {
    let stage: Stage
    let isCleared: Bool
    let isUnlocked: Bool

    var body: some View {
        NavigationLink(destination: MainView(stage: stage, isReviewMode: false)) {
            HStack(spacing: 20) { // Increased spacing
                // Icon logic based on status
                if isCleared {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(.green)
                } else {
                    Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .foregroundColor(isUnlocked ? .accentColor : .gray) // Use accentColor for unlocked
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
            .padding(.vertical, 8) // Vertical padding for list item
        }
        .disabled(!isUnlocked) // Disable navigation for locked stages
        .listRowBackground(isUnlocked ? Color.clear : Color(.systemGray6).opacity(0.5)) // Adaptive background for locked rows
    }
}