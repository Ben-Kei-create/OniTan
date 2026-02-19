import XCTest
@testable import OniTan

@MainActor
final class QuizSessionViewModelTests: XCTestCase {

    var store: InMemoryPersistenceStore!
    var appState: AppState!
    var statsRepo: StudyStatsRepository!
    var stage: Stage!

    // Test questions
    var q1: Question!
    var q2: Question!
    var q3: Question!

    override func setUpWithError() throws {
        store = InMemoryPersistenceStore()
        appState = AppState(store: store)
        statsRepo = StudyStatsRepository(store: store)

        q1 = Question(kanji: "燎", choices: ["かがりび", "ひのき", "ともしび", "てまり"], answer: "かがりび", explain: "野火・かがり火")
        q2 = Question(kanji: "逞", choices: ["たくましい", "こころよい", "やさしい", "うつくしい"], answer: "たくましい", explain: "たくましいさま")
        q3 = Question(kanji: "慧", choices: ["かしこい", "いそがしい", "くるしい", "たのしい"], answer: "かしこい", explain: "かしこいさま")
        stage = Stage(stage: 1, questions: [q1, q2, q3])
    }

    override func tearDownWithError() throws {
        appState = nil
        statsRepo = nil
        store = nil
        stage = nil
        q1 = nil; q2 = nil; q3 = nil
    }

    // MARK: - Initial state

    func testInitialState() {
        let vm = makeVM()
        XCTAssertEqual(vm.clearedCount, 0)
        XCTAssertEqual(vm.phase, .answering)
        XCTAssertEqual(vm.currentQuestion.kanji, "燎")
        XCTAssertEqual(vm.totalGoal, 3)
        XCTAssertEqual(vm.passNumber, 1)
        XCTAssertEqual(vm.lastAnswerResult, .none)
    }

