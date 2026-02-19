import XCTest
import Foundation
@testable import OniTan

final class AppStateTests: XCTestCase {

    // Uses InMemoryPersistenceStore — no UserDefaults side-effects
    var store: InMemoryPersistenceStore!
    var appState: AppState!

    override func setUpWithError() throws {
        store = InMemoryPersistenceStore()
        appState = AppState(store: store)
    }

    override func tearDownWithError() throws {
        appState = nil
        store = nil
    }

    // MARK: - Initialization

    func testInitialization_empty() {
        XCTAssertTrue(appState.clearedStages.isEmpty, "clearedStages should be empty with no saved data")
    }

    func testInitialization_withSavedData() throws {
        let saved: Set<Int> = [1, 3]
        let encoded = try JSONEncoder().encode(saved)
        store.set(encoded, forKey: "clearedStages")
        let newState = AppState(store: store)
        XCTAssertEqual(newState.clearedStages, saved)
    }

    // MARK: - markStageCleared

    func testMarkStageCleared() {
        appState.markStageCleared(1)
        XCTAssertTrue(appState.isCleared(1))
        XCTAssertFalse(appState.isCleared(2))
    }

    func testMarkStageCleared_persists() throws {
        appState.markStageCleared(2)
        let newState = AppState(store: store)
        XCTAssertTrue(newState.isCleared(2), "Cleared stage should be persisted to the store")
    }

    func testMarkStageCleared_idempotent() {
        appState.markStageCleared(1)
        appState.markStageCleared(1)
        XCTAssertEqual(appState.clearedStages.count, 1)
    }

    // MARK: - isUnlocked

    func testIsUnlocked_stage1_alwaysUnlocked() {
        XCTAssertTrue(appState.isUnlocked(1))
    }

    func testIsUnlocked_stage2_lockedByDefault() {
        XCTAssertFalse(appState.isUnlocked(2))
    }

    func testIsUnlocked_stage2_unlockedAfterStage1Cleared() {
        appState.markStageCleared(1)
        XCTAssertTrue(appState.isUnlocked(2))
    }

    func testIsUnlocked_stage3_lockedWhenOnlyStage1Cleared() {
        appState.markStageCleared(1)
        XCTAssertFalse(appState.isUnlocked(3))
    }

    // MARK: - overallProgress

    func testOverallProgress_zeroClearedStages() {
        XCTAssertEqual(appState.overallProgress(totalStages: 3), 0.0, accuracy: 0.001)
    }

    func testOverallProgress_allCleared() {
        appState.markStageCleared(1)
        appState.markStageCleared(2)
        appState.markStageCleared(3)
        XCTAssertEqual(appState.overallProgress(totalStages: 3), 1.0, accuracy: 0.001)
    }

    func testOverallProgress_partialCleared() {
        appState.markStageCleared(1)
        XCTAssertEqual(appState.overallProgress(totalStages: 3), 1.0 / 3.0, accuracy: 0.001)
    }

    func testOverallProgress_zeroTotal() {
        XCTAssertEqual(appState.overallProgress(totalStages: 0), 0.0)
    }

    // MARK: - reset

    func testReset_clearsInMemory() {
        appState.markStageCleared(1)
        appState.markStageCleared(2)
        appState.reset()
        XCTAssertTrue(appState.clearedStages.isEmpty)
    }

    func testReset_clearsStore() {
        appState.markStageCleared(1)
        appState.reset()
        let newState = AppState(store: store)
        XCTAssertTrue(newState.clearedStages.isEmpty, "Store should be cleared after reset")
    }
}
