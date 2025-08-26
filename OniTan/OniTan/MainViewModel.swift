
import Foundation
import SwiftUI

class MainViewModel: ObservableObject {
    // MARK: - Dependencies
    let stage: Stage
    let isReviewMode: Bool
    private var progressStore: ProgressStore
    private var allQuestions: [Question]
    private let soundManager: SoundManaging
    private let hapticsManager: HapticsManaging
    var dismissAction: (() -> Void)? // New: Closure to dismiss the view

    // MARK: - Published Properties (for UI updates)
    @Published var currentQuestion: Question
    @Published var totalCorrect = 0
    @Published var showResult = false
    @Published var isCorrect = false
    @Published var showBackToStartButton = false
    @Published var isStageCleared = false
    @Published var showingQuitAlert = false
    @Published var buttonsDisabled = false
    @Published var showExplanation = false
    @Published var goal: Int
    @Published var questions: [Question]

    // MARK: - App Settings (from UserDefaults)
    @AppStorage("soundEnabled") public var soundEnabled: Bool = true
    @AppStorage("hapticsEnabled") public var hapticsEnabled: Bool = true
    @AppStorage("shuffleQuestionsEnabled") private var shuffleQuestionsEnabled: Bool = false

    // MARK: - Private State
    private var currentQuestionIndex = 0
    private var answeredQuestion: Question?

    // MARK: - Initialization
    init(stage: Stage, 
         isReviewMode: Bool, 
         progressStore: ProgressStore, 
         allQuestions: [Question],
         soundManager: SoundManaging = SoundManager.shared,
         hapticsManager: HapticsManaging = HapticsManager.shared) {
        self.stage = stage
        self.isReviewMode = isReviewMode
        self.progressStore = progressStore
        self.allQuestions = allQuestions
        self.soundManager = soundManager
        self.hapticsManager = hapticsManager
        
        let initialQuestions = stage.questions
        self.questions = initialQuestions
        self.goal = initialQuestions.count
        self.currentQuestion = initialQuestions.first ?? Question(kanji: "エラー", answer: "", choices: [], explain: "問題がありません。")

        if shuffleQuestionsEnabled {
            self.questions.shuffle()
            for i in 0..<self.questions.count {
                self.questions[i].choices.shuffle()
            }
            self.currentQuestion = self.questions.first ?? Question(kanji: "エラー", answer: "", choices: [], explain: "問題がありません。")
        }
    }

    // MARK: - Game Logic Methods
    func answer(selected: Choice) {
        if buttonsDisabled { return }
        buttonsDisabled = true

        answeredQuestion = currentQuestion
        isCorrect = selected.text == currentQuestion.answer

        if isCorrect {
            handleCorrectAnswer()
        } else {
            handleIncorrectAnswer()
        }
        
        showResult = true

        // Schedule next action
        if isReviewMode {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                if self.isCorrect {
                    self.progressStore.removeIncorrectQuestion(self.currentQuestion.kanji)
                    self.progressStore.removeBookmarkedQuestion(self.currentQuestion.kanji)
                    self.updateReviewQuestions()
                }
                self.showResult = false
                self.buttonsDisabled = false
                if !self.isCorrect {
                    self.nextQuestion()
                }
            }
        } else {
            if isCorrect {
                totalCorrect += 1
                if !isStageCleared {
                    showExplanation = true
                }
            } else {
                showBackToStartButton = true
            }
            buttonsDisabled = false
        }
    }

    func nextQuestion() {
        guard !isStageCleared else { return }

        if currentQuestionIndex < questions.count - 1 {
            currentQuestionIndex += 1
        } else {
            if isReviewMode {
                currentQuestionIndex = 0
            } else {
                isStageCleared = true
                saveStageCleared()
            }
        }
        
        if !questions.isEmpty {
            currentQuestion = questions[currentQuestionIndex]
        }
        
        showResult = false
        showBackToStartButton = false
        buttonsDisabled = false
    }

    func resetGame() {
        currentQuestionIndex = 0
        totalCorrect = 0
        showResult = false
        showBackToStartButton = false
        buttonsDisabled = false
        showExplanation = false
        
        if shuffleQuestionsEnabled {
            questions.shuffle()
            for i in 0..<questions.count {
                questions[i].choices.shuffle()
            }
        }
        currentQuestion = questions[0]
    }
    
    func onQuit() {
        if isReviewMode || progressStore.clearedStages.contains(stage.stage) {
            dismissAction?()
        } else {
            showingQuitAlert = true
        }
    }
    
    func toggleBookmark() {
        if progressStore.isBookmarked(currentQuestion.kanji) {
            progressStore.removeBookmarkedQuestion(currentQuestion.kanji)
        } else {
            progressStore.addBookmarkedQuestion(currentQuestion.kanji)
        }
    }
    
    func isBookmarked() -> Bool {
        progressStore.isBookmarked(currentQuestion.kanji)
    }

    // MARK: - Private Helper Methods
    private func handleCorrectAnswer() {
        if soundEnabled { soundManager.playSound(sound: .correct, volume: 1.0) }
        if hapticsEnabled { hapticsManager.play(.success) }
    }

    private func handleIncorrectAnswer() {
        if soundEnabled { soundManager.playSound(sound: .incorrect, volume: 1.0) }
        if hapticsEnabled { hapticsManager.play(.error) }
        if !isReviewMode {
            progressStore.addIncorrectQuestion(currentQuestion.kanji)
        }
    }

    private func saveStageCleared() {
        progressStore.clearedStages.insert(stage.stage)
        print("DEBUG: saveStageCleared called with stage \(stage.stage)")
        print("DEBUG: clearedStages after insert: \(progressStore.clearedStages)")
    }
    
    private func updateReviewQuestions() {
        let reviewKanji = progressStore.incorrectQuestions.union(progressStore.bookmarkedQuestions)
        
        questions = allQuestions.filter { reviewKanji.contains($0.kanji) }.shuffled()
        goal = questions.count

        if questions.isEmpty {
            // This should be handled by the view
        } else {
            if currentQuestionIndex >= questions.count {
                currentQuestionIndex = 0
            }
            currentQuestion = questions[currentQuestionIndex]
        }
    }
    
    func onExplanationDismissed() {
        showExplanation = false
        nextQuestion()
    }
}
