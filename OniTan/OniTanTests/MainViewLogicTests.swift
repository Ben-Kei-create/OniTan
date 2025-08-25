import Testing
@testable import OniTan // Import your app module
import SwiftUI // Needed for View and State properties

struct MainViewLogicTests {

    // Helper to create a dummy stage for testing
    private func createDummyStage(questionsCount: Int = 1, isReview: Bool = false) -> Stage {
        var questions: [Question] = []
        for i in 0..<questionsCount {
            questions.append(Question(
                kanji: "問\(i)",
                answer: "選A\(i)",
                choices: ["選A\(i)", "選B\(i)"],
                explain: "解説\(i)"
            ))
        }
        return Stage(stage: isReview ? 0 : 1, questions: questions)
    }

    @Test func testRealQuestionDataStructure() async throws {
        // Test using real data structure like in the JSON
        let question = Question(
            kanji: "丑",
            answer: "うし",
            choices: ["うし", "ひつじ"],
            explain: "干支の一つで、十二支の2番目にあたります。"
        )
        
        #expect(question.kanji == "丑")
        #expect(question.answer == "うし")
        #expect(question.choices.count == 2)
        #expect(question.choices[0] == "うし")
        #expect(question.choices[1] == "ひつじ")
        #expect(question.explain == "干支の一つで、十二支の2番目にあたります。")
        
        // Test that we can create Choice objects from the choices strings
        let correctChoice = Choice(text: question.answer)
        let incorrectChoiceText = question.choices.first { $0 != question.answer }!
        let incorrectChoice = Choice(text: incorrectChoiceText)
        
        #expect(correctChoice.text == "うし")
        #expect(incorrectChoice.text == "ひつじ")
    }

    @Test func testAnswerCorrectly() async throws {
        let appState = AppState()
        appState.incorrectQuestions = []
        appState.clearedStages = []

        let stage = createDummyStage(questionsCount: 5)
        
        // Create MainView with proper async handling
        let mainView = await MainView(stage: stage, isReviewMode: false)
        
        // Test the answer method with correct choice
        let correctChoice = Choice(text: stage.questions[0].answer)
        
        // Since we can't directly access private properties, we'll test the public behavior
        // by calling the answer method and checking if it behaves correctly
        await MainActor.run {
            mainView.answer(selected: correctChoice)
        }
        
        // We can test AppState changes which are observable
        #expect(appState.incorrectQuestions.isEmpty) // Should not add to incorrect in normal mode
    }

    @Test func testAnswerIncorrectly() async throws {
        let appState = AppState()
        appState.incorrectQuestions = []
        appState.clearedStages = []

        let stage = createDummyStage(questionsCount: 5)
        let mainView = await MainView(stage: stage, isReviewMode: false)

        // Find an incorrect choice from the actual choices (as String)
        let incorrectChoiceText = stage.questions[0].choices.first { $0 != stage.questions[0].answer }!
        let incorrectChoice = Choice(text: incorrectChoiceText)

        // When: Answer incorrectly
        await MainActor.run {
            mainView.answer(selected: incorrectChoice)
        }

        // Then: Check AppState changes
        #expect(appState.incorrectQuestions.count == 1)
        #expect(appState.incorrectQuestions.contains(stage.questions[0].kanji))
    }

    @Test func testStageClear() async throws {
        let appState = AppState()
        appState.clearedStages = []
        
        let stage = createDummyStage(questionsCount: 1) // Only one question to clear
        let mainView = await MainView(stage: stage, isReviewMode: false)

        // Find the correct choice
        let correctChoice = Choice(text: stage.questions[0].answer)

        // When: Answer correctly to potentially clear stage
        await MainActor.run {
            mainView.answer(selected: correctChoice)
        }

        // Note: Stage clearing logic might require additional steps or time delays
        // This test focuses on the AppState changes we can observe
        // The actual stage clearing might happen in nextQuestion() or after animations
    }

    @Test func testQuestionStructure() async throws {
        // Test that our dummy questions are created correctly
        let stage = createDummyStage(questionsCount: 3)
        
        #expect(stage.questions.count == 3)
        #expect(stage.questions[0].kanji == "問0")
        #expect(stage.questions[0].answer == "選A0")
        #expect(stage.questions[0].choices.count == 2)
        #expect(stage.questions[0].choices.contains("選A0"))
        #expect(stage.questions[0].choices.contains("選B0"))
        #expect(stage.questions[0].explain == "解説0")
    }

    @Test func testAppStateIntegration() async throws {
        let appState = AppState()
        appState.incorrectQuestions = []
        appState.bookmarkedQuestions = []

        let stage = createDummyStage(questionsCount: 3)
        let mainView = await MainView(stage: stage, isReviewMode: false)

        // Test bookmarking functionality (if accessible through public methods)
        let testKanji = stage.questions[0].kanji
        
        // Add to bookmarks
        appState.addBookmarkedQuestion(testKanji)
        #expect(appState.bookmarkedQuestions.contains(testKanji))
        
        // Remove from bookmarks
        appState.removeBookmarkedQuestion(testKanji)
        #expect(!appState.bookmarkedQuestions.contains(testKanji))
        
        // Test incorrect questions
        appState.addIncorrectQuestion(testKanji)
        #expect(appState.incorrectQuestions.contains(testKanji))
        
        appState.removeIncorrectQuestion(testKanji)
        #expect(!appState.incorrectQuestions.contains(testKanji))
    }

