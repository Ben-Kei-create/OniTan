import SwiftUI

struct StageSelectView: View {
    // Use the new property wrapper to store a Set of cleared stage numbers.
    @AppStorageCodable(wrappedValue: [], "clearedStages") var clearedStages: Set<Int>
    
    // Access the global quiz data
    private let stages = quizData.stages.sorted { $0.stage < $1.stage }

    var body: some View {
        List(stages, id: \.stage) { stage in
            // Determine the status of the stage
            let isCleared = clearedStages.contains(stage.stage)
            // A stage is unlocked if it's stage 1, or if the previous stage has been cleared.
            let isUnlocked = (stage.stage == 1) || clearedStages.contains(stage.stage - 1)
            
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
        .onAppear { // Add onAppear to print clearedStages
            print("StageSelectView: clearedStages onAppear = \(clearedStages)")
        }
    }
}

struct StageSelectView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StageSelectView()
        }
    }
}
