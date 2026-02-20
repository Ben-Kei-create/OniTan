import Foundation
import OSLog

private let streakLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan", category: "Streak")

// MARK: - Streak Data

struct StreakData: Codable {
    var currentStreak: Int = 0
    var longestStreak: Int = 0
    /// Date of the last session where the daily goal was completed.
    var lastStudyDate: Date? = nil
    var todayCompleted: Bool = false
    /// Number of correct answers submitted today.
    var todayAnswerCount: Int = 0
    /// Accumulated study seconds today.
    var todayStudySeconds: Double = 0
}

// MARK: - StreakRepository

final class StreakRepository: ObservableObject {
    // Published read-only state consumed by views
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0
    @Published private(set) var todayCompleted: Bool = false
    @Published private(set) var todayAnswerCount: Int = 0
    @Published private(set) var todayStudySeconds: Double = 0

    /// Number of correct answers required to satisfy today's goal.
    static let dailyGoalQuestions = 10
    /// Alternatively, 2 minutes of active study counts.
    static let dailyGoalSeconds: Double = 120

    private let store: PersistenceStore
    private let key = "streak_v1"
    private var data = StreakData()

    convenience init() {
        self.init(store: UserDefaults.standard)
    }

    init(store: PersistenceStore) {
        self.store = store
        load()
        repairForToday()
    }

    // MARK: - Public API

    /// Call each time the user answers a question correctly.
    func recordCorrectAnswer() {
        data.todayAnswerCount += 1
        checkAndMarkCompleted()
        save()
        publish()
    }

    /// Call to accumulate active study time in seconds.
    func addStudyTime(_ seconds: Double) {
        data.todayStudySeconds += seconds
        checkAndMarkCompleted()
        save()
        publish()
    }

    // MARK: - Private

    private func checkAndMarkCompleted() {
        guard !data.todayCompleted else { return }
        let questionsMet = data.todayAnswerCount >= StreakRepository.dailyGoalQuestions
        let timeMet = data.todayStudySeconds >= StreakRepository.dailyGoalSeconds
        guard questionsMet || timeMet else { return }

        data.todayCompleted = true
        incrementStreak()
    }

    private func incrementStreak() {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        if let last = data.lastStudyDate {
            let lastDay = cal.startOfDay(for: last)
            let yesterday = cal.date(byAdding: .day, value: -1, to: today)!
            if lastDay == yesterday {
                // Played yesterday → extend streak
                data.currentStreak += 1
            } else if lastDay == today {
                // Already counted today; guard (shouldn't reach here)
                return
            } else {
                // Gap: reset
                data.currentStreak = 1
            }
        } else {
            data.currentStreak = 1
        }

        data.lastStudyDate = Date()
        data.longestStreak = max(data.longestStreak, data.currentStreak)
        streakLogger.info("Streak updated to \(self.data.currentStreak, privacy: .public)")
    }

    /// Called at init: resets daily counters if it's a new day, breaks streak if gap > 1 day.
    private func repairForToday() {
        guard let last = data.lastStudyDate else {
            publish()
            return
        }
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let lastDay = cal.startOfDay(for: last)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        if lastDay < yesterday {
            // More than one day gap — streak broken
            data.currentStreak = 0
        }

        if lastDay < today {
            // New day — reset daily counters
            data.todayCompleted = false
            data.todayAnswerCount = 0
            data.todayStudySeconds = 0
        }

        save()
        publish()
    }

    private func publish() {
        currentStreak = data.currentStreak
        longestStreak = data.longestStreak
        todayCompleted = data.todayCompleted
        todayAnswerCount = data.todayAnswerCount
        todayStudySeconds = data.todayStudySeconds
    }

    private func load() {
        guard let d = store.data(forKey: key),
              let decoded = try? JSONDecoder().decode(StreakData.self, from: d) else { return }
        data = decoded
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(data) else {
            streakLogger.error("Failed to encode StreakData")
            return
        }
        store.set(encoded, forKey: key)
    }
}
