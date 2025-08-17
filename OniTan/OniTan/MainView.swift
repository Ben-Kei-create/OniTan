
import SwiftUI

struct MainView: View {
    // MARK: - Properties
    let stage: Stage
    
    @AppStorageCodable(wrappedValue: [], "clearedStages") var clearedStages: Set<Int>
    @Environment(\.presentationMode) var presentationMode

    // MARK: - State Properties
    @State private var currentQuestionIndex = 0
    @State private var consecutiveCorrect = 0
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var showBackToStartButton = false
    @State private var isStageCleared = false
    @State private var showingQuitAlert = false // State for the quit confirmation dialog
    @State private var buttonsDisabled = false // State to disable buttons during processing

    // Game constants
    private var goal: Int { stage.questions.count }
    private var questions: [Question] { stage.questions }
    private var currentQuestion: Question { questions[currentQuestionIndex] }

    var body: some View {
        VStack(spacing: 20) {
            if isStageCleared {
                // --- Stage Cleared View ---
                Spacer()
                Text("ステージ \(stage.stage) クリア！")
                    .font(.largeTitle)
                    .padding()
                Text("🎉 おめでとうございます！ 🎉")
                    .font(.title)
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("ステージ選択へ戻る")
                        .font(.title)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                Spacer()
            } else {
                // --- Main Quiz View ---
                Text("ステージ \(stage.stage)")
                    .font(.largeTitle)
                    .padding(.bottom)

                Text("\(consecutiveCorrect) / \(goal) 問正解")
                    .font(.headline)

                Spacer()

                Text(currentQuestion.kanji)
                    .font(.system(size: 120, weight: .bold))
                    .padding()

                Spacer()

                if showResult {
                    if isCorrect {
                        Text("◯ 正解！")
                            .font(.title)
                            .foregroundColor(.green)
                    } else {
                        Text("× 不正解… 正解は「\(currentQuestion.answer)」")
                            .font(.title)
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                if !showResult {
                    HStack(spacing: 20) {
                        ForEach(currentQuestion.choices, id: \.self) {
                            choice in
                            Button(action: { self.answer(selected: choice) }) {
                                Text(choice)
                                    .font(.title)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                    .padding()
                    .disabled(buttonsDisabled) // Apply disabled modifier here
                }

                if showBackToStartButton {
                    Button(action: resetGame) {
                        Text("最初からやり直す")
                            .font(.title)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !isStageCleared { // Don't show quit button on cleared screen
                    Button("辞める") {
                        if clearedStages.contains(stage.stage) {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            showingQuitAlert = true
                        }
                    }
                }
            }
        }
        .alert(isPresented: $showingQuitAlert) {
            Alert(
                title: Text("確認"),
                message: Text("途中で辞めると、ステージクリアになりません。\nよろしいですか？"),
                primaryButton: .destructive(Text("OK")) {
                    presentationMode.wrappedValue.dismiss()
                },
                secondaryButton: .cancel(Text("キャンセル"))
            )
        }
    }

    // MARK: - Game Logic Methods

    func answer(selected: String) {
        buttonsDisabled = true // Disable buttons immediately
        if selected == currentQuestion.answer {
            isCorrect = true
            if !showResult { 
                consecutiveCorrect += 1
            }
            showResult = true
            
            if consecutiveCorrect >= goal {
                isStageCleared = true
                print("MainView: Before insert - clearedStages: \(clearedStages), inserting stage: \(stage.stage)")
                clearedStages.insert(stage.stage)
                print("MainView: After insert - clearedStages: \(clearedStages)")
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if !isStageCleared { // Only call nextQuestion if stage is not cleared
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
        guard !isStageCleared else { return } // Prevent further execution if stage is cleared
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            showResult = false
            showBackToStartButton = false
            buttonsDisabled = false // Re-enable buttons
        } else {
            isStageCleared = true
            print("MainView: Fallback - Before insert - clearedStages: \(clearedStages), inserting stage: \(stage.stage)")
            clearedStages.insert(stage.stage)
            print("MainView: Fallback - After insert - clearedStages: \(clearedStages)")
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
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            MainView(stage: quizData.stages[0])
        }
    }
}

