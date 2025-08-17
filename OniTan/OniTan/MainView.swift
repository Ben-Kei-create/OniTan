import SwiftUI

struct MainView: View {
    // MARK: - Properties
    let stage: Stage // Keep stage for normal mode
    let isReviewMode: Bool
    
    @EnvironmentObject var appState: AppState // Access AppState
    @Environment(\.presentationMode) var presentationMode

    @AppStorage("soundEnabled") private var soundEnabled: Bool = true
    @AppStorage("hapticsEnabled") private var hapticsEnabled: Bool = true
    @AppStorage("shuffleQuestionsEnabled") private var shuffleQuestionsEnabled: Bool = false
    @AppStorage("kanjiFont") private var kanjiFont: String = "system"
    @AppStorage("themeColor") private var themeColor: String = "classic"

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
    
    // Animation states for stage clear
    @State private var showClearAnimation = false
    @State private var clearTextScale: CGFloat = 0.1
    @State private var clearTextOpacity: Double = 0
    @State private var confettiOpacity: Double = 0
    @State private var confettiRotation: Double = 0
    
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
    
    // Computed property for selected kanji font
    private var selectedKanjiFont: Font {
        switch kanjiFont {
        case "hiragino":
            return .custom("Hiragino Kaku Gothic ProN", size: 150, relativeTo: .largeTitle)
        case "yuGothic":
            return .custom("YuGothic-Medium", size: 150, relativeTo: .largeTitle)
        case "mincho":
            return .custom("Hiragino Mincho ProN", size: 150, relativeTo: .largeTitle)
        default:
            return .system(size: 150, weight: .heavy, design: .rounded)
        }
    }
    
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
            if isReviewMode && questions.isEmpty {
                Color.clear
                    .onAppear {
                        print("DEBUG: Review mode completed - questions.isEmpty: \(questions.isEmpty)")
                        appState.showReviewCompletion = true
                        presentationMode.wrappedValue.dismiss()
                    }
            } else {
                VStack(spacing: 20) {
                    // "辞める" Button and Bookmark Button
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
                        
                        Spacer() // Pushes the buttons to the edges
                        
                        // Bookmark button (only show in normal mode)
                        if !isReviewMode {
                            Button(action: {
                                if appState.isBookmarked(currentQuestion.kanji) {
                                    appState.removeBookmarkedQuestion(currentQuestion.kanji)
                                } else {
                                    appState.addBookmarkedQuestion(currentQuestion.kanji)
                                }
                            }) {
                                Image(systemName: appState.isBookmarked(currentQuestion.kanji) ? "bookmark.fill" : "bookmark")
                                    .font(.title2)
                                    .foregroundColor(appState.isBookmarked(currentQuestion.kanji) ? .yellow : .gray)
                            }
                        }
                    }
                    .padding(.horizontal) // Add horizontal padding to align with other content

                    if isStageCleared {
                        // --- Stage Cleared View with Animation (for normal stages) ---
                        ZStack {
                            // Confetti background
                            ForEach(0..<20, id: \.self) { index in
                                ConfettiPiece(index: index, opacity: confettiOpacity, rotation: confettiRotation)
                            }
                            
                            VStack(spacing: 30) {
                                Spacer()
                                
                                // Stage clear text with animation
                                VStack(spacing: 15) {
                                    Text("ステージ \(stage.stage)")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.primary)
                                        .opacity(clearTextOpacity)
                                        .scaleEffect(clearTextScale)
                                    
                                    Text("クリア！")
                                        .font(.system(size: 60, weight: .heavy))
                                        .foregroundColor(.green)
                                        .opacity(clearTextOpacity)
                                        .scaleEffect(clearTextScale)
                                        .shadow(color: .green.opacity(0.5), radius: 10, x: 0, y: 5)
                                }
                                .animation(.spring(response: 0.8, dampingFraction: 0.6), value: clearTextScale)
                                .animation(.easeIn(duration: 0.5), value: clearTextOpacity)
                                
                                Text("おめでとうございます！")
                                    .font(.title)
                                    .foregroundColor(.primary)
                                    .opacity(clearTextOpacity)
                                    .animation(.easeIn(duration: 0.5).delay(0.3), value: clearTextOpacity)
                                
                                Spacer()
                                
                                // Return button with animation
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
                                .opacity(clearTextOpacity)
                                .scaleEffect(clearTextScale * 0.8)
                                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.6), value: clearTextScale)
                                .animation(.easeIn(duration: 0.5).delay(0.6), value: clearTextOpacity)
                                .padding(.bottom, 20)
                            }
                        }
                    } else {
                        // --- Main Quiz View ---
                        Text(isReviewMode ? "復習モード" : "ステージ \(stage.stage)")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.accentColor)
                            .padding(.bottom)

                        if !isReviewMode {
                            Text("進行度: \(consecutiveCorrect) / \(goal) 問") // More descriptive progress
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(currentQuestion.kanji)
                            .font(selectedKanjiFont)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .minimumScaleFactor(0.5) // Allow text to shrink
                            .lineLimit(1)
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: 200) // Fixed size for kanji
                            .background(Color(.systemBackground).opacity(0.1)) // Adaptive background for kanji
                            .cornerRadius(20)
                            .shadow(color: Color(.systemGray4).opacity(0.3), radius: 5, x: 0, y: 5)

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
                                            .background(selectedThemeColor)
                                            .foregroundColor(.white)
                                            .cornerRadius(15)
                                            .shadow(color: selectedThemeColor.opacity(0.4), radius: 8, x: 0, y: 4)
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
            LinearGradient(
                gradient: Gradient(colors: [
                    selectedThemeColor.opacity(0.15),
                    selectedThemeColor.opacity(0.1),
                    Color(.systemBackground).opacity(0.05)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .edgesIgnoringSafeArea(.all)
        )
        .onAppear {
            // Shuffle questions and choices if enabled
            if shuffleQuestionsEnabled {
                shuffleQuestionsAndChoices()
            }
        }
        .onChange(of: appState.incorrectQuestions) { oldQuestions, newQuestions in
            if isReviewMode {
                updateReviewQuestions()
            }
        }
        .onChange(of: appState.bookmarkedQuestions) { oldBookmarks, newBookmarks in
            if isReviewMode {
                updateReviewQuestions()
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
                print("DEBUG: Review mode - removing question: \(currentQuestion.kanji)")
                print("DEBUG: Questions count before removal: \(questions.count)")
                appState.removeIncorrectQuestion(currentQuestion.kanji)
                appState.removeBookmarkedQuestion(currentQuestion.kanji)
                // Remove the current question from the questions array
                questions.remove(at: currentQuestionIndex)
                print("DEBUG: Questions count after removal: \(questions.count)")
                // Reset currentQuestionIndex to 0 since we're now at the beginning of the updated array
                currentQuestionIndex = 0
                print("DEBUG: Current question index reset to: \(currentQuestionIndex)")
            }

            isCorrect = true
            if !showResult {
                consecutiveCorrect += 1
            }
            showResult = true
            
            if consecutiveCorrect >= goal {
                isStageCleared = true
                if !isReviewMode {
                    saveStageCleared()
                    // Start clear animation
                    startClearAnimation()
                }
                // Dismissal will be handled by the conditional body
                return
            }

            if !isStageCleared {
                if isReviewMode {
                    // For review mode, go to next question without explanation
                    nextQuestion()
                } else {
                    // For normal mode, show explanation
                    showExplanation = true
                    buttonsDisabled = false
                }
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
            consecutiveCorrect = 0
            
            if isReviewMode {
                // For review mode, show back to start button immediately
                showBackToStartButton = true
                buttonsDisabled = false
            } else {
                // For normal mode, show back to start button
                showBackToStartButton = true
                buttonsDisabled = false
            }
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
    
    // 問題と選択肢をシャッフルするメソッド
    private func shuffleQuestionsAndChoices() {
        // Shuffle the order of questions
        questions = questions.shuffled()
        
        // Shuffle choices for each question
        for i in 0..<questions.count {
            questions[i].choices = questions[i].choices.shuffled()
        }
    }
    
    // 復習問題を更新するメソッド
    private func updateReviewQuestions() {
        let allQuestions = quizData.stages.flatMap { $0.questions }
        let reviewKanji = appState.incorrectQuestions.union(appState.bookmarkedQuestions)
        questions = allQuestions.filter { reviewKanji.contains($0.kanji) }.shuffled()
        goal = questions.count

        print("DEBUG: Review questions updated - count: \(questions.count)")
        
        // If all review questions are cleared, dismiss to home
        if questions.isEmpty {
            print("DEBUG: All review questions completed, dismissing to home")
            appState.showReviewCompletion = true
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    // ステージクリアアニメーションを開始するメソッド
    private func startClearAnimation() {
        // Play success sound and haptics
        if soundEnabled { SoundManager.shared.playSound(sound: .correct) }
        if hapticsEnabled { HapticsManager.shared.play(.success) }
        
        // Start text animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            clearTextScale = 1.0
            clearTextOpacity = 1.0
        }
        
        // Start confetti animation
        withAnimation(.easeIn(duration: 0.5)) {
            confettiOpacity = 1.0
        }
        
        // Rotate confetti
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            confettiRotation = 360
        }
    }
}

struct ConfettiPiece: View {
    let index: Int
    let opacity: Double
    let rotation: Double
    
    private let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    private let shapes: [String] = ["circle.fill", "square.fill", "triangle.fill", "star.fill"]
    
    var body: some View {
        Image(systemName: shapes[index % shapes.count])
            .foregroundColor(colors[index % colors.count])
            .font(.system(size: CGFloat.random(in: 8...15)))
            .position(
                x: CGFloat.random(in: 0...UIScreen.main.bounds.width),
                y: CGFloat.random(in: 0...UIScreen.main.bounds.height)
            )
            .opacity(opacity)
            .rotationEffect(.degrees(rotation))
            .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: opacity)
    }
}

struct ExplanationView: View {
    let question: Question
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            Color(.systemBackground).opacity(0.9)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(question.explain)
                        .font(.body)
                        .foregroundColor(.primary) // Adaptive text color
                }
                .padding()
                .background(Color(.systemGray6).opacity(0.8)) // Adaptive background
                .cornerRadius(15)
                .shadow(color: Color(.systemGray4).opacity(0.3), radius: 10, x: 0, y: 5)

                Text("タップして次へ")
                    .font(.headline)
                    .foregroundColor(.primary) // Adaptive text color
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
