import XCTest
@testable import OniTan

final class KeyValueStoreTests: XCTestCase {

    func testInMemoryStore_setGetRemove() {
        let store = InMemoryStore()
        let key = "com.onitan.tests.temp"
        let value = Data([0x01, 0x02, 0x03])

        store.set(value, forKey: key)
        XCTAssertEqual(store.data(forKey: key), value)

        store.removeValue(forKey: key)
        XCTAssertNil(store.data(forKey: key))
    }

    func testUserDefaultsStore_setGetRemove() {
        let suiteName = "com.onitan.tests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Failed to create isolated UserDefaults suite")
            return
        }
        let store = UserDefaultsStore(defaults: defaults)
        let key = "com.onitan.tests.temp"
        let value = Data([0xAA, 0xBB, 0xCC])

        store.set(value, forKey: key)
        XCTAssertEqual(store.data(forKey: key), value)

        store.removeValue(forKey: key)
        XCTAssertNil(store.data(forKey: key))

        defaults.removePersistentDomain(forName: suiteName)
    }
}
