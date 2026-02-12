import SwiftUI

struct MainView: View {
    // MARK: - Properties
    let stage: Stage

    @EnvironmentObject var appState: AppState
    @Environment(\.presentationMode) var presentationMode

    // MARK: - State Properties
    @State private var currentQuestionIndex = 0
    @State private var consecutiveCorrect = 0
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var showBackToStartButton = false
    @State private var isStageCleared = false
    @State private var showingQuitAlert = false
    @State private var buttonsDisabled = false
    @State private var showExplanation = false
    @State private var resultScale: CGFloat = 0.5
    @State private var kanjiAppear = false

    // Game constants
    private var goal: Int { stage.questions.count }
    private var questions: [Question] { stage.questions }
    private var currentQuestion: Question { questions[currentQuestionIndex] }
    private var progress: Double { Double(consecutiveCorrect) / Double(goal) }

    var body: some View {
        ZStack {
            VStack(spacing: OniTheme.Spacing.md) {
                // Top bar
                topBar

                if isStageCleared {
                    stageClearedView
                } else {
                    quizContentView
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

            // Explanation Overlay
            if showExplanation {
                ExplanationView(question: currentQuestion)
                    .onTapGesture {
                        showExplanation = false
                        nextQuestion()
                    }
                    .transition(.opacity)
            }
        }
        .gradientBackground()
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button(action: {
                if appState.clearedStages.contains(stage.stage) {
                    presentationMode.wrappedValue.dismiss()
                } else {
                    showingQuitAlert = true
                }
            }) {
                HStack(spacing: OniTheme.Spacing.xs) {
                    Image(systemName: "chevron.left")
                    Text("辞める")
                }
                .font(.body.weight(.medium))
                .foregroundColor(OniTheme.Colors.danger)
            }
            Spacer()

            if !isStageCleared {
                Text("\(consecutiveCorrect) / \(goal)")
                    .font(.headline.monospacedDigit())
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, OniTheme.Spacing.xs)
    }

    // MARK: - Stage Cleared View
    private var stageClearedView: some View {
        VStack(spacing: OniTheme.Spacing.lg) {
            Spacer()

            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .shadow(color: .yellow.opacity(0.4), radius: 12, x: 0, y: 4)

            Text("ステージ \(stage.stage) クリア！")
                .font(.largeTitle.weight(.bold))
                .foregroundColor(OniTheme.Colors.success)

            Text("おめでとうございます！")
                .font(.title2)
                .foregroundColor(.primary)

            Spacer()

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                HStack(spacing: OniTheme.Spacing.sm) {
                    Image(systemName: "list.bullet")
                    Text("ステージ選択へ戻る")
                }
                .primaryButton(color: OniTheme.Colors.success)
            }
            .padding(.horizontal, OniTheme.Spacing.lg)

            Spacer()
        }
        .transition(.scale.combined(with: .opacity))
    }

    // MARK: - Quiz Content View
    private var quizContentView: some View {
        VStack(spacing: OniTheme.Spacing.md) {
            Text("ステージ \(stage.stage)")
                .font(.title2.weight(.bold))
                .foregroundColor(.accentColor)

            // Progress Bar
            progressBar

            Spacer()

            // Kanji Display
            kanjiCard

            Spacer()

            if !showResult {
                answerButtons
            } else {
                resultDisplay
            }

            Spacer()

            if showBackToStartButton {
                Button(action: resetGame) {
                    HStack(spacing: OniTheme.Spacing.sm) {
                        Image(systemName: "arrow.counterclockwise")
                        Text("最初からやり直す")
                    }
                    .primaryButton(color: OniTheme.Colors.warning)
                }
                .padding(.horizontal, OniTheme.Spacing.lg)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Progress Bar
    private var progressBar: some View {
        VStack(spacing: OniTheme.Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: OniTheme.Radius.sm)
                        .fill(Color(.systemGray5))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: OniTheme.Radius.sm)
                        .fill(
                            LinearGradient(
                                colors: [OniTheme.Colors.quizBlue, OniTheme.Colors.success],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 8)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: consecutiveCorrect)
                }
            }
            .frame(height: 8)

            Text("進行度: \(consecutiveCorrect) / \(goal) 問")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, OniTheme.Spacing.sm)
    }

