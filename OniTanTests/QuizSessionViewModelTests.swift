import XCTest
@testable import OniTan

@MainActor
final class QuizSessionViewModelTests: XCTestCase {

    var appState: AppState!
    var statsRepo: StudyStatsRepository!
    var stage: Stage!

    override func setUpWithError() throws {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        appState = AppState()
        statsRepo = StudyStatsRepository()

        // Build a minimal 2-question test stage
        let q1 = Question(kanji: "燎", choices: ["かがりび", "ひのき"], answer: "かがりび", explain: "野火・かがり火")
        let q2 = Question(kanji: "逞", choices: ["たくましい", "こころよい"], answer: "たくましい", explain: "たくましいさま")
        stage = Stage(stage: 1, questions: [q1, q2])
    }

    override func tearDownWithError() throws {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        appState = nil
        statsRepo = nil
        stage = nil
    }

    // MARK: - Initial state

    func testInitialState() {
        let vm = makeVM()
        XCTAssertEqual(vm.clearedCount, 0)
        XCTAssertEqual(vm.phase, .answering)
        XCTAssertEqual(vm.currentQuestion.kanji, "燎")
    }

    // MARK: - Correct answer

    func testCorrectAnswer_incrementsCount() {
        let vm = makeVM()
        vm.answer(selected: "かがりび")
        XCTAssertEqual(vm.clearedCount, 1)
    }

    func testCorrectAnswer_showsExplanation() {
        let vm = makeVM()
        vm.answer(selected: "かがりび")
        XCTAssertEqual(vm.phase, .showingExplanation)
    }

    func testCorrectAnswer_proceedToNextQuestion() {
        let vm = makeVM()
        vm.answer(selected: "かがりび")
        vm.proceed()
        XCTAssertEqual(vm.currentQuestion.kanji, "逞")
        XCTAssertEqual(vm.phase, .answering)
    }

    // MARK: - Wrong answer

    func testWrongAnswer_doesNotIncrementCount() {
        let vm = makeVM()
        vm.answer(selected: "ひのき")
        XCTAssertEqual(vm.clearedCount, 0)
    }

    func testWrongAnswer_showsWrongAnswerPhase() {
        let vm = makeVM()
        vm.answer(selected: "ひのき")
        if case .showingWrongAnswer(let correct) = vm.phase {
            XCTAssertEqual(correct, "かがりび")
        } else {
            XCTFail("Expected showingWrongAnswer, got \(vm.phase)")
        }
    }

    func testWrongAnswer_queuesForReview() {
        let vm = makeVM()
        // Wrong on q1
        vm.answer(selected: "ひのき")
        vm.proceed()
        // Correct on q2 → stage not cleared yet (q1 still pending review)
        vm.answer(selected: "たくましい")
        vm.proceed()
        // Should loop back to review q1
        XCTAssertEqual(vm.currentQuestion.kanji, "燎")
        XCTAssertEqual(vm.phase, .answering)
    }

    // MARK: - Stage clear

    func testAllCorrect_clearsStage() {
        let vm = makeVM()
        vm.answer(selected: "かがりび")
        vm.proceed()
        vm.answer(selected: "たくましい")
        XCTAssertEqual(vm.phase, .stageCleared)
        XCTAssertTrue(appState.isCleared(1))
    }

    func testAllCorrect_clearedCountMatchesGoal() {
        let vm = makeVM()
        vm.answer(selected: "かがりび")
        vm.proceed()
        vm.answer(selected: "たくましい")
        XCTAssertEqual(vm.clearedCount, vm.totalGoal)
    }

    // MARK: - Reset

    func testResetGame_restoresInitialState() {
        let vm = makeVM()
        vm.answer(selected: "かがりび")
        vm.proceed()
        vm.resetGame()
        XCTAssertEqual(vm.clearedCount, 0)
        XCTAssertEqual(vm.phase, .answering)
        XCTAssertEqual(vm.currentQuestion.kanji, "燎")
    }

    // MARK: - Quit alert

    func testShowingQuitAlert_defaultFalse() {
        let vm = makeVM()
        XCTAssertFalse(vm.showingQuitAlert)
    }

    func testShowingQuitAlert_canBeSet() {
        let vm = makeVM()
        vm.showingQuitAlert = true
        XCTAssertTrue(vm.showingQuitAlert)
    }

    // MARK: - Review session

    /// 苦手問題だけを渡した「復習セッション」として動作することを検証
    func testReviewSession_clearsWithSubsetOfQuestions() {
        // 弱点問題 q1 だけで復習ステージを構成
        let q1 = stage.questions[0]
        let reviewStage = Stage(stage: stage.stage, questions: [q1])
        let vm = QuizSessionViewModel(stage: reviewStage, appState: appState, statsRepo: statsRepo)

        XCTAssertEqual(vm.totalGoal, 1, "復習セッションのゴールは渡した問題数")
        XCTAssertEqual(vm.currentQuestion.kanji, q1.kanji)

        vm.answer(selected: q1.answer)
        XCTAssertEqual(vm.phase, .stageCleared, "1問正解でセッション完了")
    }

    /// 復習セッション中に不正解 → 再度出題 → 正解でクリア
    func testReviewSession_wrongThenCorrectClears() {
        let q1 = stage.questions[0]
        let reviewStage = Stage(stage: stage.stage, questions: [q1])
        let vm = QuizSessionViewModel(stage: reviewStage, appState: appState, statsRepo: statsRepo)

        // 不正解
        let wrongChoice = q1.choices.first { $0 != q1.answer }!
        vm.answer(selected: wrongChoice)
        XCTAssertEqual(vm.clearedCount, 0)

        // 次へ進む（reviewQueue に入り再出題）
        vm.proceed()
        XCTAssertEqual(vm.currentQuestion.kanji, q1.kanji, "不正解は再出題される")

        // 正解
        vm.answer(selected: q1.answer)
        XCTAssertEqual(vm.phase, .stageCleared)
    }

    // MARK: - Helpers

    private func makeVM() -> QuizSessionViewModel {
        QuizSessionViewModel(stage: stage, appState: appState, statsRepo: statsRepo)
    }
}
