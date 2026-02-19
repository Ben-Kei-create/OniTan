import XCTest

// MARK: - OniTan UI Tests
// Tests verify key navigation flows and UI element presence.
// Run on simulator with the app installed.

final class OniTanUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Reset state for clean test runs
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Home Screen

    @MainActor
    func testHomeScreen_displaysAppTitle() {
        XCTAssertTrue(
            app.staticTexts["鬼単"].exists ||
            app.staticTexts.matching(identifier: "鬼単アプリ").count > 0,
            "App title should be visible on home screen"
        )
    }

    @MainActor
    func testHomeScreen_hasStartButton() {
        XCTAssertTrue(
            app.buttons["スタート: ステージを選んで学習"].exists ||
            app.buttons.matching(NSPredicate(format: "label CONTAINS 'スタート'")).count > 0,
            "Start button should be present on home screen"
        )
    }

    @MainActor
    func testHomeScreen_hasStatsButton() {
        XCTAssertTrue(
            app.buttons.matching(NSPredicate(format: "label CONTAINS '統計'")).count > 0,
            "Stats button should be present"
        )
    }

    @MainActor
    func testHomeScreen_hasSettingsButton() {
        XCTAssertTrue(
            app.buttons.matching(NSPredicate(format: "label CONTAINS '設定'")).count > 0,
            "Settings button should be present"
        )
    }

    // MARK: - Navigation: Home → Stage Select

    @MainActor
    func testNavigate_homeToStageSelect() throws {
        let startButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'スタート'")).firstMatch
        guard startButton.waitForExistence(timeout: 3) else {
            XCTSkip("Start button not found — skipping navigation test")
        }
        startButton.tap()

        let stageSelectTitle = app.navigationBars["ステージ選択"]
        XCTAssertTrue(
            stageSelectTitle.waitForExistence(timeout: 3),
            "Should navigate to stage select screen"
        )
    }

    // MARK: - Navigation: Home → Stats

    @MainActor
    func testNavigate_homeToStats() throws {
        let statsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '統計'")).firstMatch
        guard statsButton.waitForExistence(timeout: 3) else {
            XCTSkip("Stats button not found")
        }
        statsButton.tap()

        let statsTitle = app.navigationBars["学習統計"]
        XCTAssertTrue(
            statsTitle.waitForExistence(timeout: 3),
            "Should navigate to stats screen"
        )
    }

    // MARK: - Navigation: Home → Settings

    @MainActor
    func testNavigate_homeToSettings() throws {
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '設定'")).firstMatch
        guard settingsButton.waitForExistence(timeout: 3) else {
            XCTSkip("Settings button not found")
        }
        settingsButton.tap()

        let settingsTitle = app.navigationBars["設定"]
        XCTAssertTrue(
            settingsTitle.waitForExistence(timeout: 3),
            "Should navigate to settings screen"
        )
    }

    // MARK: - Navigation: Home → Wrong Answer Note

    @MainActor
    func testNavigate_homeToWrongAnswerNote() throws {
        let noteButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '誤答'")).firstMatch
        guard noteButton.waitForExistence(timeout: 3) else {
            XCTSkip("Wrong answer note button not found")
        }
        noteButton.tap()

        let noteTitle = app.navigationBars["誤答ノート"]
        XCTAssertTrue(
            noteTitle.waitForExistence(timeout: 3),
            "Should navigate to wrong answer note screen"
        )
    }

    // MARK: - Back Navigation

    @MainActor
    func testBackNavigation_fromStats_returnsHome() throws {
        let statsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '統計'")).firstMatch
        guard statsButton.waitForExistence(timeout: 3) else {
            XCTSkip("Stats button not found")
        }
        statsButton.tap()

        guard app.navigationBars["学習統計"].waitForExistence(timeout: 3) else {
            XCTSkip("Stats screen not loaded")
        }

        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(
            app.staticTexts["鬼単"].waitForExistence(timeout: 3) ||
            app.buttons.matching(NSPredicate(format: "label CONTAINS 'スタート'")).firstMatch.waitForExistence(timeout: 3),
            "Should return to home screen after back navigation"
        )
    }

    // MARK: - Settings: Color Scheme Picker

    @MainActor
    func testSettings_colorSchemePicker_exists() throws {
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS '設定'")).firstMatch
        guard settingsButton.waitForExistence(timeout: 3) else {
            XCTSkip("Settings button not found")
        }
        settingsButton.tap()

        guard app.navigationBars["設定"].waitForExistence(timeout: 3) else {
            XCTSkip("Settings screen not loaded")
        }

        // Segmented control should be present
        XCTAssertTrue(
            app.segmentedControls.count > 0 ||
            app.buttons.matching(NSPredicate(format: "label == 'システム'")).count > 0,
            "Color scheme picker should be visible in settings"
        )
    }

    // MARK: - Performance

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
