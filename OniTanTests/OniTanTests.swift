import Testing
import XCTest
@testable import OniTan

// MARK: - JSON Validation Tests (Swift Testing framework)

struct OniTanTests {

    // MARK: - validateQuizData

    @Test func validateQuizData_emptyStage_reportsIssue() {
        let empty = Stage(stage: 1, questions: [])
        let data = QuizData(stages: [empty], unused_questions: nil)
        let issues = validateQuizData(data)
        #expect(!issues.isEmpty, "Empty stage should produce a validation issue")
        #expect(issues.contains { $0.contains("0件") })
    }

    @Test func validateQuizData_duplicateKanji_reportsIssue() {
        let q1 = Question(kanji: "燎", choices: ["A", "B"], answer: "A", explain: "e")
        let q2 = Question(kanji: "燎", choices: ["A", "B"], answer: "A", explain: "e")  // duplicate
        let stage = Stage(stage: 1, questions: [q1, q2])
        let data = QuizData(stages: [stage], unused_questions: nil)
        let issues = validateQuizData(data)
        #expect(issues.contains { $0.contains("重複") })
    }

    @Test func validateQuizData_answerNotInChoices_reportsIssue() {
        let q = Question(kanji: "燎", choices: ["A", "B"], answer: "Z", explain: "e")
        let stage = Stage(stage: 1, questions: [q])
        let data = QuizData(stages: [stage], unused_questions: nil)
        let issues = validateQuizData(data)
        #expect(issues.contains { $0.contains("選択肢に含まれていません") })
    }

    @Test func validateQuizData_tooFewChoices_reportsIssue() {
        let q = Question(kanji: "燎", choices: ["A"], answer: "A", explain: "e")
        let stage = Stage(stage: 1, questions: [q])
        let data = QuizData(stages: [stage], unused_questions: nil)
        let issues = validateQuizData(data)
        #expect(issues.contains { $0.contains("最低2個") })
    }

    @Test func validateQuizData_validData_noIssues() {
        let q1 = Question(kanji: "燎", choices: ["A", "B", "C", "D"], answer: "A", explain: "e1")
        let q2 = Question(kanji: "逞", choices: ["W", "X", "Y", "Z"], answer: "W", explain: "e2")
        let stage = Stage(stage: 1, questions: [q1, q2])
        let data = QuizData(stages: [stage], unused_questions: nil)
        let issues = validateQuizData(data)
        #expect(issues.isEmpty, "Valid data should produce no issues. Got: \(issues)")
    }

    @Test func validateQuizData_emptyKanji_reportsIssue() {
        let q = Question(kanji: "", choices: ["A", "B"], answer: "A", explain: "e")
        let stage = Stage(stage: 1, questions: [q])
        let data = QuizData(stages: [stage], unused_questions: nil)
        let issues = validateQuizData(data)
        #expect(issues.contains { $0.contains("空の kanji") })
    }

    // MARK: - QuizMode buildQuestionList

    @Test func quizMode_quick10_deduplicatesKanji() {
        // Create 10 questions with 5 duplicates
        var pool: [Question] = []
        for i in 0..<5 {
            pool.append(Question(kanji: "漢\(i)", choices: ["A", "B"], answer: "A", explain: ""))
            pool.append(Question(kanji: "漢\(i)", choices: ["A", "B"], answer: "A", explain: ""))  // dup
        }
        let result = QuizMode.quick10.buildQuestionList(from: pool)
        let kanjis = result.map { $0.kanji }
        let uniqueKanjis = Set(kanjis)
        #expect(kanjis.count == uniqueKanjis.count, "buildQuestionList should deduplicate kanji")
    }

    @Test func quizMode_normal_preservesOrder() {
        let pool = [
            Question(kanji: "A", choices: ["1", "2"], answer: "1", explain: ""),
            Question(kanji: "B", choices: ["1", "2"], answer: "1", explain: ""),
            Question(kanji: "C", choices: ["1", "2"], answer: "1", explain: ""),
        ]
        let result = QuizMode.normal.buildQuestionList(from: pool)
        XCTAssertEqual(result.map { $0.kanji }, ["A", "B", "C"])
    }