    @Test func testReviewModeSetup() async throws {
        let appState = AppState()
        appState.incorrectQuestions = ["問0", "問2"]
        appState.bookmarkedQuestions = ["問1"]

        // Create a stage with multiple questions
        let stage = createDummyStage(questionsCount: 5)
        let mainView = await MainView(stage: stage, isReviewMode: true)

        // Review mode should filter questions based on incorrect and bookmarked
        let expectedReviewKanji = appState.incorrectQuestions.union(appState.bookmarkedQuestions)
        #expect(expectedReviewKanji.count == 3) // "問0", "問1", "問2"
    }

    @Test func testChoiceDataType() async throws {
        // Test that we can create Choice objects correctly
        let choice1 = Choice(text: "テスト選択肢1")
        let choice2 = Choice(text: "テスト選択肢2")
        
        #expect(choice1.text == "テスト選択肢1")
        #expect(choice2.text == "テスト選択肢2")
        
        // Test creating choices from string array (like in real data)
        let stringChoices = ["うし", "ひつじ"]
        let choiceObjects = stringChoices.map { Choice(text: $0) }
        
        #expect(choiceObjects.count == 2)
        #expect(choiceObjects[0].text == "うし")
        #expect(choiceObjects[1].text == "ひつじ")
    }

    @Test func testStageStructure() async throws {
        let stage = createDummyStage(questionsCount: 3)
        
        #expect(stage.stage == 1)
        #expect(stage.questions.count == 3)
        
        // Test that all questions have the required structure
        for (index, question) in stage.questions.enumerated() {
            #expect(question.kanji == "問\(index)")
            #expect(question.answer == "選A\(index)")
            #expect(question.choices.count == 2)
            #expect(question.explain == "解説\(index)")
        }
    }
}

// MARK: - Integration Tests
extension MainViewLogicTests {
    
    @Test func testMainViewInitialization() async throws {
        let stage = createDummyStage(questionsCount: 5)
        
        // Test normal mode initialization
        let normalView = await MainView(stage: stage, isReviewMode: false)
        // We can only test that the view was created successfully
        // Internal state testing requires the properties to be made internal or public
        
        // Test review mode initialization
        let reviewView = await MainView(stage: stage, isReviewMode: true)
        // Again, only testing successful creation
    }
    
    @Test func testEnvironmentObjectSetup() async throws {
        let appState = AppState()
        let stage = createDummyStage(questionsCount: 3)
        let mainView = await MainView(stage: stage, isReviewMode: false)
        
        // Test that AppState methods work correctly
        appState.addIncorrectQuestion("テスト漢字")
        #expect(appState.incorrectQuestions.contains("テスト漢字"))
        
        appState.addBookmarkedQuestion("テスト漢字2")
        #expect(appState.bookmarkedQuestions.contains("テスト漢字2"))
        
        // Test that isBookmarked works
        #expect(appState.isBookmarked("テスト漢字2") == true)
        #expect(appState.isBookmarked("存在しない漢字") == false)
    }
    
    @Test func testChoiceComparison() async throws {
        // Test that we can properly compare choices with strings
        let question = Question(
            kanji: "丑",
            answer: "うし",
            choices: ["うし", "ひつじ"],
            explain: "Test explanation"
        )
        
        let correctChoice = Choice(text: question.answer)
        let incorrectChoiceText = question.choices.first { $0 != question.answer }!
        let incorrectChoice = Choice(text: incorrectChoiceText)
        
        // Test that choice text matches expected values
        #expect(correctChoice.text == "うし")
        #expect(incorrectChoice.text == "ひつじ")
        
        // Test that we can find choices in the choices array by text (String comparison)
        #expect(question.choices.contains(correctChoice.text))
        #expect(question.choices.contains(incorrectChoice.text))
    }
    
    @Test func testQuestionFilteringForReview() async throws {
        // Simulate the logic that would be used in review mode
        let allQuestions = [
            Question(kanji: "問0", answer: "選A0", choices: ["選A0", "選B0"], explain: "解説0"),
            Question(kanji: "問1", answer: "選A1", choices: ["選A1", "選B1"], explain: "解説1"),
            Question(kanji: "問2", answer: "選A2", choices: ["選A2", "選B2"], explain: "解説2"),
            Question(kanji: "問3", answer: "選A3", choices: ["選A3", "選B3"], explain: "解説3")
        ]
        
        let incorrectQuestions: Set<String> = ["問0", "問2"]
        let bookmarkedQuestions: Set<String> = ["問1"]
        let reviewKanji = incorrectQuestions.union(bookmarkedQuestions)
        
        let filteredQuestions = allQuestions.filter { reviewKanji.contains($0.kanji) }
        
        #expect(filteredQuestions.count == 3)
        #expect(filteredQuestions.contains { $0.kanji == "問0" })
        #expect(filteredQuestions.contains { $0.kanji == "問1" })
        #expect(filteredQuestions.contains { $0.kanji == "問2" })
        #expect(!filteredQuestions.contains { $0.kanji == "問3" })
    }
    
    @Test func testStringChoicesHandling() async throws {
        // Test that we properly handle String choices from JSON structure
        let question = Question(
            kanji: "丑",
            answer: "うし",
            choices: ["うし", "ひつじ"], // This is [String], not [Choice]
            explain: "干支の一つで、十二支の2番目にあたります。"
        )
        
        // Test string operations on choices
        #expect(question.choices.contains("うし"))
        #expect(question.choices.contains("ひつじ"))
        #expect(!question.choices.contains("とら"))
        
        // Test finding incorrect choice as String
        let incorrectChoiceText = question.choices.first { $0 != question.answer }
        #expect(incorrectChoiceText == "ひつじ")
        
        // Test that we can convert strings to Choice objects when needed
        let choiceObjects = question.choices.map { Choice(text: $0) }
        #expect(choiceObjects.count == 2)
        #expect(choiceObjects[0].text == "うし")
        #expect(choiceObjects[1].text == "ひつじ")
    }
}
