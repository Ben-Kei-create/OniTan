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
    /// Monthly consumable that can prevent streak loss once.
    var freezeCount: Int = 1
    /// Month marker for monthly freeze grant.
    var freezeGrantMonthKey: String? = nil
}

// MARK: - StreakRepository

final class StreakRepository: ObservableObject {
    // Published read-only state consumed by views
    @Published private(set) var currentStreak: Int = 0
    @Published private(set) var longestStreak: Int = 0
    @Published private(set) var todayCompleted: Bool = false
    @Published private(set) var todayAnswerCount: Int = 0
    @Published private(set) var todayStudySeconds: Double = 0
    @Published private(set) var freezeCount: Int = 1
    @Published private(set) var freezeConsumedNoticeID: Int = 0

    /// Number of correct answers required to satisfy today's goal.
    static let dailyGoalQuestions = 10
    /// Alternatively, 2 minutes of active study counts.
    static let dailyGoalSeconds: Double = 120

    private let store: PersistenceStore
    private let key = "streak_v2"
    private let legacyKey = "streak_v1"
    private let nowProvider: () -> Date
    private var data = StreakData()
    private var hasPendingFreezeNotice = false

    convenience init() {
        self.init(store: UserDefaults.standard, nowProvider: Date.init)
    }

    init(store: PersistenceStore, nowProvider: @escaping () -> Date = Date.init) {
        self.store = store
        self.nowProvider = nowProvider
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
        let today = cal.startOfDay(for: nowProvider())

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

        data.lastStudyDate = nowProvider()
        data.longestStreak = max(data.longestStreak, data.currentStreak)
        streakLogger.info("Streak updated to \(self.data.currentStreak, privacy: .public)")
    }

    /// Called at init: resets daily counters if it's a new day, breaks streak if gap > 1 day.
    private func repairForToday() {
        grantMonthlyFreezeIfNeeded()
        guard let last = data.lastStudyDate else {
            publish()
            return
        }
        let cal = Calendar.current
        let today = cal.startOfDay(for: nowProvider())
        let lastDay = cal.startOfDay(for: last)
        let yesterday = cal.date(byAdding: .day, value: -1, to: today)!

        if lastDay < yesterday {
            handleStreakGap(today: today)
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

    private func grantMonthlyFreezeIfNeeded() {
        let currentMonthKey = Self.monthKey(for: nowProvider())
        guard data.freezeGrantMonthKey != currentMonthKey else { return }
        data.freezeGrantMonthKey = currentMonthKey
        data.freezeCount = max(data.freezeCount, 1)
    }

    private func handleStreakGap(today: Date) {
        let cal = Calendar.current
        if data.freezeCount > 0 {
            data.freezeCount -= 1
            hasPendingFreezeNotice = true
            data.lastStudyDate = cal.date(byAdding: .day, value: -1, to: today)
            streakLogger.info("Streak freeze consumed. remaining=\(self.data.freezeCount, privacy: .public)")
            return
        }

        data.currentStreak = 0
    }

    private static func monthKey(for date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)"
    }

    private func publish() {
        currentStreak = data.currentStreak
        longestStreak = data.longestStreak
        todayCompleted = data.todayCompleted
        todayAnswerCount = data.todayAnswerCount
        todayStudySeconds = data.todayStudySeconds
        freezeCount = data.freezeCount
        if hasPendingFreezeNotice {
            freezeConsumedNoticeID += 1
            hasPendingFreezeNotice = false
        }
    }

    private func load() {
        if let d = store.data(forKey: key),
           let decoded = try? JSONDecoder().decode(StreakData.self, from: d) {
            data = decoded
            return
        }

        guard let legacyData = store.data(forKey: legacyKey),
              let decodedLegacy = try? JSONDecoder().decode(StreakData.self, from: legacyData) else { return }
        data = decodedLegacy
        save()
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(data) else {
            streakLogger.error("Failed to encode StreakData")
            return
        }
        store.set(encoded, forKey: key)
    }
}
