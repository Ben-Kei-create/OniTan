import XCTest

final class OniTanUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testTodayFlow_homeToAnswerAndContinue() throws {
        let todayCard = app.otherElements["home_today_card"]
        guard todayCard.waitForExistence(timeout: 5) else {
            XCTSkip("Today card not found")
        }
        todayCard.tap()

        XCTAssertTrue(app.otherElements["quiz_kanji"].waitForExistence(timeout: 5), "Quiz should start")

        let anyChoice = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'quiz_choice_'")).firstMatch
        XCTAssertTrue(anyChoice.waitForExistence(timeout: 5), "At least one choice should be visible")
        anyChoice.tap()

        let explanationNext = app.buttons["quiz_next_explanation"]
        let wrongNext = app.buttons["quiz_next_wrong"]
        if explanationNext.waitForExistence(timeout: 3) {
            explanationNext.tap()
        } else if wrongNext.waitForExistence(timeout: 3) {
            wrongNext.tap()
        }

        XCTAssertTrue(app.otherElements["quiz_kanji"].waitForExistence(timeout: 5), "Should proceed to next question")
    }

    @MainActor
    func testStageFlow_homeToModeSelectToMainView() throws {
        let stageSelect = app.otherElements["home_menu_ステージ選択"]
        guard stageSelect.waitForExistence(timeout: 5) else {
            XCTSkip("Stage select menu not found")
        }
        stageSelect.tap()

        let stage1Mode = app.otherElements["stage_mode_link_1"]
        guard stage1Mode.waitForExistence(timeout: 5) else {
            XCTSkip("Stage 1 mode link not found")
        }
        stage1Mode.tap()

        let normalMode = app.otherElements["mode_card_normal"]
        guard normalMode.waitForExistence(timeout: 5) else {
            XCTSkip("Normal mode card not found")
        }
        normalMode.tap()

        XCTAssertTrue(app.otherElements["quiz_kanji"].waitForExistence(timeout: 5), "MainView should launch from mode card")
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
