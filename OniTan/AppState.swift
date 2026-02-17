import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    // MARK: - Storage
    private let store: KeyValueStore

    // MARK: - Published Properties
    @Published var clearedStages: Set<Int> {
        didSet { save(clearedStages, forKey: Keys.clearedStages) }
    }

    @Published var wrongQuestions: Set<String> {
        didSet { save(wrongQuestions, forKey: Keys.wrongQuestions) }
    }

    @Published var totalAnswered: Int {
        didSet { save(totalAnswered, forKey: Keys.totalAnswered) }
    }

    @Published var totalCorrect: Int {
        didSet { save(totalCorrect, forKey: Keys.totalCorrect) }
    }

    @Published var bestStreak: Int {
        didSet { save(bestStreak, forKey: Keys.bestStreak) }
    }

    @Published var showingResetAlert: Bool = false
    @Published var showResetConfirmation: Bool = false
    @Published var showingCannotResetAlert: Bool = false

    // MARK: - Keys
    private enum Keys {
        static let clearedStages = "clearedStages"
        static let wrongQuestions = "wrongQuestions"
        static let totalAnswered = "totalAnswered"
        static let totalCorrect = "totalCorrect"
        static let bestStreak = "bestStreak"
    }

    // MARK: - Init
    init(store: KeyValueStore = UserDefaultsStore()) {
        self.store = store
        self.clearedStages = Self.load(from: store, forKey: Keys.clearedStages) ?? []
        self.wrongQuestions = Self.load(from: store, forKey: Keys.wrongQuestions) ?? []
        self.totalAnswered = Self.load(from: store, forKey: Keys.totalAnswered) ?? 0
        self.totalCorrect = Self.load(from: store, forKey: Keys.totalCorrect) ?? 0
        self.bestStreak = Self.load(from: store, forKey: Keys.bestStreak) ?? 0
    }

    // MARK: - Persistence Helpers
    private func save<T: Encodable>(_ value: T, forKey key: String) {
        if let encoded = try? JSONEncoder().encode(value) {
            store.set(encoded, forKey: key)
        }
    }

    private static func load<T: Decodable>(from store: KeyValueStore, forKey key: String) -> T? {
        guard let data = store.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Wrong Questions Management
    func recordWrongAnswer(kanji: String) {
        wrongQuestions.insert(kanji)
    }

    func recordCorrectReview(kanji: String) {
        wrongQuestions.remove(kanji)
    }

    var hasWrongQuestions: Bool {
        !wrongQuestions.isEmpty
    }

    func wrongQuestionsList() -> [Question] {
        let allQuestions = quizData.stages.flatMap { $0.questions }
        var seen = Set<String>()
        return allQuestions.filter { q in
            guard wrongQuestions.contains(q.kanji) else { return false }
            guard !seen.contains(q.kanji) else { return false }
            seen.insert(q.kanji)
            return true
        }
    }

    // MARK: - Statistics
    func recordAnswer(correct: Bool, currentStreak: Int) {
        totalAnswered += 1
        if correct {
            totalCorrect += 1
            if currentStreak > bestStreak {
                bestStreak = currentStreak
            }
        }
    }

    var correctRate: Double {
        guard totalAnswered > 0 else { return 0 }
        return Double(totalCorrect) / Double(totalAnswered)
    }

    // MARK: - Stage Unlock Logic
    func isStageUnlocked(_ stageNumber: Int) -> Bool {
        stageNumber == 1 || clearedStages.contains(stageNumber - 1)
    }

    func isStageCleared(_ stageNumber: Int) -> Bool {
        clearedStages.contains(stageNumber)
    }

    // MARK: - Reset
    func resetUserDefaults() {
        store.removeAll()
        self.clearedStages = []
        self.wrongQuestions = []
        self.totalAnswered = 0
        self.totalCorrect = 0
        self.bestStreak = 0
        self.showingResetAlert = false
        self.showResetConfirmation = false
        self.showingCannotResetAlert = false
        objectWillChange.send()
    }
}
