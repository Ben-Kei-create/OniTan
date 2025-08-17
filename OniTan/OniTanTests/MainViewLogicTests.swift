import Testing
@testable import OniTan // Import your app module
import SwiftUI // Needed for View and State properties

struct MainViewLogicTests {

    // Helper to create a dummy stage for testing
    private func createDummyStage(questionsCount: Int = 1, isReview: Bool = false) -> Stage {
        var questions: [Question] = []
        for i in 0..<questionsCount {
            questions.append(Question(kanji: "問\(i)", choices: ["選A\(i)", "選B\(i)"], answer: "選A\(i)", explain: "解説\(i)"))
        }
        return Stage(stage: isReview ? 0 : 1, questions: questions)
    }

    @Test func testAnswerCorrectly() async throws {
        let appState = AppState()
        // Ensure appState is clean for this test
        appState.incorrectQuestions = []
        appState.clearedStages = []

        let stage = createDummyStage(questionsCount: 5)
        // Create MainView instance. Use a wrapper to access @State properties if needed.
        // For testing methods, we can directly call them on the instance.
        var mainView = MainView(stage: stage, isReviewMode: false)
        mainView._appState = EnvironmentObject(wrappedValue: appState) // Inject AppState

        // Simulate initial state
        mainView.currentQuestionIndex = 0
        mainView.consecutiveCorrect = 0
        mainView.showResult = false
        mainView.isCorrect = false

        // When: Answer correctly
        mainView.answer(selected: mainView.questions[0].answer)

        // Then
        #expect(mainView.isCorrect == true)
        #expect(mainView.consecutiveCorrect == 1)
        #expect(mainView.showResult == true)
        #expect(mainView.buttonsDisabled == false) // Should be re-enabled after explanation
        #expect(mainView.showExplanation == true) // Explanation should be shown
        #expect(appState.incorrectQuestions.isEmpty) // Should not add to incorrect in normal mode
    }

    @Test func testAnswerIncorrectly() async throws {
        let appState = AppState()
        appState.incorrectQuestions = []
        appState.clearedStages = []

        let stage = createDummyStage(questionsCount: 5)
        var mainView = MainView(stage: stage, isReviewMode: false)
        mainView._appState = EnvironmentObject(wrappedValue: appState)

        // Simulate initial state
        mainView.currentQuestionIndex = 0
        mainView.consecutiveCorrect = 0
        mainView.showResult = false
        mainView.isCorrect = false

        // When: Answer incorrectly
        mainView.answer(selected: "間違った選択肢")

        // Then
        #expect(mainView.isCorrect == false)
        #expect(mainView.consecutiveCorrect == 0) // Score resets
        #expect(mainView.showResult == true)
        #expect(mainView.showBackToStartButton == true)
        #expect(mainView.buttonsDisabled == false)
        #expect(appState.incorrectQuestions.count == 1) // Should add to incorrect
        #expect(appState.incorrectQuestions.contains(mainView.questions[0].kanji))
    }

    @Test func testNextQuestion() async throws {
        let appState = AppState()
        let stage = createDummyStage(questionsCount: 3)
        var mainView = MainView(stage: stage, isReviewMode: false)
        mainView._appState = EnvironmentObject(wrappedValue: appState)

        // Given: Not at last question
        mainView.currentQuestionIndex = 0
        mainView.isStageCleared = false

        // When
        mainView.nextQuestion()

        // Then
        #expect(mainView.currentQuestionIndex == 1)
        #expect(mainView.showResult == false)
        #expect(mainView.showBackToStartButton == false)
        #expect(mainView.buttonsDisabled == false)
    }

    @Test func testStageClear() async throws {
        let appState = AppState()
        appState.clearedStages = []
        let stage = createDummyStage(questionsCount: 1) // Only one question to clear
        var mainView = MainView(stage: stage, isReviewMode: false)
        mainView._appState = EnvironmentObject(wrappedValue: appState)

        // Given: At last question, about to clear
        mainView.currentQuestionIndex = 0
        mainView.consecutiveCorrect = 0 // Will become 1 after answer
        mainView.goal = 1 // Set goal to 1 for easy clear

        // When: Answer correctly to clear stage
        mainView.answer(selected: mainView.questions[0].answer)

        // Then
        #expect(mainView.isStageCleared == true)
        #expect(appState.clearedStages.contains(stage.stage)) // Stage should be marked as cleared
    }

    @Test func testResetGame() async throws {
        let appState = AppState()
        let stage = createDummyStage(questionsCount: 5)
        var mainView = MainView(stage: stage, isReviewMode: false)
        mainView._appState = EnvironmentObject(wrappedValue: appState)

        // Given: Game in a mid-state
        mainView.currentQuestionIndex = 2
        mainView.consecutiveCorrect = 1
        mainView.showResult = true
        mainView.showBackToStartButton = true
        mainView.buttonsDisabled = true
        mainView.showExplanation = true

        // When
        mainView.resetGame()

        // Then
        #expect(mainView.currentQuestionIndex == 0)
        #expect(mainView.consecutiveCorrect == 0)
        #expect(mainView.showResult == false)
        #expect(mainView.showBackToStartButton == false)
        #expect(mainView.buttonsDisabled == false)
        #expect(mainView.showExplanation == false)
    }

    @Test func testShuffleQuestionsAndChoices() async throws {
        let appState = AppState()
        let stage = createDummyStage(questionsCount: 3)
        var mainView = MainView(stage: stage, isReviewMode: false)
        mainView._appState = EnvironmentObject(wrappedValue: appState)

        let originalQuestions = mainView.questions // Copy original questions
        let originalChoices = mainView.questions.map { $0.choices } // Copy original choices

        // When
        mainView.shuffleQuestionsAndChoices()

        // Then: Questions should be shuffled (unlikely to be same order)
        #expect(mainView.questions.count == originalQuestions.count)
        // Cannot directly expect different order, but can check content is same
        #expect(Set(mainView.questions.map { $0.kanji }) == Set(originalQuestions.map { $0.kanji }))

        // Then: Choices should be shuffled (unlikely to be same order)
        let newChoices = mainView.questions.map { $0.choices }
        #expect(newChoices.count == originalChoices.count)
        // Check that choices within each question are shuffled
        for i in 0..<mainView.questions.count {
            #expect(Set(newChoices[i]) == Set(originalChoices[i])) // Content should be same
            // Cannot expect different order directly
        }
    }

    @Test func testUpdateReviewQuestions() async throws {
        let appState = AppState()
        appState.incorrectQuestions = ["問0", "問2"] // Simulate some incorrect questions
        let stage = createDummyStage(questionsCount: 5) // All possible questions
        var mainView = MainView(stage: stage, isReviewMode: true) // Start in review mode
        mainView._appState = EnvironmentObject(wrappedValue: appState)

        // When
        mainView.updateReviewQuestions()

        // Then
        #expect(mainView.questions.count == 2)
        #expect(mainView.questions.map { $0.kanji }.contains("問0"))
        #expect(mainView.questions.map { $0.kanji }.contains("問2"))
        #expect(mainView.goal == 2)
    }
}
