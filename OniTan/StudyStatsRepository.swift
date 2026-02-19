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
        self.wrongAnswerLog = []
    }
}

// MARK: - Wrong Answer Entry (for notebook feature)

struct WrongAnswerEntry: Codable, Identifiable {
    let id: UUID
    let kanji: String
    let selectedAnswer: String    // what the user chose (empty string if not captured)
    let correctAnswer: String
    let stageNumber: Int
    let date: Date

    init(kanji: String, selectedAnswer: String = "", correctAnswer: String, stageNumber: Int) {
        self.id = UUID()
        self.kanji = kanji
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

    convenience init() {
        self.init(store: UserDefaults.standard)
    }

    init(store: PersistenceStore) {
        self.store = store
        load()
    }

    // MARK: - Recording

    func record(
        stageNumber: Int,
        kanji: String,
        wasCorrect: Bool,
        selectedAnswer: String = "",
        correctAnswer: String = ""
    ) {
        var stats = stageStats[stageNumber] ?? StageStats(stageNumber: stageNumber)
        stats.totalAttempts += 1

        if wasCorrect {
            stats.correctAttempts += 1
            stats.wrongKanji.removeAll { $0 == kanji }
        } else {
            if !stats.wrongKanji.contains(kanji) {
                stats.wrongKanji.append(kanji)
            }
            // Append to wrong-answer log (cap at 200 per stage to avoid bloat)
            let entry = WrongAnswerEntry(
                kanji: kanji,
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
        return stage.questions.filter { stats.wrongKanji.contains($0.kanji) }
    }

    /// All weak kanji for a given stage (used by QuizSessionViewModel).
    func allWeakKanji(forStage stageNumber: Int) -> [String] {
        stageStats[stageNumber]?.wrongKanji ?? []
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

    /// Whether there are any weak kanji in any stage.
    var hasWeakPoints: Bool {
        stageStats.values.contains { !$0.wrongKanji.isEmpty }
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
}
