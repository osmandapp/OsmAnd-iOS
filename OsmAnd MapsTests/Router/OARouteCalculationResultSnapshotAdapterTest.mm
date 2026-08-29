//
//  OARouteCalculationResultSnapshotAdapterTest.mm
//  OsmAnd MapsTests
//

#import <XCTest/XCTest.h>

#import "OAAlarmInfo.h"
#import "OAAppSettings.h"
#import "OALocationSimulation.h"
#import "OARouteCalculationResult.h"
#import "OARouteCalculationResultSnapshotAdapter.h"
#import "OARouteDirectionInfo.h"
#import "OsmAndSharedWrapper.h"

#include <binaryRead.h>
#include <routeSegmentResult.h>
#include <turnType.h>

@interface OARouteCalculationResultSnapshotAdapterTest : XCTestCase

@end

@implementation OARouteCalculationResultSnapshotAdapterTest

- (void)testCopiesLegacyRouteDetailsWithoutRecalculatingThem
{
    NSDate *timestamp = [NSDate dateWithTimeIntervalSince1970:12];
    CLLocation *rawFirst = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(51.5, -0.1)
                                                        altitude:123
                                              horizontalAccuracy:2
                                                verticalAccuracy:3
                                                          course:0
                                                           speed:4.5
                                                       timestamp:timestamp];
    OALocation *first = [[OALocation alloc] initWithProvider:@"pnt" location:rawFirst];
    CLLocation *last = [[CLLocation alloc] initWithLatitude:51.6 longitude:-0.2];

    std::shared_ptr<TurnType> turn = TurnType::ptrValueOf(TurnType::TL, false);
    turn->setTurnAngle(91.5f);
    turn->setPossibleLeftTurn(true);
    turn->setLanes({3, 5});
    OARouteDirectionInfo *direction = [[OARouteDirectionInfo alloc] initWithAverageSpeed:4 turnType:turn];
    direction.routePointOffset = 0;
    direction.routeEndPointOffset = 1;
    direction.distance = 100;
    direction.afterLeftTime = 30;
    direction.streetName = @"Road";
    direction.ref = @"A1";
    direction.destinationName = @"Center";
    direction.destinationRef = @"B2";
    direction.exitInfo = [[OASRouteExitInfo alloc] initWithRef:@"7" exitStreetName:@"Exit road"];

    OAAlarmInfo *alarm = [[OAAlarmInfo alloc] initWithType:AIT_TUNNEL locationIndex:1];
    alarm.coordinate = CLLocationCoordinate2DMake(51.55, -0.15);
    alarm.lastLocationIndex = 2;
    alarm.intValue = 7;
    alarm.floatValue = 42.5f;

    std::shared_ptr<RoutingIndex> region = std::make_shared<RoutingIndex>();
    region->routeEncodingRules.push_back(RouteTypeRule("highway", "primary"));
    region->routeEncodingRules.push_back(RouteTypeRule("surface", "asphalt"));
    std::shared_ptr<RouteDataObject> road = std::make_shared<RouteDataObject>(region);
    road->id = 1234;
    road->types = {0, 1};
    road->pointsX = {1, 2};
    road->pointsY = {3, 4};
    road->heightDistanceArray = {0, 10, 100, 20};
    std::shared_ptr<RouteSegmentResult> segment = std::make_shared<RouteSegmentResult>(road, 0, 1);
    segment->distance = 100;
    segment->segmentTime = 25;
    segment->segmentSpeed = 4;
    std::vector<std::shared_ptr<RouteSegmentResult>> segments = {segment, segment};
    OASRouteDetailsSnapshot *snapshot = [OARouteCalculationResultSnapshotAdapter
        createWithLocations:@[first, last]
        directions:@[direction]
        segments:segments
        alarms:@[alarm]
        listDistance:@[@100, @0]
        intermediateDirectionIndexes:@[@0]
        profileId:@"car"
        routeProvider:@(STRAIGHT)
        routingTime:1.25f
        initialCalculation:YES
        currentRoutePointIndex:0
        currentDirectionIndex:0
        nextIntermediateIndex:0];

    XCTAssertEqual(snapshot.schemaVersion, OASRouteDetailsSnapshot.companion.CURRENT_SCHEMA_VERSION);
    XCTAssertEqual(snapshot.points.count, 2);
    XCTAssertEqualWithAccuracy(snapshot.points[0].location.latitude, 51.5, 0.000001);
    XCTAssertEqual(snapshot.points[0].distanceToFinishMeters, 100);
    XCTAssertEqualWithAccuracy(snapshot.points[0].altitudeMeters.doubleValue, 123, 0.001);
    XCTAssertEqualWithAccuracy(snapshot.points[0].speedMetersPerSecond.floatValue, 4.5, 0.001);
    XCTAssertEqual(snapshot.points[0].timeMillis, 12000);
    XCTAssertEqualObjects(snapshot.points[0].provider, @"pnt");
    XCTAssertNil(snapshot.points[1].altitudeMeters);
    XCTAssertNil(snapshot.points[1].speedMetersPerSecond);

    XCTAssertEqual(snapshot.segments.count, 1);
    XCTAssertEqual(snapshot.segments[0].routePointStartIndex, 0);
    XCTAssertEqual(snapshot.segments[0].routePointEndIndex, 1);
    XCTAssertEqual(snapshot.segments[0].roadId, 1234);
    XCTAssertEqualObjects(snapshot.segments[0].highway, @"primary");
    XCTAssertEqual(snapshot.segments[0].routeTypes.count, 2);
    XCTAssertEqualObjects(snapshot.segments[0].routeTypes[0].tag, @"highway");
    XCTAssertEqualObjects(snapshot.segments[0].routeTypes[1].tag, @"surface");
    XCTAssertEqual(snapshot.segments[0].heightValues.count, 4);
    XCTAssertEqualWithAccuracy(snapshot.segments[0].heightValues[3].floatValue, 20, 0.001);

    XCTAssertEqual(snapshot.maneuvers.count, 1);
    OASRouteManeuver *maneuver = snapshot.maneuvers.firstObject;
    XCTAssertEqual(maneuver.turnTypeValue, TurnType::TL);
    XCTAssertEqual(maneuver.expectedTimeSeconds, 25);
    XCTAssertEqual(maneuver.afterLeftTimeSeconds, 30);
    XCTAssertEqualWithAccuracy(maneuver.turnAngleDegrees, 91.5, 0.001);
    XCTAssertTrue(maneuver.possibleLeftTurn);
    XCTAssertEqual(maneuver.lanes.count, 2);
    XCTAssertEqual(maneuver.lanes[0].intValue, 3);
    XCTAssertEqualObjects(maneuver.exitInfo.ref, @"7");

    XCTAssertEqual(snapshot.events.count, 1);
    XCTAssertEqual(snapshot.events.firstObject.type, OASRouteEventType.tunnel);
    XCTAssertEqual(snapshot.events.firstObject.lastLocationIndex, 2);
    XCTAssertEqual(snapshot.events.firstObject.intValue, 7);
    XCTAssertEqualWithAccuracy(snapshot.events.firstObject.floatValue, 42.5, 0.001);

    XCTAssertEqual(snapshot.summary.totalDistanceMeters, 100);
    XCTAssertEqual(snapshot.summary.totalTimeSeconds, 30);
    XCTAssertEqualObjects(snapshot.summary.profileId, @"car");
    XCTAssertEqual(snapshot.summary.routeService, OASRouteServiceType.straight);
    XCTAssertEqualWithAccuracy(snapshot.summary.routingTimeSeconds, 1.25, 0.001);
    XCTAssertTrue(snapshot.summary.initialCalculation);
    XCTAssertEqual(snapshot.intermediateRoutePointOffsets.firstObject.intValue, 0);
}

