import UIKit
import XCTest
@testable import OsmAnd_Maps

@MainActor
final class PlanRouteProfileSelectionTests: XCTestCase {

    override func setUp() {
        super.setUp()
        let initialized = XCTNSPredicateExpectation(predicate: NSPredicate(format: "initialized == YES"),
                                                    object: OsmAndApp.swiftInstance())
        XCTAssertEqual(XCTWaiter.wait(for: [initialized], timeout: 30), .completed)
    }

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

    func testSimpleMenuNextKeepsSavedProfileDuringUnconfirmedSelectionAndTabSwitch() throws {
        let bicycle = try XCTUnwrap(OAApplicationMode.bicycle())
        let continuationModes: [OAApplicationMode?] = [nil, bicycle]
        for continuationMode in continuationModes {
            let source = PlanRouteProfileTestDataSource()
            source.defaultMode = continuationMode
            source.routeSegments = [makeSegment(groups: [
                PlanRouteProfileGroup(appMode: nil, distance: 175, lastPointIndex: 1,
                                      points: (0..<2).map { makePoint(index: $0, count: 2) },
                                      profilePointIndexes: [0, 1])
            ])]
            let controller = SegmentRouteSettingsViewController(context: .wholeTrack, dataSource: source)
            let navigation = UINavigationController(rootViewController: controller)
            navigation.loadViewIfNeeded()
            controller.loadViewIfNeeded()
            let picker = try XCTUnwrap(controller.children.first as? RouteTypeViewController)
            let table = try XCTUnwrap(picker.view.subviews.first as? UITableView)
            let continuePath = IndexPath(row: 0, section: 2)
            let expectedTitle = localizedString("plan_route_continue_with_different_route_type")
            let expectedSubtitle = String(format: localizedString("ltr_or_rtl_combine_via_colon"),
                                          localizedString("shared_string_next"),
                                          continuationMode?.toHumanString() ?? localizedString("plan_route_straight_line"))
            XCTAssertEqual(picker.tableView(table, cellForRowAt: continuePath).accessibilityValue, expectedSubtitle)
            XCTAssertEqual(picker.tableView(table, cellForRowAt: continuePath).accessibilityLabel, expectedTitle)
            let pedestrianIndex = try XCTUnwrap(source.availableModes.firstIndex { $0.stringKey == OAApplicationMode.pedestrian()?.stringKey })
            picker.tableView(table, didSelectRowAt: IndexPath(row: pedestrianIndex, section: 1))
            XCTAssertEqual(picker.tableView(table, cellForRowAt: continuePath).accessibilityValue, expectedSubtitle)
            let tabs = try XCTUnwrap(controller.view.subviews.compactMap { $0 as? UISegmentedControl }.first)
            tabs.selectedSegmentIndex = 1
            tabs.sendActions(for: .valueChanged)
            tabs.selectedSegmentIndex = 0
            tabs.sendActions(for: .valueChanged)
            let restoredPicker = try XCTUnwrap(controller.children.first as? RouteTypeViewController)
            let restoredTable = try XCTUnwrap(restoredPicker.view.subviews.first as? UITableView)
            XCTAssertEqual(restoredPicker.tableView(restoredTable, cellForRowAt: continuePath).accessibilityValue, expectedSubtitle)
            XCTAssertEqual(restoredPicker.tableView(restoredTable, cellForRowAt: continuePath).accessibilityLabel, expectedTitle)
            XCTAssertEqual(source.defaultMode?.stringKey, continuationMode?.stringKey)
            XCTAssertNil(source.appliedContext)
            XCTAssertTrue(navigation.topViewController === controller)
        }
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

    func testBoundaryPointUsesDifferentGroupsBeforeAndAfter() throws {
        let segment = makeMixedSegment()
        XCTAssertEqual(segment.groups[0].points.map(\.index), [0, 1])
        XCTAssertNil(segment.groups[0].appMode)
        XCTAssertEqual(segment.profileGroup(forLegStartingAt: 1)?.appMode?.stringKey, OAApplicationMode.bicycle()?.stringKey)
        XCTAssertEqual(segment.profileGroup(forLegStartingAt: 3)?.appMode?.stringKey, OAApplicationMode.pedestrian()?.stringKey)
        XCTAssertNil(segment.profileGroup(forLegStartingAt: 6))
    }

    func testPartialProfileChangeUsesLegStartsWithoutCrossingBoundary() throws {
        let source = PlanRouteProfileTestDataSource()
        let segment = makeMixedSegment()
        let context = SegmentRouteContext.profileGroup(segment.groups[1], segment: segment)
        let before = SegmentRouteSettingsViewController(context: context, dataSource: source, applyUpToPointIndex: 2)
        before.loadViewIfNeeded()
        before.perform(NSSelectorFromString("onConfirmTapped"))
        XCTAssertEqual(source.appliedPointIndexes, [1])
        let after = SegmentRouteSettingsViewController(context: context, dataSource: source, applyFromPointIndex: 2)
        after.loadViewIfNeeded()
        after.perform(NSSelectorFromString("onConfirmTapped"))
        XCTAssertEqual(source.appliedPointIndexes, [2])
    }

    func testContinueSubtitleRefreshesWithoutChangingPointRows() throws {
        let source = PlanRouteProfileTestDataSource()
        source.routeSegments = [makeMixedSegment()]
        let controller = PlanRouteRouteViewController(dataSource: source)
        controller.loadViewIfNeeded()
        let table = try XCTUnwrap(controller.view.subviews.first as? UITableView)
        let rowCount = controller.tableView(table, numberOfRowsInSection: 0)
        let continuePath = IndexPath(row: rowCount - 1, section: 0)
        source.defaultMode = OAApplicationMode.car()
        controller.reloadData()
        XCTAssertEqual(controller.tableView(table, numberOfRowsInSection: 0), rowCount)
        let cell = controller.tableView(table, cellForRowAt: continuePath)
        XCTAssertEqual(cell.accessibilityLabel, localizedString("plan_route_continue_with_different_type"))
        XCTAssertEqual(cell.accessibilityValue, String(format: localizedString("ltr_or_rtl_combine_via_colon"),
                                                       localizedString("shared_string_next"),
                                                       try XCTUnwrap(source.defaultMode?.toHumanString())))
        source.defaultMode = OAApplicationMode.pedestrian()
        controller.reloadData()
        let updated = controller.tableView(table, cellForRowAt: continuePath)
        XCTAssertEqual(updated.accessibilityValue, String(format: localizedString("ltr_or_rtl_combine_via_colon"),
                                                          localizedString("shared_string_next"),
                                                          try XCTUnwrap(source.defaultMode?.toHumanString())))
    }

    func testChangeTypeAfterDestinationUsesFutureProfile() throws {
        let source = PlanRouteProfileTestDataSource()
        let segment = makeMixedSegment()
        source.routeSegments = [segment]
        source.defaultMode = OAApplicationMode.car()
        let context = SegmentRouteContext.profileGroup(segment.groups[2], segment: segment)
        let settings = SegmentRouteSettingsViewController(context: context, dataSource: source, applyFromPointIndex: 5)
        settings.loadViewIfNeeded()
        settings.perform(NSSelectorFromString("onConfirmTapped"))
        XCTAssertEqual(source.appliedPointIndexes, [5])
        XCTAssertEqual(source.appliedMode?.stringKey, source.defaultMode?.stringKey)
    }

    func testComplexRouteSheetUsesSameGroupDistancesAndProfileIndexes() throws {
        let source = PlanRouteProfileTestDataSource()
        let segment = makeMixedSegment()
        source.routeSegments = [segment]
        let controller = RouteBetweenPointsViewController(dataSource: source)
        let navigation = UINavigationController(rootViewController: controller)
        controller.loadViewIfNeeded()
        let table = try XCTUnwrap(controller.view.subviews.first as? UITableView)
        XCTAssertEqual(controller.tableView(table, numberOfRowsInSection: 0), 4)
        let continueCell = controller.tableView(table, cellForRowAt: IndexPath(row: 3, section: 0))
        XCTAssertEqual(continueCell.accessibilityLabel, localizedString("plan_route_continue_with_different_type"))
        controller.tableView(table, didSelectRowAt: IndexPath(row: 1, section: 0))
        let settings = try XCTUnwrap(navigation.topViewController as? SegmentRouteSettingsViewController)
        settings.loadViewIfNeeded()
        settings.perform(NSSelectorFromString("onConfirmTapped"))
        guard case let .profileGroup(selected, _)? = source.appliedContext else {
            XCTFail("Expected the middle profile group")
            return
        }
        XCTAssertEqual(selected.distance, 1568)
        XCTAssertEqual(selected.profilePointIndexes, [1, 2])
    }

    func testMoveDefersRegroupingUntilTableMoveCompletes() throws {
        let source = PlanRouteProfileTestDataSource()
        let points = (0..<4).map { makePoint(index: $0, count: 4) }
        let straight = PlanRouteProfileGroup(appMode: nil, distance: 175, lastPointIndex: 2,
                                             points: Array(points.prefix(3)), profilePointIndexes: [0, 1])
        let cycling = PlanRouteProfileGroup(appMode: OAApplicationMode.bicycle(), distance: 368, lastPointIndex: 3,
                                            points: [points[3]], profilePointIndexes: [2, 3])
        source.routeSegments = [makeSegment(groups: [straight, cycling])]
        let controller = PlanRouteRouteViewController(dataSource: source)
        controller.loadViewIfNeeded()
        let table = try XCTUnwrap(controller.view.subviews.first as? UITableView)
        XCTAssertEqual(controller.tableView(table, numberOfRowsInSection: 0), 7)
        XCTAssertEqual(table.numberOfRows(inSection: 0), 7)
        source.onMove = { [weak controller, weak source] from, to in
            XCTAssertEqual(from, 0)
            XCTAssertEqual(to, 1)
            let merged = PlanRouteProfileGroup(appMode: OAApplicationMode.bicycle(), distance: 543, lastPointIndex: 3,
                                               points: points, profilePointIndexes: [0, 1, 2, 3])
            source?.routeSegments = [self.makeSegment(groups: [merged])]
            controller?.reloadData()
        }
        let from = IndexPath(row: 1, section: 0)
        let to = IndexPath(row: 2, section: 0)
        controller.tableView(table, moveRowAt: from, to: to)
        XCTAssertEqual(controller.tableView(table, numberOfRowsInSection: 0), 7)
        table.moveRow(at: from, to: to)
        let reloaded = expectation(description: "Groups reload after the move")
        DispatchQueue.main.async {
            XCTAssertEqual(controller.tableView(table, numberOfRowsInSection: 0), 5)
            reloaded.fulfill()
        }
        wait(for: [reloaded], timeout: 1)
    }

    func testMovesAreClampedToTheirDisplayedProfileGroup() throws {
        let source = PlanRouteProfileTestDataSource()
        source.routeSegments = [makeTenPointSegment()]
        source.defaultMode = OAApplicationMode.bicycle()
        let controller = PlanRouteRouteViewController(dataSource: source)
        controller.loadViewIfNeeded()
        let table = try XCTUnwrap(controller.view.subviews.first as? UITableView)
        for (from, proposed, expected) in [(3, 9, 4), (9, 3, 7), (2, 100, 4), (9, 0, 7), (2, 3, 3), (9, 8, 8)] {
            XCTAssertEqual(controller.tableView(table, targetIndexPathForMoveFromRowAt: IndexPath(row: from, section: 0),
                                                toProposedIndexPath: IndexPath(row: proposed, section: 0)),
                           IndexPath(row: expected, section: 0))
        }
        XCTAssertEqual(controller.tableView(table, targetIndexPathForMoveFromRowAt: IndexPath(row: 3, section: 0),
                                            toProposedIndexPath: IndexPath(row: 0, section: 1)), IndexPath(row: 4, section: 0))
        source.onMove = { _, _ in XCTFail("Moving between displayed profile groups must be rejected") }
        controller.tableView(table, moveRowAt: IndexPath(row: 3, section: 0), to: IndexPath(row: 9, section: 0))
        controller.tableView(table, moveRowAt: IndexPath(row: 9, section: 0), to: IndexPath(row: 3, section: 0))
    }

    func testProfileBoundaryAndDifferentNextProfileStayFixed() throws {
        let source = PlanRouteProfileTestDataSource()
        source.routeSegments = [makeTenPointSegment()]
        source.defaultMode = OAApplicationMode.pedestrian()
        let controller = PlanRouteRouteViewController(dataSource: source)
        controller.loadViewIfNeeded()
        let table = try XCTUnwrap(controller.view.subviews.first as? UITableView)
        XCTAssertFalse(controller.tableView(table, canMoveRowAt: IndexPath(row: 5, section: 0)))
        XCTAssertFalse(controller.tableView(table, canMoveRowAt: IndexPath(row: 11, section: 0)))
        XCTAssertTrue(controller.tableView(table, canMoveRowAt: IndexPath(row: 10, section: 0)))
        XCTAssertEqual(controller.tableView(table, targetIndexPathForMoveFromRowAt: IndexPath(row: 8, section: 0),
                                            toProposedIndexPath: IndexPath(row: 11, section: 0)), IndexPath(row: 10, section: 0))
        source.onMove = { _, _ in XCTFail("Moving a profile boundary must be rejected") }
        for (from, to) in [(5, 2), (2, 5), (11, 8), (8, 11)] {
            controller.tableView(table, moveRowAt: IndexPath(row: from, section: 0), to: IndexPath(row: to, section: 0))
        }
    }

    func testSinglePointProfileGroupHasNoReorderHandle() throws {
        let source = PlanRouteProfileTestDataSource()
        let points = (0..<4).map { makePoint(index: $0, count: 4) }
        source.routeSegments = [makeSegment(groups: [
            PlanRouteProfileGroup(appMode: nil, distance: 175, lastPointIndex: 2,
                                  points: Array(points.prefix(3)), profilePointIndexes: [0, 1]),
            PlanRouteProfileGroup(appMode: OAApplicationMode.bicycle(), distance: 100, lastPointIndex: 3,
                                  points: [points[3]], profilePointIndexes: [2, 3])
        ])]
        source.defaultMode = OAApplicationMode.bicycle()
        let controller = PlanRouteRouteViewController(dataSource: source)
        controller.loadViewIfNeeded()
        let table = try XCTUnwrap(controller.view.subviews.first as? UITableView)
        XCTAssertTrue(controller.tableView(table, canMoveRowAt: IndexPath(row: 1, section: 0)))
        XCTAssertFalse(controller.tableView(table, canMoveRowAt: IndexPath(row: 5, section: 0)))
    }

    func testGapEndpointCannotMoveOrReceiveAnotherPoint() throws {
        let source = PlanRouteProfileTestDataSource()
        let points = (0..<3).map { makePoint(index: $0, count: 3) }
        let group = PlanRouteProfileGroup(appMode: nil, distance: 200, lastPointIndex: 2,
                                          points: points, profilePointIndexes: [0, 1])
        source.routeSegments = [makeSegment(groups: [group])]
        let controller = PlanRouteRouteViewController(dataSource: source)
        controller.loadViewIfNeeded()
        let table = try XCTUnwrap(controller.view.subviews.first as? UITableView)
        let first = IndexPath(row: 0, section: 0)
        let gap = IndexPath(row: 2, section: 0)
        XCTAssertFalse(controller.tableView(table, canMoveRowAt: gap))
        XCTAssertTrue(controller.tableView(table, canMoveRowAt: first))
        XCTAssertEqual(controller.tableView(table, targetIndexPathForMoveFromRowAt: first,
                                            toProposedIndexPath: gap), IndexPath(row: 1, section: 0))
        source.onMove = { _, _ in XCTFail("Moving a gap endpoint must be rejected") }
        controller.tableView(table, moveRowAt: first, to: gap)
        controller.tableView(table, moveRowAt: gap, to: first)
    }

    func testReloadWaitsForTableInteractionToFinish() throws {
        let source = PlanRouteProfileTestDataSource()
        source.routeSegments = [makeMixedSegment()]
        let controller = PlanRouteRouteViewController(dataSource: source)
        controller.loadViewIfNeeded()
        let table = try XCTUnwrap(controller.view.subviews.first as? UITableView)
        let observer = try XCTUnwrap(table.gestureRecognizers?.first { String(describing: type(of: $0)).contains("InteractionObserver") })
        let initialCount = table.numberOfRows(inSection: 0)
        observer.touchesBegan([], with: UIEvent())
        source.routeSegments = []
        controller.reloadData()
        XCTAssertEqual(table.numberOfRows(inSection: 0), initialCount)
        observer.touchesCancelled([], with: UIEvent())
        controller.perform(NSSelectorFromString("onTableInteraction:"), with: observer)
        let reloaded = expectation(description: "Reload resumes after cancelled interaction")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            XCTAssertEqual(table.numberOfRows(inSection: 0), 1)
            reloaded.fulfill()
        }
        wait(for: [reloaded], timeout: 1)
    }

