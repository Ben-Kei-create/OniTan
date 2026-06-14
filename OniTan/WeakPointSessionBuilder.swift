import Foundation

enum WeakPointSessionBuilder {
    static let targetCount = 10

    /// Builds a cross-stage random session containing currently stocked weak
    /// questions for the home screen's "弱点復習" entry point.
    static func buildWeakStage(
        statsRepo: StudyStatsRepository,
        allStages: [Stage],
        questions: [Question] = allQuestions
    ) -> Stage {
        var weakKanji = Set<String>()
        var weakQuestionIDs = Set<String>()
        let trackedStageNumbers = Set(allStages.map(\.stage)).union(statsRepo.stageStats.keys)
        for stageNumber in trackedStageNumbers {
            weakKanji.formUnion(statsRepo.allWeakKanji(forStage: stageNumber))
            weakQuestionIDs.formUnion(statsRepo.allWeakQuestionIDs(forStage: stageNumber))
        }

        var seen = Set<String>()
        let filtered = questions.filter { question in
            guard question.kind.isExamEligible else { return false }
            if !weakQuestionIDs.isEmpty {
                return weakQuestionIDs.contains(question.id)
                    && seen.insert(question.id).inserted
            }
            return weakKanji.contains(question.kanji)
                && seen.insert(question.kanji).inserted
        }
        .shuffled()

        return Stage(stage: -3, questions: Array(filtered.prefix(targetCount)))
    }
}
