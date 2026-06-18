import Foundation

// MARK: - KindScore

struct KindScore: Codable {
    let total: Int
    let correct: Int
    var accuracy: Double { total > 0 ? Double(correct) / Double(total) : 0 }
}

// MARK: - QuestionAttempt

struct QuestionAttempt: Codable, Identifiable {
    var id: String { questionID }
    let questionID: String
    let kanji: String
    let kind: QuestionKind
    let userAnswer: String?
    let correctAnswer: String
    let isCorrect: Bool
}

// MARK: - ExamResult

struct ExamResult: Codable, Identifiable {
    let id: UUID
    let date: Date
    let blueprintID: String
    let totalQuestions: Int
    let correctCount: Int
    var accuracy: Double { totalQuestions > 0 ? Double(correctCount) / Double(totalQuestions) : 0 }

    /// Key is QuestionKind.rawValue (String) for Codable compatibility.
    let byKind: [String: KindScore]
    let wrongQuestionIDs: [String]
    let attempts: [QuestionAttempt]

    init(
        id: UUID,
        date: Date,
        blueprintID: String,
        totalQuestions: Int,
        correctCount: Int,
        byKind: [String: KindScore],
        wrongQuestionIDs: [String],
        attempts: [QuestionAttempt] = []
    ) {
        self.id = id
        self.date = date
        self.blueprintID = blueprintID
        self.totalQuestions = totalQuestions
        self.correctCount = correctCount
        self.byKind = byKind
        self.wrongQuestionIDs = wrongQuestionIDs
        self.attempts = attempts
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        date = try c.decode(Date.self, forKey: .date)
        blueprintID = try c.decode(String.self, forKey: .blueprintID)
        totalQuestions = try c.decode(Int.self, forKey: .totalQuestions)
        correctCount = try c.decode(Int.self, forKey: .correctCount)
        byKind = try c.decode([String: KindScore].self, forKey: .byKind)
        wrongQuestionIDs = try c.decode([String].self, forKey: .wrongQuestionIDs)
        attempts = (try? c.decode([QuestionAttempt].self, forKey: .attempts)) ?? []
    }

    func score(for kind: QuestionKind) -> KindScore? {
        byKind[kind.rawValue]
    }

    var weakestKind: QuestionKind? {
        byKind
            .filter { $0.value.total > 0 }
            .min(by: { $0.value.accuracy < $1.value.accuracy })
            .flatMap { QuestionKind(rawValue: $0.key) }
    }

    var wrongAttempts: [QuestionAttempt] {
        attempts.filter { !$0.isCorrect }
    }

    var passed: Bool { accuracy >= 0.70 }   // default pass threshold; blueprint may differ
}

// MARK: - ExamResultRepository

@MainActor
final class ExamResultRepository: ObservableObject {

    @Published private(set) var results: [ExamResult] = []

    private let store: PersistenceStore
    private let key = "examResults_v1"
    private let maxStored = 50

    init() { self.store = UserDefaults.standard; load() }
    init(store: PersistenceStore) { self.store = store; load() }

    // MARK: - Save

    func save(_ result: ExamResult) {
        results.insert(result, at: 0)
        if results.count > maxStored { results = Array(results.prefix(maxStored)) }
        persist()
    }

    // MARK: - Queries

    func recentResults(limit: Int = 10) -> [ExamResult] {
        Array(results.prefix(limit))
    }

    func averageAccuracy(for kind: QuestionKind) -> Double? {
        let kindResults = results.compactMap { $0.score(for: kind) }.filter { $0.total > 0 }
        guard !kindResults.isEmpty else { return nil }
        return kindResults.reduce(0.0) { $0 + $1.accuracy } / Double(kindResults.count)
    }

    func overallAverageAccuracy() -> Double? {
        let recent = recentResults(limit: 5)
        guard !recent.isEmpty else { return nil }
        return recent.reduce(0.0) { $0 + $1.accuracy } / Double(recent.count)
    }

    func bestAccuracy(forBlueprintID blueprintID: String) -> Double? {
        results
            .filter { $0.blueprintID == blueprintID }
            .map(\.accuracy)
            .max()
    }

    func hasPassed(blueprintID: String, threshold: Double) -> Bool {
        guard let bestAccuracy = bestAccuracy(forBlueprintID: blueprintID) else { return false }
        return bestAccuracy >= threshold
    }

    // MARK: - Reset

    func reset() {
        results = []
        store.remove(forKey: key)
    }

    // MARK: - Private

    private func load() {
        guard let data = store.data(forKey: key),
              let decoded = try? JSONDecoder().decode([ExamResult].self, from: data)
        else { return }
        results = decoded
    }

    private func persist() {
        guard let data = try? JSONEncoder().encode(results) else { return }
        store.set(data, forKey: key)
    }
}