    func testPointMenuInsertionAndTrimUseTheSelectedBoundaryPoint() throws {
        let source = PlanRouteProfileTestDataSource()
        let segment = makeMixedSegment()
        source.routeSegments = [segment]
        for group in segment.groups.prefix(2) {
            let point = try XCTUnwrap(group.points.last)
            for (section, row, action) in [(1, 0, "addBefore"), (1, 1, "addAfter"), (2, 0, "trimBefore"), (2, 1, "trimAfter")] {
                let controller = PlanRoutePointMenuViewController(point: point, segment: segment, group: group, dataSource: source)
                controller.loadViewIfNeeded()
                let table = try XCTUnwrap(controller.view.subviews.first as? UITableView)
                let indexPath = IndexPath(row: row, section: section)
                XCTAssertTrue(controller.tableView(table, cellForRowAt: indexPath).isUserInteractionEnabled)
                controller.tableView(table, didSelectRowAt: indexPath)
                XCTAssertEqual(source.editedPointAction, "\(action):\(point.index)")
            }
        }
    }

    private func makeTenPointSegment() -> PlanRouteSegment {
        let points = (0..<10).map { makePoint(index: $0, count: 10) }
        return makeSegment(groups: [
            PlanRouteProfileGroup(appMode: nil, distance: 400, lastPointIndex: 4,
                                  points: Array(points[0...4]), profilePointIndexes: [0, 1, 2, 3]),
            PlanRouteProfileGroup(appMode: OAApplicationMode.bicycle(), distance: 500, lastPointIndex: 9,
                                  points: Array(points[5...9]), profilePointIndexes: [4, 5, 6, 7, 8, 9])
        ])
    }

