import Foundation

enum FavoriteSessionBuilder {

    static func buildFavoriteStage(
        favoriteKanji: Set<String>,
        questions: [Question] = allQuestions
    ) -> Stage {
        let favoriteCharacters = Set(favoriteKanji.filter(\.isSingleKanjiCharacter))
        var seen = Set<String>()
        let filtered = questions.filter { question in
            let relatedCharacters = Set(question.catalogKanjiCharacters)
            return question.kind.isExamEligible
                && !relatedCharacters.isDisjoint(with: favoriteCharacters)
                && seen.insert(question.id).inserted
        }
        return Stage(stage: -2, questions: filtered)
    }
}
