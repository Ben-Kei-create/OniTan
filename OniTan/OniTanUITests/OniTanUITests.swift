import XCTest

final class OniTanUITests: XCTestCase {

    override func setUpWithError() throws {
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to make sure the application is launched in a clean state,
        // because they start as soon as they are launched.
        XCUIApplication().launchArguments = ["-resetUserDefaults"] // Launch with clean state
        XCUIApplication().launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAppLaunchAndStartButton() throws {
        let app = XCUIApplication()
        
        // Check if "スタート" button exists and tap it
        let startButton = app.buttons["スタート"]
        XCTAssertTrue(startButton.exists)
        startButton.tap()
        
        // Check if we are on the Stage Select View
        XCTAssertTrue(app.navigationBars["ステージ選択"].exists)
    }
    
    func testSettingsNavigationAndColorSchemeToggle() throws {
        let app = XCUIApplication()
        
        // Navigate to Settings
        let settingsButton = app.buttons["設定"]
        XCTAssertTrue(settingsButton.exists)
        settingsButton.tap()
        
        // Check if we are on the Settings View
        XCTAssertTrue(app.navigationBars["設定"].exists)
        
        // Test color scheme picker (assuming "システム設定" is default)
        let systemMode = app.buttons["システム設定"]
        let lightMode = app.buttons["ライト"]
        let darkMode = app.buttons["ダーク"]
        
        XCTAssertTrue(systemMode.exists)
        XCTAssertTrue(lightMode.exists)
        XCTAssertTrue(darkMode.exists)
        
        // Tap light mode and then dark mode
        lightMode.tap()
        darkMode.tap()
        
        // Go back to Home View
        app.navigationBars["設定"].buttons["OniTan"].tap() // Back button
        XCTAssertTrue(app.buttons["スタート"].exists) // Back on Home View
    }
    
    func testResetProgressFunctionality() throws {
        let app = XCUIApplication()
        
        // First, make some progress (e.g., clear stage 1)
        app.buttons["スタート"].tap()
        app.buttons["ステージ 1"].tap()
        
        // Answer the first question correctly to clear stage 1 (assuming 1 question stage for simplicity)
        // This part is highly dependent on the actual quiz content and logic.
        // For a real test, you'd need to simulate answering all questions correctly.
        // For now, we'll just assume some progress is made.
        // Let's simulate answering one question correctly
        let kanjiText = app.staticTexts.matching(identifier: "kanjiText").firstMatch
        if kanjiText.exists {
            let choiceButton = app.buttons.matching(identifier: "choiceButton").firstMatch // Assuming choices have accessibility identifiers
            if choiceButton.exists {
                choiceButton.tap() // Tap a choice
                // Wait for explanation to appear and tap it
                let explanationOverlay = app.otherElements.matching(identifier: "explanationOverlay").firstMatch
                if explanationOverlay.exists {
                    explanationOverlay.tap()
                }
            }
        }
        
        // Go to Settings
        app.navigationBars["ステージ選択"].buttons["OniTan"].tap() // Back to Home
        app.buttons["設定"].tap()
        
        // Tap "進行状況を初期化" button
        let resetButton = app.buttons["進行状況を初期化"]
        XCTAssertTrue(resetButton.exists)
        resetButton.tap()
        
        // Confirm reset in alert
        let confirmAlert = app.alerts["確認"]
        XCTAssertTrue(confirmAlert.exists)
        confirmAlert.buttons["初期化"].tap()
        
        // Check confirmation alert
        let completionAlert = app.alerts["完了"]
        XCTAssertTrue(completionAlert.exists)
        completionAlert.buttons["OK"].tap()
        
        // Go back to Stage Select and verify stage 1 is not cleared
        app.navigationBars["設定"].buttons["OniTan"].tap() // Back to Home
        app.buttons["スタート"].tap()
        
        // Verify stage 1 is locked or not cleared (depends on UI representation)
        // This requires inspecting the UI element for stage 1
        let stage1Button = app.buttons["ステージ 1"]
        XCTAssertTrue(stage1Button.exists)
        // Further assertions would depend on how locked/unlocked stages are visually represented
    }
    
    func testReviewModeFlow() throws {
        let app = XCUIApplication()
        
        // Ensure clean state
        app.launchArguments = ["-resetUserDefaults"]
        app.launch()
        
        // Make some questions incorrect
        app.buttons["スタート"].tap()
        app.buttons["ステージ 1"].tap()
        
        // Answer first question incorrectly
        let kanjiText = app.staticTexts.matching(identifier: "kanjiText").firstMatch
        if kanjiText.exists {
            let incorrectChoiceButton = app.buttons.matching(identifier: "choiceButton").element(boundBy: 1) // Assuming second choice is incorrect
            if incorrectChoiceButton.exists {
                incorrectChoiceButton.tap()
            }
        }
        
        // Go back to Home
        app.navigationBars["ステージ 1"].buttons["辞める"].tap() // Tap "辞める"
        app.alerts["確認"].buttons["OK"].tap() // Confirm quit
        
        // Check if Review Mode button exists and has count
        let reviewModeButton = app.buttons["復習モード"]
        XCTAssertTrue(reviewModeButton.exists)
        XCTAssertTrue(reviewModeButton.label.contains("1")) // Assuming 1 incorrect question
        
        // Enter Review Mode
        reviewModeButton.tap()
        
        // Answer the incorrect question correctly
        let reviewKanjiText = app.staticTexts.matching(identifier: "kanjiText").firstMatch
        if reviewKanjiText.exists {
            let correctChoiceButton = app.buttons.matching(identifier: "choiceButton").firstMatch // Assuming first choice is correct in review
            if correctChoiceButton.exists {
                correctChoiceButton.tap()
                // Wait for explanation and tap it
                let explanationOverlay = app.otherElements.matching(identifier: "explanationOverlay").firstMatch
                if explanationOverlay.exists {
                    explanationOverlay.tap()
                }
            }
        }
        
        // Verify dismissal to Home screen
        XCTAssertTrue(app.buttons["スタート"].exists) // Back on Home View
        
        // Verify Review Mode button is disabled or gone
        XCTAssertFalse(reviewModeButton.isEnabled) // Should be disabled if no questions left
    }
}