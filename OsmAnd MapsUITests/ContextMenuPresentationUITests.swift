//
//  ContextMenuPresentationUITests.swift
//  OsmAnd MapsUITests
//
//  Created by Oleksandr Panchenko on 01.09.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import XCTest

final class ContextMenuPresentationUITests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testQueuedContextMenuPresentationShowsLatestMenuAfterDismissal() {
        app.launchArguments += ["-ui-testing-context-menu-presentation-race"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30))
        dismissStartupIfNeeded()

        let stateMarker = app.descendants(matching: .any)
            .matching(identifier: "context_menu_presentation_test_state")
            .firstMatch

        XCTAssertTrue(stateMarker.waitForExistence(timeout: 30))

        waitForContextMenuPresentationHistory(containing: "UITest Destination A", stateMarker: stateMarker)
        waitForCurrentContextMenuPresentation("UITest My Location C", stateMarker: stateMarker)
        waitForContextMenuPresentationHistory(containing: "UITest My Location C", stateMarker: stateMarker)
        XCTAssertFalse((stateMarker.value as? String)?.contains("UITest Parking B") ?? false)

        if !app.descendants(matching: .any)
            .matching(identifier: "context_menu_container")
            .firstMatch
            .exists {
            XCTFail("Expected the queued context menu presentation fixture to show the latest synthetic target.")
        }
        assertNoOverlappingContextMenus()
    }

    private func waitForCurrentContextMenuPresentation(
        _ title: String,
        stateMarker: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "label == %@", title)
        let expectation = expectation(for: predicate, evaluatedWith: stateMarker)
        let result = XCTWaiter().wait(for: [expectation], timeout: 30)
        if result != .completed {
            XCTFail("Expected context menu presentation state to become \(title).", file: file, line: line)
        }
    }

    private func waitForContextMenuPresentationHistory(
        containing title: String,
        stateMarker: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "value CONTAINS %@", title)
        let expectation = expectation(for: predicate, evaluatedWith: stateMarker)
        let result = XCTWaiter().wait(for: [expectation], timeout: 30)
        if result != .completed {
            XCTFail("Expected context menu presentation history to contain \(title).", file: file, line: line)
        }
    }

    private func dismissStartupIfNeeded() {
        let skipDownloadButton = app.buttons["first_usage_skip_download_button"]
        if skipDownloadButton.waitForExistence(timeout: 20) {
            skipDownloadButton.tap()
            XCTAssertTrue(skipDownloadButton.waitForNonExistence(timeout: 10))
        }
    }

    private func assertNoOverlappingContextMenus(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let regularMenus = app.descendants(matching: .any)
            .matching(identifier: "context_menu_container")
            .count
        let multiMenus = app.descendants(matching: .any)
            .matching(identifier: "multi_context_menu_container")
            .count

        XCTAssertLessThanOrEqual(regularMenus + multiMenus, 1, file: file, line: line)
    }
}
