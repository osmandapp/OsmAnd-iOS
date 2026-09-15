import XCTest

final class TravelRouteIdentityTests: XCTestCase {
    func testSignedOsmRouteIdsAndBounds() {
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "O7700604"), 7700604)
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "O+1"), 1)
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "O-1"), -1)
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "O9223372036854775807"), Int64.max)
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "O-9223372036854775808"), Int64.min)
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "O9223372036854775808"), 0)
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "O-9223372036854775809"), 0)
    }

    func testAndroidPrefixReplacementSemantics() {
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "O1O2"), 12)
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "OO12"), 12)
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "OSM7700604"), 0)
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "O١٢"), 12)
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "O１２"), 12)
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "O𝟙"), 0)
        XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: "O²"), 0)
    }

    func testInvalidAndAbsentRouteIds() {
        let invalidIds: [String?] = [nil, "", "O", "O0", "o1", "123", "OSM", "O+", "O 1", "O1 ", "O1.0", "O--1"]
        for routeId in invalidIds {
            XCTAssertEqual(TravelRouteIdentity.osmRouteId(from: routeId), 0, routeId ?? "nil")
        }
    }

    func testRouteIdIsRequiredForEveryCandidate() {
        XCTAssertFalse(TravelRouteIdentity.isTravelGpx(tags: [:]))
        XCTAssertFalse(TravelRouteIdentity.isTravelGpx(tags: ["route": "segment"]))
        XCTAssertFalse(TravelRouteIdentity.isTravelGpx(tags: ["route_type": "hiking"]))
        XCTAssertFalse(TravelRouteIdentity.isTravelGpx(tags: ["route": "segment", "route_type": "hiking"]))
        XCTAssertFalse(TravelRouteIdentity.isTravelGpx(tags: ["route_id": "O1"]))
        XCTAssertFalse(TravelRouteIdentity.isTravelGpx(tags: ["route_id": "O1", "route": "hiking"]))
        XCTAssertTrue(TravelRouteIdentity.isTravelGpx(tags: ["route_id": "O1", "route": "segment"]))
        XCTAssertTrue(TravelRouteIdentity.isTravelGpx(tags: ["route_id": "collection", "route_type": "hiking"]))
        XCTAssertTrue(TravelRouteIdentity.isTravelGpx(tags: ["route_id": "", "route_type": ""]))
    }

    func testFirstMatchingSubtypeInOriginalOrder() {
        XCTAssertEqual(TravelRouteIdentity.routeType(from: "routes_hiking"), "hiking")
        XCTAssertEqual(TravelRouteIdentity.routeType(from: "route_track;routes_hiking;routes_cycling"), "hiking")
        XCTAssertEqual(TravelRouteIdentity.routeType(from: ";routes_cycling;routes_hiking;"), "cycling")
        XCTAssertEqual(TravelRouteIdentity.routeType(from: "routes_routes_hiking"), "hiking")
        XCTAssertEqual(TravelRouteIdentity.routeType(from: "routes_;routes_hiking"), "")
        XCTAssertNil(TravelRouteIdentity.routeType(from: nil))
        XCTAssertNil(TravelRouteIdentity.routeType(from: ""))
        XCTAssertNil(TravelRouteIdentity.routeType(from: "route_track; Routes_hiking; routes_hiking"))
    }
}
