import Foundation
import OSLog

private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan", category: "StudyStats")

struct StageStats: Codable {
    let stageNumber: Int
    var totalAttempts: Int
    var correctAttempts: Int
    var wrongKanji: [String]

    var accuracy: Double {
        guard totalAttempts > 0 else { return 0 }
        return Double(correctAttempts) / Double(totalAttempts)
    }

    init(stageNumber: Int) {
        self.stageNumber = stageNumber
        self.totalAttempts = 0
        self.correctAttempts = 0
        self.wrongKanji = []
    }
}

final class StudyStatsRepository: ObservableObject {
    @Published private(set) var stageStats: [Int: StageStats] = [:]

    private let key = "stageStats_v1"

    init() {
        load()
    }

    func record(stageNumber: Int, kanji: String, wasCorrect: Bool) {
        var stats = stageStats[stageNumber] ?? StageStats(stageNumber: stageNumber)
        stats.totalAttempts += 1
        if wasCorrect {
            stats.correctAttempts += 1
            stats.wrongKanji.removeAll { $0 == kanji }
        } else {
            if !stats.wrongKanji.contains(kanji) {
                stats.wrongKanji.append(kanji)
            }
        }
        stageStats[stageNumber] = stats
        save()
    }

    func weakQuestions(for stage: Stage) -> [Question] {
        guard let stats = stageStats[stage.stage] else { return [] }
        return stage.questions.filter { stats.wrongKanji.contains($0.kanji) }
    }

    func reset() {
        stageStats = [:]
        UserDefaults.standard.removeObject(forKey: key)
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([Int: StageStats].self, from: data) else { return }
        stageStats = decoded
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(stageStats) else {
            logger.error("Failed to encode stageStats")
            return
        }
        UserDefaults.standard.set(encoded, forKey: key)
    }
}