    // MARK: - Kanji Card
    private var kanjiCard: some View {
        Text(currentQuestion.kanji)
            .font(.system(size: 130, weight: .heavy, design: .rounded))
            .foregroundColor(.primary)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .padding(OniTheme.Spacing.lg)
            .frame(maxWidth: .infinity, maxHeight: 200)
            .background(OniTheme.Colors.subtleBackground)
            .cornerRadius(OniTheme.Radius.xl)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
            .scaleEffect(kanjiAppear ? 1.0 : 0.9)
            .opacity(kanjiAppear ? 1.0 : 0.0)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    kanjiAppear = true
                }
            }
            .onChange(of: currentQuestionIndex) { _, _ in
                kanjiAppear = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    kanjiAppear = true
                }
            }
    }

    // MARK: - Answer Buttons
    private var answerButtons: some View {
        VStack(spacing: OniTheme.Spacing.sm + 2) {
            ForEach(currentQuestion.choices, id: \.self) { choice in
                Button(action: { self.answer(selected: choice) }) {
                    Text(choice)
                        .primaryButton(color: OniTheme.Colors.quizBlue, minHeight: 54)
                }
            }
        }
        .padding(.horizontal, OniTheme.Spacing.sm)
        .disabled(buttonsDisabled)
        .transition(.opacity)
    }

    // MARK: - Result Display
    private var resultDisplay: some View {
        VStack(spacing: OniTheme.Spacing.md) {
            Text(isCorrect ? "○ 正解！" : "× 不正解…")
                .font(.system(size: 50, weight: .heavy, design: .rounded))
                .foregroundColor(isCorrect ? OniTheme.Colors.success : OniTheme.Colors.danger)
                .scaleEffect(resultScale)
                .onAppear {
                    resultScale = 0.5
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.5)) {
                        resultScale = 1.0
                    }
                }

            if !isCorrect {
                Text("正解は「\(currentQuestion.answer)」")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Game Logic Methods

    func answer(selected: String) {
        if buttonsDisabled { return }
        buttonsDisabled = true

        if selected == currentQuestion.answer {
            isCorrect = true
            if !showResult {
                consecutiveCorrect += 1
            }
            showResult = true

            if consecutiveCorrect >= goal {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isStageCleared = true
                }
                saveStageCleared()
                return
            }

            if !isStageCleared {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showExplanation = true
                }
                buttonsDisabled = false
            }
        } else {
            isCorrect = false
            showResult = true
            withAnimation(.easeInOut(duration: 0.3)) {
                showBackToStartButton = true
            }
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
            buttonsDisabled = false
        } else {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                isStageCleared = true
            }
            saveStageCleared()
        }
    }

    func resetGame() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentQuestionIndex = 0
            consecutiveCorrect = 0
            showResult = false
            showBackToStartButton = false
            buttonsDisabled = false
            showExplanation = false
        }
    }

    private func saveStageCleared() {
        var newClearedStages = appState.clearedStages
        newClearedStages.insert(stage.stage)
        appState.clearedStages = newClearedStages
    }
}

// MARK: - Explanation View

struct ExplanationView: View {
    let question: Question

    var body: some View {
        ZStack {
            OniTheme.Colors.overlayBackground
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: OniTheme.Spacing.lg) {
                VStack(alignment: .leading, spacing: OniTheme.Spacing.md) {
                    HStack {
                        Text(question.kanji)
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(OniTheme.Colors.success)
                    }

                    Divider()

                    Text(question.explain)
                        .font(.body)
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(OniTheme.Spacing.lg)
                .background(OniTheme.Colors.cardBackground)
                .cornerRadius(OniTheme.Radius.lg)
                .shadow(color: .black.opacity(0.15), radius: 16, x: 0, y: 8)
                .padding(.horizontal, OniTheme.Spacing.xl)

                Text("タップして次へ")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, OniTheme.Spacing.sm)
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainView(stage: quizData.stages[0])
        }
        .environmentObject(AppState())
    }
}