- (void)testMatchesAndroidPointAlignedSegmentRanges
{
    [self assertNativeStart:0 nativeEnd:2 runStart:0 runEnd:2 pointCount:5 expectedStart:0 expectedEnd:2];
    [self assertNativeStart:0 nativeEnd:2 runStart:2 runEnd:5 pointCount:5 expectedStart:2 expectedEnd:4];
    [self assertNativeStart:0 nativeEnd:2 runStart:0 runEnd:3 pointCount:6 expectedStart:0 expectedEnd:2];
    [self assertNativeStart:0 nativeEnd:1 runStart:4 runEnd:5 pointCount:5 expectedStart:3 expectedEnd:4];
}

- (void)testCalculationResultCachesOneEmptySnapshot
{
    OARouteCalculationResult *result = [[OARouteCalculationResult alloc] initWithErrorMessage:@"error"];
    OASRouteDetailsSnapshot *snapshot = result.routeDetailsSnapshot;

    XCTAssertNotNil(snapshot);
    XCTAssertEqual(snapshot, result.routeDetailsSnapshot);
    XCTAssertEqual(snapshot.points.count, 0);
    XCTAssertEqual(snapshot.summary.totalDistanceMeters, 0);
    XCTAssertNil(snapshot.summary.routeService);
}

- (void)assertNativeStart:(int)nativeStart
                nativeEnd:(int)nativeEnd
                 runStart:(int)runStart
                   runEnd:(int)runEnd
               pointCount:(int)pointCount
            expectedStart:(int)expectedStart
              expectedEnd:(int)expectedEnd
{
    int actualStart = -1;
    int actualEnd = -1;
    [OARouteCalculationResultSnapshotAdapter
        routePointRangeWithNativeStartPointIndex:nativeStart
        nativeEndPointIndex:nativeEnd
        runStart:runStart
        runEnd:runEnd
        routePointCount:pointCount
        routePointStartIndexOut:&actualStart
        routePointEndIndexOut:&actualEnd];
    XCTAssertEqual(actualStart, expectedStart);
    XCTAssertEqual(actualEnd, expectedEnd);
}

@end
