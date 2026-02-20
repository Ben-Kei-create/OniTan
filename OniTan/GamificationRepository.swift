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

    struct Config {
        let correctAnswerPoints: Int
        let sessionCompletePoints: Int
        let wrongNoteRetrievedPoints: Int
        let comboBonusPoints: Int

        static let `default` = Config(
            correctAnswerPoints: 5,
            sessionCompletePoints: 20,
            wrongNoteRetrievedPoints: 3,
            comboBonusPoints: 2
        )
    }

    static var config: Config = .default

    var points: Int {
        switch self {
        case .correctAnswer:      return Self.config.correctAnswerPoints
        case .sessionComplete:    return Self.config.sessionCompletePoints
        case .wrongNoteRetrieved: return Self.config.wrongNoteRetrievedPoints
        case .comboBonus:         return Self.config.comboBonusPoints
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
    /// 1-based level derived from `requiredXP(for:)` formula.
    @Published private(set) var level: Int = 1
    /// XP accumulated within the current level.
    @Published private(set) var xpInCurrentLevel: Int = 0
    /// XP needed to reach next level from current level.
    @Published private(set) var xpToNextLevel: Int = 100
    /// Fraction (0...1) in the current level for UI progress bars.
    @Published private(set) var levelProgress: Double = 0

    struct LevelCurve {
        /// XP required to go from level N to N+1.
        let requiredXP: (_ level: Int) -> Int

        static let `default` = LevelCurve { level in
            max(60, 60 + (level - 1) * 20)
        }
    }

    private let store: PersistenceStore
    private let key = "gamification_v2"
    private let legacyKey = "gamification_v1"
    private let levelCurve: LevelCurve
    private let nowProvider: () -> Date
    private var data = GamificationData()

    convenience init() {
        self.init(store: UserDefaults.standard)
    }

    init(
        store: PersistenceStore,
        levelCurve: LevelCurve = .default,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.levelCurve = levelCurve
        self.nowProvider = nowProvider
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
        data.lastXPDate = nowProvider()
        save()
        publish()
        xpLogger.info("XP +\(pts, privacy: .public) (\(String(describing: event), privacy: .public)) → total \(self.data.totalXP, privacy: .public)")
        return pts
    }

    // MARK: - Private

    func requiredXP(for level: Int) -> Int {
        max(1, levelCurve.requiredXP(max(1, level)))
    }

    func levelState(for totalXP: Int) -> (level: Int, xpInLevel: Int, xpToNext: Int, progress: Double) {
        var remaining = max(0, totalXP)
        var currentLevel = 1

        while true {
            let required = requiredXP(for: currentLevel)
            if remaining < required {
                let progress = Double(remaining) / Double(required)
                return (currentLevel, remaining, required, min(max(progress, 0), 1))
            }
            remaining -= required
            currentLevel += 1
        }
    }

    private func resetTodayXPIfNewDay() {
        guard let last = data.lastXPDate else { return }
        let today = Calendar.current.startOfDay(for: nowProvider())
        let lastDay = Calendar.current.startOfDay(for: last)
        if lastDay < today {
            data.todayXP = 0
        }
    }

    private func publish() {
        totalXP = data.totalXP
        todayXP = data.todayXP
        let state = levelState(for: data.totalXP)
        level = state.level
        xpInCurrentLevel = state.xpInLevel
        xpToNextLevel = state.xpToNext
        levelProgress = state.progress
    }

    private func load() {
        if let d = store.data(forKey: key),
           let decoded = try? JSONDecoder().decode(GamificationData.self, from: d) {
            data = decoded
            return
        }

        guard let legacy = store.data(forKey: legacyKey),
              let decodedLegacy = try? JSONDecoder().decode(GamificationData.self, from: legacy) else { return }
        data = decodedLegacy
        save()
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(data) else {
            xpLogger.error("Failed to encode GamificationData")
            return
        }
        store.set(encoded, forKey: key)
    }
}