    @Test func quizMode_exam30_limitsTo30() {
        var pool: [Question] = []
        for i in 0..<50 {
            pool.append(Question(kanji: "漢\(i)", choices: ["A", "B"], answer: "A", explain: ""))
        }
        let result = QuizMode.exam30.buildQuestionList(from: pool)
        #expect(result.count == 30)
    }

    @Test func quizMode_weakFocus_filtersToWeakKanji() {
        let pool = [
            Question(kanji: "弱", choices: ["A", "B"], answer: "A", explain: ""),
            Question(kanji: "強", choices: ["A", "B"], answer: "A", explain: ""),
        ]
        let result = QuizMode.weakFocus.buildQuestionList(from: pool, weakKanji: ["弱"])
        #expect(result.count == 1)
        #expect(result[0].kanji == "弱")
    }

    @Test func quizMode_weakFocus_fallsBackWhenNoWeak() {
        let pool = [
            Question(kanji: "A", choices: ["1", "2"], answer: "1", explain: ""),
            Question(kanji: "B", choices: ["1", "2"], answer: "1", explain: ""),
        ]
        let result = QuizMode.weakFocus.buildQuestionList(from: pool, weakKanji: [])
        #expect(result.count == 2, "Should fall back to all questions when weak set is empty")
    }

    // MARK: - StudyStatsRepository

    @Test func studyStats_wrongAnswerLog_capturesEntries() {
        let store = InMemoryPersistenceStore()
        let repo = StudyStatsRepository(store: store)
        repo.record(stageNumber: 1, kanji: "燎", wasCorrect: false,
                    selectedAnswer: "ひのき", correctAnswer: "かがりび")
        let log = repo.wrongAnswerLog(forStage: 1)
        #expect(log.count == 1)
        #expect(log[0].kanji == "燎")
        #expect(log[0].correctAnswer == "かがりび")
        #expect(log[0].selectedAnswer == "ひのき")
    }

    @Test func studyStats_wrongAnswerLog_clearedOnCorrectAnswer() {
        let store = InMemoryPersistenceStore()
        let repo = StudyStatsRepository(store: store)
        repo.record(stageNumber: 1, kanji: "燎", wasCorrect: false, correctAnswer: "かがりび")
        repo.record(stageNumber: 1, kanji: "燎", wasCorrect: true, correctAnswer: "かがりび")
        #expect(repo.allWeakKanji(forStage: 1).isEmpty,
            "Weak kanji list should be cleared after correct answer")
    }

    @Test func studyStats_overallAccuracy_calculatesCorrectly() {
        let store = InMemoryPersistenceStore()
        let repo = StudyStatsRepository(store: store)
        repo.record(stageNumber: 1, kanji: "A", wasCorrect: true, correctAnswer: "x")
        repo.record(stageNumber: 1, kanji: "B", wasCorrect: true, correctAnswer: "x")
        repo.record(stageNumber: 1, kanji: "C", wasCorrect: false, correctAnswer: "x")
        // 2/3 correct
        #expect(abs(repo.overallAccuracy - 2.0/3.0) < 0.001)
    }

    @Test func studyStats_recentWrongAnswers_sortsByDateNewestFirst() {
        let store = InMemoryPersistenceStore()
        let repo = StudyStatsRepository(store: store)
        repo.record(stageNumber: 1, kanji: "A", wasCorrect: false, correctAnswer: "x")
        repo.record(stageNumber: 2, kanji: "B", wasCorrect: false, correctAnswer: "y")
        let recent = repo.recentWrongAnswers(limit: 10)
        #expect(recent.count == 2)
        #expect(recent[0].date >= recent[1].date, "Newest entries should come first")
    }
}

// MARK: - StreakRepository Tests

struct StreakRepositoryTests {

    @Test func streak_startsAtZero() {
        let repo = StreakRepository(store: InMemoryPersistenceStore())
        #expect(repo.currentStreak == 0)
        #expect(repo.todayCompleted == false)
        #expect(repo.todayAnswerCount == 0)
    }

