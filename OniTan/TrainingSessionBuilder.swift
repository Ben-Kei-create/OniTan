import Foundation

// MARK: - TrainingSessionBuilder

/// Assembles a Stage (question pool) for a given TrainingMode.
/// The returned Stage uses stageID = 0 (cross-stage session).
struct TrainingSessionBuilder {

    /// Builds a question pool for the given training mode.
    ///
    /// - Parameters:
    ///   - mode: Training mode determining selection strategy.
    ///   - categoryID: Optional CategoryEntry.id to restrict to a single category.
    ///   - kindFilter: Optional kind filter (overrides category if both provided).
    ///   - allQuestions: Full question pool to sample from.
    ///   - masteryRepo: Used for mastery-based selection.
    ///   - statsRepo: Used for weak-point / recent-wrong selection.
    static func build(
        mode: TrainingMode,
        categoryID: String? = nil,
        kindFilter: QuestionKind? = nil,
        allQuestions: [Question],
        masteryRepo: MasteryRepository,
        statsRepo: StudyStatsRepository
    ) -> Stage {

        // Exclude writing-skipped questions from all training sessions
        var pool = allQuestions.filter { $0.kind.isExamEligible }

        // Apply category / kind filter
        if let kind = kindFilter {
            pool = pool.filter { $0.kind == kind }
        } else if let catID = categoryID,
                  let cat = categoryManifest?.entry(for: catID) {
            pool = pool.filter { cat.questionKinds.contains($0.kind) }
        }

        let questions = selectQuestions(
            mode: mode,
            from: pool,
            masteryRepo: masteryRepo,
            statsRepo: statsRepo
        )

        return Stage(stage: 0, questions: questions)
    }

    // MARK: - Selection Strategy

    private static func selectQuestions(
        mode: TrainingMode,
        from pool: [Question],
        masteryRepo: MasteryRepository,
        statsRepo: StudyStatsRepository
    ) -> [Question] {

        guard !pool.isEmpty else { return [] }
        var result: [Question] = []

        switch mode {

        case .weakFocus:
            let weakIDs = Set(masteryRepo.weakQuestionIDs())
            result = pool.filter { weakIDs.contains($0.id) }
            if result.isEmpty { result = pool }

        case .mistakeReview:
            let recent = statsRepo.recentWrongAnswers(limit: 100).map(\.kanji)
            let recentSet = Set(recent)
            result = pool.filter { recentSet.contains($0.kanji) }
            if result.isEmpty { result = pool.shuffled() }

        case .masteryReview:
            let ids = masteryRepo.prioritizedReviewIDs(from: pool)
            let idToQ = Dictionary(uniqueKeysWithValues: pool.map { ($0.id, $0) })
            result = ids.compactMap { idToQ[$0] }

        case .quick10:
            result = pool.shuffled()

        case .examMini, .examFull:
            // For exam modes, use ExamBuilder with a matching blueprint
            let targetCount = mode.questionLimit ?? 30
            let blueprint = examBlueprints.first ?? ExamBlueprint(
                id: "fallback",
                title: "模試",
                questionCount: targetCount,
                distribution: Dictionary(
                    uniqueKeysWithValues: QuestionKind.coreKinds.map {
                        ($0.rawValue, max(1, targetCount / QuestionKind.coreKinds.count))
                    }
                ),
                passingAccuracy: 0.70
            )
            result = ExamBuilder.build(blueprint: blueprint, from: pool).questions

        case .finalBoss:
            let weakIDs = Set(masteryRepo.weakQuestionIDs())
            let hardWeak = pool
                .filter { weakIDs.contains($0.id) }
                .filter { ($0.difficulty ?? 1) >= 4 }
                .shuffled()
            let hardNew = pool
                .filter { !weakIDs.contains($0.id) }
                .filter { ($0.difficulty ?? 1) >= 4 }
                .shuffled()
            result = (hardWeak + hardNew).shuffled()

        case .normal, .categoryFocus:
            result = pool

        }

        // Deduplicate
        var seen = Set<String>()
        result = result.filter { seen.insert($0.id).inserted }

        // Apply limit
        if let limit = mode.questionLimit {
            result = Array(result.prefix(limit))
        }

        return result
    }
}

// MARK: - QuestionKind Core List (mirrors ReadinessCalculator)

private extension QuestionKind {
    static var coreKinds: [QuestionKind] {
        [.reading, .writing, .yojijukugo, .synonym, .antonym,
         .composition, .okurigana, .errorcorrection, .cloze, .usage]
    }
}
