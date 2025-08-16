import SwiftUI

struct StageSelectView: View {
    // Persistently store the highest stage the user has unlocked. Default is 1.
    @AppStorage("unlockedStage") var unlockedStage = 1
    
    // Access the global quiz data which is loaded in Data.swift
    private let stages = quizData.stages.sorted { $0.stage < $1.stage }

    var body: some View {
        List(stages, id: \.stage) { stage in
            // A stage is unlocked if its number is less than or equal to the highest unlocked stage
            let isUnlocked = stage.stage <= unlockedStage
            
            // NavigationLink to the quiz view for the selected stage
            NavigationLink(destination: MainView(stage: stage)) {
                HStack(spacing: 15) {
                    Image(systemName: isUnlocked ? "lock.open.fill" : "lock.fill")
                        .foregroundColor(isUnlocked ? .green : .secondary)
                        .font(.title)
                    Text("ステージ \(stage.stage)")
                        .font(.title2)
                        .strikethrough(!isUnlocked, color: .secondary)
                }
                .padding(.vertical, 10)
            }
            .disabled(!isUnlocked) // Disable navigation for locked stages
        }
        .navigationTitle("ステージ選択")
    }
}

struct StageSelectView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            StageSelectView()
        }
    }
}
