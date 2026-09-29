import UIKit
import XCTest
@testable import OsmAnd_Maps

@MainActor
final class PlanRouteProfileSelectionTests: XCTestCase {

    func testMixedSegmentRequiresExplicitSelection() throws {
        let controller = makeController(mixed: true)
        controller.loadViewIfNeeded()
        let confirm = try XCTUnwrap(controller.navigationItem.rightBarButtonItem)
        XCTAssertFalse(confirm.isEnabled)
        let picker = try XCTUnwrap(controller.children.first as? RouteTypeViewController)
        let table = try XCTUnwrap(picker.view.subviews.first as? UITableView)
        let cell = picker.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertFalse(cell.accessibilityTraits.contains(.selected))
        let tabs = try XCTUnwrap(controller.view.subviews.compactMap { $0 as? UISegmentedControl }.first)
        XCTAssertFalse(tabs.isEnabledForSegment(at: 1))
    }

    func testExplicitStraightLineEnablesConfirmationAndSurvivesTabSwitch() throws {
        let controller = makeController(mixed: true)
        controller.loadViewIfNeeded()
        let picker = try XCTUnwrap(controller.children.first as? RouteTypeViewController)
        let table = try XCTUnwrap(picker.view.subviews.first as? UITableView)
        picker.tableView(table, didSelectRowAt: IndexPath(row: 0, section: 0))
        XCTAssertTrue(try XCTUnwrap(controller.navigationItem.rightBarButtonItem).isEnabled)
        XCTAssertTrue(picker.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0)).accessibilityTraits.contains(.selected))
        let tabs = try XCTUnwrap(controller.view.subviews.compactMap { $0 as? UISegmentedControl }.first)
        XCTAssertTrue(tabs.isEnabledForSegment(at: 1))
        tabs.selectedSegmentIndex = 1
        tabs.sendActions(for: .valueChanged)
        tabs.selectedSegmentIndex = 0
        tabs.sendActions(for: .valueChanged)
        let restoredPicker = try XCTUnwrap(controller.children.first as? RouteTypeViewController)
        let restoredTable = try XCTUnwrap(restoredPicker.view.subviews.first as? UITableView)
        XCTAssertTrue(restoredPicker.tableView(restoredTable, cellForRowAt: IndexPath(row: 0, section: 0)).accessibilityTraits.contains(.selected))
        XCTAssertTrue(try XCTUnwrap(controller.navigationItem.rightBarButtonItem).isEnabled)
    }

    func testSingleStraightLineSegmentRemainsPreselected() throws {
        let controller = makeController(mixed: false)
        controller.loadViewIfNeeded()
        XCTAssertTrue(try XCTUnwrap(controller.navigationItem.rightBarButtonItem).isEnabled)
        let picker = try XCTUnwrap(controller.children.first as? RouteTypeViewController)
        let table = try XCTUnwrap(picker.view.subviews.first as? UITableView)
        XCTAssertTrue(picker.tableView(table, cellForRowAt: IndexPath(row: 0, section: 0)).accessibilityTraits.contains(.selected))
    }

    func testUnselectedPickerCanSelectRoutedProfileThenStraightLine() throws {
        let mode = try XCTUnwrap(OAApplicationMode.car())
        var selections: [String?] = []
        let picker = RouteTypeViewController(context: .wholeTrack,
                                             availableModes: [mode],
                                             selectedMode: nil,
                                             hasSelectedMode: false,
                                             canStartNewSegment: false,
                                             onModeSelected: { selections.append($0?.stringKey) },
                                             onStartNewSegment: {})
        picker.loadViewIfNeeded()
        let table = try XCTUnwrap(picker.view.subviews.first as? UITableView)
        let straightLine = IndexPath(row: 0, section: 0)
        let routed = IndexPath(row: 0, section: 1)
        XCTAssertFalse(picker.tableView(table, cellForRowAt: routed).accessibilityTraits.contains(.selected))
        picker.tableView(table, didSelectRowAt: routed)
        XCTAssertTrue(picker.tableView(table, cellForRowAt: routed).accessibilityTraits.contains(.selected))
        XCTAssertFalse(picker.tableView(table, cellForRowAt: straightLine).accessibilityTraits.contains(.selected))
        picker.tableView(table, didSelectRowAt: straightLine)
        XCTAssertTrue(picker.tableView(table, cellForRowAt: straightLine).accessibilityTraits.contains(.selected))
        XCTAssertFalse(picker.tableView(table, cellForRowAt: routed).accessibilityTraits.contains(.selected))
        XCTAssertEqual(selections.count, 2)
        XCTAssertEqual(selections[0], mode.stringKey)
        XCTAssertNil(selections[1])
    }

    private func makeController(mixed: Bool) -> SegmentRouteSettingsViewController {
        let segment = PlanRouteSegment(index: 0,
                                       groups: [],
                                       routed: mixed,
                                       multiMode: mixed,
                                       singleMode: nil,
                                       distance: 0,
                                       isPendingEmpty: false,
                                       gapAfter: nil)
        return SegmentRouteSettingsViewController(context: .wholeSegment(segment), dataSource: nil)
    }
}
