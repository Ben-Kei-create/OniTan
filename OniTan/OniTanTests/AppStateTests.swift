import Testing
@testable import OniTan // Import your app module

struct AppStateTests {

    @Test func testClearedStagesPersistence() async throws {
        let appState = AppState()
        // Clear any persisted data before each test to ensure isolation
        UserDefaults.standard.removeObject(forKey: "clearedStages")
        UserDefaults.standard.removeObject(forKey: "incorrectQuestions")
        
        // Given: AppState with some cleared stages
        appState.clearedStages = [1, 2, 3]
        
        // When: AppState is re-initialized (simulating app restart)
        let newAppState = AppState()
        
        // Then: Cleared stages should be loaded correctly
        #expect(newAppState.clearedStages == [1, 2, 3])
    }

    @Test func testIncorrectQuestionsPersistence() async throws {
        let appState = AppState()
        // Clear any persisted data before each test to ensure isolation
        UserDefaults.standard.removeObject(forKey: "clearedStages")
        UserDefaults.standard.removeObject(forKey: "incorrectQuestions")
        
        // Given: AppState with some incorrect questions
        appState.incorrectQuestions = ["黙", "錆"]
        
        // When: AppState is re-initialized (simulating app restart)
        let newAppState = AppState()
        
        // Then: Incorrect questions should be loaded correctly
        #expect(newAppState.incorrectQuestions == ["黙", "錆"])
    }

    @Test func testAddIncorrectQuestion() async throws {
        let appState = AppState()
        appState.incorrectQuestions = [] // Ensure empty
        
        // Given
        let kanjiToAdd = "黙"

        // When
        appState.addIncorrectQuestion(kanjiToAdd)

        // Then
        #expect(appState.incorrectQuestions.count == 1)
        #expect(appState.incorrectQuestions.contains(kanjiToAdd))
    }

    @Test func testRemoveIncorrectQuestion() async throws {
        let appState = AppState()
        let kanjiToRemove = "黙"
        appState.incorrectQuestions = [kanjiToRemove] // Pre-fill
        
        // Given
        #expect(appState.incorrectQuestions.count == 1)

        // When
        appState.removeIncorrectQuestion(kanjiToRemove)

        // Then
        #expect(appState.incorrectQuestions.isEmpty)
        #expect(!appState.incorrectQuestions.contains(kanjiToRemove))
    }

    @Test func testResetUserDefaults() async throws {
        let appState = AppState()
        appState.clearedStages = [1, 2]
        appState.incorrectQuestions = ["黙", "錆"]
        
        // Given
        #expect(!appState.clearedStages.isEmpty)
        #expect(!appState.incorrectQuestions.isEmpty)

        // When
        appState.resetUserDefaults()

        // Then
        #expect(appState.clearedStages.isEmpty)
        #expect(appState.incorrectQuestions.isEmpty)
        
        // Verify persistence after reset
        let newAppState = AppState()
        #expect(newAppState.clearedStages.isEmpty)
        #expect(newAppState.incorrectQuestions.isEmpty)
    }
}
