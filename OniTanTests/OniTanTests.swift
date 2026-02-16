import Testing
import Foundation
@testable import OniTan

// MARK: - QuizData Tests

struct QuizDataTests {

    @Test func allStagesLoadSuccessfully() {
        #expect(quizData.stages.count == 3, "Should have 3 stages")
    }

    @Test func eachStageHas30Questions() {
        for stage in quizData.stages {
            #expect(
                stage.questions.count == 30,
                "Stage \(stage.stage) should have 30 questions, got \(stage.questions.count)"
            )
        }
    }

    @Test func stageNumbersAreSequential() {
        let numbers = quizData.stages.map { $0.stage }.sorted()
        #expect(numbers == [1, 2, 3])
    }

    @Test func allQuestionsHaveRequiredFields() {
        for stage in quizData.stages {
            for q in stage.questions {
                #expect(!q.kanji.isEmpty, "Kanji should not be empty")
                #expect(!q.answer.isEmpty, "Answer should not be empty")
                #expect(!q.explain.isEmpty, "Explanation should not be empty")
                #expect(q.choices.count >= 2, "Should have at least 2 choices")
            }
        }
    }

    @Test func allAnswersAreInChoices() {
        for stage in quizData.stages {
            for q in stage.questions {
                #expect(
                    q.choices.contains(q.answer),
                    "Stage \(stage.stage): Answer '\(q.answer)' for '\(q.kanji)' must be in choices \(q.choices)"
                )
            }
        }
    }

    @Test func detectDuplicateKanjiWithinStage() {
        for stage in quizData.stages {
            var seen = Set<String>()
            var duplicates: [String] = []
            for q in stage.questions {
                if seen.contains(q.kanji) {
                    duplicates.append(q.kanji)
                }
                seen.insert(q.kanji)
            }
            // Report duplicates (currently stage1 has "逞" twice)
            // This test documents the current state rather than failing
            if !duplicates.isEmpty {
                Issue.record("Stage \(stage.stage) has duplicate kanji: \(duplicates)")
            }
        }
    }

    @Test func totalQuestionCount() {
        let total = quizData.stages.reduce(0) { $0 + $1.questions.count }
        #expect(total == 90, "Total should be 90 questions across 3 stages")
    }
}

// MARK: - Stage Unlock Logic Tests

struct StageUnlockTests {

    @Test func stage1AlwaysUnlocked() {
        let state = AppState(store: InMemoryStore())
        #expect(state.isStageUnlocked(1) == true)
    }

    @Test func stage2LockedInitially() {
        let state = AppState(store: InMemoryStore())
        #expect(state.isStageUnlocked(2) == false)
    }

    @Test func stage2UnlockedAfterStage1Cleared() {
        let state = AppState(store: InMemoryStore())
        state.clearedStages.insert(1)
        #expect(state.isStageUnlocked(2) == true)
    }

    @Test func stage3LockedWithOnlyStage1Cleared() {
        let state = AppState(store: InMemoryStore())
        state.clearedStages.insert(1)
        #expect(state.isStageUnlocked(3) == false)
    }

    @Test func stage3UnlockedAfterStage2Cleared() {
        let state = AppState(store: InMemoryStore())
        state.clearedStages = [1, 2]
        #expect(state.isStageUnlocked(3) == true)
    }

    @Test func isStageClearedReturnsCorrectly() {
        let state = AppState(store: InMemoryStore())
        #expect(state.isStageCleared(1) == false)

        state.clearedStages.insert(1)
        #expect(state.isStageCleared(1) == true)
        #expect(state.isStageCleared(2) == false)
    }

    @Test func progressiveUnlockSequence() {
        let state = AppState(store: InMemoryStore())

        // Initially only stage 1 is unlocked
        #expect(state.isStageUnlocked(1) == true)
        #expect(state.isStageUnlocked(2) == false)
        #expect(state.isStageUnlocked(3) == false)

        // Clear stage 1 -> stage 2 unlocks
        state.clearedStages.insert(1)
        #expect(state.isStageUnlocked(2) == true)
        #expect(state.isStageUnlocked(3) == false)

        // Clear stage 2 -> stage 3 unlocks
        state.clearedStages.insert(2)
        #expect(state.isStageUnlocked(3) == true)
    }
}

// MARK: - Wrong Questions List Tests

struct WrongQuestionsListTests {

    @Test func wrongQuestionsListReturnsMatchingQuestions() {
        let state = AppState(store: InMemoryStore())
        // Use a kanji that exists in stage1
        state.wrongQuestions = ["燎"]

        let list = state.wrongQuestionsList()
        #expect(list.count == 1)
        #expect(list.first?.kanji == "燎")
    }

    @Test func wrongQuestionsListDeduplicates() {
        let state = AppState(store: InMemoryStore())
        // "逞" appears twice in stage1
        state.wrongQuestions = ["逞"]

        let list = state.wrongQuestionsList()
        #expect(list.count == 1)
    }

    @Test func wrongQuestionsListEmptyWhenNoWrongAnswers() {
        let state = AppState(store: InMemoryStore())
        let list = state.wrongQuestionsList()
        #expect(list.isEmpty)
    }
}
