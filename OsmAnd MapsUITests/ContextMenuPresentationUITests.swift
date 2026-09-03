//
//  ContextMenuPresentationUITests.swift
//  OsmAnd MapsUITests
//
//  Created by Oleksandr Panchenko on 02.09.2026.
//  Copyright (c) 2026 OsmAnd. All rights reserved.
//

import XCTest

final class ContextMenuPresentationUITests: XCTestCase {

    private enum LaunchArgument {
        static let uiTesting = "-ui-testing"

        enum ContextMenu {
            static let presentationRace = "-ui-testing-context-menu-presentation-race"
            static let gpxWaypointOpenTrack = "-ui-testing-gpx-waypoint-open-track"
        }
    }

    private enum AccessibilityIdentifier {
        static let firstUsageSkipDownloadButton = "first_usage_skip_download_button"

        enum ContextMenu {
            static let container = "context_menu_container"
            static let multiContainer = "multi_context_menu_container"
            static let presentationState = "context_menu_presentation_test_state"

            enum GPX {
                static let trackMenuTitle = "gpx_track_menu_title"
                static let waypointOpenTrackButton = "gpx_waypoint_open_track_button"

                static func waypoint(_ title: String) -> String {
                    "gpx_track_menu_waypoint_\(title)"
                }
            }
        }
    }

    private enum Timeout {
        static let launch: TimeInterval = 30
        static let startupPrompt: TimeInterval = 5
        static let initialMenu: TimeInterval = 30
        static let menu: TimeInterval = 10
        static let transition: TimeInterval = 10
    }

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += [LaunchArgument.uiTesting]
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testQueuedContextMenuPresentationShowsLatestMenuAfterDismissal() {
        app.launchArguments += [LaunchArgument.ContextMenu.presentationRace]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30))
        dismissStartupIfNeeded()

        let stateMarker = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.ContextMenu.presentationState)
            .firstMatch

        XCTAssertTrue(stateMarker.waitForExistence(timeout: 30))

        waitForContextMenuPresentationHistory(containing: "UITest Destination A", stateMarker: stateMarker)
        waitForCurrentContextMenuPresentation("UITest My Location C", stateMarker: stateMarker)
        waitForContextMenuPresentationHistory(containing: "UITest My Location C", stateMarker: stateMarker)
        XCTAssertFalse((stateMarker.value as? String)?.contains("UITest Parking B") ?? false)

        if !app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.ContextMenu.container)
            .firstMatch
            .exists {
            XCTFail("Expected the queue context menu presentation fixture to show the latest synthetic target.")
        }
        assertNoOverlappingContextMenus()
    }

    func testWaypointOpenTrackReturnsToCurrentTrackMenu() {
        app.launchArguments += [LaunchArgument.ContextMenu.gpxWaypointOpenTrack]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: Timeout.launch))

        let waypoint = element(identifier: AccessibilityIdentifier.ContextMenu.GPX.waypoint("UITest Waypoint A"))
        XCTAssertTrue(waypoint.waitForExistence(timeout: Timeout.initialMenu))
        waypoint.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let openTrackButton = element(identifier: AccessibilityIdentifier.ContextMenu.GPX.waypointOpenTrackButton)
        XCTAssertTrue(openTrackButton.waitForExistence(timeout: Timeout.transition))
        openTrackButton.tap()

        XCTAssertTrue(openTrackButton.waitForNonExistence(timeout: Timeout.transition))
        XCTAssertTrue(element(identifier: AccessibilityIdentifier.ContextMenu.GPX.trackMenuTitle).waitForExistence(timeout: Timeout.transition))
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
        let skipDownloadButton = app.buttons[AccessibilityIdentifier.firstUsageSkipDownloadButton]
        if skipDownloadButton.waitForExistence(timeout: Timeout.startupPrompt) {
            skipDownloadButton.tap()
            XCTAssertTrue(skipDownloadButton.waitUntilHidden(timeout: Timeout.transition))
        }
    }

    private func element(identifier: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
    }

    private func assertNoOverlappingContextMenus(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let regularMenus = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.ContextMenu.container)
            .count
        let multiMenus = app.descendants(matching: .any)
            .matching(identifier: AccessibilityIdentifier.ContextMenu.multiContainer)
            .count

        XCTAssertLessThanOrEqual(regularMenus + multiMenus, 1, file: file, line: line)
    }
}

private extension XCUIElement {
    func waitUntilHidden(timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "exists == false OR hittable == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }
}
