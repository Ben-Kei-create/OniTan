import SwiftUI

// A property wrapper to allow storing Codable types in UserDefaults via AppStorage-like syntax.
@propertyWrapper
struct AppStorageCodable<T: Codable>: DynamicProperty {
    private let key: String
    private let defaultValue: T
    
    @State private var storedValue: T

    init(wrappedValue: T, _ key: String) {
        self.key = key
        self.defaultValue = wrappedValue
        
        // Try to load an existing value from UserDefaults.
        if let data = UserDefaults.standard.data(forKey: key) {
            print("AppStorageCodable: Loading data for key '\(key)' - raw data size: \(data.count) bytes")
            if let decoded = try? JSONDecoder().decode(T.self, from: data) {
                _storedValue = State(initialValue: decoded)
                print("AppStorageCodable: Successfully decoded '\(key)': \(decoded)")
            } else {
                _storedValue = State(initialValue: wrappedValue)
                print("AppStorageCodable: Failed to decode '\(key)', using default: \(wrappedValue)")
            }
        } else {
            // Otherwise, use the default value.
            _storedValue = State(initialValue: wrappedValue)
            print("AppStorageCodable: No data found for key '\(key)', using default: \(wrappedValue)")
        }
    }

    var wrappedValue: T {
        get {
            storedValue
        }
        nonmutating set {
            storedValue = newValue
            // Encode the new value to JSON and save to UserDefaults.
            if let encoded = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(encoded, forKey: key)
                UserDefaults.standard.synchronize() // Force immediate write
                print("AppStorageCodable: Saved '\(key)': \(newValue) (raw data size: \(encoded.count) bytes)")
            } else {
                print("AppStorageCodable: Failed to encode '\(key)': \(newValue)")
            }
        }
    }
    
    var projectedValue: Binding<T> {
        Binding(
            get: { self.wrappedValue },
            set: { self.wrappedValue = $0 }
        )
    }
}