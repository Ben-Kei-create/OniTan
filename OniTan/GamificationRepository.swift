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

    /// Per-event point table. Injected into GamificationRepository at init.
    /// No mutable global state — each repository instance owns its own config.
    struct Config: Equatable {
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

        /// Resolve points for a given event type.
        func points(for event: XPEvent) -> Int {
            switch event {
            case .correctAnswer:      return correctAnswerPoints
            case .sessionComplete:    return sessionCompletePoints
            case .wrongNoteRetrieved: return wrongNoteRetrievedPoints
            case .comboBonus:         return comboBonusPoints
            }
        }

        /// Localized label for UI display (e.g., "+5 XP", "+2 XP コンボ！").
        func label(for event: XPEvent) -> String {
            let pts = points(for: event)
            switch event {
            case .correctAnswer:      return "+\(pts) XP"
            case .sessionComplete:    return "+\(pts) XP"
            case .wrongNoteRetrieved: return "+\(pts) XP 回収！"
            case .comboBonus:         return "+\(pts) XP コンボ！"
            }
        }
    }
}

// MARK: - XP Curve Config (Deterministic)

/// Consolidates all XP calculation parameters into a single, testable config.
/// The deterministic formula:
///   xp = Int(Double(baseXP) * streakMultiplier * difficultyMultiplier) + passageBonus
///
/// Usage:
///   let config = XPCurveConfig(baseXP: 5, streakMultiplier: 1.5, difficultyMultiplier: 1.0, passageBonus: 0)
///   let xp = config.computeXP()  // → 7
struct XPCurveConfig {
    let baseXP: Int
    let streakMultiplier: Double
    let difficultyMultiplier: Double
    let passageBonus: Int

    static let `default` = XPCurveConfig(
        baseXP: 5,
        streakMultiplier: 1.0,
        difficultyMultiplier: 1.0,
        passageBonus: 0
    )

    static let passageDefault = XPCurveConfig(
        baseXP: 5,
        streakMultiplier: 1.0,
        difficultyMultiplier: 1.0,
        passageBonus: 3
    )

    /// Deterministic XP calculation. No hidden state, no side effects.
    func computeXP() -> Int {
        Int(Double(baseXP) * streakMultiplier * difficultyMultiplier) + passageBonus
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

        /// Quasi-exponential growth (×1.35/level): motivating early progression
        /// that slows to reflect genuine long-term effort.
        /// Sample thresholds with default XP rates (+5 correct, +20 session):
        ///   Lv1→2:  100 XP  ≈ 1-2 sessions
        ///   Lv3→4:  182 XP  ≈ 3 sessions
        ///   Lv5→6:  332 XP  ≈ 5 sessions
        ///   Lv10→11: 1604 XP ≈ 23 sessions
        static let `default` = LevelCurve { level in
            Int(100.0 * pow(1.35, Double(level - 1)))
        }

        /// Linear ramp, useful for testing and gentle levelling.
        static let linear = LevelCurve { level in
            max(60, 60 + (level - 1) * 20)
        }
    }

    /// The per-event point table owned by this repository instance.
    /// Tests can inject custom configs; production uses `.default`.
    let eventConfig: XPEvent.Config

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
        eventConfig: XPEvent.Config = .default,
        levelCurve: LevelCurve = .default,
        nowProvider: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.eventConfig = eventConfig
        self.levelCurve = levelCurve
        self.nowProvider = nowProvider
        load()
        resetTodayXPIfNewDay()
        publish()
    }

    // MARK: - Public API

    /// Resolve the point value for an event using this repository's config.
    func points(for event: XPEvent) -> Int {
        eventConfig.points(for: event)
    }

    /// Localized label for an event (e.g., "+5 XP").
    func label(for event: XPEvent) -> String {
        eventConfig.label(for: event)
    }

    /// Award XP for an event and return the points added (useful for UI feedback).
    @discardableResult
    func addXP(_ event: XPEvent) -> Int {
        let pts = eventConfig.points(for: event)
        data.totalXP += pts
        data.todayXP += pts
        data.lastXPDate = nowProvider()
        save()
        publish()
        xpLogger.info("XP +\(pts, privacy: .public) (\(String(describing: event), privacy: .public)) → total \(self.data.totalXP, privacy: .public)")
        return pts
    }

    /// Reset all XP and level data to initial state.
    func reset() {
        data = GamificationData()
        store.remove(forKey: key)
        store.remove(forKey: legacyKey)
        publish()
        xpLogger.info("Gamification data reset")
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
