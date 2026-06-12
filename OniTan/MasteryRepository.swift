import Foundation
import OSLog

private let masteryLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan",
                                   category: "MasteryRepository")

// MARK: - MasteryLevel

enum MasteryLevel: String, Codable, CaseIterable {
    case unseen    // no attempts
    case weak      // wrong ≥ 1 and consecutiveCorrect < 2
    case learning  // some correct but not yet stable
    case stable    // 2 consecutive correct
    case mastered  // 3+ consecutive correct and accuracy ≥ 90%

    var displayName: String {
        switch self {
        case .unseen:   return "未挑戦"
        case .weak:     return "苦手"
        case .learning: return "学習中"
        case .stable:   return "定着"
        case .mastered: return "習得済"
        }
    }

    var sortPriority: Int {
        switch self {
        case .weak:     return 0
        case .learning: return 1
        case .unseen:   return 2
        case .stable:   return 3
        case .mastered: return 4
        }
    }
}

// MARK: - QuestionMasteryRecord

struct QuestionMasteryRecord: Codable, Identifiable {
    let id: String          // = questionID
    let kanji: String
    let kind: QuestionKind
    let tags: [String]

    var attempts: Int
    var correct: Int
    var wrong: Int
    var consecutiveCorrect: Int
    var lastAnsweredAt: Date?
    var masteryLevel: MasteryLevel

    var accuracy: Double {
        guard attempts > 0 else { return 0 }
        return Double(correct) / Double(attempts)
    }

    mutating func recordAnswer(wasCorrect: Bool) {
        attempts += 1
        lastAnsweredAt = Date()
        if wasCorrect {
            correct += 1
            consecutiveCorrect += 1
        } else {
            wrong += 1
            consecutiveCorrect = 0
        }
        masteryLevel = computedMasteryLevel
    }

    private var computedMasteryLevel: MasteryLevel {
        if attempts == 0 { return .unseen }
        if wrong > 0 && consecutiveCorrect < 2 { return .weak }
        if consecutiveCorrect >= 3 && accuracy >= 0.90 { return .mastered }
        if consecutiveCorrect >= 2 { return .stable }
        return .learning
    }
}

// MARK: - MasteryRepository

@MainActor
final class MasteryRepository: ObservableObject {

    @Published private(set) var records: [String: QuestionMasteryRecord] = [:]

    // MARK: Aggregate stats
    @Published private(set) var weakCount: Int = 0
    @Published private(set) var masteredCount: Int = 0
    @Published private(set) var unseenCount: Int = 0

    private let store: PersistenceStore
    private let key = "masteryRecords_v1"

    init() { self.store = UserDefaults.standard; load() }
    init(store: PersistenceStore) { self.store = store; load() }

    // MARK: - Recording

    func record(
        questionID: String,
        kanji: String,
        kind: QuestionKind,
        tags: [String],
        wasCorrect: Bool
    ) {
        var rec = records[questionID] ?? QuestionMasteryRecord(
            id: questionID,
            kanji: kanji,
            kind: kind,
            tags: tags,
            attempts: 0,
            correct: 0,
            wrong: 0,
            consecutiveCorrect: 0,
            lastAnsweredAt: nil,
            masteryLevel: .unseen
        )
        rec.recordAnswer(wasCorrect: wasCorrect)
        records[questionID] = rec
        updateAggregates()
        save()
        masteryLogger.debug("Recorded \(wasCorrect ? "✓" : "✗") for \(questionID, privacy: .public) → \(rec.masteryLevel.rawValue, privacy: .public)")
    }

    /// Convenience overload for recording an answer directly from a `Question`.
    func record(question: Question, wasCorrect: Bool) {
        record(
            questionID: question.id,
            kanji: question.kanji,
            kind: question.kind,
            tags: question.tags ?? [],
            wasCorrect: wasCorrect
        )
    }

    // MARK: - Queries

    func masteryLevel(for questionID: String) -> MasteryLevel {
        records[questionID]?.masteryLevel ?? .unseen
    }

    func weakQuestionIDs() -> [String] {
        records.values
            .filter { $0.masteryLevel == .weak }
            .sorted { $0.wrong > $1.wrong }
            .map(\.id)
    }

    func prioritizedReviewIDs(from pool: [Question]) -> [String] {
        let poolIDs = Set(pool.map(\.id))
        return pool
            .sorted { a, b in
                let la = masteryLevel(for: a.id)
                let lb = masteryLevel(for: b.id)
                if la.sortPriority != lb.sortPriority {
                    return la.sortPriority < lb.sortPriority
                }
                // Among same level, sort by last answered (oldest first)
                let da = records[a.id]?.lastAnsweredAt ?? .distantPast
                let db = records[b.id]?.lastAnsweredAt ?? .distantPast
                return da < db
            }
            .map(\.id)
            .filter { poolIDs.contains($0) }
    }

    func accuracy(for kind: QuestionKind) -> Double {
        let kindRecords = records.values.filter { $0.kind == kind }
        guard !kindRecords.isEmpty else { return 0 }
        let totalAttempts = kindRecords.reduce(0) { $0 + $1.attempts }
        let totalCorrect  = kindRecords.reduce(0) { $0 + $1.correct }
        guard totalAttempts > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAttempts)
    }

    func coverage(for kind: QuestionKind, in pool: [Question]) -> Double {
        let kindPool = pool.filter { $0.kind == kind }
        guard !kindPool.isEmpty else { return 0 }
        let attempted = kindPool.filter { (records[$0.id]?.attempts ?? 0) > 0 }.count
        return Double(attempted) / Double(kindPool.count)
    }

    // MARK: - Reset

    func reset() {
        records = [:]
        updateAggregates()
        store.remove(forKey: key)
    }

    // MARK: - Private

    private func updateAggregates() {
        weakCount    = records.values.filter { $0.masteryLevel == .weak }.count
        masteredCount = records.values.filter { $0.masteryLevel == .mastered }.count
        unseenCount  = records.values.filter { $0.masteryLevel == .unseen }.count
    }

    private func load() {
        guard let data = store.data(forKey: key),
              let decoded = try? JSONDecoder().decode([String: QuestionMasteryRecord].self, from: data)
        else { return }
        records = decoded
        updateAggregates()
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(records) else { return }
        store.set(data, forKey: key)
    }
}
