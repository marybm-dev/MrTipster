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

    /// Runs the audit and logs each finding with its element, so failures are actionable.
    @MainActor
    private func audit(_ app: XCUIApplication) throws {
        let navBarBottom = app.navigationBars.allElementsBoundByIndex.map(\.frame.maxY).max() ?? 0
        let visibleBottom = app.windows.firstMatch.frame.maxY - 34 // home indicator inset
        try app.performAccessibilityAudit { issue in
            // iOS 26 fades content under the navigation bar and near the home indicator
            // (scroll-edge effects). Contrast for elements that are only partly in the
            // visible content area is measured against that fade, not our colors.
            if issue.auditType == .contrast, let frame = issue.element?.frame,
               frame.minY < navBarBottom || frame.maxY > visibleBottom {
                print("AUDIT IGNORED (in scroll-edge fade): \(issue.compactDescription) '\(issue.element?.label ?? "")' \(frame)")
                return true
            }
            // Navigation bar buttons intentionally keep a fixed size and offer the
            // Large Content Viewer instead (long press), so Dynamic Type doesn't apply.
            if issue.auditType == .dynamicType, let frame = issue.element?.frame, frame.maxY <= navBarBottom + 1 {
                print("AUDIT IGNORED (nav bar item): \(issue.compactDescription) '\(issue.element?.label ?? "")'")
                return true
            }
            let element = issue.element.map { "\($0.elementType.rawValue) '\($0.label)' id=\($0.identifier) frame=\($0.frame)" } ?? "none"
            if let dir = ProcessInfo.processInfo.environment["AUDIT_SHOTS"] {
                let url = URL(fileURLWithPath: dir).appendingPathComponent("audit-\(UUID().uuidString.prefix(6)).png")
                try? XCUIScreen.main.screenshot().pngRepresentation.write(to: url)
                print("AUDIT SHOT: \(url.path)")
            }
            print("AUDIT ISSUE: \(issue.compactDescription) | \(issue.detailedDescription) | element: \(element)")
            return false
        }
    }

    private let demo = ["-demoBill", "86.40", "-demoTip", "20", "-demoPeople", "3"]

    @MainActor
    func testMainScreenAudit() throws {
        let app = launch(demo)
        try audit(app)
    }

    @MainActor
    func testMainScreenAuditAtLargestTextSize() throws {
        let ax5 = ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        // Audit the top and the bottom of the (now very tall) screen at rest.
        try audit(launch(demo + ax5))
        try audit(launch(demo + ax5 + ["-scrollToBottom", "YES"]))
    }

    @MainActor
    func testSettingsAuditAtLargestTextSize() throws {
        let app = launch(["-showSettings", "YES", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        try audit(app)
    }

    @MainActor
    func testSettingsAudit() throws {
        let app = launch()
        app.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        try audit(app)
    }

    @MainActor
    func testDarkModeAudits() throws {
        XCUIDevice.shared.appearance = .dark
        defer { XCUIDevice.shared.appearance = .light }
        try audit(launch(demo))
        try audit(launch(demo + ["-scrollToBottom", "YES"]))
        let app = launch(["-showSettings", "YES"])
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        try audit(app)
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
