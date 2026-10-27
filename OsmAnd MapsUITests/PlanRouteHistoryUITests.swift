import XCTest

final class PlanRouteHistoryUITests: XCTestCase {
    private enum Identifier {
        static let state = "plan_route_test_state"
        static let sheet = "plan_route_sheet"
        static let summary = "plan_route_summary"
        static let points = "plan_route_points"
        static let undo = "plan_route_undo"
        static let redo = "plan_route_redo"
        static let add = "plan_route_add"
        static let close = "plan_route_close"
        static let options = "plan_route_options"
        static let apply = "plan_route_apply"
        static let cancel = "plan_route_cancel"
        static let pointMenu = "plan_route_point_action_menu"

        static func point(_ index: Int) -> String { "plan_route_point_\(index)" }
        static func action(_ key: String) -> String { "plan_route_point_action_" + key }
    }

    private let app = XCUIApplication()
    private let timeout: TimeInterval = 15

    private var visibleMapFrame: CGRect {
        let top = element(Identifier.close).frame.maxY + 12
        return CGRect(x: 0, y: top, width: app.frame.width, height: element(Identifier.sheet).frame.minY - top)
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .portrait
        app.launchArguments = ["-ui-testing", "-ui-testing-plan-route-history", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
    }

    override func tearDownWithError() throws {
        if let testRun, testRun.failureCount > 0 {
            attachEvidence("Failure")
        }
        app.terminate()
    }

    func testTP01TrimBeforeRemovesLinesThroughUndoRedoAndMapGestures() throws {
        try verifyTrim(before: true)
    }

    func testTP02TrimAfterRemovesLinesThroughUndoRedoAndMapGestures() throws {
        try verifyTrim(before: false)
    }

    func testTP03SuccessiveTrimsKeepIndependentSnapshots() throws {
        let original = try launchFixture()
        let six = Array(original.positions.suffix(6))
        let four = Array(original.positions.suffix(4))
        try pointAction("trim_before", at: 2)
        try assertRoute(six)
        try pointAction("trim_before", at: 2)
        try assertRoute(four)
        try history(Identifier.undo, expecting: six)
        try history(Identifier.undo, expecting: original.positions)
        try history(Identifier.redo, expecting: six)
        try history(Identifier.redo, expecting: four)
        for _ in 0..<3 {
            try history(Identifier.undo, expecting: six)
            try history(Identifier.redo, expecting: four)
        }
        try panAndZoom(expecting: four)
    }

    func testTP04TrimBeforeAndAfterWithOneAddition() throws {
        for before in [true, false] {
            try verifyTrimHistory(before: before, additions: 1)
        }
    }

    func testTP05TrimBeforeAndAfterWithThreeAdditions() throws {
        for before in [true, false] {
            try verifyTrimHistory(before: before, additions: 3)
        }
    }

    func testTP06TrimBeforeAndAfterWithTwoAdditions() throws {
        for before in [true, false] {
            try verifyTrimHistory(before: before, additions: 2)
        }
    }

    func testTP07DeleteAndInsertPreservesSuffixAndLineColor() throws {
        let original = try launchFixture(withGeometry: true)
        let prefix = try geometry(original, retaining: Array(original.positions.prefix(3)))[0]
        let suffix = try geometry(original, retaining: Array(original.positions.suffix(4)))[0]
        XCTAssertGreaterThan(prefix.count, 3)
        XCTAssertGreaterThan(suffix.count, 4)
        var deleted = original.positions
        deleted.remove(at: 3)
        let deletedGeometry = [prefix + suffix]
        try pointAction("delete_point", at: 3)
        try assertRoute(deleted, geometry: deletedGeometry)
        try pointAction("add_before", at: 3)
        try moveCrosshair()
        try tap(element(Identifier.apply))
        let inserted = try waitForPointCount(8)
        XCTAssertEqual(Array(inserted.positions.prefix(3)), Array(original.positions.prefix(3)))
        XCTAssertEqual(Array(inserted.positions.suffix(4)), Array(original.positions.suffix(4)))
        XCTAssertFalse(original.positions.contains(inserted.positions[3]))
        XCTAssertEqual(inserted.lines.map(\.color), original.lines.map(\.color))
        let insertedGeometry = [prefix + [inserted.positions[3]] + suffix]
        try assertRoute(inserted.positions, geometry: insertedGeometry)
        try history(Identifier.undo, expecting: deleted, geometry: deletedGeometry)
        try history(Identifier.redo, expecting: inserted.positions, geometry: insertedGeometry)
        try panAndZoom(expecting: inserted.positions, geometry: insertedGeometry)
    }

    func testTP08AddOneMoreApplyCommitsThreeInsertions() throws {
        try verifyMultipleInsertion(applyLast: true)
    }

    func testTP08AddOneMoreCancelKeepsOnlyCommittedInsertions() throws {
        try verifyMultipleInsertion(applyLast: false)
    }

    func testTP09DeleteEndpointUndoRestoresExactlyTheOriginalGap() throws {
        let original = try launchFixture()
        try pointAction("split_after", at: 3)
        try assertRoute(original.positions, gaps: [3])
        var deleted = original.positions
        deleted.remove(at: 3)
        try pointAction("delete_point", at: 3)
        try assertRoute(deleted, gaps: [2])
        try history(Identifier.undo, expecting: original.positions, gaps: [3])
        for _ in 0..<3 {
            try history(Identifier.redo, expecting: deleted, gaps: [2])
            try history(Identifier.undo, expecting: original.positions, gaps: [3])
        }
        try panAndZoom(expecting: original.positions, gaps: [3])
    }

    func testTP10TrimAndClearUndoRestoreDetailedGeometryRepeatedly() throws {
        let original = try launchFixture(withGeometry: true)
        let retained = Array(original.positions.suffix(4))
        let trimmedGeometry = try geometry(original, retaining: retained)
        try pointAction("trim_before", at: 4)
        try assertRoute(retained, geometry: trimmedGeometry)
        for _ in 0..<4 {
            try history(Identifier.undo, expecting: original.positions, geometry: original.geometry)
            try history(Identifier.redo, expecting: retained, geometry: trimmedGeometry)
        }
        try history(Identifier.undo, expecting: original.positions, geometry: original.geometry)
        try menuAction("Clear all points")
        try tap(app.buttons["Clear"].firstMatch)
        try assertRoute([])
        for _ in 0..<2 {
            try history(Identifier.undo, expecting: original.positions, geometry: original.geometry)
            try history(Identifier.redo, expecting: [])
        }
        try history(Identifier.undo, expecting: original.positions, geometry: original.geometry)
    }

    func testTP11ReverseUndoRestoresGeometryAndSavedCopy() throws {
        let original = try launchFixture(withGeometry: true)
        try menuAction("Reverse route")
        let reversed = Array(original.positions.reversed())
        try waitForPositions(reversed)
        for _ in 0..<3 {
            try history(Identifier.undo, expecting: original.positions, geometry: original.geometry)
            try tap(element(Identifier.redo))
            try waitForPositions(reversed)
        }
        try history(Identifier.undo, expecting: original.positions, geometry: original.geometry)
        try saveAndReopen(expecting: original.positions, geometry: original.geometry)
    }

    func testTP12JoinFromFirstSegmentEndRestoresGapAndGeometry() throws {
        try verifyJoin(at: 3)
    }

    func testTP13JoinFromSecondSegmentStartRemainsAvailableAfterHistory() throws {
        try verifyJoin(at: 4)
    }

    func testTP14OnePointAndEmptyRouteNeverKeepOldLines() throws {
        let original = try launchFixture()
        let one = Array(original.positions.prefix(1))
        try pointAction("trim_after", at: 0)
        try assertRoute(one)
        try pointAction("delete_point", at: 0)
        try assertRoute([])
        try history(Identifier.undo, expecting: one)
        try history(Identifier.undo, expecting: original.positions)
        try history(Identifier.redo, expecting: one)
        try history(Identifier.redo, expecting: [])
        try panAndZoom(expecting: [])
    }

    func testTP15SaveCopyAfterRedoTrimKeepsOnlyRetainedGeometry() throws {
        let original = try launchFixture(withGeometry: true)
        let retained = Array(original.positions.suffix(4))
        let trimmedGeometry = try geometry(original, retaining: retained)
        try pointAction("trim_before", at: 4)
        try assertRoute(retained, geometry: trimmedGeometry)
        try history(Identifier.undo, expecting: original.positions, geometry: original.geometry)
        try history(Identifier.redo, expecting: retained, geometry: trimmedGeometry)
        try saveAndReopen(expecting: retained, geometry: trimmedGeometry)
    }

    func testTP16MapTapsDuringMoveDoNotCreateHistoryEntries() throws {
        let original = try launchFixture()
        try pointAction("move_point", at: 2)
        XCTAssertTrue(element(Identifier.apply).waitForExistence(timeout: timeout))
        var boundaryPosition: CGPoint?
        for _ in 0..<6 {
            let state = try snapshot()
            let point = try XCTUnwrap(state.points.first { $0.name == "P6" })
            if let coordinates = point.screenPosition, coordinates.count == 2 {
                let position = CGPoint(x: coordinates[0], y: coordinates[1])
                if visibleMapFrame.insetBy(dx: 24, dy: 24).contains(position) {
                    boundaryPosition = position
                    break
                }
            }
            try tap(app.buttons["Zoom Out"].firstMatch)
        }
        let position = try XCTUnwrap(boundaryPosition, "P6 must be visible before tapping near it during Move")
        for offset in [-4.0, 0.0, 4.0] {
            app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: position.x + offset, dy: position.y)).tap()
            XCTAssertTrue(element(Identifier.apply).exists)
            XCTAssertFalse(element(Identifier.pointMenu).exists)
        }
        mapCoordinate(x: 0.15, y: 0.7).tap()
        XCTAssertTrue(element(Identifier.apply).exists)
        try tap(element(Identifier.cancel))
        try assertRoute(original.positions)
        XCTAssertFalse(element(Identifier.undo).isEnabled)
        XCTAssertFalse(element(Identifier.redo).isEnabled)
        let appended = try appendPoint(to: original.positions)
        try history(Identifier.undo, expecting: original.positions)
        try history(Identifier.redo, expecting: appended)
        try history(Identifier.undo, expecting: original.positions)
        XCTAssertFalse(element(Identifier.undo).isEnabled)
    }

    func testTP17NewRouteUndoRedoAndDiscard() throws {
        app.launchEnvironment.removeValue(forKey: "OSMAND_UI_TEST_PLAN_ROUTE_GPX")
        app.launch()
        XCTAssertTrue(element(Identifier.state).waitForExistence(timeout: 60))
        try assertRoute([])
        var points: [[Int]] = []
        for _ in 0..<3 {
            points = try appendPoint(to: points)
        }
        let two = Array(points.prefix(2))
        try history(Identifier.undo, expecting: two)
        try history(Identifier.redo, expecting: points)
        try history(Identifier.undo, expecting: two)
        try tap(element(Identifier.close))
        try tap(app.buttons["Discard"].firstMatch)
        XCTAssertTrue(element(Identifier.state).waitForNonExistence(timeout: timeout))
        XCTAssertTrue(element(Identifier.sheet).waitForNonExistence(timeout: timeout))
        XCTAssertEqual(app.state, .runningForeground)
    }

    private func launchFixture(withGeometry: Bool = false) throws -> PlanRouteHistorySnapshot {
        app.terminate()
        app.launchEnvironment["OSMAND_UI_TEST_PLAN_ROUTE_GPX"] = PlanRouteHistoryFixture.gpx(withGeometry: withGeometry)
        app.launch()
        XCTAssertTrue(element(Identifier.state).waitForExistence(timeout: 60))
        let initial = try waitForPointCount(8)
        XCTAssertEqual(initial.points.map(\.name), (1...8).map { "P\($0)" })
        XCTAssertEqual(Set(initial.positions).count, 8)
        XCTAssertFalse(element(Identifier.undo).isEnabled)
        XCTAssertFalse(element(Identifier.redo).isEnabled)
        if withGeometry {
            XCTAssertEqual(initial.lines.count, 1)
            XCTAssertGreaterThan(initial.lines[0].positions.count, initial.points.count)
        } else {
            try assertRoute(initial.positions)
        }
        attachEvidence("Initial fixture")
        return initial
    }

    private func verifyTrim(before: Bool) throws {
        let original = try launchFixture()
        let retained = before ? Array(original.positions.suffix(4)) : Array(original.positions.prefix(4))
        try pointAction(before ? "trim_before" : "trim_after", at: before ? 4 : 3)
        try assertRoute(retained)
        try panAndZoom(expecting: retained)
        try history(Identifier.undo, expecting: original.positions)
        try history(Identifier.redo, expecting: retained)
        try panAndZoom(expecting: retained)
    }

    private func verifyTrimHistory(before: Bool, additions: Int) throws {
        let original = try launchFixture()
        let retained = before ? Array(original.positions.suffix(4)) : Array(original.positions.prefix(4))
        try pointAction(before ? "trim_before" : "trim_after", at: before ? 4 : 3)
        try assertRoute(retained)
        var states = [retained]
        for _ in 0..<additions {
            states.append(try appendPoint(to: XCTUnwrap(states.last)))
        }
        for state in states.dropLast().reversed() {
            try history(Identifier.undo, expecting: state)
        }
        try history(Identifier.undo, expecting: original.positions)
        for state in states {
            try history(Identifier.redo, expecting: state)
        }
        let final = states[states.count - 2]
        try history(Identifier.undo, expecting: final)
        try panAndZoom(expecting: final)
    }

    private func verifyMultipleInsertion(applyLast: Bool) throws {
        let original = try launchFixture()
        var states = [original.positions]
        try pointAction("add_before", at: 3)
        for addition in 1...2 {
            try moveCrosshair()
            try tap(app.staticTexts["Add one more point"].firstMatch)
            let committed = try waitForState(allowEditing: true) { $0.points.count == original.points.count + addition }
            let previous = try XCTUnwrap(states.last)
            XCTAssertEqual(committed.positions.filter { previous.contains($0) }, previous)
            XCTAssertEqual(Array(committed.positions.prefix(3)), Array(original.positions.prefix(3)))
            XCTAssertEqual(Array(committed.positions.suffix(5)), Array(original.positions.suffix(5)))
            states.append(committed.positions)
        }
        try moveCrosshair()
        try tap(element(applyLast ? Identifier.apply : Identifier.cancel))
        let count = applyLast ? 11 : 10
        let inserted = try waitForPointCount(count)
        XCTAssertEqual(Array(inserted.positions.prefix(3)), Array(original.positions.prefix(3)))
        XCTAssertEqual(Array(inserted.positions.suffix(5)), Array(original.positions.suffix(5)))
        XCTAssertEqual(Set(inserted.positions).count, count)
        let previous = try XCTUnwrap(states.last)
        if applyLast {
            XCTAssertEqual(inserted.positions.filter { previous.contains($0) }, previous)
            states.append(inserted.positions)
        } else {
            XCTAssertEqual(inserted.positions, previous)
        }
        try assertRoute(inserted.positions)
        for expected in states.dropLast().reversed() {
            try history(Identifier.undo, expecting: expected)
        }
        if applyLast {
            for expected in states.dropFirst() {
                try history(Identifier.redo, expecting: expected)
            }
        }
    }

    private func verifyJoin(at index: Int) throws {
        let original = try launchFixture(withGeometry: true)
        let first = try geometry(original, retaining: Array(original.positions.prefix(4)))
        let second = try geometry(original, retaining: Array(original.positions.suffix(4)))
        let splitGeometry = first + second
        try pointAction("split_after", at: 3)
        try assertRoute(original.positions, gaps: [3], geometry: splitGeometry)
        try pointAction("join_segments", at: index)
        try assertJoined(original.positions, first: first[0], second: second[0])
        for _ in 0..<4 {
            try history(Identifier.undo, expecting: original.positions, gaps: [3], geometry: splitGeometry)
            try tap(element(Identifier.redo))
            try assertJoined(original.positions, first: first[0], second: second[0])
        }
        try history(Identifier.undo, expecting: original.positions, gaps: [3], geometry: splitGeometry)
        try openPoint(index)
        XCTAssertTrue(element(Identifier.action("join_segments")).waitForExistence(timeout: timeout))
        attachEvidence("Join remains available at boundary \(index)")
        try tap(app.buttons["Cancel"].firstMatch)
        try panAndZoom(expecting: original.positions, gaps: [3], geometry: splitGeometry)
    }

    private func assertJoined(_ positions: [[Int]], first: [[Int]], second: [[Int]]) throws {
        let state = try waitForState { $0.positions == positions && $0.gaps.isEmpty && $0.lines.count == 1 }
        XCTAssertEqual(state.gaps, [])
        XCTAssertEqual(state.lines.count, 1)
        let line = try XCTUnwrap(state.lines.first)
        XCTAssertEqual(Array(line.positions.prefix(first.count)), first)
        XCTAssertEqual(Array(line.positions.suffix(second.count)), second)
    }

    private func saveAndReopen(expecting positions: [[Int]], geometry: [[[Int]]]) throws {
        try menuAction("Save as copy")
        let nameField = app.textViews.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: timeout))
        let name = try XCTUnwrap(nameField.value as? String)
        XCTAssertTrue(name.hasPrefix("UITest-5782-source-"))
        let save = try XCTUnwrap(app.buttons.matching(identifier: "Save").allElementsBoundByIndex.first { $0.isHittable })
        try tap(save)
        XCTAssertTrue(element(Identifier.state).waitForNonExistence(timeout: timeout))
        try tap(app.buttons["Open saved track"].firstMatch)
        try tap(app.buttons["Actions"].firstMatch)
        let edit = app.staticTexts["Edit track"].firstMatch
        try reveal(edit, in: app.tables.firstMatch)
        try tap(edit)
        XCTAssertTrue(element(Identifier.state).waitForExistence(timeout: timeout))
        try assertRoute(positions, geometry: geometry)
        XCTAssertTrue(app.staticTexts[name].firstMatch.exists)
        attachEvidence("Saved copy reopened: " + name)
    }

    private func element(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: identifier).firstMatch
    }

    private func tap(_ target: XCUIElement) throws {
        let predicate = NSPredicate(format: "exists == true AND hittable == true AND enabled == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: target)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed, "Unavailable control: \(target)")
        target.tap()
    }

    private func reveal(_ target: XCUIElement, in table: XCUIElement, anchor: XCUIElement? = nil) throws {
        XCTAssertTrue(table.waitForExistence(timeout: timeout))
        for _ in 0..<12 {
            if target.exists && target.isHittable { return }
            let position = anchor ?? target
            let above = position.exists && position.frame.maxY < table.frame.minY + 24
            scroll(table, down: above)
        }
        XCTFail("Could not reveal \(target)")
    }

    private func scroll(_ table: XCUIElement, down: Bool) {
        let frame = table.frame.intersection(app.frame)
        let undo = element(Identifier.undo)
        let bottom = undo.exists ? min(frame.maxY, undo.frame.minY - 12) : min(frame.maxY, app.frame.maxY - 80)
        let top = frame.minY + 24
        XCTAssertGreaterThan(bottom - top, 40)
        let origin = app.coordinate(withNormalizedOffset: .zero)
        let inset = (bottom - top) * 0.2
        let upper = origin.withOffset(CGVector(dx: frame.midX, dy: top + inset))
        let lower = origin.withOffset(CGVector(dx: frame.midX, dy: bottom - inset))
        if down {
            upper.press(forDuration: 0.1, thenDragTo: lower, withVelocity: .slow, thenHoldForDuration: 0.2)
        } else {
            lower.press(forDuration: 0.1, thenDragTo: upper, withVelocity: .slow, thenHoldForDuration: 0.2)
        }
    }

    private func openPoint(_ index: Int) throws {
        let table = element(Identifier.points)
        if !table.isHittable {
            try tap(element(Identifier.summary))
        }
        XCTAssertTrue(table.waitForExistence(timeout: timeout))
        for _ in 0..<12 {
            if element(Identifier.point(0)).isHittable { break }
            scroll(table, down: true)
        }
        let point = element(Identifier.point(index))
        let cell = table.cells.containing(.staticText, identifier: Identifier.point(index)).firstMatch
        try reveal(point, in: table, anchor: cell)
        try tap(point)
        XCTAssertTrue(element(Identifier.pointMenu).waitForExistence(timeout: timeout))
    }

    private func pointAction(_ key: String, at index: Int) throws {
        try openPoint(index)
        let action = element(Identifier.action(key))
        try reveal(action, in: element(Identifier.pointMenu))
        try tap(action)
        XCTAssertTrue(element(Identifier.pointMenu).waitForNonExistence(timeout: timeout))
    }

    private func menuAction(_ title: String) throws {
        try tap(element(Identifier.options))
        try tap(app.buttons[title].firstMatch)
    }

    private func mapCoordinate(x: Double, y: Double) -> XCUICoordinate {
        let frame = visibleMapFrame
        XCTAssertGreaterThan(frame.height, 60, "The sheet must leave map space for the gesture")
        return app.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: frame.width * x, dy: frame.minY + frame.height * y))
    }

    private func moveCrosshair() throws {
        let from = mapCoordinate(x: 0.6, y: 0.45)
        let to = mapCoordinate(x: 0.35, y: 0.3)
        from.press(forDuration: 0.05, thenDragTo: to)
    }

    private func appendPoint(to points: [[Int]]) throws -> [[Int]] {
        try moveCrosshair()
        try tap(element(Identifier.add))
        let state = try waitForPointCount(points.count + 1)
        XCTAssertEqual(Array(state.positions.dropLast()), points)
        XCTAssertEqual(Set(state.positions).count, state.positions.count)
        try assertRoute(state.positions)
        return state.positions
    }

    private func history(_ identifier: String, expecting points: [[Int]], gaps: [Int] = [], geometry: [[[Int]]]? = nil) throws {
        try tap(element(identifier))
        try assertRoute(points, gaps: gaps, geometry: geometry)
    }

    private func panAndZoom(expecting points: [[Int]], gaps: [Int] = [], geometry: [[[Int]]]? = nil) throws {
        let target = try snapshot().viewport.target
        try moveCrosshair()
        try assertRoute(points, gaps: gaps, geometry: geometry)
        XCTAssertNotEqual(try snapshot().viewport.target, target)
        let originalZoom = try snapshot().viewport.zoom
        try tap(app.buttons["Zoom Out"].firstMatch)
        try assertRoute(points, gaps: gaps, geometry: geometry)
        let zoomedOut = try snapshot().viewport.zoom
        XCTAssertLessThan(zoomedOut, originalZoom)
        try tap(app.buttons["Zoom In"].firstMatch)
        try assertRoute(points, gaps: gaps, geometry: geometry)
        XCTAssertGreaterThan(try snapshot().viewport.zoom, zoomedOut)
        attachEvidence("After pan and zoom")
    }

    private func snapshot() throws -> PlanRouteHistorySnapshot {
        let value = try XCTUnwrap(element(Identifier.state).value as? String)
        return try JSONDecoder().decode(PlanRouteHistorySnapshot.self, from: Data(value.utf8))
    }

    private func waitForState(allowEditing: Bool = false, _ predicate: @escaping (PlanRouteHistorySnapshot) -> Bool) throws -> PlanRouteHistorySnapshot {
        let marker = element(Identifier.state)
        let condition = NSPredicate { object, _ in
            guard let target = object as? XCUIElement,
                  let value = target.value as? String,
                  let state = try? JSONDecoder().decode(PlanRouteHistorySnapshot.self, from: Data(value.utf8)) else { return false }
            return !state.calculating && (allowEditing || (!state.editing && state.hasCurrentLastLine)) && predicate(state)
        }
        let expectation = XCTNSPredicateExpectation(predicate: condition, object: marker)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed, "Unexpected route state: \(marker.value ?? "missing")")
        return try snapshot()
    }

    private func waitForPointCount(_ count: Int) throws -> PlanRouteHistorySnapshot {
        try waitForState { $0.points.count == count }
    }

    @discardableResult private func waitForPositions(_ positions: [[Int]]) throws -> PlanRouteHistorySnapshot {
        try waitForState { $0.positions == positions }
    }

    private func assertRoute(_ positions: [[Int]], gaps: [Int] = [], geometry: [[[Int]]]? = nil) throws {
        var expectedLines = geometry
        if expectedLines == nil {
            var segments: [[[Int]]] = []
            var start = 0
            for end in gaps + [positions.count - 1] where end >= start {
                let segment = Array(positions[start...end])
                if segment.count > 1 { segments.append(segment) }
                start = end + 1
            }
            expectedLines = segments
        }
        let state = try waitForState { $0.positions == positions && $0.gaps == gaps && $0.geometry == expectedLines }
        XCTAssertEqual(state.positions, positions)
        XCTAssertEqual(state.gaps, gaps)
        XCTAssertEqual(state.geometry, expectedLines)
        XCTAssertEqual(app.state, .runningForeground)
    }

    private func geometry(_ original: PlanRouteHistorySnapshot, retaining positions: [[Int]]) throws -> [[[Int]]] {
        let line = try XCTUnwrap(original.lines.first)
        let first = try XCTUnwrap(positions.first)
        let last = try XCTUnwrap(positions.last)
        let start = try XCTUnwrap(line.positions.firstIndex(of: first))
        let end = try XCTUnwrap(line.positions.lastIndex(of: last))
        return [Array(line.positions[start...end])]
    }

    private func attachEvidence(_ name: String) {
        let screenshot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        screenshot.name = name
        screenshot.lifetime = .keepAlways
        add(screenshot)
        if name == "Failure", app.state == .runningForeground {
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "Failure accessibility hierarchy"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
        }
        if app.state == .runningForeground,
           element(Identifier.state).exists,
           let value = element(Identifier.state).value as? String {
            let state = XCTAttachment(string: value)
            state.name = name + " renderer state"
            state.lifetime = .keepAlways
            add(state)
        }
    }
}
