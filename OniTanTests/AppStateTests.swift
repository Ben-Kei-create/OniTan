import XCTest
import Foundation
@testable import OniTan // Import your app module

class AppStateTests: XCTestCase {

    var appState: AppState!
    let userDefaultsSuiteName = "testUserDefaults" // Use a separate suite for testing

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        // Use a separate UserDefaults suite for testing to avoid interfering with the actual app's data
        UserDefaults.standard.removePersistentDomain(forName: userDefaultsSuiteName)
        let testUserDefaults = UserDefaults(suiteName: userDefaultsSuiteName)!
        
        // Initialize AppState with the test UserDefaults
        // Note: AppState currently uses UserDefaults.standard directly.
        // For proper testability, AppState should ideally accept a UserDefaults instance in its initializer.
        // For now, we'll clear standard UserDefaults and rely on its behavior.
        // In a real project, consider refactoring AppState to be more testable.
        
        // Clear standard UserDefaults before each test to ensure a clean state
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }
        
        appState = AppState()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        appState = nil
        // Clean up standard UserDefaults after each test
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
        }
    }

    func testAppStateInitialization_emptyUserDefaults() {
        // Given: UserDefaults is empty (cleared in setUpWithError)
        
        // When: AppState is initialized
        // (already done in setUpWithError)
        
        // Then: clearedStages should be empty
        XCTAssertTrue(appState.clearedStages.isEmpty, "clearedStages should be empty on initial load with empty UserDefaults")
    }
    
    func testAppStateInitialization_withSavedData() {
        // Given: Some data saved in UserDefaults
        let savedStages: Set<Int> = [1, 3, 5]
        if let encoded = try? JSONEncoder().encode(savedStages) {
            UserDefaults.standard.set(encoded, forKey: "clearedStages")
            UserDefaults.standard.synchronize()
        } else {
            XCTFail("Failed to encode savedStages for test setup.")
        }
        
        // When: AppState is initialized
        appState = AppState() // Re-initialize to load saved data
        
        // Then: clearedStages should contain the saved data
        XCTAssertEqual(appState.clearedStages, savedStages, "clearedStages should load saved data from UserDefaults")
    }
    
    func testSaveClearedStages() {
        // Given: AppState with some cleared stages
        let stagesToClear: Set<Int> = [2, 4]
        appState.clearedStages = stagesToClear // This triggers didSet and saveClearedStages()
        
        // When: AppState is re-initialized to load from UserDefaults
        let newAppState = AppState()
        
        // Then: The new AppState should have the previously saved stages
        XCTAssertEqual(newAppState.clearedStages, stagesToClear, "clearedStages should be correctly saved and loaded")
    }
    
    func testResetUserDefaults() {
        // Given: AppState with some cleared stages and alert states set
        appState.clearedStages = [1, 2, 3]
        appState.showingResetAlert = true
        appState.showResetConfirmation = true
        appState.showingCannotResetAlert = true
        
        // Ensure data is saved to UserDefaults
        if let encoded = try? JSONEncoder().encode(appState.clearedStages) {
            UserDefaults.standard.set(encoded, forKey: "clearedStages")
            UserDefaults.standard.synchronize()
        }
        
        // When: resetUserDefaults is called
        appState.resetUserDefaults()
        
        // Then: clearedStages should be empty
        XCTAssertTrue(appState.clearedStages.isEmpty, "clearedStages should be empty after reset")
        
        // Then: Alert states should be reset
        XCTAssertFalse(appState.showingResetAlert, "showingResetAlert should be false after reset")
        XCTAssertFalse(appState.showResetConfirmation, "showResetConfirmation should be false after reset")
        XCTAssertFalse(appState.showingCannotResetAlert, "showingCannotResetAlert should be false after reset")
        
        // Then: UserDefaults should be cleared (verify by re-initializing AppState)
        let reinitializedAppState = AppState()
        XCTAssertTrue(reinitializedAppState.clearedStages.isEmpty, "UserDefaults should be cleared after reset")
    }
}