    @Test func streak_completedAfter10CorrectAnswers() {
        let repo = StreakRepository(store: InMemoryPersistenceStore())
        for _ in 0..<10 { repo.recordCorrectAnswer() }
        #expect(repo.todayCompleted == true, "Daily goal should be met after 10 correct answers")
        #expect(repo.currentStreak == 1)
        #expect(repo.longestStreak == 1)
    }

    @Test func streak_completedAfterSufficientStudyTime() {
        let repo = StreakRepository(store: InMemoryPersistenceStore())
        repo.addStudyTime(120)
        #expect(repo.todayCompleted == true, "Daily goal should be met after 120 seconds")
        #expect(repo.currentStreak == 1)
    }

    @Test func streak_partialAnswersDontComplete() {
        let repo = StreakRepository(store: InMemoryPersistenceStore())
        for _ in 0..<9 { repo.recordCorrectAnswer() }
        #expect(repo.todayCompleted == false, "9 correct answers should not satisfy the 10-question goal")
        #expect(repo.currentStreak == 0)
    }

    @Test func streak_notDuplicatedOnDoubleComplete() {
        let repo = StreakRepository(store: InMemoryPersistenceStore())
        for _ in 0..<15 { repo.recordCorrectAnswer() }
        #expect(repo.currentStreak == 1, "Streak should only increment once per day")
    }

    @Test func streak_longestTracked() {
        let repo = StreakRepository(store: InMemoryPersistenceStore())
        for _ in 0..<10 { repo.recordCorrectAnswer() }
        #expect(repo.longestStreak >= repo.currentStreak)
    }

    @Test func streak_freezeConsumesOnGapOverOneDay() {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: now)!

        let seed = StreakData(
            currentStreak: 5,
            longestStreak: 5,
            lastStudyDate: threeDaysAgo,
            todayCompleted: false,
            todayAnswerCount: 0,
            todayStudySeconds: 0,
            freezeCount: 1,
            freezeGrantMonthKey: nil
        )

        let store = InMemoryPersistenceStore()
        store.set(try! JSONEncoder().encode(seed), forKey: "streak_v2")

