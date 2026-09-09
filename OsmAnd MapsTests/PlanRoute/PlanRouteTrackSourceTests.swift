import XCTest

final class PlanRouteTrackSourceTests: XCTestCase {

    func testPathlessGpxKeepsSourceFilePathSeparateFromEditableFilePath() {
        let source = PlanRouteTrackSource(gpxFilePath: "", sourceFilePath: "/Documents/GPX/twisty-route.gpx")

        XCTAssertNil(source.editableFilePath)
        XCTAssertEqual(source.sourceFilePath, "/Documents/GPX/twisty-route.gpx")
    }

    func testPathlessGpxUsesSourceFilePathForWaypointEditing() {
        let source = PlanRouteTrackSource(gpxFilePath: "", sourceFilePath: "/Documents/GPX/twisty-route.gpx")

        XCTAssertEqual(source.waypointEditingFilePath, "/Documents/GPX/twisty-route.gpx")
    }

    func testGpxFilePathIsUsedWhenExplicitSourceFilePathIsMissing() {
        let source = PlanRouteTrackSource(gpxFilePath: "/Documents/GPX/twisty-route.gpx", sourceFilePath: nil)

        XCTAssertEqual(source.editableFilePath, "/Documents/GPX/twisty-route.gpx")
        XCTAssertEqual(source.sourceFilePath, "/Documents/GPX/twisty-route.gpx")
    }

    func testPathlessGpxWithoutSourceFilePathKeepsBothPathsEmpty() {
        let source = PlanRouteTrackSource(gpxFilePath: "", sourceFilePath: nil)

        XCTAssertNil(source.editableFilePath)
        XCTAssertNil(source.sourceFilePath)
        XCTAssertNil(source.waypointEditingFilePath)
    }
}
