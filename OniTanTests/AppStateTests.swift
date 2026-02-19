import XCTest
import Foundation
@testable import OniTan

final class AppStateTests: XCTestCase {

    var appState: AppState!

    override func setUpWithError() throws {
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        appState = AppState()
    }

    override func tearDownWithError() throws {
        appState = nil
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
    }

    // MARK: - Initialization

    func testInitialization_emptyUserDefaults() {
        XCTAssertTrue(appState.clearedStages.isEmpty, "clearedStages should be empty with no saved data")
    }

    func testInitialization_withSavedData() {
        let saved: Set<Int> = [1, 3]
        if let encoded = try? JSONEncoder().encode(saved) {
            UserDefaults.standard.set(encoded, forKey: "clearedStages")
        }
        let newState = AppState()
        XCTAssertEqual(newState.clearedStages, saved, "clearedStages should load saved data")
    }

    // MARK: - markStageCleared

    func testMarkStageCleared() {
        appState.markStageCleared(1)
        XCTAssertTrue(appState.isCleared(1), "Stage 1 should be cleared")
        XCTAssertFalse(appState.isCleared(2), "Stage 2 should not be cleared")
    }

    func testMarkStageCleared_persists() {
        appState.markStageCleared(2)
        let newState = AppState()
        XCTAssertTrue(newState.isCleared(2), "Cleared stage should be persisted")
    }

    // MARK: - isUnlocked

    func testIsUnlocked_stage1_alwaysUnlocked() {
        XCTAssertTrue(appState.isUnlocked(1), "Stage 1 is always unlocked")
    }

    func testIsUnlocked_stage2_lockedByDefault() {
        XCTAssertFalse(appState.isUnlocked(2), "Stage 2 locked before stage 1 cleared")
    }

    func testIsUnlocked_stage2_unlockedAfterStage1Cleared() {
        appState.markStageCleared(1)
        XCTAssertTrue(appState.isUnlocked(2), "Stage 2 unlocked after stage 1 cleared")
    }

    // MARK: - reset

    func testReset_clearsStages() {
        appState.markStageCleared(1)
        appState.markStageCleared(2)
        appState.reset()
        XCTAssertTrue(appState.clearedStages.isEmpty, "clearedStages should be empty after reset")
    }

    func testReset_clearsUserDefaults() {
        appState.markStageCleared(1)
        appState.reset()
        let newState = AppState()
        XCTAssertTrue(newState.clearedStages.isEmpty, "UserDefaults should be cleared after reset")
    }
}
