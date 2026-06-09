import Foundation

// MARK: - ExamBlueprint

struct ExamBlueprint: Codable, Identifiable {
    let id: String
    let title: String
    let questionCount: Int
    /// Keys are QuestionKind.rawValue for JSON compatibility.
    let distribution: [String: Int]
    let passingAccuracy: Double

    var kindDistribution: [QuestionKind: Int] {
        Dictionary(uniqueKeysWithValues:
            distribution.compactMap { k, v -> (QuestionKind, Int)? in
                guard let kind = QuestionKind(rawValue: k) else { return nil }
                return (kind, v)
            }
        )
    }
}

// MARK: - ExamSession

struct ExamSession {
    let blueprint: ExamBlueprint
    let questions: [Question]
    let startedAt: Date
}

// MARK: - ExamBuilder

struct ExamBuilder {

    /// Assembles a randomised ExamSession from the given pool according to the blueprint.
    /// writingSkipped questions are always excluded.
    /// Falls back to any available questions if a kind's target count can't be met.
    static func build(blueprint: ExamBlueprint, from pool: [Question]) -> ExamSession {
        var selected: [Question] = []
        let usablePool = pool.filter { $0.kind.isExamEligible }

        let kindDist = blueprint.kindDistribution

        // Pick per kind
        for (kind, count) in kindDist.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            let candidates = usablePool
                .filter { $0.kind == kind }
                .shuffled()
            selected += Array(candidates.prefix(count))
        }

        // If we still need more questions (kinds underrepresented), fill from any pool
        let deficit = blueprint.questionCount - selected.count
        if deficit > 0 {
            let usedIDs = Set(selected.map(\.id))
            let extras = usablePool
                .filter { !usedIDs.contains($0.id) }
                .shuffled()
                .prefix(deficit)
            selected += extras
        }

        return ExamSession(
            blueprint: blueprint,
            questions: selected.shuffled(),
            startedAt: Date()
        )
    }

    /// Scores a completed exam session.
    static func score(
        session: ExamSession,
        answers: [String: String]  // questionID → selectedAnswer
    ) -> ExamResult {
        var byKind: [String: (total: Int, correct: Int)] = [:]
        var wrongIDs: [String] = []

        for question in session.questions {
            let selected = answers[question.id]
            let isCorrect = selected == question.answer
            let key = question.kind.rawValue
            var entry = byKind[key] ?? (0, 0)
            entry.total += 1
            if isCorrect { entry.correct += 1 } else { wrongIDs.append(question.id) }
            byKind[key] = entry
        }

        let kindScores = byKind.mapValues { KindScore(total: $0.total, correct: $0.correct) }
        let totalQ = session.questions.count
        let totalC = kindScores.values.reduce(0) { $0 + $1.correct }

        return ExamResult(
            id: UUID(),
            date: Date(),
            blueprintID: session.blueprint.id,
            totalQuestions: totalQ,
            correctCount: totalC,
            byKind: kindScores,
            wrongQuestionIDs: wrongIDs
        )
    }
}

// MARK: - Global Blueprints

/// Loaded once at app start; empty list if exam_blueprints.json is absent.
let examBlueprints: [ExamBlueprint] = loadOptional("exam_blueprints.json") ?? []
