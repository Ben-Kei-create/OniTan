import Foundation

// MARK: - KeyValueStore Protocol

protocol KeyValueStore {
    func data(forKey key: String) -> Data?
    func set(_ data: Data?, forKey key: String)
    func removeValue(forKey key: String)
}

// MARK: - UserDefaultsStore (Production)

final class UserDefaultsStore: KeyValueStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func data(forKey key: String) -> Data? {
        defaults.data(forKey: key)
    }

    func set(_ data: Data?, forKey key: String) {
        defaults.set(data, forKey: key)
    }

    func removeValue(forKey key: String) {
        defaults.removeObject(forKey: key)
    }
}

// MARK: - InMemoryStore (Testing)

final class InMemoryStore: KeyValueStore {
    private var storage: [String: Data] = [:]

    func data(forKey key: String) -> Data? {
        storage[key]
    }

    func set(_ data: Data?, forKey key: String) {
        if let data = data {
            storage[key] = data
        } else {
            storage.removeValue(forKey: key)
        }
    }

    func removeValue(forKey key: String) {
        storage.removeValue(forKey: key)
    }
}
