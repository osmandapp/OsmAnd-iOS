import XCTest

final class FavoriteOriginalIconUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    }

    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }

    func testSelectingOriginalIsSavedAndRestoredAfterRelaunch() {
        let folderName = "Original UI test \(UUID().uuidString.prefix(8))"
        app.launch()
        openFavorites()
        tap(app.buttons["Actions"])
        tap(app.buttons["Add new folder"])

        let name = app.textViews.firstMatch
        tap(name)
        name.typeText(folderName)

        // Start with a concrete category, then explicitly change the saved folder to Original.
        tap(iconCell.buttons["Original"])
        tap(app.buttons["Special"])
        tap(app.navigationBars["Add new group"].buttons["Done"])
        openAppearance(of: folderName)
        tap(iconCell.buttons["Special"])
        tap(app.buttons["Original"])
        XCTAssertTrue(iconCell.staticTexts["Each point retains its individual icon."].exists)
        tap(app.navigationBars["Default appearance"].buttons["Done"])
        tap(app.buttons["Apply only to new points"])
        XCTAssertTrue(app.staticTexts[folderName].firstMatch.waitForExistence(timeout: 10))

        app.terminate()
        app.launch()
        openFavorites()
        openAppearance(of: folderName)
        XCTAssertTrue(iconCell.buttons["Original"].waitForExistence(timeout: 10))
        XCTAssertTrue(iconCell.staticTexts["Each point retains its individual icon."].exists)

        // Remove only the folder created by this test.
        tap(app.navigationBars["Default appearance"].buttons["Cancel"])
        let folder = app.staticTexts[folderName].firstMatch
        XCTAssertTrue(folder.waitForExistence(timeout: 10))
        folder.press(forDuration: 1)
        tap(app.buttons["Delete"])
        tap(app.alerts.buttons["Delete"])
        XCTAssertTrue(folder.waitForNonExistence(timeout: 10))
    }

    private var iconCell: XCUIElement {
        app.tables.cells.containing(.staticText, identifier: "Icon").firstMatch
    }

    private func openFavorites() {
        let menu = app.buttons["Menu"]
        let myPlaces = app.descendants(matching: .any).matching(identifier: "My Places").firstMatch
        XCTAssertTrue(menu.waitForExistence(timeout: 60))
        // Startup can finish presenting the map after its controls first become accessible.
        for _ in 0..<3 where !myPlaces.exists {
            tap(menu)
            _ = myPlaces.waitForExistence(timeout: 5)
        }
        tap(myPlaces)
        let favoritesTab = app.segmentedControls.buttons["Favorites"]
        if favoritesTab.waitForExistence(timeout: 5), !favoritesTab.isSelected {
            favoritesTab.tap()
        }
        XCTAssertTrue(app.buttons["Actions"].waitForExistence(timeout: 10))
    }

    private func openAppearance(of folderName: String) {
        let folder = app.staticTexts[folderName].firstMatch
        XCTAssertTrue(folder.waitForExistence(timeout: 10))
        folder.press(forDuration: 1)
        tap(app.buttons["Default appearance"])
        XCTAssertTrue(iconCell.waitForExistence(timeout: 10))
    }

    private func tap(_ element: XCUIElement, timeout: TimeInterval = 10,
                     file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: timeout), app.debugDescription, file: file, line: line)
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "hittable == true"), object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: timeout), .completed, file: file, line: line)
        element.tap()
    }
}
