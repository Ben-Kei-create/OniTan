import XCTest
@testable import OniTan

class AppStateTests: XCTestCase {

    // MARK: - Initialization Tests

    func testPersistenceKeys_areNamespaced() {
        for key in AppState.Keys.all {
            XCTAssertTrue(key.hasPrefix("com.onitan.appState."))
        }
    }

    func testInitialization_emptyStore() {
        let store = InMemoryStore()
        let state = AppState(store: store)

        XCTAssertTrue(state.clearedStages.isEmpty)
        XCTAssertTrue(state.wrongQuestions.isEmpty)
        XCTAssertEqual(state.totalAnswered, 0)
        XCTAssertEqual(state.totalCorrect, 0)
        XCTAssertEqual(state.bestStreak, 0)
    }

    func testInitialization_withSavedClearedStages() {
        let store = InMemoryStore()
        let saved: Set<Int> = [1, 2]
        let data = try! JSONEncoder().encode(saved)
        store.set(data, forKey: AppState.Keys.clearedStages)

        let state = AppState(store: store)
        XCTAssertEqual(state.clearedStages, saved)
    }

    func testInitialization_withSavedWrongQuestions() {
        let store = InMemoryStore()
        let saved: Set<String> = ["燎", "鬱"]
        let data = try! JSONEncoder().encode(saved)
        store.set(data, forKey: AppState.Keys.wrongQuestions)

        let state = AppState(store: store)
        XCTAssertEqual(state.wrongQuestions, saved)
    }

    func testInitialization_withSavedStatistics() {
        let store = InMemoryStore()
        store.set(try! JSONEncoder().encode(50), forKey: AppState.Keys.totalAnswered)
        store.set(try! JSONEncoder().encode(40), forKey: AppState.Keys.totalCorrect)
        store.set(try! JSONEncoder().encode(15), forKey: AppState.Keys.bestStreak)

        let state = AppState(store: store)
        XCTAssertEqual(state.totalAnswered, 50)
        XCTAssertEqual(state.totalCorrect, 40)
        XCTAssertEqual(state.bestStreak, 15)
    }

    // MARK: - Persistence Tests

    func testClearedStages_persistsOnChange() {
        let store = InMemoryStore()
        let state = AppState(store: store)

        state.clearedStages = [1, 3]

        let reloaded = AppState(store: store)
        XCTAssertEqual(reloaded.clearedStages, [1, 3])
    }

    func testWrongQuestions_persistsOnChange() {
        let store = InMemoryStore()
        let state = AppState(store: store)

        state.wrongQuestions = ["燎", "蹙"]

        let reloaded = AppState(store: store)
        XCTAssertEqual(reloaded.wrongQuestions, ["燎", "蹙"])
    }

    func testStatistics_persistOnChange() {
        let store = InMemoryStore()
        let state = AppState(store: store)

        state.totalAnswered = 10
        state.totalCorrect = 7
        state.bestStreak = 5

        let reloaded = AppState(store: store)
        XCTAssertEqual(reloaded.totalAnswered, 10)
        XCTAssertEqual(reloaded.totalCorrect, 7)
        XCTAssertEqual(reloaded.bestStreak, 5)
    }

    // MARK: - Wrong Questions Management

    func testRecordWrongAnswer() {
        let state = AppState(store: InMemoryStore())

        state.recordWrongAnswer(kanji: "鬱")
        XCTAssertTrue(state.wrongQuestions.contains("鬱"))
        XCTAssertTrue(state.hasWrongQuestions)
    }

    func testRecordCorrectReview_removesFromWrongQuestions() {
        let state = AppState(store: InMemoryStore())
        state.wrongQuestions = ["鬱", "燎"]

        state.recordCorrectReview(kanji: "鬱")
        XCTAssertFalse(state.wrongQuestions.contains("鬱"))
        XCTAssertTrue(state.wrongQuestions.contains("燎"))
    }

    func testHasWrongQuestions_falseWhenEmpty() {
        let state = AppState(store: InMemoryStore())
        XCTAssertFalse(state.hasWrongQuestions)
    }

    // MARK: - Statistics

    func testRecordAnswer_correct() {
        let state = AppState(store: InMemoryStore())
        state.recordAnswer(correct: true, currentStreak: 3)

        XCTAssertEqual(state.totalAnswered, 1)
        XCTAssertEqual(state.totalCorrect, 1)
        XCTAssertEqual(state.bestStreak, 3)
    }

    func testRecordAnswer_incorrect() {
        let state = AppState(store: InMemoryStore())
        state.recordAnswer(correct: false, currentStreak: 0)

        XCTAssertEqual(state.totalAnswered, 1)
        XCTAssertEqual(state.totalCorrect, 0)
        XCTAssertEqual(state.bestStreak, 0)
    }

    func testBestStreak_onlyUpdatesWhenHigher() {
        let state = AppState(store: InMemoryStore())
        state.recordAnswer(correct: true, currentStreak: 10)
        state.recordAnswer(correct: true, currentStreak: 5)

        XCTAssertEqual(state.bestStreak, 10)
    }

    func testCorrectRate_noAnswers() {
        let state = AppState(store: InMemoryStore())
        XCTAssertEqual(state.correctRate, 0)
    }

    func testCorrectRate_withAnswers() {
        let state = AppState(store: InMemoryStore())
        state.totalAnswered = 10
        state.totalCorrect = 7
        XCTAssertEqual(state.correctRate, 0.7, accuracy: 0.001)
    }

    // MARK: - Reset

    func testResetUserDefaults_clearsEverything() {
        let store = InMemoryStore()
        let state = AppState(store: store)

        state.clearedStages = [1, 2, 3]
        state.wrongQuestions = ["鬱", "燎"]
        state.totalAnswered = 50
        state.totalCorrect = 40
        state.bestStreak = 15
        state.showingResetAlert = true
        state.showResetConfirmation = true
        state.showingCannotResetAlert = true

        state.resetUserDefaults()

        XCTAssertTrue(state.clearedStages.isEmpty)
        XCTAssertTrue(state.wrongQuestions.isEmpty)
        XCTAssertEqual(state.totalAnswered, 0)
        XCTAssertEqual(state.totalCorrect, 0)
        XCTAssertEqual(state.bestStreak, 0)
        XCTAssertFalse(state.showingResetAlert)
        XCTAssertFalse(state.showResetConfirmation)
        XCTAssertFalse(state.showingCannotResetAlert)

        // Verify store is also cleared
        let reloaded = AppState(store: store)
        XCTAssertTrue(reloaded.clearedStages.isEmpty)
        XCTAssertTrue(reloaded.wrongQuestions.isEmpty)
    }

    func testResetUserDefaults_doesNotClearUnownedKeys() {
        let store = InMemoryStore()
        let state = AppState(store: store)
        let unrelatedKey = "com.onitan.settings.colorScheme"

        store.set(try! JSONEncoder().encode("dark"), forKey: unrelatedKey)
        state.clearedStages = [1]

        state.resetUserDefaults()

        XCTAssertNotNil(store.data(forKey: unrelatedKey))
    }
}
