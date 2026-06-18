import Foundation
import OSLog

private let examBuilderLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan", category: "ExamBuilder")

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

    /// Assembles an ExamSession from the given pool according to the blueprint.
    /// .writing questions are always excluded.
    /// Falls back to any available questions if a kind's target count can't be met.
    ///
    /// - Parameter fixedSet: When `true`, selection is deterministic (sorted by question ID
    ///   rather than shuffled) and the resulting question order is stable, so repeat
    ///   attempts present the same fixed question set. Used for numbered exam rounds.
    static func build(blueprint: ExamBlueprint, from pool: [Question], fixedSet: Bool = false) -> ExamSession {
        var selected: [Question] = []
        let usablePool = pool.filter { $0.kind.isExamEligible }

        let kindDist = blueprint.kindDistribution

        // Pick per kind
        for (kind, count) in kindDist.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            var candidates = usablePool.filter { $0.kind == kind }
            candidates = fixedSet ? candidates.sorted(by: { $0.id < $1.id }) : candidates.shuffled()
            if candidates.count < count {
                examBuilderLogger.warning(
                    "Exam blueprint '\(blueprint.id, privacy: .public)' requested \(count, privacy: .public) '\(kind.rawValue, privacy: .public)' questions, but only \(candidates.count, privacy: .public) are available."
                )
            }
            selected += Array(candidates.prefix(count))
        }

        // If we still need more questions (kinds underrepresented), fill from any pool
        let deficit = blueprint.questionCount - selected.count
        if deficit > 0 {
            let usedIDs = Set(selected.map(\.id))
            var extras = usablePool.filter { !usedIDs.contains($0.id) }
            extras = fixedSet ? extras.sorted(by: { $0.id < $1.id }) : extras.shuffled()
            selected += extras.prefix(deficit)
        }

        if selected.count < blueprint.questionCount {
            examBuilderLogger.warning(
                "Exam blueprint '\(blueprint.id, privacy: .public)' requested \(blueprint.questionCount, privacy: .public) questions, but only \(selected.count, privacy: .public) exam-eligible questions could be assembled from \(usablePool.count, privacy: .public) available candidates."
            )
        }

        return ExamSession(
            blueprint: blueprint,
            questions: fixedSet ? selected : selected.shuffled(),
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
        var attempts: [QuestionAttempt] = []

        for question in session.questions {
            let selected = answers[question.id]
            let isCorrect = selected == question.answer
            let key = question.kind.rawValue
            var entry = byKind[key] ?? (0, 0)
            entry.total += 1
            if isCorrect { entry.correct += 1 } else { wrongIDs.append(question.id) }
            byKind[key] = entry

            attempts.append(QuestionAttempt(
                questionID: question.id,
                kanji: question.kanji,
                kind: question.kind,
                userAnswer: selected,
                correctAnswer: question.answer,
                isCorrect: isCorrect
            ))
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
            wrongQuestionIDs: wrongIDs,
            attempts: attempts
        )
    }
}

// MARK: - Global Blueprints

/// Loaded once at app start; empty list if exam_blueprints.json is absent.
let examBlueprints: [ExamBlueprint] = loadOptional("exam_blueprints.json") ?? []