        let repo = StreakRepository(store: store, nowProvider: { now })
        #expect(repo.currentStreak == 5, "Freeze should preserve streak when there is a gap")
        #expect(repo.freezeCount == 0, "Freeze should be consumed")
    }

    @Test func streak_resetsWithoutFreezeOnGapOverOneDay() {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: now)!

        let seed = StreakData(
            currentStreak: 5,
            longestStreak: 5,
            lastStudyDate: threeDaysAgo,
            todayCompleted: false,
            todayAnswerCount: 0,
            todayStudySeconds: 0,
            freezeCount: 0,
            freezeGrantMonthKey: StreakRepositoryTests.monthKey(for: now)
        )

        let store = InMemoryPersistenceStore()
        store.set(try! JSONEncoder().encode(seed), forKey: "streak_v2")

        let repo = StreakRepository(store: store, nowProvider: { now })
        #expect(repo.currentStreak == 0, "Streak should reset when no freeze remains")
        #expect(repo.freezeCount == 0)
    }

    @Test func streak_freezeConsumedOnlyOncePerGapRepair() {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: now)!

        let seed = StreakData(
            currentStreak: 4,
            longestStreak: 4,
            lastStudyDate: threeDaysAgo,
            todayCompleted: false,
            todayAnswerCount: 0,
            todayStudySeconds: 0,
            freezeCount: 1,
            freezeGrantMonthKey: StreakRepositoryTests.monthKey(for: now)
        )

        let store = InMemoryPersistenceStore()
        store.set(try! JSONEncoder().encode(seed), forKey: "streak_v2")

        _ = StreakRepository(store: store, nowProvider: { now })
        let repoAgain = StreakRepository(store: store, nowProvider: { now })

        #expect(repoAgain.freezeCount == 0, "Freeze should not be consumed multiple times for same day")
        #expect(repoAgain.currentStreak == 4)
    }

    /// Exactly 2-day gap: lastStudyDate is 2 days ago, which is < yesterday,
    /// so a freeze should be consumed (boundary condition).
    @Test func streak_exactlyTwoDayGap_consumesFreeze() {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: now)!

        let seed = StreakData(
            currentStreak: 3,
            longestStreak: 3,
            lastStudyDate: twoDaysAgo,
            todayCompleted: false,
            todayAnswerCount: 0,
            todayStudySeconds: 0,
            freezeCount: 1,
            freezeGrantMonthKey: StreakRepositoryTests.monthKey(for: now)
        )

        let store = InMemoryPersistenceStore()
        store.set(try! JSONEncoder().encode(seed), forKey: "streak_v2")

        let repo = StreakRepository(store: store, nowProvider: { now })
        #expect(repo.currentStreak == 3, "2-day gap with freeze should preserve streak")
        #expect(repo.freezeCount == 0, "Freeze must be consumed on 2-day gap")
    }

    /// Exactly 1-day gap: lastStudyDate is yesterday, which is NOT < yesterday.
    /// No freeze should be consumed; streak stays intact and awaits today.
    @Test func streak_exactlyOneDayGap_noFreezeConsumed() {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let yesterday = cal.date(byAdding: .day, value: -1, to: now)!

        let seed = StreakData(
            currentStreak: 7,
            longestStreak: 7,
            lastStudyDate: yesterday,
            todayCompleted: false,
            todayAnswerCount: 0,
            todayStudySeconds: 0,
            freezeCount: 1,
            freezeGrantMonthKey: StreakRepositoryTests.monthKey(for: now)
        )

        let store = InMemoryPersistenceStore()
        store.set(try! JSONEncoder().encode(seed), forKey: "streak_v2")

        let repo = StreakRepository(store: store, nowProvider: { now })
        #expect(repo.currentStreak == 7, "1-day gap must not break streak (played yesterday)")
        #expect(repo.freezeCount == 1, "Freeze must NOT be consumed for a 1-day gap")
    }

    /// When a freeze is consumed, freezeConsumedNoticeID should increment
    /// so the UI can present a toast (without relying on SwiftUI onChange alone).
    @Test func streak_freezeConsumedNoticeIDIncrements() {
        let cal = Calendar.current
        let now = cal.startOfDay(for: Date())
        let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: now)!

        let seed = StreakData(
            currentStreak: 2,
            longestStreak: 2,
            lastStudyDate: threeDaysAgo,
            todayCompleted: false,
            todayAnswerCount: 0,
            todayStudySeconds: 0,
            freezeCount: 1,
            freezeGrantMonthKey: StreakRepositoryTests.monthKey(for: now)
        )

        let store = InMemoryPersistenceStore()
        store.set(try! JSONEncoder().encode(seed), forKey: "streak_v2")

        let repo = StreakRepository(store: store, nowProvider: { now })
        #expect(repo.freezeConsumedNoticeID > 0,
            "freezeConsumedNoticeID should increment when freeze is consumed at init")
    }

    private static func monthKey(for date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)"
    }
}

// MARK: - GamificationRepository Tests

struct GamificationRepositoryTests {

    @Test func xp_startsAtZero() {
        let repo = GamificationRepository(store: InMemoryPersistenceStore())
        #expect(repo.totalXP == 0)
        #expect(repo.todayXP == 0)
        #expect(repo.level == 1)
    }

    @Test func xp_correctAnswerAdds5() {
        let repo = GamificationRepository(store: InMemoryPersistenceStore())
        let gained = repo.addXP(.correctAnswer)
        #expect(gained == 5)
        #expect(repo.totalXP == 5)
        #expect(repo.todayXP == 5)
    }

    @Test func xp_sessionCompleteAdds20() {
        let repo = GamificationRepository(store: InMemoryPersistenceStore())
        repo.addXP(.sessionComplete)
        #expect(repo.totalXP == 20)
    }

    @Test func xp_requiredXP_isMonotonicIncreasing() {
        let repo = GamificationRepository(store: InMemoryPersistenceStore())
        var previous = 0
        for level in 1...12 {
            let required = repo.requiredXP(for: level)
            #expect(required >= previous, "requiredXP should be monotonic")
            previous = required
        }
    }

