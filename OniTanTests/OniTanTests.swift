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

    @Test func xp_levelIncreasesAt100XP() {
        let repo = GamificationRepository(store: InMemoryPersistenceStore())
        for _ in 0..<20 { repo.addXP(.correctAnswer) }  // 100 XP
        #expect(repo.level == 2, "Level should be 2 at 100 XP")
    }

    @Test func xp_levelIsAtLeast1() {
        let repo = GamificationRepository(store: InMemoryPersistenceStore())
        #expect(repo.level >= 1)
    }

    @Test func xp_xpInCurrentLevelIsModulo100() {
        let repo = GamificationRepository(store: InMemoryPersistenceStore())
        for _ in 0..<23 { repo.addXP(.correctAnswer) }  // 115 XP → level 2, 15 in level
        #expect(repo.xpInCurrentLevel == 15)
        #expect(repo.level == 2)
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
