
import SwiftUI

struct MainView: View {
    // MARK: - Properties
    let stage: Stage
    
    // AppStorage to save unlock progress
    @AppStorage("unlockedStage") var unlockedStage = 1
    
    // Environment property to dismiss the view
    @Environment(\.presentationMode) var presentationMode

    // MARK: - State Properties
    @State private var currentQuestionIndex = 0
    @State private var consecutiveCorrect = 0 // This now tracks progress within the stage
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var showBackToStartButton = false
    @State private var isStageCleared = false

    // Game constants
    private var goal: Int {
        return stage.questions.count
    }
    private var questions: [Question] {
        return stage.questions
    }

    // Computed property for the current question
    private var currentQuestion: Question {
        return questions[currentQuestionIndex]
    }

    var body: some View {
        VStack(spacing: 20) {
            if isStageCleared {
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
                // Progress Bar
                Text("ステージ \(stage.stage)")
                    .font(.largeTitle)
                    .padding(.bottom)

                Text("\(consecutiveCorrect) / \(goal) 問正解")
                    .font(.headline)

                Spacer()

                // Kanji Display
                Text(currentQuestion.kanji)
                    .font(.system(size: 120, weight: .bold))
                    .padding()

                Spacer()

                // Result Display
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

                // Choice Buttons
                if !showResult {
                    HStack(spacing: 20) {
                        ForEach(currentQuestion.choices, id: \.self) { choice in
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
                }

                // Reset Button
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
        .navigationBarBackButtonHidden(true) // Hide default back button to control flow
    }

    // MARK: - Game Logic Methods

    func answer(selected: String) {
        if selected == currentQuestion.answer {
            isCorrect = true
            // Only advance if not already correct
            if !showResult { 
                consecutiveCorrect += 1
            }
            showResult = true
            
            if consecutiveCorrect >= goal {
                // Stage cleared
                isStageCleared = true
                // Unlock the next stage
                unlockedStage = max(unlockedStage, stage.stage + 1)
                return
            }

            // Move to the next question after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                nextQuestion()
            }
        } else {
            isCorrect = false
            showResult = true
            showBackToStartButton = true
            consecutiveCorrect = 0 // Reset progress on wrong answer
        }
    }

    func nextQuestion() {
        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
            showResult = false
            showBackToStartButton = false
        } else {
            // This case should be handled by the stage clear logic
            // but as a fallback, we can consider the stage cleared.
            isStageCleared = true
            unlockedStage = max(unlockedStage, stage.stage + 1)
        }
    }

    func resetGame() {
        currentQuestionIndex = 0
        consecutiveCorrect = 0
        showResult = false
        showBackToStartButton = false
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a sample stage for the preview
        MainView(stage: quizData.stages[0])
    }
}