    /// Default quasi-exponential curve must be strictly increasing (not just monotone).
    @Test func xp_defaultCurve_isStrictlyIncreasing() {
        let repo = GamificationRepository(store: InMemoryPersistenceStore())
        for level in 1...15 {
            let current = repo.requiredXP(for: level)
            let next = repo.requiredXP(for: level + 1)
            #expect(next > current,
                "Default curve must strictly increase: requiredXP(\(level+1)) > requiredXP(\(level))")
        }
    }

    /// Verify that XPEvent.label reflects the active Config values,
    /// so custom point values render correctly in the UI.
    @Test func xp_labelReflectsConfig() {
        let original = XPEvent.config
        defer { XPEvent.config = original }

        XPEvent.config = XPEvent.Config(
            correctAnswerPoints: 10,
            sessionCompletePoints: 50,
            wrongNoteRetrievedPoints: 6,
            comboBonusPoints: 4
        )

        #expect(XPEvent.correctAnswer.label == "+10 XP")
        #expect(XPEvent.sessionComplete.label == "+50 XP")
        #expect(XPEvent.wrongNoteRetrieved.label == "+6 XP 回収！")
        #expect(XPEvent.comboBonus.label == "+4 XP コンボ！")
    }

    @Test func xp_levelState_matchesExpectedBoundaries() {
        let curve = GamificationRepository.LevelCurve { level in
            switch level {
            case 1: return 100
            case 2: return 200
            default: return 300
            }
        }
        let repo = GamificationRepository(store: InMemoryPersistenceStore(), levelCurve: curve)

        let atBoundary = repo.levelState(for: 100)
        #expect(atBoundary.level == 2)
        #expect(atBoundary.xpInLevel == 0)

        let beforeBoundary = repo.levelState(for: 99)
        #expect(beforeBoundary.level == 1)
        #expect(beforeBoundary.xpInLevel == 99)

        let afterBoundary = repo.levelState(for: 101)
        #expect(afterBoundary.level == 2)
        #expect(afterBoundary.xpInLevel == 1)
        #expect(abs(afterBoundary.progress - 0.005) < 0.0001)
    }

    @Test func xp_levelIsAtLeast1() {
        let repo = GamificationRepository(store: InMemoryPersistenceStore())
        #expect(repo.level >= 1)
    }

    @Test func xp_progressUsesConfigurableCurve() {
        let curve = GamificationRepository.LevelCurve { _ in 50 }
        let repo = GamificationRepository(store: InMemoryPersistenceStore(), levelCurve: curve)
        for _ in 0..<12 { repo.addXP(.correctAnswer) } // 60 XP
        #expect(repo.level == 2)
        #expect(repo.xpInCurrentLevel == 10)
        #expect(repo.xpToNextLevel == 50)
        #expect(abs(repo.levelProgress - 0.2) < 0.0001)
    }

    @Test func xp_accumulatesAcrossEvents() {
        let repo = GamificationRepository(store: InMemoryPersistenceStore())
        repo.addXP(.correctAnswer)       // +5
        repo.addXP(.wrongNoteRetrieved)  // +3
        repo.addXP(.comboBonus)          // +2
        #expect(repo.totalXP == 10)
    }

    @Test func xp_todayXPAccumulates() {
        let repo = GamificationRepository(store: InMemoryPersistenceStore())
        repo.addXP(.correctAnswer)   // +5
        repo.addXP(.sessionComplete) // +20
        #expect(repo.todayXP == 25)
    }
}

// MARK: - TodaySessionBuilder Tests

struct TodaySessionBuilderTests {

    private func makeStage(_ n: Int, kanjiPrefix: String, count: Int) -> Stage {
        let questions = (0..<count).map { i in
            Question(kanji: "\(kanjiPrefix)\(i)", choices: ["A", "B"], answer: "A", explain: "")
        }
        return Stage(stage: n, questions: questions)
    }

    @Test func todaySession_returnsAtMost10Questions() {
        let stages = [makeStage(1, kanjiPrefix: "漢", count: 30)]
        let repo = StudyStatsRepository(store: InMemoryPersistenceStore())
        let pool = TodaySessionBuilder.buildPool(
            allStages: stages, statsRepo: repo, clearedStages: []
        )
        #expect(pool.count <= 10)
    }

