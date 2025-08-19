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
    @State private var answeredQuestion: Question?
    
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
        print("--- currentQuestion CALLED ---")
        print("Accessing index: \(currentQuestionIndex) in questions array with count: \(questions.count)")
        if questions.isEmpty {
            print("DEBUG: currentQuestion accessed when questions is empty. Returning dummy question.")
            return Question(kanji: "", answer: "", choices: [], explain: "")
        } else if currentQuestionIndex >= questions.count {
            print("DEBUG: currentQuestion accessed with out-of-bounds index. Resetting to 0 and returning first question.")
            // This is a safeguard, but the issue should be fixed elsewhere.
            DispatchQueue.main.async {
                currentQuestionIndex = 0
            }
            return questions[0]
        }
        print("Returning question: \(questions[currentQuestionIndex].kanji)")
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

                        Text((showResult && isCorrect) ? (answeredQuestion?.kanji ?? currentQuestion.kanji) : currentQuestion.kanji)
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
                                ForEach(currentQuestion.choices) { choice in
                                    Button(action: {
                                        if hapticsEnabled {
                                            HapticsManager.shared.impact(style: .light)
                                        }
                                        self.answer(selected: choice)
                                    }) {
                                        Text(choice.text)
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

    func answer(selected: Choice) {
        print("--- answer(selected:) CALLED ---")
        print("Mode: \(isReviewMode ? "Review" : "Normal")")
        print("Current Kanji: \(currentQuestion.kanji), Index: \(currentQuestionIndex)")
        print("Selected: \(selected.text), Correct Answer: \(currentQuestion.answer)")

        if buttonsDisabled { 
            print("Buttons are disabled, returning.")
            return
        }
        buttonsDisabled = true

        if selected.text == currentQuestion.answer {
            print("--- CORRECT ANSWER ---")
            if soundEnabled { SoundManager.shared.playSound(sound: .correct) }
            if hapticsEnabled { HapticsManager.shared.play(.success) }
            
            isCorrect = true
            showResult = true
            answeredQuestion = currentQuestion // Save the question that was just answered

            if isReviewMode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    print("Review Mode: Delay finished. Updating questions.")
                    appState.removeIncorrectQuestion(currentQuestion.kanji)
                    appState.removeBookmarkedQuestion(currentQuestion.kanji)
                    updateReviewQuestions() // Manually update the questions list
                    
                    showResult = false
                    answeredQuestion = nil
                    buttonsDisabled = false
                    print("Review Mode: Ready for next question.")
                }
            } else {
                if !showResult {
                    consecutiveCorrect += 1
                }
                print("Normal Mode: Consecutive correct answers: \(consecutiveCorrect)")
                
                if consecutiveCorrect >= goal {
                    print("Normal Mode: Stage cleared!")
                    isStageCleared = true
                    saveStageCleared()
                    startClearAnimation()
                    return
                }

                if !isStageCleared {
                    print("Normal Mode: Showing explanation.")
                    showExplanation = true
                    buttonsDisabled = false
                }
            }
        } else {
            print("--- INCORRECT ANSWER ---")
            if soundEnabled { SoundManager.shared.playSound(sound: .incorrect) }
            if hapticsEnabled { HapticsManager.shared.play(.error) }

            if !isReviewMode {
                print("Normal Mode: Adding incorrect question to AppState.")
                appState.addIncorrectQuestion(currentQuestion.kanji)
            }

            isCorrect = false
            showResult = true
            consecutiveCorrect = 0
            answeredQuestion = currentQuestion // Save the question that was just answered
            
            if isReviewMode {
                print("Review Mode: Incorrect answer. Moving to next question after delay.")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("Review Mode: Hiding result, re-enabling buttons, and calling nextQuestion().")
                    showResult = false
                    answeredQuestion = nil
                    buttonsDisabled = false
                    nextQuestion()
                }
            } else {
                print("Normal Mode: Incorrect answer. Showing 'try again' button.")
                showBackToStartButton = true
                buttonsDisabled = false
            }
        }
    }

    func nextQuestion() {
        print("--- nextQuestion() CALLED ---")
        print("Current Index: \(currentQuestionIndex), Questions Count: \(questions.count)")
        guard !isStageCleared else { 
            print("Stage is already cleared, returning.")
            return
        }

        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            print("Moving to next question. New Index: \(currentQuestionIndex)")
        } else {
            print("Last question reached.")
            if isReviewMode {
                print("Review Mode: Looping back to the first question.")
                currentQuestionIndex = 0
            } else {
                print("Normal Mode: Stage considered cleared.")
                isStageCleared = true
                saveStageCleared()
            }
        }
        showResult = false
        showBackToStartButton = false
        buttonsDisabled = false
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
        print("--- updateReviewQuestions() CALLED ---")
        let allQuestions = quizData.stages.flatMap { $0.questions }
        let reviewKanji = appState.incorrectQuestions.union(appState.bookmarkedQuestions)
        
        print("Current review Kanji count: \(reviewKanji.count)")
        questions = allQuestions.filter { reviewKanji.contains($0.kanji) }.shuffled()
        goal = questions.count

        print("Review questions updated. New count: \(questions.count)")
        
        if questions.isEmpty {
            print("All review questions completed, dismissing to home.")
            appState.showReviewCompletion = true
            // Safely dismiss
            DispatchQueue.main.async {
                presentationMode.wrappedValue.dismiss()
            }
        } else {
            if currentQuestionIndex >= questions.count {
                print("Index \(currentQuestionIndex) is out of bounds. Resetting to 0.")
                currentQuestionIndex = 0
            }
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
