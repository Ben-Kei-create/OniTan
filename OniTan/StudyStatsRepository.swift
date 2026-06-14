import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan", category: "StudyStats")

// MARK: - Stage Stats Model

struct StageStats: Codable {
    let stageNumber: Int
    var totalAttempts: Int
    var correctAttempts: Int
    /// Kanji answered incorrectly at least once (not yet mastered).
    var wrongKanji: [String]
    /// Exact question IDs answered incorrectly at least once.
    var wrongQuestionIDs: [String]
    /// Full wrong-answer log with timestamps for the notebook view.
    var wrongAnswerLog: [WrongAnswerEntry]

    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAttempts) / Double(totalAttempts)
    }

    init(stageNumber: Int) {
        self.stageNumber = stageNumber
        self.totalAttempts = 0
        self.correctAttempts = 0
        self.wrongKanji = []
        self.wrongQuestionIDs = []
        self.wrongAnswerLog = []
    }

    private enum CodingKeys: String, CodingKey {
        case stageNumber
        case totalAttempts
        case correctAttempts
        case wrongKanji
        case wrongQuestionIDs
        case wrongAnswerLog
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        stageNumber = try container.decode(Int.self, forKey: .stageNumber)
        totalAttempts = try container.decode(Int.self, forKey: .totalAttempts)
        correctAttempts = try container.decode(Int.self, forKey: .correctAttempts)
        wrongKanji = try container.decodeIfPresent([String].self, forKey: .wrongKanji) ?? []
        wrongQuestionIDs = try container.decodeIfPresent([String].self, forKey: .wrongQuestionIDs) ?? []
        wrongAnswerLog = try container.decodeIfPresent([WrongAnswerEntry].self, forKey: .wrongAnswerLog) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(stageNumber, forKey: .stageNumber)
        try container.encode(totalAttempts, forKey: .totalAttempts)
        try container.encode(correctAttempts, forKey: .correctAttempts)
        try container.encode(wrongKanji, forKey: .wrongKanji)
        try container.encode(wrongQuestionIDs, forKey: .wrongQuestionIDs)
        try container.encode(wrongAnswerLog, forKey: .wrongAnswerLog)
    }
}

// MARK: - Wrong Answer Entry (for notebook feature)

struct WrongAnswerEntry: Codable, Identifiable {
    let id: UUID
    let questionID: String?
    let kanji: String
    let questionKind: QuestionKind?
    let selectedAnswer: String    // what the user chose (empty string if not captured)
    let correctAnswer: String
    let stageNumber: Int
    let date: Date

    init(
        questionID: String? = nil,
        kanji: String,
        questionKind: QuestionKind? = nil,
        selectedAnswer: String = "",
        correctAnswer: String,
        stageNumber: Int
    ) {
        self.id = UUID()
        self.questionID = questionID
        self.kanji = kanji
        self.questionKind = questionKind
        self.selectedAnswer = selectedAnswer
        self.correctAnswer = correctAnswer
        self.stageNumber = stageNumber
        self.date = Date()
    }
}

// MARK: - Repository

final class StudyStatsRepository: ObservableObject {
    @Published private(set) var stageStats: [Int: StageStats] = [:]

    private let store: PersistenceStore
    private let key = "stageStats_v2"   // bumped version for new schema
    private let contentVersionKey = "stageStatsContentVersion"

    /// Days after last wrong answer before a kanji is auto-removed from weak list.
    static let weakKanjiExpiryDays = 14

    convenience init() {
        self.init(store: UserDefaults.standard)
    }

    init(store: PersistenceStore) {
        self.store = store
        load()
        migrateContentVersionIfNeeded()
        cleanupExpiredWeakKanji()
    }

    // MARK: - Recording

    func record(
        stageNumber: Int,
        kanji: String,
        questionID: String? = nil,
        questionKind: QuestionKind? = nil,
        wasCorrect: Bool,
        selectedAnswer: String = "",
        correctAnswer: String = ""
    ) {
        var stats = stageStats[stageNumber] ?? StageStats(stageNumber: stageNumber)
        stats.totalAttempts += 1

        if wasCorrect {
            stats.correctAttempts += 1
            stats.wrongKanji.removeAll { $0 == kanji }
            if let questionID {
                stats.wrongQuestionIDs.removeAll { $0 == questionID }
            }
        } else {
            if !stats.wrongKanji.contains(kanji) {
                stats.wrongKanji.append(kanji)
            }
            if let questionID, !stats.wrongQuestionIDs.contains(questionID) {
                stats.wrongQuestionIDs.append(questionID)
            }
            // Append to wrong-answer log (cap at 200 per stage to avoid bloat)
            let entry = WrongAnswerEntry(
                questionID: questionID,
                kanji: kanji,
                questionKind: questionKind,
                selectedAnswer: selectedAnswer,
                correctAnswer: correctAnswer,
                stageNumber: stageNumber
            )
            stats.wrongAnswerLog.append(entry)
            if stats.wrongAnswerLog.count > 200 {
                stats.wrongAnswerLog.removeFirst(stats.wrongAnswerLog.count - 200)
            }
        }

        stageStats[stageNumber] = stats
        save()
    }

    // MARK: - Queries

