import Foundation

// MARK: - Persistence Store Protocol
// Decouples AppState from UserDefaults for testability.
// In production the default implementation uses UserDefaults.
// In tests, inject InMemoryPersistenceStore for isolation.

protocol PersistenceStore {
    func data(forKey key: String) -> Data?
    func set(_ data: Data, forKey key: String)
    func remove(forKey key: String)
    func removeAll()
}

// MARK: - UserDefaults conformance (production default)
// UserDefaults.data(forKey:) already satisfies the protocol — no override needed.
// Only methods not present in UserDefaults require explicit implementations.

extension UserDefaults: PersistenceStore {
    // data(forKey:) -> Data? is already present in UserDefaults SDK.

    func set(_ data: Data, forKey key: String) {
        // Use KVC setValue to avoid ambiguity with UserDefaults.set(_:forKey:)
        setValue(data, forKey: key)
    }

    func remove(forKey key: String) {
        removeObject(forKey: key)
    }

    func removeAll() {
        if let id = Bundle.main.bundleIdentifier {
            removePersistentDomain(forName: id)
        }
    }
}

// MARK: - In-memory store (for unit tests)

final class InMemoryPersistenceStore: PersistenceStore {
    private var store: [String: Data] = [:]
    func data(forKey key: String) -> Data? { store[key] }
    func set(_ data: Data, forKey key: String) { store[key] = data }
    func remove(forKey key: String) { store.removeValue(forKey: key) }
    func removeAll() { store.removeAll() }
}

// MARK: - AppState

final class AppState: ObservableObject {
    @Published var clearedStages: Set<Int> {
        didSet { saveClearedStages() }
    }

    private let store: PersistenceStore
    private let clearedKey = "clearedStages"

    /// Production initialiser — uses UserDefaults.
    convenience init() {
        self.init(store: UserDefaults.standard)
    }

    /// Dependency-injected initialiser for testing.
    init(store: PersistenceStore) {
        self.store = store
        if let data = store.data(forKey: "clearedStages"),
           let decoded = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            self.clearedStages = decoded
        } else {
            self.clearedStages = []
        }
    }

    // MARK: - Stage Management

    func markStageCleared(_ stage: Int) {
        clearedStages.insert(stage)
    }

    func isCleared(_ stage: Int) -> Bool {
        clearedStages.contains(stage)
    }

    func isUnlocked(_ stage: Int) -> Bool {
        stage == 1 || clearedStages.contains(stage - 1)
    }

    /// Overall progress ratio across all stages (0.0 – 1.0).
    func overallProgress(totalStages: Int) -> Double {
        guard totalStages > 0 else { return 0 }
        return Double(clearedStages.count) / Double(totalStages)
    }

    func reset() {
        store.removeAll()
        clearedStages = []
    }

    // MARK: - Persistence

    private func saveClearedStages() {
        guard let encoded = try? JSONEncoder().encode(clearedStages) else { return }
        store.set(encoded, forKey: clearedKey)
    }
}
