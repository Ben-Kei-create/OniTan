import Foundation

enum WeakPointSessionBuilder {

    /// Builds a cross-stage session containing every kanji the user has
    /// currently marked as weak (not yet mastered), for the home screen's
    /// "弱点復習" entry point.
    static func buildWeakStage(
        statsRepo: StudyStatsRepository,
        allStages: [Stage],
        questions: [Question] = allQuestions
    ) -> Stage {
        var weakKanji = Set<String>()
        for stage in allStages {
            weakKanji.formUnion(statsRepo.allWeakKanji(forStage: stage.stage))
        }

        var seen = Set<String>()
        let filtered = questions.filter { question in
            question.kind.isExamEligible
                && weakKanji.contains(question.kanji)
                && seen.insert(question.kanji).inserted
        }
        return Stage(stage: -3, questions: filtered)
    }
}
