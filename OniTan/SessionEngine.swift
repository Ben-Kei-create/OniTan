import Foundation

enum SessionEngine {
    static let defaultQuestionLimit = 5

    static func prepareTodaySession(
        weakQuestionsOrdered: [Question],
        quizData: QuizData,
        questionLimit: Int = defaultQuestionLimit
    ) -> PreparedSession {
        let limit = max(0, questionLimit)

        if !weakQuestionsOrdered.isEmpty {
            let reviewQuestions = uniqueByKanji(weakQuestionsOrdered, limit: limit)
            return PreparedSession(action: .review, questions: reviewQuestions)
        }

        let gentlePool = quizData.stages
            .sorted { $0.stage < $1.stage }
            .flatMap(\.questions)
        let gentleQuestions = uniqueByKanji(gentlePool, limit: limit)
        return PreparedSession(action: .gentle, questions: gentleQuestions)
    }

    private static func uniqueByKanji(_ questions: [Question], limit: Int) -> [Question] {
        guard limit > 0 else { return [] }

        var seen = Set<String>()
        var result: [Question] = []
        result.reserveCapacity(min(limit, questions.count))

        for question in questions {
            if seen.contains(question.kanji) {
                continue
            }
            seen.insert(question.kanji)
            result.append(question)

            if result.count == limit {
                break
            }
        }

        return result
    }
}
