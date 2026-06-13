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
    /// Day-keys ("yyyy-MM-dd") on which the daily goal was completed, for calendar visualization.
    var completedDayKeys: Set<String> = []
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
    @Published private(set) var completedDayKeys: Set<String> = []
    /// Whether the most recent `incrementStreak()` set a new personal-best streak.
    @Published private(set) var lastCompletionWasNewRecord: Bool = false

    /// Number of correct answers required to satisfy today's goal.
    static let dailyGoalQuestions = 10
    /// Alternatively, 2 minutes of active study counts.
    static let dailyGoalSeconds: Double = 120

    private let store: PersistenceStore
    private let key = "streak_v2"
    private let legacyKey = "streak_v1"
    private let contentVersionKey = "streakContentVersion"
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
        migrateContentVersionIfNeeded()
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

    /// Reset all streak data to initial state.
    func reset() {
        data = StreakData()
        store.remove(forKey: key)
        store.remove(forKey: legacyKey)
        publish()
        streakLogger.info("Streak data reset")
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
        lastCompletionWasNewRecord = data.currentStreak > data.longestStreak
        data.longestStreak = max(data.longestStreak, data.currentStreak)
        data.completedDayKeys.insert(Self.dayKey(for: today))
        streakLogger.info("Streak updated to \(self.data.currentStreak, privacy: .public)")
    }

    /// Day-key string ("yyyy-MM-dd") for the given date, used for calendar visualization.
    static func dayKey(for date: Date) -> String {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", comps.year ?? 0, comps.month ?? 0, comps.day ?? 0)
    }

    /// Whether the daily goal was completed on the given date.
    func isCompleted(on date: Date) -> Bool {
        completedDayKeys.contains(Self.dayKey(for: date))
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
        completedDayKeys = data.completedDayKeys
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

    private func migrateContentVersionIfNeeded() {
        let savedVersion = loadContentVersion()
        guard savedVersion == quizContentVersion else {
            data = StreakData()
            save()
            saveContentVersion()
            streakLogger.info("Streak data reset for quiz content version migration")
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
