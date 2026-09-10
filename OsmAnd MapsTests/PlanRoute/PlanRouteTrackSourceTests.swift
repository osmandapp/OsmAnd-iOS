import XCTest

final class PlanRouteTrackSourceTests: XCTestCase {

    private let gpxDirectory = "/Documents/GPX"

    func testPathlessGpxKeepsSourceFilePathSeparateFromEditableFilePath() {
        let sourceFilePath = "\(gpxDirectory)/twisty-route.gpx"
        let source = PlanRouteTrackSource(gpxFilePath: "", sourceFilePath: sourceFilePath)

        XCTAssertNil(source.editableFilePath)
        XCTAssertEqual(source.sourceFilePath, sourceFilePath)
    }

    func testPathlessGpxUsesSourceFilePathForWaypointEditing() {
        let sourceFilePath = "\(gpxDirectory)/twisty-route.gpx"
        let source = PlanRouteTrackSource(gpxFilePath: "", sourceFilePath: sourceFilePath)

        XCTAssertEqual(source.waypointEditingFilePath, sourceFilePath)
    }

    func testPathlessGpxUsesSourceFolderForSaving() {
        let sourceFilePath = "\(gpxDirectory)/import/twisty-route.gpx"
        let source = PlanRouteTrackSource(gpxFilePath: "", sourceFilePath: sourceFilePath)

        XCTAssertEqual(source.savingFolder(relativeTo: gpxDirectory), "import")
    }

    func testGpxInRootFolderHasNoSavingSubfolder() {
        let sourceFilePath = "\(gpxDirectory)/twisty-route.gpx"
        let source = PlanRouteTrackSource(gpxFilePath: sourceFilePath, sourceFilePath: nil)

        XCTAssertNil(source.savingFolder(relativeTo: gpxDirectory))
    }

    func testGpxFilePathIsUsedWhenExplicitSourceFilePathIsMissing() {
        let sourceFilePath = "\(gpxDirectory)/twisty-route.gpx"
        let source = PlanRouteTrackSource(gpxFilePath: sourceFilePath, sourceFilePath: nil)

        XCTAssertEqual(source.editableFilePath, sourceFilePath)
        XCTAssertEqual(source.sourceFilePath, sourceFilePath)
    }

    func testPathlessGpxWithoutSourceFilePathKeepsBothPathsEmpty() {
        let source = PlanRouteTrackSource(gpxFilePath: "", sourceFilePath: nil)

        XCTAssertNil(source.editableFilePath)
        XCTAssertNil(source.sourceFilePath)
        XCTAssertNil(source.waypointEditingFilePath)
        XCTAssertNil(source.savingFolder(relativeTo: gpxDirectory))
    }
}