    @Test func todaySession_noDuplicateKanji() {
        let stages = [makeStage(1, kanjiPrefix: "字", count: 20),
                      makeStage(2, kanjiPrefix: "語", count: 20)]
        let repo = StudyStatsRepository(store: InMemoryPersistenceStore())
        let pool = TodaySessionBuilder.buildPool(
            allStages: stages, statsRepo: repo, clearedStages: []
        )
        let kanjis = pool.map { $0.kanji }
        #expect(Set(kanjis).count == kanjis.count, "No duplicate kanji in today's pool")
    }

    @Test func todaySession_prefersUnclearedStages() {
        let stage1 = makeStage(1, kanjiPrefix: "A", count: 10)  // cleared
        let stage2 = makeStage(2, kanjiPrefix: "B", count: 10)  // not cleared
        let repo = StudyStatsRepository(store: InMemoryPersistenceStore())
        let pool = TodaySessionBuilder.buildPool(
            allStages: [stage1, stage2],
            statsRepo: repo,
            clearedStages: [1]
        )
        // All fill questions should come from stage2 (prefix "B")
        let fromStage2 = pool.filter { $0.kanji.hasPrefix("B") }
        let fromStage1 = pool.filter { $0.kanji.hasPrefix("A") }
        #expect(fromStage2.count >= fromStage1.count,
            "Should prefer uncleared stage2 questions over cleared stage1")
    }

    @Test func todaySession_includesWeakQuestionsFirst() {
        let stage = makeStage(1, kanjiPrefix: "W", count: 20)
        let repo = StudyStatsRepository(store: InMemoryPersistenceStore())
        // Mark first 3 kanji as weak
        repo.record(stageNumber: 1, kanji: "W0", wasCorrect: false, correctAnswer: "A")
        repo.record(stageNumber: 1, kanji: "W1", wasCorrect: false, correctAnswer: "A")
        repo.record(stageNumber: 1, kanji: "W2", wasCorrect: false, correctAnswer: "A")

        let pool = TodaySessionBuilder.buildPool(
            allStages: [stage], statsRepo: repo, clearedStages: []
        )
        let weakInPool = pool.filter { ["W0", "W1", "W2"].contains($0.kanji) }
        #expect(weakInPool.count == 3, "All 3 weak questions should appear in pool (≤5 weak slots)")
    }

    @Test func todaySession_syntheticStageHasStage0() {
        let stage = makeStage(1, kanjiPrefix: "Z", count: 10)
        let repo = StudyStatsRepository(store: InMemoryPersistenceStore())
        let synthetic = TodaySessionBuilder.buildTodayStage(
            allStages: [stage], statsRepo: repo, clearedStages: []
        )
        #expect(synthetic.stage == 0, "Synthetic today-stage should have stageNumber 0")
        #expect(!synthetic.questions.isEmpty)
    }

    @Test func todaySession_emptyStagesReturnsFallback() {
        let repo = StudyStatsRepository(store: InMemoryPersistenceStore())
        let synthetic = TodaySessionBuilder.buildTodayStage(
            allStages: [], statsRepo: repo, clearedStages: []
        )
        #expect(synthetic.questions.isEmpty, "Empty input should produce empty stage safely")
    }
}

// MARK: - XCTest-based real data tests

final class RealDataTests: XCTestCase {

    func testAllStageJSONFiles_haveNoValidationIssues() {
        // This test validates the actual production JSON files bundled with the app
        // It will only run when tests have bundle access to the JSON files
        guard !quizData.stages.isEmpty else {
            XCTSkip("No stages loaded — skipping real data test")
        }
        let issues = validateQuizData(quizData)
        XCTAssertTrue(issues.isEmpty, "Production data has validation issues:\n\(issues.joined(separator: "\n"))")
    }

    func testAllStages_haveAtLeastOneQuestion() {
        guard !quizData.stages.isEmpty else {
            XCTSkip("No stages loaded")
        }
        for stage in quizData.stages {
            XCTAssertFalse(stage.questions.isEmpty, "Stage \(stage.stage) has no questions")
        }
    }

