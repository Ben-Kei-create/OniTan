import Foundation
import OSLog

private let xpLogger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "OniTan", category: "XP")

// MARK: - XP Event

/// All the ways a user can earn XP. Points are intentionally modest so
/// the system feels rewarding without being exploitable.
enum XPEvent {
    case correctAnswer       // +5  — per correct answer in quiz
    case sessionComplete     // +20 — finishing any mode
    case wrongNoteRetrieved  // +3  — viewing a wrong-answer detail (encourages review)
    case comboBonus          // +2  — every 3-consecutive-correct streak

    var points: Int {
        switch self {
        case .correctAnswer:      return 5
        case .sessionComplete:    return 20
        case .wrongNoteRetrieved: return 3
        case .comboBonus:         return 2
        }
    }

    var label: String {
        switch self {
        case .correctAnswer:      return "+5 XP"
        case .sessionComplete:    return "+20 XP"
        case .wrongNoteRetrieved: return "+3 XP 回収！"
        case .comboBonus:         return "+2 XP コンボ！"
        }
    }
}

// MARK: - Persistence Model

struct GamificationData: Codable {
    var totalXP: Int = 0
    var todayXP: Int = 0
    var lastXPDate: Date? = nil
}

// MARK: - GamificationRepository

final class GamificationRepository: ObservableObject {
    @Published private(set) var totalXP: Int = 0
    @Published private(set) var todayXP: Int = 0
    /// 1-based level derived from totalXP. Increases every 100 XP.
    @Published private(set) var level: Int = 1
    /// XP accumulated within the current level (0 ..< 100).
    @Published private(set) var xpInCurrentLevel: Int = 0
    /// Always 100 (XP needed per level). Exposed for progress-ring math.
    let xpPerLevel: Int = 100

    private let store: PersistenceStore
    private let key = "gamification_v1"
    private var data = GamificationData()

    convenience init() {
        self.init(store: UserDefaults.standard)
    }

    init(store: PersistenceStore) {
        self.store = store
        load()
        resetTodayXPIfNewDay()
        publish()
    }

    // MARK: - Public API

    /// Award XP for an event and return the points added (useful for UI feedback).
    @discardableResult
    func addXP(_ event: XPEvent) -> Int {
        let pts = event.points
        data.totalXP += pts
        data.todayXP += pts
        data.lastXPDate = Date()
        save()
        publish()
        xpLogger.info("XP +\(pts, privacy: .public) (\(String(describing: event), privacy: .public)) → total \(self.data.totalXP, privacy: .public)")
        return pts
    }

    // MARK: - Private

    private static func levelFrom(xp: Int) -> Int {
        max(1, (xp / 100) + 1)
    }

    private func resetTodayXPIfNewDay() {
        guard let last = data.lastXPDate else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let lastDay = Calendar.current.startOfDay(for: last)
        if lastDay < today {
            data.todayXP = 0
        }
    }

    private func publish() {
        totalXP = data.totalXP
        todayXP = data.todayXP
        level = Self.levelFrom(xp: data.totalXP)
        xpInCurrentLevel = data.totalXP % xpPerLevel
    }

    private func load() {
        guard let d = store.data(forKey: key),
              let decoded = try? JSONDecoder().decode(GamificationData.self, from: d) else { return }
        data = decoded
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(data) else {
            xpLogger.error("Failed to encode GamificationData")
            return
        }
        store.set(encoded, forKey: key)
    }
}
