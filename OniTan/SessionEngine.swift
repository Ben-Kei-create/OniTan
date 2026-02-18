import Foundation

enum SessionEngine {
    static func makeTodaySession(
        weakKanji: Set<String>,
        reviewOrdered: [Question],
        allQuestions: [Question],
        cap: Int = 5
    ) -> PreparedSession {
        let safeCap = max(0, cap)
        let reviewMatches = reviewOrdered.filter { weakKanji.contains($0.kanji) }

        if !weakKanji.isEmpty && !reviewMatches.isEmpty {
            let selected = uniqueByKanjiPrefix(reviewMatches, cap: safeCap)
            return PreparedSession(action: .review, questions: selected)
        }

        let selected = uniqueByKanjiPrefix(allQuestions, cap: safeCap)
        return PreparedSession(action: .gentle, questions: selected)
    }

    private static func uniqueByKanjiPrefix(_ questions: [Question], cap: Int) -> [Question] {
        guard cap > 0 else { return [] }

        var seen = Set<String>()
        var result: [Question] = []
        result.reserveCapacity(min(cap, questions.count))

        for question in questions {
            guard seen.insert(question.kanji).inserted else { continue }
            result.append(question)
            if result.count == cap { break }
        }

        return result
    }
}