    func testNoDuplicateKanji_withinAnyStage() {
        guard !quizData.stages.isEmpty else {
            XCTSkip("No stages loaded")
        }
        for stage in quizData.stages {
            var seen = Set<String>()
            for q in stage.questions {
                let inserted = seen.insert(q.kanji).inserted
                XCTAssertTrue(inserted, "Duplicate kanji '\(q.kanji)' in stage \(stage.stage)")
            }
        }
    }

    func testAllQuestions_answerInChoices() {
        guard !quizData.stages.isEmpty else {
            XCTSkip("No stages loaded")
        }
        for stage in quizData.stages {
            for q in stage.questions {
                XCTAssertTrue(q.choices.contains(q.answer),
                    "Stage \(stage.stage)/\(q.kanji): answer '\(q.answer)' not in choices \(q.choices)")
            }
        }
    }

    func testDataLoadError_isNilForProductionBundle() {
        // dataLoadError should be nil when JSON files are properly bundled
        XCTAssertNil(dataLoadError, "Production data should load without errors. Error: \(dataLoadError?.localizedDescription ?? "none")")
    }
}

// MARK: - QuestionModel Tests (decoding + validation)

struct QuestionModelTests {

    // ── Helpers ─────────────────────────────────────────────────────────

    private func decode(_ json: String) throws -> Question {
        let data = json.data(using: .utf8)!
        return try JSONDecoder().decode(Question.self, from: data)
    }

    private func stage(_ questions: Question...) -> Stage {
        Stage(stage: 99, questions: questions)
    }

    private func quizData(_ stages: Stage...) -> QuizData {
        QuizData(stages: stages, unused_questions: nil)
    }

    // ── Decoding: legacy format ──────────────────────────────────────────

    /// Legacy JSON without "kind" → defaults to .reading
    @Test func decode_legacyJSON_noKindField() throws {
        let json = """
        {"kanji":"燎","choices":["A","B","C","D"],"answer":"A","explain":"説明"}
        """
        let q = try decode(json)
        #expect(q.kind == .reading, "Missing kind should default to .reading")
        #expect(q.kanji == "燎")
        #expect(q.explain == "説明")
        #expect(q.payload == nil)
    }

    /// Legacy JSON using "explain" key (not "explanation")
    @Test func decode_legacyJSON_explainKey() throws {
        let json = """
        {"kanji":"逞","choices":["A","B"],"answer":"B","explain":"旧キー説明"}
        """
        let q = try decode(json)
        #expect(q.explain == "旧キー説明")
    }

    /// New JSON with "explanation" key (preferred new key)
    @Test func decode_newJSON_explanationKey() throws {
        let json = """
        {"kanji":"燎","choices":["A","B"],"answer":"A","explanation":"新キー説明"}
        """
        let q = try decode(json)
        #expect(q.explain == "新キー説明", "explanation key should be accepted")
    }

    /// Full new JSON with kind, payload, tags, difficulty
    @Test func decode_newJSON_withKindAndPayload() throws {
        let json = """
        {
          "kanji": "燎",
          "choices": ["A","B","C","D"],
          "answer": "A",
          "explain": "e",
          "kind": "reading",
          "tags": ["常用外"],
          "difficulty": 3,
          "payload": {
            "type": "reading",
            "targetKanji": "燎",
            "readingType": "on"
          }
        }
        """
        let q = try decode(json)
        #expect(q.kind == .reading)
        #expect(q.tags == ["常用外"])
        #expect(q.difficulty == 3)
        #expect(q.payload?.targetKanji == "燎")
        #expect(q.payload?.readingType == "on")
    }

    /// Unknown kind string → .unknown (must not crash)
    @Test func decode_unknownKind() throws {
        let json = """
        {"kanji":"燎","choices":["A","B"],"answer":"A","explain":"e","kind":"future_kind_xyz"}
        """
        let q = try decode(json)
        #expect(q.kind == .unknown, "Unrecognised kind should map to .unknown")
    }

    // ── validateQuizDataStrict: fatal errors ─────────────────────────────

