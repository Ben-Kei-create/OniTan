import Foundation

enum FavoriteSessionBuilder {

    static func buildFavoriteStage(
        favoriteKanji: Set<String>,
        questions: [Question] = allQuestions
    ) -> Stage {
        var seen = Set<String>()
        let filtered = questions.filter { question in
            favoriteKanji.contains(question.kanji) && seen.insert(question.kanji).inserted
        }
        return Stage(stage: -2, questions: filtered)
    }
}
