import XCTest

final class OfflineConversionTests: XCTestCase {

    @MainActor
    func testConvertsUsingSampleRates() {
        let app = XCUIApplication()
        app.launchArguments = ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()

        let amount = app.textFields["conversion-amount"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        amount.tap()
        amount.typeText("10")
        app.buttons["convert"].tap()

        let result = app.staticTexts["conversion-result"]
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        XCTAssertTrue(result.label.contains("8.00"))
    }
}
