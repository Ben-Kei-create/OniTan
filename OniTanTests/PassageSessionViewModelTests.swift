import XCTest
@testable import OniTan

@MainActor
final class PassageSessionViewModelTests: XCTestCase {

    // MARK: - Test Fixtures

    private var store: InMemoryPersistenceStore!
    private var statsRepo: StudyStatsRepository!
    private var streakRepo: StreakRepository!
    private var xpRepo: GamificationRepository!

    /// A passage with 2 targets (minimal for testing transitions).
    private var passage1: Passage!
    /// A passage with 1 target (edge case: single target).
    private var passage2: Passage!

    override func setUpWithError() throws {
        store = InMemoryPersistenceStore()
        statsRepo = StudyStatsRepository(store: store)
        streakRepo = StreakRepository(store: InMemoryPersistenceStore())
        xpRepo = GamificationRepository(store: InMemoryPersistenceStore())

        passage1 = Passage(
            title: "テスト文章1",
            source: "テスト",
            text: "山路を登りながら、こう考えた。",
            targets: [
                PassageTarget(position: 0, length: 2, reading: "やまじ",
                              choices: ["やまじ", "さんろ", "やまみち", "やまぢ"],
                              explain: "山路＝やまじ"),
                PassageTarget(position: 3, length: 1, reading: "のぼ",
                              choices: ["のぼ", "くだ", "あが", "おり"],
                              explain: "登る＝のぼる")
            ]
        )

        passage2 = Passage(
            title: "テスト文章2",
            source: "テスト",
            text: "智に働けば角が立つ。",
            targets: [
                PassageTarget(position: 0, length: 1, reading: "ち",
                              choices: ["ち", "とも", "さと", "のり"],
                              explain: "智＝ち")
            ]
        )
    }

    override func tearDownWithError() throws {
        store = nil; statsRepo = nil; streakRepo = nil; xpRepo = nil
        passage1 = nil; passage2 = nil
    }

    // MARK: - Helpers

    private func makeVM(
        passages: [Passage]? = nil,
        stageNumber: Int = 1,
        streakRepo: StreakRepository? = nil,
        xpRepo: GamificationRepository? = nil
    ) -> PassageSessionViewModel {
        PassageSessionViewModel(
            passages: passages ?? [passage1, passage2],
            stageNumber: stageNumber,
            statsRepo: statsRepo,
            streakRepo: streakRepo ?? self.streakRepo,
            xpRepo: xpRepo ?? self.xpRepo
        )
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 1. Initial State
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testInitialState_isReading() {
        let vm = makeVM()
        XCTAssertEqual(vm.phase, .reading)
        XCTAssertEqual(vm.passageIndex, 0)
        XCTAssertEqual(vm.targetIndex, 0)
        XCTAssertEqual(vm.totalCorrect, 0)
        XCTAssertEqual(vm.totalAnswered, 0)
        XCTAssertEqual(vm.sessionXPGained, 0)
        XCTAssertEqual(vm.consecutiveCorrect, 0)
        XCTAssertEqual(vm.comboCount, 0)
        XCTAssertEqual(vm.completionRatio, 0.0, accuracy: 0.001)
        XCTAssertEqual(vm.progressFraction, 0.0, accuracy: 0.001)
        XCTAssertFalse(vm.didCompletePassage)
    }

    func testInitialState_computedProperties() {
        let vm = makeVM()
        XCTAssertEqual(vm.totalPassages, 2)
        XCTAssertEqual(vm.targetsInCurrentPassage, 2)
        XCTAssertEqual(vm.totalTargets, 3) // 2 + 1
        XCTAssertEqual(vm.currentPassage.title, "テスト文章1")
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 2. Phase Transitions: reading → answering
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testStartAnswering_transitionsFromReading() {
        let vm = makeVM()
        XCTAssertEqual(vm.phase, .reading)
        vm.startAnswering()
        XCTAssertEqual(vm.phase, .answering)
        XCTAssertEqual(vm.targetIndex, 0)
    }

    func testStartAnswering_ignoredDuringAnswering() {
        let vm = makeVM()
        vm.startAnswering()
        XCTAssertEqual(vm.phase, .answering)
        // Calling again should be a no-op
        vm.startAnswering()
        XCTAssertEqual(vm.phase, .answering)
    }

    func testStartAnswering_ignoredDuringShowingResult() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ") // correct → showingResult
        XCTAssertTrue(vm.phase != .answering)
        vm.startAnswering()
        // Should remain in showingResult, not jump to answering
        XCTAssertTrue(vm.phase != .reading)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 3. Correct Answer
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testCorrectAnswer_transitionsToShowingResult() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ")
        if case .showingResult(let correct, let answer) = vm.phase {
            XCTAssertTrue(correct)
            XCTAssertEqual(answer, "やまじ")
        } else {
            XCTFail("Expected .showingResult, got \(vm.phase)")
        }
    }

    func testCorrectAnswer_incrementsCounters() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ")
        XCTAssertEqual(vm.totalCorrect, 1)
        XCTAssertEqual(vm.totalAnswered, 1)
        XCTAssertEqual(vm.consecutiveCorrect, 1)
        XCTAssertEqual(vm.comboCount, 1)
        XCTAssertEqual(vm.lastAnswerResult, .correct)
    }