    private func makeMixedSegment() -> PlanRouteSegment {
        let points = (0..<6).map { makePoint(index: $0, count: 6) }
        return makeSegment(groups: [
            PlanRouteProfileGroup(appMode: nil, distance: 175, lastPointIndex: 1,
                                  points: Array(points[0...1]), profilePointIndexes: [0]),
            PlanRouteProfileGroup(appMode: OAApplicationMode.bicycle(), distance: 1568, lastPointIndex: 3,
                                  points: Array(points[2...3]), profilePointIndexes: [1, 2]),
            PlanRouteProfileGroup(appMode: OAApplicationMode.pedestrian(), distance: 1500, lastPointIndex: 5,
                                  points: Array(points[4...5]), profilePointIndexes: [3, 4, 5])
        ])
    }

    private func makePoint(index: Int, count: Int) -> PlanRoutePoint {
        PlanRoutePoint(index: index, indexInSegment: index, name: "Point \(index + 1)",
                       distanceFromPrevious: 0, distanceFromStart: 0, bearing: 0,
                       isStart: index == 0, isDestination: index == count - 1)
    }

    private func makeSegment(groups: [PlanRouteProfileGroup]) -> PlanRouteSegment {
        PlanRouteSegment(index: 0, groups: groups, routed: true, multiMode: groups.count > 1,
                         singleMode: groups.count == 1 ? groups.first?.appMode : nil,
                         distance: groups.reduce(0) { $0 + $1.distance }, isPendingEmpty: false, gapAfter: nil)
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

private final class PlanRouteProfileTestDataSource: PlanRoutePointsDataSource {
    var routeSegments: [PlanRouteSegment] = []
    var defaultMode: OAApplicationMode?
    var appliedPointIndexes: [Int] = []
    var appliedContext: SegmentRouteContext?
    var appliedMode: OAApplicationMode?
    var onMove: ((Int, Int) -> Void)?
    var editedPointAction: String?
    var routeInfo: PlanRouteInfo { fatalError("Route info is not used by these tests") }
    var pendingEmptySegmentIndex: Int? { nil }
    var isTrackReadyToCalculate: Bool { true }
    var isApproximationNeeded: Bool { false }
    var shouldRequestApproximationBeforeNavigation: Bool { false }
    var shouldShowApproximationWarning: Bool { false }
    var approximationWarningViewController: UIViewController? { nil }
    var canStartNewSegment: Bool { false }
    var availableModes: [OAApplicationMode] { [OAApplicationMode.bicycle(), OAApplicationMode.pedestrian(), OAApplicationMode.car()].compactMap { $0 } }

    func moveRoutePoint(from: Int, to: Int) { onMove?(from, to) }
    func applyMode(_ mode: OAApplicationMode, pointIndexes: [Int]) {
        appliedMode = mode
        appliedPointIndexes = pointIndexes
    }
    func applyModeToContext(_ mode: OAApplicationMode?, context: SegmentRouteContext) { appliedContext = context }
    func addRoutePoint() {}
    func undo() {}
    func redo() {}
    func reverseRoute() {}
    func clearAllPoints() {}
    func moveSegment(from srcIdx: Int, to dstIdx: Int) {}
    func deleteRoutePoint(at index: Int) {}
    func deleteSegment(pointIndexes: [Int]) {}
    func startNewSegment() {}
    func startNewSegment(mode: OAApplicationMode?) {}
    func continueRoute(mode: OAApplicationMode?) {}
    func applyMode(_ mode: OAApplicationMode, pointIndex: Int, wholeRoute: Bool) {}
    func sortDoorToDoor(pointIndexes: [Int]) {}
    func saveSegment(pointIndexes: [Int], fileName: String, showOnMap: Bool, onComplete: @escaping (Bool, String?) -> Void) {}
    func selectRoutePoint(at index: Int) {}
    func showPointOptions(at index: Int) {}
    func addPointBefore(index: Int) { editedPointAction = "addBefore:\(index)" }
    func addPointAfter(index: Int) { editedPointAction = "addAfter:\(index)" }
    func trimBefore(index: Int) { editedPointAction = "trimBefore:\(index)" }
    func trimAfter(index: Int) { editedPointAction = "trimAfter:\(index)" }
    func refreshRoute(for mode: OAApplicationMode) {}
}
