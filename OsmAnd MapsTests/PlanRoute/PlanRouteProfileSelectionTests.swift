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

    func testContinueOnlyHasNoNewSegmentFooter() throws {
        try verifyActions(canContinue: true, canStartNewSegment: false,
                          expectedActions: ["continue"], expectedFooter: nil)
    }

    func testBothActionsHaveCombinedFooter() throws {
        try verifyActions(canContinue: true, canStartNewSegment: true,
                          expectedActions: ["continue", "start"],
                          expectedFooter: localizedString("plan_route_continue_or_start_segment_hint"))
    }

    func testStartOnlyHasNewSegmentFooter() throws {
        try verifyActions(canContinue: false, canStartNewSegment: true,
                          expectedActions: ["start"],
                          expectedFooter: localizedString("plan_route_new_segment_separate_hint"))
    }

    func testUnavailableActionsHaveNoSectionOrFooter() throws {
        try verifyActions(canContinue: false, canStartNewSegment: false,
                          expectedActions: [], expectedFooter: nil)
    }

    private func verifyActions(canContinue: Bool,
                               canStartNewSegment: Bool,
                               expectedActions: [String],
                               expectedFooter: String?) throws {
        var selectedActions: [String] = []
        let onContinue: (() -> Void)? = canContinue ? { selectedActions.append("continue") } : nil
        let picker = RouteTypeViewController(context: .wholeTrack,
                                             availableModes: [],
                                             selectedMode: nil,
                                             canStartNewSegment: canStartNewSegment,
                                             onContinueRoute: onContinue,
                                             onModeSelected: { _ in },
                                             onStartNewSegment: { selectedActions.append("start") })
        picker.loadViewIfNeeded()
        let table = try XCTUnwrap(picker.view.subviews.first as? UITableView)
        XCTAssertNil(picker.tableView(table, titleForFooterInSection: 0))
        XCTAssertNil(picker.tableView(table, titleForFooterInSection: 1))
        guard !expectedActions.isEmpty else {
            XCTAssertEqual(picker.numberOfSections(in: table), 2)
            return
        }
        XCTAssertEqual(picker.numberOfSections(in: table), 3)
        XCTAssertEqual(picker.tableView(table, numberOfRowsInSection: 2), expectedActions.count)
        XCTAssertEqual(picker.tableView(table, titleForFooterInSection: 2), expectedFooter)
        for row in expectedActions.indices {
            picker.tableView(table, didSelectRowAt: IndexPath(row: row, section: 2))
        }
        XCTAssertEqual(selectedActions, expectedActions)
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