    func weakQuestions(for stage: Stage) -> [Question] {
        guard let stats = stageStats[stage.stage] else { return [] }
        let wrongQuestionIDs = Set(stats.wrongQuestionIDs)
        if !wrongQuestionIDs.isEmpty {
            return stage.questions.filter { wrongQuestionIDs.contains($0.id) }
        }
        return stage.questions.filter { stats.wrongKanji.contains($0.kanji) }
    }

    /// All weak kanji for a given stage (used by QuizSessionViewModel).
    func allWeakKanji(forStage stageNumber: Int) -> [String] {
        stageStats[stageNumber]?.wrongKanji ?? []
    }

    /// Exact weak question IDs for a given stage.
    func allWeakQuestionIDs(forStage stageNumber: Int) -> [String] {
        stageStats[stageNumber]?.wrongQuestionIDs ?? []
    }

    /// Recent wrong-answer log entries across all stages, newest first.
    func recentWrongAnswers(limit: Int = 50) -> [WrongAnswerEntry] {
        let all = stageStats.values
            .flatMap { $0.wrongAnswerLog }
            .sorted { $0.date > $1.date }
        return Array(all.prefix(limit))
    }

    /// Wrong-answer log for a specific stage, newest first.
    func wrongAnswerLog(forStage stageNumber: Int, limit: Int = 50) -> [WrongAnswerEntry] {
        let entries = stageStats[stageNumber]?.wrongAnswerLog
            .sorted { $0.date > $1.date } ?? []
        return Array(entries.prefix(limit))
    }

    var weakPointCount: Int {
        let questionIDs = Set(stageStats.values.flatMap(\.wrongQuestionIDs))
        if !questionIDs.isEmpty { return questionIDs.count }
        return Set(stageStats.values.flatMap(\.wrongKanji)).count
    }

    /// Whether there are any currently stocked weak questions.
    var hasWeakPoints: Bool {
        weakPointCount > 0
    }

    /// Removes a solved question from every weak-point stock. Used by synthetic
    /// cross-stage review sessions whose stage number does not match the
    /// original stage that first stored the mistake.
    func removeFromWeakStock(question: Question) {
        var changed = false

        for stageNumber in Array(stageStats.keys) {
            guard var stats = stageStats[stageNumber] else { continue }
            let beforeIDs = stats.wrongQuestionIDs.count
            let beforeKanji = stats.wrongKanji.count

            stats.wrongQuestionIDs.removeAll { $0 == question.id }
            stats.wrongKanji.removeAll { $0 == question.kanji }

            if stats.wrongQuestionIDs.count != beforeIDs || stats.wrongKanji.count != beforeKanji {
                stageStats[stageNumber] = stats
                changed = true
            }
        }

        if changed { save() }
    }

    /// Total correct answers across all stages.
    var totalCorrect: Int {
        stageStats.values.reduce(0) { $0 + $1.correctAttempts }
    }

    /// Overall accuracy across all stages.
    var overallAccuracy: Double {
        let total = stageStats.values.reduce(0) { $0 + $1.totalAttempts }
        let correct = stageStats.values.reduce(0) { $0 + $1.correctAttempts }
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    // MARK: - Weak Kanji Expiry

    /// Removes kanji from wrongKanji if the last wrong answer was more than `expiryDays` ago.
    /// Called on init so stale weak kanji clear on next app launch.
    func cleanupExpiredWeakKanji(expiryDays: Int = weakKanjiExpiryDays) {
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -expiryDays, to: Date()) else { return }
        var changed = false

        for stageNumber in stageStats.keys {
            var stats = stageStats[stageNumber]!
            let before = stats.wrongKanji.count
            let beforeQuestionIDCount = stats.wrongQuestionIDs.count
            stats.wrongKanji.removeAll { kanji in
                let lastWrong = stats.wrongAnswerLog
                    .filter { $0.kanji == kanji }
                    .map { $0.date }
                    .max()
                // No log entry or older than cutoff → expire
                guard let lastDate = lastWrong else { return true }
                return lastDate < cutoff
            }
            stats.wrongQuestionIDs.removeAll { questionID in
                let lastWrong = stats.wrongAnswerLog
                    .filter { $0.questionID == questionID }
                    .map { $0.date }
                    .max()
                guard let lastDate = lastWrong else { return true }
                return lastDate < cutoff
            }
            if stats.wrongKanji.count != before || stats.wrongQuestionIDs.count != beforeQuestionIDCount {
                stageStats[stageNumber] = stats
                changed = true
            }
        }
        if changed { save() }
    }

    // MARK: - Reset

    func reset() {
        stageStats = [:]
        store.remove(forKey: key)
    }

    // MARK: - Persistence

    private func load() {
        guard let data = store.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Int: StageStats].self, from: data) else { return }
        stageStats = decoded
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(stageStats) else {
            logger.error("Failed to encode stageStats")
            return
        }
        store.set(encoded, forKey: key)
    }

    private func migrateContentVersionIfNeeded() {
        let savedVersion = loadContentVersion()
        guard savedVersion == quizContentVersion else {
            stageStats = [:]
            save()
            saveContentVersion()
            return
        }
        saveContentVersion()
    }

    private func loadContentVersion() -> String? {
        guard let data = store.data(forKey: contentVersionKey),
              let decoded = try? JSONDecoder().decode(String.self, from: data) else {
            return nil
        }
        return decoded
    }

    private func saveContentVersion() {
        guard let encoded = try? JSONEncoder().encode(quizContentVersion) else { return }
        store.set(encoded, forKey: contentVersionKey)
    }
}