    /// Empty kanji (prompt) → fatal error
    @Test func validate_missingPrompt() throws {
        let q = Question(kanji: "", choices: ["A", "B"], answer: "A", explain: "e")
        #expect(throws: DataLoadError.self) {
            try validateQuizDataStrict(quizData(stage(q)))
        }
    }

    /// Answer not in choices → fatal error
    @Test func validate_answerNotInChoices() throws {
        let q = Question(kanji: "燎", choices: ["A", "B"], answer: "Z", explain: "e")
        #expect(throws: DataLoadError.self) {
            try validateQuizDataStrict(quizData(stage(q)))
        }
    }

    /// Duplicate kanji within same stage → fatal error
    @Test func validate_duplicateIDsWithinStage() throws {
        let q1 = Question(kanji: "燎", choices: ["A", "B"], answer: "A", explain: "e")
        let q2 = Question(kanji: "燎", choices: ["C", "D"], answer: "C", explain: "e")
        let s = Stage(stage: 99, questions: [q1, q2])
        #expect(throws: DataLoadError.self) {
            try validateQuizDataStrict(QuizData(stages: [s], unused_questions: nil))
        }
    }

    /// Duplicate kanji across different stages (different JSON files) is allowed
    @Test func validate_duplicateKanjiAcrossStages_isAllowed() throws {
        let s1 = Stage(stage: 1, questions: [
            Question(kanji: "綻", choices: ["A", "B"], answer: "A", explain: "e1")
        ])
        let s2 = Stage(stage: 2, questions: [
            Question(kanji: "綻", choices: ["C", "D"], answer: "C", explain: "e2")
        ])
        let data = QuizData(stages: [s1, s2], unused_questions: nil)

        // Must not throw: duplicate scope is per-stage (per JSON), not global.
        try validateQuizDataStrict(data)
        let warnings = validateQuizData(data)
        #expect(!warnings.contains { $0.contains("重複漢字") })
    }

    /// cloze where sentence does not contain blankToken → fatal error
    @Test func validate_cloze_blankNotInSentence() throws {
        let payload = QuestionPayload(
            type: "cloze",
            sentence: "この文章に穴はありません",
            blankToken: "存在しないトークン"
        )
        let q = Question(kanji: "燎", choices: ["A", "B"], answer: "A",
                         explain: "e", kind: .cloze, payload: payload)
        #expect(throws: DataLoadError.self) {
            try validateQuizDataStrict(quizData(stage(q)))
        }
    }

    /// errorcorrection where wrongKanji == correctKanji → fatal error
    @Test func validate_errorcorrection_sameKanji() throws {
        let payload = QuestionPayload(
            type: "errorcorrection",
            originalSentence: "誤字を含む文章",
            wrongKanji: "燎",
            correctKanji: "燎"
        )
        let q = Question(kanji: "燎", choices: ["A", "B"], answer: "A",
                         explain: "e", kind: .errorcorrection, payload: payload)
        #expect(throws: DataLoadError.self) {
            try validateQuizDataStrict(quizData(stage(q)))
        }
    }

    // ── validateQuizData: warnings (non-throwing) ─────────────────────────

    /// 2 choices is below the 4-choice recommendation but above the 2-choice
    /// hard minimum → must NOT throw, but should appear in warnings.
    @Test func validate_choicesLessThanFour_isWarningNotError() throws {
        let q = Question(kanji: "燎", choices: ["A", "B"], answer: "A", explain: "e")
        // Must not throw
        try validateQuizDataStrict(quizData(stage(q)))
        // Must appear as a warning in the soft-validation list
        let warnings = validateQuizData(quizData(stage(q)))
        #expect(warnings.contains { $0.contains("推奨は4個") },
            "2-choice question should produce a '推奨は4個' warning")
    }

    /// Unknown kind produces a warning but does not throw
    @Test func validate_unknownKind_isWarning() throws {
        let q = Question(kanji: "燎", choices: ["A", "B", "C", "D"], answer: "A",
                         explain: "e", kind: .unknown)
        try validateQuizDataStrict(quizData(stage(q)))  // must not throw
        let warnings = validateQuizData(quizData(stage(q)))
        #expect(warnings.contains { $0.contains("不明な値") },
            "unknown kind should produce a warning")
    }
}
