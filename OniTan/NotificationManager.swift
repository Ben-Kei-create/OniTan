import Foundation
import UserNotifications
import OSLog

private let notifLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan", category: "Notifications")

// MARK: - NotificationManager

@MainActor
final class NotificationManager: ObservableObject {

    static let shared = NotificationManager()

    @Published private(set) var authStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var isReminderScheduled: Bool = false

    private let center = UNUserNotificationCenter.current()
    private let reminderID = "onitan_daily_reminder_v1"
    private let weeklySummaryID = "onitan_weekly_summary_v1"

    // UserDefaults key for reminder hour (0-23), -1 = disabled
    private let reminderHourKey = "onitan_reminder_hour"
    var reminderHour: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: reminderHourKey)
            guard (0...23).contains(v) else { return 20 }   // default 20:00
            return v == 0 ? 20 : v
        }
        set {
            UserDefaults.standard.set(newValue, forKey: reminderHourKey)
        }
    }

    private init() {}

    // MARK: - Public API

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await refresh()
            notifLogger.info("Notification permission \(granted ? "granted" : "denied", privacy: .public)")
            return granted
        } catch {
            notifLogger.error("requestAuthorization error: \(error, privacy: .public)")
            return false
        }
    }

    func refresh() async {
        let settings = await center.notificationSettings()
        authStatus = settings.authorizationStatus
        let pending = await center.pendingNotificationRequests()
        isReminderScheduled = pending.contains { $0.identifier == reminderID }
    }

    /// Schedule (or re-schedule) the daily reminder for `reminderHour`:00.
    func scheduleReminder() {
        guard authStatus == .authorized else { return }
        cancelReminder()

        var comps = DateComponents()
        comps.hour = reminderHour
        comps.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "今日の鬼単、まだ？"
        content.body = "今日の10問をこなしてストリークを守ろう！🔥"
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: reminderID, content: content, trigger: trigger)

        center.add(request) { [weak self] error in
            if let error {
                notifLogger.error("Failed to schedule reminder: \(error, privacy: .public)")
            } else {
                notifLogger.info("Daily reminder scheduled for \(comps.hour ?? -1):00")
                Task { @MainActor [weak self] in self?.isReminderScheduled = true }
            }
        }
    }

    func cancelReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [reminderID])
        isReminderScheduled = false
        notifLogger.info("Daily reminder cancelled")
    }

    /// Call when the user completes today's study — removes today's pending fire.
    /// Since `repeats: true` triggers never skip individual days, we cancel and rely
    /// on the app re-scheduling on next launch when `!todayCompleted`.
    func handleTodayCompleted() {
        guard isReminderScheduled else { return }
        // Re-schedule so the next trigger is tomorrow (cancels any queued "today" delivery)
        scheduleReminder()
    }

    /// Schedule (or re-schedule) a weekly summary notification for Sunday at `reminderHour`:00,
    /// reflecting the current count of weak (often-missed) questions.
    func scheduleWeeklySummary(weakCount: Int) {
        guard authStatus == .authorized else { return }
        center.removePendingNotificationRequests(withIdentifiers: [weeklySummaryID])

        var comps = DateComponents()
        comps.weekday = 1   // Sunday
        comps.hour = reminderHour
        comps.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "今週の振り返り"
        content.body = weakCount > 0
            ? "苦手な漢字が\(weakCount)問たまっています。週末にまとめて復習しよう！"
            : "今週も苦手なし！この調子で続けよう。"
        content.sound = .default
        content.categoryIdentifier = "WEEKLY_SUMMARY"

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(identifier: weeklySummaryID, content: content, trigger: trigger)

        center.add(request) { error in
            if let error {
                notifLogger.error("Failed to schedule weekly summary: \(error, privacy: .public)")
            } else {
                notifLogger.info("Weekly summary scheduled for Sunday \(comps.hour ?? -1):00")
            }
        }
    }

    func cancelWeeklySummary() {
        center.removePendingNotificationRequests(withIdentifiers: [weeklySummaryID])
    }

    /// Call on app foreground if the user hasn't studied yet today.
    func ensureScheduledIfNeeded(todayCompleted: Bool) {
        guard authStatus == .authorized else { return }
        if !isReminderScheduled && !todayCompleted {
            scheduleReminder()
        }
    }
}
