import SwiftUI

struct MainView: View {
    // MARK: - Properties
    let stage: Stage // Keep stage for normal mode
    let isReviewMode: Bool
    
    @EnvironmentObject var appState: AppState // Access AppState
    @Environment(\.presentationMode) var presentationMode

    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true

    // MARK: - State Properties
    @State private var currentQuestionIndex = 0
    @State private var consecutiveCorrect = 0
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var showBackToStartButton = false
    @State private var isStageCleared = false
    @State private var showingQuitAlert = false
    @State private var buttonsDisabled = false // State to disable buttons during processing
    @State private var showExplanation = false // State for showing explanation
    
    @State private var questions: [Question] // Now a @State property
    @State private var goal: Int // Now a @State property

    // Computed property for currentQuestion
    private var currentQuestion: Question {
        if questions.isEmpty {
            print("DEBUG: currentQuestion accessed when questions is empty. currentQuestionIndex: \(currentQuestionIndex)")
            // Return a dummy question to prevent crash, but this should not be accessed
            return Question(kanji: "", answer: "", choices: [], explain: "")
        } else if currentQuestionIndex >= questions.count {
            print("DEBUG: currentQuestion accessed with out-of-bounds index. currentQuestionIndex: \(currentQuestionIndex), questions.count: \(questions.count)")
            return questions[0] // Fallback to first question
        }
        return questions[currentQuestionIndex]
    }

    // Custom initializer
    init(stage: Stage, isReviewMode: Bool = false) {
        self.stage = stage
        self.isReviewMode = isReviewMode
        
        // Initialize @State properties
        _questions = State(initialValue: stage.questions)
        _goal = State(initialValue: stage.questions.count)
    }

    var body: some View {
        ZStack { // Use ZStack for overlaying result feedback
            // If in review mode and no questions left, dismiss to home
            if isReviewMode && (questions.isEmpty || consecutiveCorrect >= goal) {
                Color.clear
                    .onAppear {
                        appState.showReviewCompletion = true
                        presentationMode.wrappedValue.dismiss()
                    }
            } else {
                VStack(spacing: 20) {
                    // "辞める" Button - Re-implemented without toolbar
                    HStack {
                        Button("辞める") {
                            if isReviewMode {
                                presentationMode.wrappedValue.dismiss()
                            } else if appState.clearedStages.contains(stage.stage) {
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
                        // --- Stage Cleared View (for normal stages) ---
                        Spacer()
                        Text("ステージ \(stage.stage) クリア！")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                            .padding()
                        Text("おめでとうございます！")
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
                        .padding(.bottom, 20)
                    } else {
                        // --- Main Quiz View ---
                        Text(isReviewMode ? "復習モード" : "ステージ \(stage.stage)")
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
                                    Button(action: {
                                        if hapticsEnabled {
                                            HapticsManager.shared.impact(style: .light)
                                        }
                                        self.answer(selected: choice)
                                    }) {
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
        }
        
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
        )
        .onChange(of: appState.incorrectQuestions) { oldQuestions, newQuestions in
            if isReviewMode {
                // Re-filter questions based on the updated incorrectQuestions list
                let allQuestions = quizData.stages.flatMap { $0.questions }
                questions = allQuestions.filter { newQuestions.contains($0.kanji) }.shuffled()
                goal = questions.count

                // If all review questions are cleared, the conditional body will handle dismissal
                // No explicit dismiss here, as ReviewCompletionView will be shown
            }
        }
        // Explanation Overlay
        if showExplanation {
            ExplanationView(question: currentQuestion)
                .onTapGesture {
                    showExplanation = false
                    nextQuestion() // Move to next question after tap
                }
                .transition(.opacity) // Smooth transition
        }
        
    }

    // MARK: - Game Logic Methods

    func answer(selected: String) {
        if buttonsDisabled { return }
        buttonsDisabled = true

        if selected == currentQuestion.answer {
            // --- Correct Answer ---
            if soundEnabled { SoundManager.shared.playSound(sound: .correct) }
            if hapticsEnabled { HapticsManager.shared.play(.success) }

            // If in review mode, remove the question from the list
            if isReviewMode {
                appState.removeIncorrectQuestion(currentQuestion.kanji)
            }

            isCorrect = true
            if !showResult {
                consecutiveCorrect += 1
            }
            showResult = true
            
            if consecutiveCorrect >= goal {
                if isReviewMode {
                    // For review mode, just mark as completed - ReviewCompletionView will be shown
                    return
                } else {
                    isStageCleared = true
                    saveStageCleared()
                    return
                }
            }

            if !isStageCleared && consecutiveCorrect < goal {
                showExplanation = true
                buttonsDisabled = false
            }
        } else {
            // --- Incorrect Answer ---
            if soundEnabled { SoundManager.shared.playSound(sound: .incorrect) }
            if hapticsEnabled { HapticsManager.shared.play(.error) }

            // If in a normal stage, add the question to the review list
            if !isReviewMode {
                appState.addIncorrectQuestion(currentQuestion.kanji)
            }

            isCorrect = false
            showResult = true
            showBackToStartButton = true
            consecutiveCorrect = 0
            buttonsDisabled = false
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
        showExplanation = false // Reset explanation state
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



struct ExplanationView: View {
    let question: Question

    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(question.explain)
                        .font(.body)
                        .foregroundColor(.white) // Make text white for dark background
                }
                .padding()
                .background(Color.black.opacity(0.5)) // Darker background for readability
                .cornerRadius(15)
                .shadow(radius: 10)

                Text("タップして次へ")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.top, 20)
            }
            .padding() // Padding for the whole VStack
        }
    }
}







struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainView(stage: quizData.stages[0], isReviewMode: false)
        }
    }
}
