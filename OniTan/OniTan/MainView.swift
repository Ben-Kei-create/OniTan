import SwiftUI

struct MainView: View {
    // MARK: - Properties
    let stage: Stage
    
    @EnvironmentObject var appState: AppState // Access AppState
    @Environment(\.presentationMode) var presentationMode

    // MARK: - State Properties
    @State private var currentQuestionIndex = 0
    @State private var consecutiveCorrect = 0
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var showBackToStartButton = false
    @State private var isStageCleared = false
    @State private var showingQuitAlert = false
    @State private var buttonsDisabled = false // State to disable buttons during processing
    

    // Game constants
    private var goal: Int { stage.questions.count }
    private var questions: [Question] { stage.questions }
    private var currentQuestion: Question { questions[currentQuestionIndex] }

    var body: some View {
        ZStack { // Use ZStack for overlaying result feedback
            VStack(spacing: 20) {
                // "辞める" Button - Re-implemented without toolbar
                HStack {
                    Button("辞める") {
                        if appState.clearedStages.contains(stage.stage) {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            showingQuitAlert = true
                        }
                    }
                    .foregroundColor(.red) // Make quit button red
                    Spacer() // Pushes the button to the leading edge
                }
                .padding(.horizontal) // Add horizontal padding to align with other content

                if isStageCleared {
                    // --- Stage Cleared View ---
                    Spacer()
                    Text("ステージ \(stage.stage) クリア！")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                        .padding()
                    Text("🎉 おめでとうございます！ 🎉")
                        .font(.title)
                        .foregroundColor(.primary)
                    Spacer()
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("ステージ選択へ戻る")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: 250, minHeight: 60)
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(30)
                            .shadow(color: Color.green.opacity(0.4), radius: 10, x: 0, y: 10)
                    }
                    Spacer()
                } else {
                    // --- Main Quiz View ---
                    Text("ステージ \(stage.stage)")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.accentColor)
                        .padding(.bottom)

                    Text("進行度: \(consecutiveCorrect) / \(goal) 問") // More descriptive progress
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text(currentQuestion.kanji)
                        .font(.system(size: 150, weight: .heavy, design: .rounded)) // Larger, heavier font
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.5) // Allow text to shrink
                        .lineLimit(1)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: 200) // Fixed size for kanji
                        .background(Color.white.opacity(0.1)) // Subtle background for kanji
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 5)

                    Spacer()

                    if !showResult {
                        VStack(spacing: 15) { // Increased spacing for buttons
                            ForEach(currentQuestion.choices, id: \.self) { choice in
                                Button(action: { self.answer(selected: choice) }) {
                                    Text(choice)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .frame(maxWidth: .infinity, minHeight: 60)
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(15)
                                        .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 5)
                                }
                            }
                        }
                        .padding(.horizontal) // Horizontal padding for buttons
                        .disabled(buttonsDisabled) // Apply disabled modifier here
                    } else {
                        // Display result message more prominently
                        Text(isCorrect ? "○ 正解！" : "× 不正解…")
                            .font(.system(size: 60, weight: .heavy))
                            .foregroundColor(isCorrect ? .green : .red)
                            .transition(.scale) // Simple animation
                        
                        if !isCorrect {
                            Text("正解は「\(currentQuestion.answer)」")
                                .font(.title2)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    if showBackToStartButton {
                        Button(action: resetGame) {
                            Text("最初からやり直す")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(maxWidth: 250, minHeight: 60)
                                .background(Color.orange) // Different color for reset
                                .foregroundColor(.white)
                                .cornerRadius(30)
                                .shadow(color: Color.orange.opacity(0.4), radius: 10, x: 0, y: 10)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .padding()
            .navigationBarBackButtonHidden(true)
            
            .alert(isPresented: $showingQuitAlert) {
                Alert(
                    title: Text("確認"),
                    message: Text("途中で辞めると、ステージクリアになりません。"),
                    primaryButton: .destructive(Text("OK")) {
                        presentationMode.wrappedValue.dismiss()
                    },
                    secondaryButton: .cancel(Text("キャンセル"))
                )
            }
        }
        
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
        )
        
    }

    // MARK: - Game Logic Methods

    func answer(selected: String) {
        // Detect rapid taps
        if buttonsDisabled {
            return
        }

        buttonsDisabled = true // Disable buttons immediately
        if selected == currentQuestion.answer {
            isCorrect = true
            if !showResult {
                consecutiveCorrect += 1
            }
            showResult = true
            
            if consecutiveCorrect >= goal {
                isStageCleared = true
                // 修正: より確実にステージクリア状態を保存
                saveStageCleared()
                return
            }

            // If correct and stage not cleared, move to the next question after a delay
            if !isStageCleared {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    nextQuestion()
                }
            }
        } else {
            isCorrect = false
            showResult = true
            showBackToStartButton = true
            consecutiveCorrect = 0
            buttonsDisabled = false // Re-enable buttons for "最初からやり直す"
        }
    }

    func nextQuestion() {
        guard !isStageCleared else { return }
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            showResult = false
            showBackToStartButton = false
            buttonsDisabled = false // Re-enable buttons
        } else {
            isStageCleared = true
            // 修正: フォールバック時も確実に保存
            saveStageCleared()
            // No need to re-enable buttons here, as the view will dismiss or transition.
        }
    }

    func resetGame() {
        currentQuestionIndex = 0
        consecutiveCorrect = 0
        showResult = false
        showBackToStartButton = false
        buttonsDisabled = false // Re-enable buttons
    }
    
    // 修正: ステージクリア状態を確実に保存するメソッド
    private func saveStageCleared() {
        // Correct way to update a Set property of an ObservableObject
        var newClearedStages = appState.clearedStages // Get a mutable copy
        newClearedStages.insert(stage.stage) // Mutate the copy
        appState.clearedStages = newClearedStages // Assign the new Set to trigger didSet
        
        // 手動で objectWillChange を送信して確実に更新を通知
        // DispatchQueue.main.async {
        //     appState.objectWillChange.send()
        // }
    }
}



struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainView(stage: quizData.stages[0])
        }
    }
}
