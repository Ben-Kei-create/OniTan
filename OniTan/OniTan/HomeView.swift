import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("themeColor") private var themeColor: String = "classic"
    
    // Computed property for selected theme color
    private var selectedThemeColor: Color {
        switch themeColor {
        case "natural":
            return .green
        case "passion":
            return .red
        case "elegant":
            return .purple
        case "sunshine":
            return .orange
        default:
            return .blue // classic
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack(spacing: 30) {
                    // Review completion message overlay
                    if appState.showReviewCompletion {
                        Text("復習完了！")
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.red)
                            .transition(.scale.combined(with: .opacity))
                            .animation(.easeInOut(duration: 0.5), value: appState.showReviewCompletion)
                    }
                    
                    Text("鬼単")
                        .font(.system(size: 80, weight: .bold))
                        .padding(.bottom, 40)
                    
                    NavigationLink(destination: StageSelectView()) {
                        Text("スタート")
                            .font(.title)
                            .padding()
                            .frame(maxWidth: 200)
                            .background(selectedThemeColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: selectedThemeColor.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    
                    // Review Mode Button
                    NavigationLink(destination: reviewDestination) {
                        HStack(spacing: 10) {
                            Text("復習モード")
                            let totalReviewQuestions = appState.incorrectQuestions.count + appState.bookmarkedQuestions.count
                            if totalReviewQuestions > 0 {
                                Text("\(totalReviewQuestions)")
                                    .font(.body.bold())
                                    .padding(8)
                                    .background(Color.white.opacity(0.3))
                                    .clipShape(Circle())
                            }
                        }
                        .font(.title)
                        .padding()
                        .frame(maxWidth: 200)
                        .background(appState.incorrectQuestions.count + appState.bookmarkedQuestions.count == 0 ? Color.gray : Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(color: (appState.incorrectQuestions.count + appState.bookmarkedQuestions.count == 0 ? Color.gray : Color.orange).opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                    .disabled(appState.incorrectQuestions.count + appState.bookmarkedQuestions.count == 0)
                    
                    NavigationLink(destination: SettingsView()) {
                        Text("設定")
                            .font(.title)
                            .padding()
                            .frame(maxWidth: 200)
                            .background(selectedThemeColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(color: selectedThemeColor.opacity(0.3), radius: 5, x: 0, y: 3)
                    }
                }
                .navigationBarHidden(true)
            }
        }
    }
    
    private var reviewDestination: some View {
        let incorrectKanji = appState.incorrectQuestions
        let bookmarkedKanji = appState.bookmarkedQuestions
        let allQuestions = quizData.stages.flatMap { $0.questions }
        
        // Combine incorrect and bookmarked questions, removing duplicates
        let reviewKanji = incorrectKanji.union(bookmarkedKanji)
        let reviewQuestions = allQuestions.filter { reviewKanji.contains($0.kanji) }
        
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
