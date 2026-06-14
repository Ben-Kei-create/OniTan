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

    /// Call on app foreground if the user hasn't studied yet today.
    func ensureScheduledIfNeeded(todayCompleted: Bool) {
        guard authStatus == .authorized else { return }
        if !isReminderScheduled && !todayCompleted {
            scheduleReminder()
        }
    }
}
