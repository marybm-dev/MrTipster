import XCTest

/// Runs Xcode's accessibility audit (contrast, hit regions, labels, Dynamic Type
/// clipping, traits) on each screen, plus a quick end-to-end smoke test.
final class AccessibilityAuditTests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(_ extra: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-resetState", "YES", "-autoFocus", "NO"] + extra
        app.launch()
        return app
    }

    private let demo = ["-demoBill", "86.40", "-demoTip", "20", "-demoPeople", "3"]

    @MainActor
    func testMainScreenAudit() throws {
        let app = launch(demo)
        try app.performAccessibilityAudit()
    }

    @MainActor
    func testMainScreenAuditAtLargestTextSize() throws {
        let app = launch(demo + ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        try app.performAccessibilityAudit()
        app.swipeUp()
        try app.performAccessibilityAudit()
        app.swipeUp()
        try app.performAccessibilityAudit()
    }

    @MainActor
    func testSettingsAudit() throws {
        let app = launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        try app.performAccessibilityAudit()
    }

    @MainActor
    func testTypingABillShowsTheTotal() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-resetState", "YES"]
        app.launch()
        let field = app.textFields["billField"]
        XCTAssertTrue(field.waitForExistence(timeout: 3))
        // The field is focused on launch, so we can type right away.
        app.typeText("100")
        XCTAssertTrue(app.staticTexts["Total, $118.00"].waitForExistence(timeout: 3)
                      || app.otherElements["Total, $118.00"].exists
                      || app.descendants(matching: .any)["headlineAmount"].label.contains("118"))
    }
}
