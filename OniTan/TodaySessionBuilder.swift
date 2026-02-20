import Foundation

// MARK: - Today Session Builder
// Builds a cross-stage 10-question pool for the "今日の10問" daily card.
//
// Curation strategy (priority order):
//   1. Up to 5 weak-point questions from any stage (shuffled)
//   2. Remaining slots filled from uncleared stages (or any stage if all cleared)
//   3. Final pool shuffled before returning
//
// Returns a synthetic Stage(stage: 0) that QuizSessionViewModel can consume
// with mode = .quick10 (no review queue, no stage-clear marking).

enum TodaySessionBuilder {

    static let targetCount = 10
    static let maxWeakSlots = 5

    // MARK: - Pool Builder

    static func buildPool(
        allStages: [Stage],
        statsRepo: StudyStatsRepository,
        clearedStages: Set<Int>
    ) -> [Question] {
        guard !allStages.isEmpty else { return [] }

        // 1. Collect weak questions across all stages
        var weakPool: [Question] = []
        for stage in allStages {
            let weakKanji = Set(statsRepo.allWeakKanji(forStage: stage.stage))
            let stageWeak = stage.questions.filter { weakKanji.contains($0.kanji) }
            weakPool.append(contentsOf: stageWeak)
        }
        // Shuffle and cap at maxWeakSlots
        weakPool = Array(weakPool.shuffled().prefix(maxWeakSlots))

        // 2. Fill remaining slots with "new" questions
        let usedKanji = Set(weakPool.map { $0.kanji })

        // Prefer uncleared stages so learners make progress
        let unclearedStages = allStages.filter { !clearedStages.contains($0.stage) }
        let fillSource = unclearedStages.isEmpty ? allStages : unclearedStages

        var fillPool = fillSource
            .flatMap { $0.questions }
            .filter { !usedKanji.contains($0.kanji) }
            .shuffled()
        fillPool = Array(fillPool.prefix(targetCount - weakPool.count))

        // 3. Combine and shuffle
        let combined = (weakPool + fillPool).shuffled()
        return Array(combined.prefix(targetCount))
    }

    // MARK: - Synthetic Stage

    /// Returns a Stage with stageNumber = 0 (the "today" sentinel) containing
    /// the curated question pool. Use with QuizMode.quick10.
    static func buildTodayStage(
        allStages: [Stage],
        statsRepo: StudyStatsRepository,
        clearedStages: Set<Int>
    ) -> Stage {
        let pool = buildPool(allStages: allStages, statsRepo: statsRepo, clearedStages: clearedStages)

        // Fallback: if pool is somehow empty use first stage questions
        let safePool = pool.isEmpty
            ? Array((allStages.first?.questions ?? []).prefix(targetCount))
            : pool

        return Stage(stage: 0, questions: safePool)
    }
}
