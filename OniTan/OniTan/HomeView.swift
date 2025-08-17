import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("鬼単")
                    .font(.system(size: 80, weight: .bold))
                    .padding(.bottom, 40)
                
                NavigationLink(destination: StageSelectView()) {
                    Text("スタート")
                        .font(.title)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
                // Review Mode Button
                NavigationLink(destination: reviewDestination) {
                    HStack(spacing: 10) {
                        Text("復習モード")
                        if !appState.incorrectQuestions.isEmpty {
                            Text("\(appState.incorrectQuestions.count)")
                                .font(.body.bold())
                                .padding(8)
                                .background(Color.white.opacity(0.3))
                                .clipShape(Circle())
                        }
                    }
                    .font(.title)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(appState.incorrectQuestions.isEmpty ? Color.gray : Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(appState.incorrectQuestions.isEmpty)
                
                NavigationLink(destination: SettingsView()) {
                    Text("設定")
                        .font(.title)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var reviewDestination: some View {
        let incorrectKanji = appState.incorrectQuestions
        let allQuestions = quizData.stages.flatMap { $0.questions }
        let reviewQuestions = allQuestions.filter { incorrectKanji.contains($0.kanji) }
        
        // Shuffle the review questions
        let reviewStage = Stage(stage: 0, questions: reviewQuestions.shuffled())
        
        return MainView(stage: reviewStage, isReviewMode: true)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(AppState()) // Provide AppState for preview
    }
}