    func testProgressFraction_startsAtZero() {
        let vm = makeVM()
        XCTAssertEqual(vm.progressFraction, 0.0, accuracy: 0.001)
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

    func testCorrectAnswer_setsLastResultCorrect() {
        let vm = makeVM()
        vm.answer(selected: "かがりび")
        XCTAssertEqual(vm.lastAnswerResult, .correct)
    }

    func testCorrectAnswer_proceedToNextQuestion() {
        let vm = makeVM()
        vm.answer(selected: "かがりび")
        vm.proceed()
        XCTAssertEqual(vm.currentQuestion.kanji, "逞")
        XCTAssertEqual(vm.phase, .answering)
        XCTAssertEqual(vm.lastAnswerResult, .none)
    }

    func testProgressFraction_updatesOnCorrectAnswer() {
        let vm = makeVM()
        vm.answer(selected: "かがりび")
        XCTAssertEqual(vm.progressFraction, 1.0 / 3.0, accuracy: 0.001)
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

    func testWrongAnswer_setsLastResultWrong() {
        let vm = makeVM()
        vm.answer(selected: "ひのき")
        XCTAssertEqual(vm.lastAnswerResult, .wrong)
    }

    func testWrongAnswer_queuesForReview_normalMode() {
        let vm = makeVM(mode: .normal)
        vm.answer(selected: "ひのき")   // wrong on q1
        vm.proceed()
        vm.answer(selected: "たくましい") // correct on q2
        vm.proceed()
        vm.answer(selected: "かしこい")  // correct on q3
        vm.proceed()
        // q1 should come back as review
        XCTAssertEqual(vm.currentQuestion.kanji, "燎")
        XCTAssertEqual(vm.passNumber, 2)
    }

    func testWrongAnswer_noReviewQueue_examMode() {
        let vm = makeVM(mode: .exam30)
        // In exam mode wrong answers don't re-queue
        vm.answer(selected: "ひのき")   // wrong on q1
        vm.proceed()
        // Next question should be q2, not back to q1
        XCTAssertNotEqual(vm.currentQuestion.kanji, "燎",
            "Exam mode should not re-queue wrong answers")
    }

    // MARK: - Stage clear (normal mode)

    func testAllCorrect_clearsStage_normalMode() {
        let vm = makeVM(mode: .normal)
        vm.answer(selected: "かがりび"); vm.proceed()
        vm.answer(selected: "たくましい"); vm.proceed()
        vm.answer(selected: "かしこい")
        XCTAssertEqual(vm.phase, .stageCleared)
        XCTAssertTrue(appState.isCleared(1))
    }

    func testAllCorrect_doesNotClearStage_examMode() {
        let examStage = Stage(stage: 1, questions: [q1, q2])
        let vm = QuizSessionViewModel(stage: examStage, appState: appState, statsRepo: statsRepo, mode: .exam30)
        vm.answer(selected: q1.answer)
        vm.proceed()
        vm.answer(selected: q2.answer)
        XCTAssertEqual(vm.phase, .stageCleared, "Exam mode should reach stageCleared")
        XCTAssertFalse(appState.isCleared(1), "Exam mode should NOT mark stage cleared in AppState")
    }

    func testAllCorrect_clearedCountMatchesGoal() {
        let vm = makeVM()
        vm.answer(selected: "かがりび"); vm.proceed()
        vm.answer(selected: "たくましい"); vm.proceed()
        vm.answer(selected: "かしこい")
        XCTAssertEqual(vm.clearedCount, vm.totalGoal)
    }

    // MARK: - Quick10 mode

    func testQuick10Mode_limitsQuestions() {
        // Build a pool larger than 10
        var pool: [Question] = []
        for i in 0..<15 {
            pool.append(Question(
                kanji: "漢\(i)", choices: ["A", "B", "C", "D"],
                answer: "A", explain: "test \(i)"
            ))
        }
        let bigStage = Stage(stage: 1, questions: pool)
        let vm = QuizSessionViewModel(stage: bigStage, appState: appState, statsRepo: statsRepo, mode: .quick10)
        XCTAssertEqual(vm.totalGoal, 10, "Quick10 mode should cap at 10 questions")
    }

    func testExam30Mode_limitsQuestions() {
        var pool: [Question] = []
        for i in 0..<40 {
            pool.append(Question(
                kanji: "漢\(i)", choices: ["A", "B", "C", "D"],
                answer: "A", explain: "test \(i)"
            ))
        }
        let bigStage = Stage(stage: 1, questions: pool)
        let vm = QuizSessionViewModel(stage: bigStage, appState: appState, statsRepo: statsRepo, mode: .exam30)
        XCTAssertEqual(vm.totalGoal, 30)
    }

    // MARK: - Weak focus mode

    func testWeakFocusMode_usesWeakKanji() {
        // Pre-populate weak kanji for stage 1
        statsRepo.record(stageNumber: 1, kanji: "燎", wasCorrect: false, correctAnswer: "かがりび")

        let vm = makeVM(mode: .weakFocus)
        XCTAssertEqual(vm.totalGoal, 1, "WeakFocus should only use weak kanji")
        XCTAssertEqual(vm.currentQuestion.kanji, "燎")
    }

    func testWeakFocusMode_fallsBackToAllQuestions_whenNoWeakPoints() {
        // No weak kanji recorded
        let vm = makeVM(mode: .weakFocus)
        XCTAssertEqual(vm.totalGoal, stage.questions.count,
            "WeakFocus should fall back to all questions when no weak points")
    }

    // MARK: - Pass counter

    func testPassNumber_incrementsOnReviewPass() {
        let twoQ = Stage(stage: 1, questions: [q1, q2])
        let vm = QuizSessionViewModel(stage: twoQ, appState: appState, statsRepo: statsRepo, mode: .normal)
        XCTAssertEqual(vm.passNumber, 1)

        vm.answer(selected: "ひのき")     // wrong on q1
        vm.proceed()
        vm.answer(selected: "たくましい") // correct on q2
        vm.proceed()
        // Now in review pass
        XCTAssertEqual(vm.passNumber, 2, "Second pass should be marked as pass 2")
    }

    // MARK: - Reset

    func testResetGame_restoresInitialState() {
        let vm = makeVM()
        vm.answer(selected: "かがりび"); vm.proceed()
        vm.resetGame()
        XCTAssertEqual(vm.clearedCount, 0)
        XCTAssertEqual(vm.phase, .answering)
        XCTAssertEqual(vm.passNumber, 1)
        XCTAssertEqual(vm.lastAnswerResult, .none)
    }

    // MARK: - Quit alert

    func testRequestQuit_setsActiveAlert() {
        let vm = makeVM()
        vm.requestQuit()
        XCTAssertEqual(vm.activeAlert, .quitConfirmation)
    }

    func testRequestQuit_whenStageCleared_doesNotSetAlert() {
        let oneQ = Stage(stage: 1, questions: [q1])
        let vm = QuizSessionViewModel(stage: oneQ, appState: appState, statsRepo: statsRepo)
        vm.answer(selected: q1.answer)
        XCTAssertEqual(vm.phase, .stageCleared)
        vm.requestQuit()
        XCTAssertNil(vm.activeAlert, "No quit alert needed when stage is already cleared")
    }

    // MARK: - Review session

    func testReviewSession_clearsWithSubsetOfQuestions() {
        let reviewStage = Stage(stage: 1, questions: [q1])
        let vm = QuizSessionViewModel(stage: reviewStage, appState: appState, statsRepo: statsRepo)
        XCTAssertEqual(vm.totalGoal, 1)
        vm.answer(selected: q1.answer)
        XCTAssertEqual(vm.phase, .stageCleared)
    }

    func testReviewSession_wrongThenCorrectClears() {
        let reviewStage = Stage(stage: 1, questions: [q1])
        let vm = QuizSessionViewModel(stage: reviewStage, appState: appState, statsRepo: statsRepo)
        let wrongChoice = q1.choices.first { $0 != q1.answer }!
        vm.answer(selected: wrongChoice)
        vm.proceed()
        XCTAssertEqual(vm.currentQuestion.kanji, q1.kanji, "Wrong answer re-queued")
        vm.answer(selected: q1.answer)
        XCTAssertEqual(vm.phase, .stageCleared)
    }

    // MARK: - Helpers

    private func makeVM(mode: QuizMode = .normal) -> QuizSessionViewModel {
        QuizSessionViewModel(stage: stage, appState: appState, statsRepo: statsRepo, mode: mode)
    }
}
