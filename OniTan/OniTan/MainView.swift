
import SwiftUI

struct MainView: View {
    // MARK: - State Properties
    @State private var currentQuestionIndex = 0
    @State private var consecutiveCorrect = 0
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var showBackToStartButton = false

    // Game constants
    private let goal = 30

    // Computed property for the current question
    private var currentQuestion: Question {
        return questions[currentQuestionIndex]
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Progress Bar
                Text("\(consecutiveCorrect) / \(goal) 連続正解")
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
                        Text("1問目へ戻る")
                            .font(.title)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
                
                // Clear Message
                if consecutiveCorrect >= goal {
                    Text("🎉 全問正解！おめでとうございます！ 🎉")
                        .font(.largeTitle)
                        .padding()
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("鬼単 (漢検準1級)")
            .navigationBarItems(trailing: 
                NavigationLink(destination: SettingsView()) {
                    Image(systemName: "gearshape.fill")
                }
            )
        }
    }

    // MARK: - Game Logic Methods

    func answer(selected: String) {
        if selected == currentQuestion.answer {
            isCorrect = true
            consecutiveCorrect += 1
            showResult = true
            
            if consecutiveCorrect >= goal {
                // Game cleared
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
        }
    }

    func nextQuestion() {
        // Ensure we don't go out of bounds and shuffle for variety
        currentQuestionIndex = (currentQuestionIndex + 1) % questions.count
        showResult = false
        showBackToStartButton = false
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
        MainView()
    }
}