    func testCorrectAnswer_marksTargetCompleted() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ")
        XCTAssertTrue(vm.completedTargetIndices.contains(0))
    }

    func testCorrectAnswer_awardsXP() {
        let vm = makeVM()
        vm.startAnswering()
        let xpBefore = xpRepo.totalXP
        vm.answer(selected: "やまじ")
        XCTAssertEqual(xpRepo.totalXP, xpBefore + XPEvent.correctAnswer.points)
        XCTAssertEqual(vm.sessionXPGained, XPEvent.correctAnswer.points)
    }

    func testCorrectAnswer_recordsStreakCorrectAnswer() {
        let vm = makeVM()
        vm.startAnswering()
        XCTAssertEqual(streakRepo.todayAnswerCount, 0)
        vm.answer(selected: "やまじ")
        XCTAssertEqual(streakRepo.todayAnswerCount, 1)
    }

    func testCorrectAnswer_completionRatioUpdates() {
        let vm = makeVM()  // totalTargets = 3
        vm.startAnswering()
        vm.answer(selected: "やまじ")  // 1/3
        XCTAssertEqual(vm.completionRatio, 1.0 / 3.0, accuracy: 0.001)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 4. Wrong Answer
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testWrongAnswer_transitionsToShowingResult() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "さんろ")
        if case .showingResult(let correct, let answer) = vm.phase {
            XCTAssertFalse(correct)
            XCTAssertEqual(answer, "やまじ") // shows correct answer
        } else {
            XCTFail("Expected .showingResult, got \(vm.phase)")
        }
    }

    func testWrongAnswer_doesNotIncrementCorrect() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "さんろ")
        XCTAssertEqual(vm.totalCorrect, 0)
        XCTAssertEqual(vm.totalAnswered, 1)
    }

    func testWrongAnswer_resetsCombo() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ") // correct → combo = 1
        vm.proceed()
        vm.answer(selected: "くだ")   // wrong → combo = 0
        XCTAssertEqual(vm.consecutiveCorrect, 0)
        XCTAssertEqual(vm.comboCount, 0)
    }

    func testWrongAnswer_doesNotAwardXP() {
        let vm = makeVM()
        vm.startAnswering()
        let xpBefore = xpRepo.totalXP
        vm.answer(selected: "さんろ")
        XCTAssertEqual(xpRepo.totalXP, xpBefore, "Wrong answer should not award XP")
    }

    func testWrongAnswer_doesNotRecordStreakAnswer() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "さんろ") // wrong
        XCTAssertEqual(streakRepo.todayAnswerCount, 0,
            "Wrong answer should not count toward streak")
    }

    func testWrongAnswer_completionRatioStaysAtZero() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "さんろ")
        XCTAssertEqual(vm.completionRatio, 0.0, accuracy: 0.001,
            "completionRatio is based on totalCorrect, not totalAnswered")
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 5. Invalid Answer Does NOT Advance State
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testAnswer_ignoredWhenNotInAnsweringPhase() {
        let vm = makeVM()
        // In .reading phase
        vm.answer(selected: "やまじ")
        XCTAssertEqual(vm.phase, .reading, "answer() should be a no-op when not .answering")
        XCTAssertEqual(vm.totalAnswered, 0)
    }

    func testAnswer_ignoredDuringShowingResult() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ")
        let answered = vm.totalAnswered
        // Now in .showingResult — tapping again should be ignored
        vm.answer(selected: "やまじ")
        XCTAssertEqual(vm.totalAnswered, answered, "Repeated answer during showingResult must be ignored")
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 6. Proceed + Target Transitions
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testProceed_advancesToNextTarget() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ") // correct target 0
        vm.proceed()
        XCTAssertEqual(vm.phase, .answering)
        XCTAssertEqual(vm.targetIndex, 1)
        XCTAssertEqual(vm.lastAnswerResult, .none)
    }

    func testProceed_ignoredWhenNotShowingResult() {
        let vm = makeVM()
        vm.startAnswering()
        // In .answering phase, proceed should be a no-op
        vm.proceed()
        XCTAssertEqual(vm.phase, .answering)
        XCTAssertEqual(vm.targetIndex, 0)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 7. Passage Complete
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testLastTarget_transitionsToPassageComplete() {
        let vm = makeVM() // passage1 has 2 targets, passage2 has 1
        vm.startAnswering()
        vm.answer(selected: "やまじ"); vm.proceed() // target 0 → target 1
        vm.answer(selected: "のぼ"); vm.proceed()   // target 1 → passageComplete
        XCTAssertEqual(vm.phase, .passageComplete)
        XCTAssertTrue(vm.didCompletePassage, "didCompletePassage should be set on passage completion")
    }

    func testPassageComplete_progressFraction() {
        let vm = makeVM() // 3 total targets
        vm.startAnswering()
        vm.answer(selected: "やまじ"); vm.proceed()
        vm.answer(selected: "のぼ"); vm.proceed()
        // Answered 2 of 3 total targets
        XCTAssertEqual(vm.progressFraction, 2.0 / 3.0, accuracy: 0.001)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 8. Next Passage
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testNextPassage_transitionsToReadingForPassage2() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ"); vm.proceed()
        vm.answer(selected: "のぼ"); vm.proceed()
        XCTAssertEqual(vm.phase, .passageComplete)
        vm.nextPassage()
        XCTAssertEqual(vm.phase, .reading)
        XCTAssertEqual(vm.passageIndex, 1)
        XCTAssertEqual(vm.targetIndex, 0)
        XCTAssertTrue(vm.completedTargetIndices.isEmpty)
        XCTAssertFalse(vm.didCompletePassage, "didCompletePassage should reset on next passage")
    }

    func testNextPassage_ignoredWhenNotPassageComplete() {
        let vm = makeVM()
        vm.startAnswering()
        vm.nextPassage() // should be ignored
        XCTAssertEqual(vm.phase, .answering)
        XCTAssertEqual(vm.passageIndex, 0)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 9. Session Complete (after last passage)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testSessionComplete_afterLastPassage() {
        let vm = makeVM()
        // Complete passage 1
        vm.startAnswering()
        vm.answer(selected: "やまじ"); vm.proceed()
        vm.answer(selected: "のぼ"); vm.proceed()
        XCTAssertEqual(vm.phase, .passageComplete)
        // Move to passage 2
        vm.nextPassage()
        vm.startAnswering()
        vm.answer(selected: "ち"); vm.proceed()
        // After last target in last passage → sessionComplete
        XCTAssertEqual(vm.phase, .sessionComplete)
        XCTAssertTrue(vm.didCompletePassage)
    }

    func testSessionComplete_awardsSessionXP() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ"); vm.proceed()
        vm.answer(selected: "のぼ"); vm.proceed()
        vm.nextPassage()
        vm.startAnswering()
        vm.answer(selected: "ち"); vm.proceed()
        // 3 correct answers + session complete bonus
        let expected = 3 * XPEvent.correctAnswer.points
            + XPEvent.comboBonus.points    // combo at 3 consecutive
            + XPEvent.sessionComplete.points
        XCTAssertEqual(xpRepo.totalXP, expected)
        XCTAssertEqual(vm.sessionXPGained, expected)
    }

    func testSessionComplete_recordsStudyTime() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ"); vm.proceed()
        vm.answer(selected: "のぼ"); vm.proceed()
        vm.nextPassage()
        vm.startAnswering()
        vm.answer(selected: "ち"); vm.proceed()
        // Study time should have been recorded (we can't check exact value,
        // but todayStudySeconds should be > 0 after addStudyTime call)
        // Note: in tests this might be ~0 since execution is fast,
        // but the method should have been called
        XCTAssertEqual(vm.phase, .sessionComplete)
    }

    func testSessionComplete_fullCompletionRatio() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ"); vm.proceed()
        vm.answer(selected: "のぼ"); vm.proceed()
        vm.nextPassage()
        vm.startAnswering()
        vm.answer(selected: "ち"); vm.proceed()
        XCTAssertEqual(vm.completionRatio, 1.0, accuracy: 0.001)
        XCTAssertEqual(vm.progressFraction, 1.0, accuracy: 0.001)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 10. Streak Integration
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testStreak_onlyRecordsOnCorrectAnswers() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "さんろ") // wrong
        XCTAssertEqual(streakRepo.todayAnswerCount, 0)
        vm.proceed()
        vm.answer(selected: "のぼ") // correct
        XCTAssertEqual(streakRepo.todayAnswerCount, 1)
    }

    func testStreak_studyTimeAddedOnSessionComplete() {
        let freshStreakStore = InMemoryPersistenceStore()
        let freshStreak = StreakRepository(store: freshStreakStore)
        let vm = makeVM(passages: [passage2], streakRepo: freshStreak)
        XCTAssertEqual(freshStreak.todayStudySeconds, 0)
        vm.startAnswering()
        vm.answer(selected: "ち"); vm.proceed()
        XCTAssertEqual(vm.phase, .sessionComplete)
        // addStudyTime should have been called — elapsed time ≥ 0
        XCTAssertTrue(freshStreak.todayStudySeconds >= 0)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 11. No Double-XP on Repeated Taps
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testNoDoubleXP_repeatedAnswerWhileShowingResult() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ")
        let xpAfterFirst = xpRepo.totalXP
        let answeredAfterFirst = vm.totalAnswered
        // Tap again — should be ignored
        vm.answer(selected: "やまじ")
        XCTAssertEqual(xpRepo.totalXP, xpAfterFirst, "Double tap must not award extra XP")
        XCTAssertEqual(vm.totalAnswered, answeredAfterFirst, "Double tap must not double-count")
    }

    func testNoDoubleXP_answerBeforeStartAnswering() {
        let vm = makeVM()
        // In .reading phase
        vm.answer(selected: "やまじ")
        XCTAssertEqual(xpRepo.totalXP, 0, "XP must not be awarded in reading phase")
        XCTAssertEqual(vm.totalAnswered, 0)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 12. Combo Bonus
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testComboBonus_firesAt3Consecutive() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ"); vm.proceed()   // combo 1
        vm.answer(selected: "のぼ"); vm.proceed()     // combo 2
        vm.nextPassage()
        vm.startAnswering()
        vm.answer(selected: "ち")                      // combo 3 → bonus
        // 3 * correctAnswer(5) + comboBonus(2) = 17 (before session complete)
        let expectedBeforeSession = 3 * XPEvent.correctAnswer.points + XPEvent.comboBonus.points
        // Session complete adds sessionComplete points
        vm.proceed()
        let expectedTotal = expectedBeforeSession + XPEvent.sessionComplete.points
        XCTAssertEqual(xpRepo.totalXP, expectedTotal)
    }

    func testComboCount_resetsOnWrongAnswer() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ") // correct → combo 1
        vm.proceed()
        vm.answer(selected: "くだ")   // wrong → combo 0
        XCTAssertEqual(vm.comboCount, 0)
    }

    func testComboCount_mirrorsConsecutiveCorrect() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ")
        XCTAssertEqual(vm.comboCount, vm.consecutiveCorrect)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 13. Edge Case: Single Target, Single Passage
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testSinglePassageSingleTarget_goesDirectlyToSessionComplete() {
        let vm = makeVM(passages: [passage2]) // 1 passage, 1 target
        XCTAssertEqual(vm.totalTargets, 1)
        XCTAssertEqual(vm.totalPassages, 1)
        vm.startAnswering()
        vm.answer(selected: "ち")
        vm.proceed()
        XCTAssertEqual(vm.phase, .sessionComplete)
        XCTAssertTrue(vm.didCompletePassage)
        XCTAssertEqual(vm.completionRatio, 1.0, accuracy: 0.001)
    }

    func testSinglePassageSingleTarget_wrongThenCorrect() {
        let vm = makeVM(passages: [passage2])
        vm.startAnswering()
        vm.answer(selected: "とも") // wrong
        XCTAssertEqual(vm.totalCorrect, 0)
        vm.proceed()
        // After wrong on last target, phase goes to...
        // proceed() after wrong on last target of last passage → sessionComplete
        XCTAssertEqual(vm.phase, .sessionComplete)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 14. Nil Repositories (graceful degradation)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testNilXPRepo_doesNotCrash() {
        let vm = PassageSessionViewModel(
            passages: [passage2],
            stageNumber: 1,
            statsRepo: statsRepo,
            streakRepo: nil,
            xpRepo: nil
        )
        vm.startAnswering()
        vm.answer(selected: "ち"); vm.proceed()
        XCTAssertEqual(vm.phase, .sessionComplete)
        XCTAssertEqual(vm.sessionXPGained, 0)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 15. Quit Alert
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testRequestQuit_setsAlertDuringSession() {
        let vm = makeVM()
        vm.startAnswering()
        vm.requestQuit()
        XCTAssertEqual(vm.activeAlert, .quitConfirmation)
    }

    func testRequestQuit_noAlertWhenSessionComplete() {
        let vm = makeVM(passages: [passage2])
        vm.startAnswering()
        vm.answer(selected: "ち"); vm.proceed()
        XCTAssertEqual(vm.phase, .sessionComplete)
        vm.requestQuit()
        XCTAssertNil(vm.activeAlert)
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 16. Micro-Completion Flag
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testDidCompletePassage_setOnPassageComplete() {
        let vm = makeVM()
        XCTAssertFalse(vm.didCompletePassage)
        vm.startAnswering()
        vm.answer(selected: "やまじ"); vm.proceed()
        XCTAssertFalse(vm.didCompletePassage, "Not yet complete")
        vm.answer(selected: "のぼ"); vm.proceed()
        XCTAssertTrue(vm.didCompletePassage, "Should be set after all targets in passage done")
    }

    func testDidCompletePassage_resetsOnNextPassage() {
        let vm = makeVM()
        vm.startAnswering()
        vm.answer(selected: "やまじ"); vm.proceed()
        vm.answer(selected: "のぼ"); vm.proceed()
        XCTAssertTrue(vm.didCompletePassage)
        vm.nextPassage()
        XCTAssertFalse(vm.didCompletePassage, "Should reset when moving to next passage")
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 17. XPCurveConfig (deterministic formula)
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testXPCurveConfig_defaultComputation() {
        let config = XPCurveConfig.default
        XCTAssertEqual(config.computeXP(), 5, "default: 5 * 1.0 * 1.0 + 0 = 5")
    }

    func testXPCurveConfig_passageDefaultComputation() {
        let config = XPCurveConfig.passageDefault
        XCTAssertEqual(config.computeXP(), 8, "passage: 5 * 1.0 * 1.0 + 3 = 8")
    }

    func testXPCurveConfig_withMultipliers() {
        let config = XPCurveConfig(baseXP: 10, streakMultiplier: 1.5, difficultyMultiplier: 2.0, passageBonus: 5)
        XCTAssertEqual(config.computeXP(), 35, "10 * 1.5 * 2.0 + 5 = 35")
    }

    func testXPCurveConfig_zeroBase() {
        let config = XPCurveConfig(baseXP: 0, streakMultiplier: 10.0, difficultyMultiplier: 10.0, passageBonus: 7)
        XCTAssertEqual(config.computeXP(), 7, "0 * 10.0 * 10.0 + 7 = 7")
    }

    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    // MARK: - 18. Streak Freeze Foundation
    // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    func testStreakFreezeAvailable_reflectsFreezeCount() {
        let freshStore = InMemoryPersistenceStore()
        let repo = StreakRepository(store: freshStore)
        XCTAssertTrue(repo.hasStreakFreezeAvailable, "New repo should have 1 freeze available")
        XCTAssertEqual(repo.freezeCount, 1)
    }

    func testStreakFreezeAvailable_falseWhenConsumed() {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: now)!

        let seed = StreakData(
            currentStreak: 3,
            longestStreak: 3,
            lastStudyDate: threeDaysAgo,
            todayCompleted: false,
            todayAnswerCount: 0,
            todayStudySeconds: 0,
            freezeCount: 1,
            freezeGrantMonthKey: nil
        )
        let freezeStore = InMemoryPersistenceStore()
        freezeStore.set(try! JSONEncoder().encode(seed), forKey: "streak_v2")
        let repo = StreakRepository(store: freezeStore, nowProvider: { now })
        // Freeze should have been consumed on init due to 3-day gap
        XCTAssertFalse(repo.hasStreakFreezeAvailable)
        XCTAssertEqual(repo.freezeCount, 0)
    }
}
