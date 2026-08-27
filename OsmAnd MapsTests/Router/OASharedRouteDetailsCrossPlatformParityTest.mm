//
//  OASharedRouteDetailsCrossPlatformParityTest.mm
//  OsmAnd MapsTests
//

#import <XCTest/XCTest.h>

#import "OAAlarmInfo.h"
#import "OALocationPointWrapper.h"
#import "OALocationSimulation.h"
#import "OARouteCalculationResult.h"
#import "OARouteCalculationResultSnapshotAdapter.h"
#import "OARouteDirectionInfo.h"
#import "OARouteStatistics.h"
#import "OARouteStatisticsHelper.h"
#import "OASharedRouteDetailsProvider.h"
#import "OsmAndSharedWrapper.h"

#include <binaryRead.h>
#include <routeSegmentResult.h>
#include <turnType.h>

#include <cstdint>
#include <memory>
#include <vector>

namespace
{

// Values are mirrored from OsmAnd-shared's android_route_details_schema_v1.json fixture.
constexpr float kFixtureDistanceMeters = 111.319f;
constexpr float kFixtureSpeedMetersPerSecond = 11.1319f;

std::shared_ptr<RouteSegmentResult> OAMakeFixtureSegment(void)
{
    std::shared_ptr<RoutingIndex> region = std::make_shared<RoutingIndex>();
    region->routeEncodingRules.push_back(RouteTypeRule("highway", "residential"));
    region->routeEncodingRules.push_back(RouteTypeRule("access", "yes"));
    region->routeEncodingRules.push_back(RouteTypeRule("access", "destination"));

    std::shared_ptr<RouteDataObject> road = std::make_shared<RouteDataObject>(region);
    road->id = 42;
    road->types = {0, 1, 2};
    road->pointsX = {1, 2};
    road->pointsY = {3, 4};
    road->heightDistanceArray = {0, 5, kFixtureDistanceMeters, 6};

    std::shared_ptr<RouteSegmentResult> segment = std::make_shared<RouteSegmentResult>(road, 0, 1);
    segment->distance = kFixtureDistanceMeters;
    segment->segmentTime = 10;
    segment->segmentSpeed = kFixtureSpeedMetersPerSecond;
    return segment;
}

OALocation *OAMakeFixtureLocation(double longitude, double altitude)
{
    CLLocation *location = [[CLLocation alloc]
        initWithCoordinate:CLLocationCoordinate2DMake(0, longitude)
        altitude:altitude
        horizontalAccuracy:1
        verticalAccuracy:1
        course:0
        speed:kFixtureSpeedMetersPerSecond
        timestamp:[NSDate dateWithTimeIntervalSince1970:0]];
    return [[OALocation alloc] initWithProvider:@"" location:location];
}

OARouteDirectionInfo *OAMakeFixtureDirection(int turnType, int routePointOffset)
{
    std::shared_ptr<TurnType> turn = TurnType::ptrValueOf(turnType, false);
    if (turnType == TurnType::TR)
    {
        turn->setTurnAngle(90);
        turn->setLanes({1, 2});
    }
    OARouteDirectionInfo *direction = [[OARouteDirectionInfo alloc]
        initWithAverageSpeed:kFixtureSpeedMetersPerSecond
        turnType:turn];
    direction.routePointOffset = routePointOffset;
    return direction;
}

OAAlarmInfo *OAMakeAlarm(EOAAlarmInfoType type, int locationIndex)
{
    OAAlarmInfo *alarm = [[OAAlarmInfo alloc] initWithType:type locationIndex:locationIndex];
    alarm.coordinate = CLLocationCoordinate2DMake(0, locationIndex * 0.001);
    return alarm;
}

NSDictionary<NSString *, NSNumber *> *OAUndefinedRenderingAttribute(void)
{
    return @{kUndefinedAttr : @(UINT32_MAX)};
}

} // namespace

@interface OASharedRouteDetailsCrossPlatformParityTest : XCTestCase

@end


@implementation OASharedRouteDetailsCrossPlatformParityTest

- (void)testIOSBackendMatchesAndroidFixtureGeometryManeuversAndSnapshotValues
{
    NSArray<CLLocation *> *locations = @[
        OAMakeFixtureLocation(0, 5),
        OAMakeFixtureLocation(0.001, 6),
    ];
    NSArray<NSNumber *> *distances = [OASharedRouteDetailsProvider
        calculateDistancesToFinish:locations];
    XCTAssertEqualObjects(distances, (@[@111, @0]));

    NSArray<OARouteDirectionInfo *> *directions = @[
        OAMakeFixtureDirection(TurnType::C, 0),
        OAMakeFixtureDirection(TurnType::TR, 1),
    ];
    [OASharedRouteDetailsProvider updateDirectionDistancesAndTimes:directions
                                           distanceToFinishMeters:distances];
    XCTAssertEqual(directions[0].distance, 111);
    XCTAssertEqual([directions[0] getExpectedTime], 10);
    XCTAssertEqual(directions[0].afterLeftTime, 10);
    XCTAssertEqual(directions[1].distance, 0);
    XCTAssertEqual([directions[1] getExpectedTime], 0);
    XCTAssertEqual(directions[1].afterLeftTime, 0);

    std::shared_ptr<RouteSegmentResult> segment = OAMakeFixtureSegment();
    std::vector<std::shared_ptr<RouteSegmentResult>> pointAlignedSegments = {segment, segment};
    OAAlarmInfo *stop = OAMakeAlarm(AIT_STOP, 2);
    stop.coordinate = CLLocationCoordinate2DMake(0, 0.001);
    OASRouteDetailsSnapshot *snapshot = [OARouteCalculationResultSnapshotAdapter
        createWithLocations:locations
        directions:directions
        segments:pointAlignedSegments
        alarms:@[stop]
        listDistance:distances
        intermediateDirectionIndexes:@[]
        profileId:@"car"
        routeProvider:@(OSMAND)
        routingTime:0
        initialCalculation:NO
        currentRoutePointIndex:2
        currentDirectionIndex:2
        nextIntermediateIndex:0];

    XCTAssertEqual(snapshot.schemaVersion, OASRouteDetailsSnapshot.companion.CURRENT_SCHEMA_VERSION);
    XCTAssertEqual(snapshot.points.count, 2);
    XCTAssertEqualWithAccuracy(snapshot.points[0].location.latitude, 0, 0.000000001);
    XCTAssertEqualWithAccuracy(snapshot.points[1].location.longitude, 0.001, 0.000000001);
    XCTAssertEqual(snapshot.points[0].distanceToFinishMeters, 111);
    XCTAssertEqual(snapshot.points[1].distanceToFinishMeters, 0);
    XCTAssertEqualWithAccuracy(snapshot.points[0].altitudeMeters.doubleValue, 5, 0.0001);
    XCTAssertEqualWithAccuracy(snapshot.points[1].altitudeMeters.doubleValue, 6, 0.0001);
    XCTAssertEqualWithAccuracy(snapshot.points[0].speedMetersPerSecond.floatValue,
                               kFixtureSpeedMetersPerSecond,
                               0.0001);
    XCTAssertEqual(snapshot.points[0].timeMillis, 0);
    XCTAssertEqualObjects(snapshot.points[0].provider, @"");

    XCTAssertEqual(snapshot.segments.count, 1);
    OASRouteSegment *sharedSegment = snapshot.segments.firstObject;
    XCTAssertEqual(sharedSegment.routePointStartIndex, 0);
    XCTAssertEqual(sharedSegment.routePointEndIndex, 1);
    XCTAssertEqual(sharedSegment.nativeStartPointIndex, 0);
    XCTAssertEqual(sharedSegment.nativeEndPointIndex, 1);
    XCTAssertEqual(sharedSegment.roadId, 42);
    XCTAssertEqualObjects(sharedSegment.highway, @"residential");
    XCTAssertEqualWithAccuracy(sharedSegment.distanceMeters, kFixtureDistanceMeters, 0.001);
    XCTAssertEqualWithAccuracy(sharedSegment.segmentTimeSeconds, 10, 0.001);
    XCTAssertEqualWithAccuracy(sharedSegment.segmentSpeedMetersPerSecond,
                               kFixtureSpeedMetersPerSecond,
                               0.0001);
    XCTAssertEqual(sharedSegment.routeTypes.count, 3);
    XCTAssertEqualObjects(sharedSegment.routeTypes[0].tag, @"highway");
    XCTAssertEqualObjects(sharedSegment.routeTypes[0].value, @"residential");
    XCTAssertEqualObjects(sharedSegment.routeTypes[1].tag, @"access");
    XCTAssertEqualObjects(sharedSegment.routeTypes[1].value, @"yes");
    XCTAssertEqualObjects(sharedSegment.routeTypes[2].tag, @"access");
    XCTAssertEqualObjects(sharedSegment.routeTypes[2].value, @"destination");
    XCTAssertEqual(sharedSegment.heightValues.count, 4);
    XCTAssertEqualWithAccuracy(sharedSegment.heightValues[0].floatValue, 0, 0.001);
    XCTAssertEqualWithAccuracy(sharedSegment.heightValues[1].floatValue, 5, 0.001);
    XCTAssertEqualWithAccuracy(sharedSegment.heightValues[2].floatValue,
                               kFixtureDistanceMeters,
                               0.001);
    XCTAssertEqualWithAccuracy(sharedSegment.heightValues[3].floatValue, 6, 0.001);

    XCTAssertEqual(snapshot.maneuvers.count, 2);
    XCTAssertEqual(snapshot.maneuvers[0].turnTypeValue, TurnType::C);
    XCTAssertEqual(snapshot.maneuvers[0].distanceMeters, 111);
    XCTAssertEqual(snapshot.maneuvers[0].expectedTimeSeconds, 10);
    XCTAssertEqual(snapshot.maneuvers[0].afterLeftTimeSeconds, 10);
    XCTAssertNil(snapshot.maneuvers[0].lanes);
    XCTAssertEqual(snapshot.maneuvers[1].turnTypeValue, TurnType::TR);
    XCTAssertEqualWithAccuracy(snapshot.maneuvers[1].turnAngleDegrees, 90, 0.001);
    XCTAssertEqual(snapshot.maneuvers[1].lanes.count, 2);
    XCTAssertEqual(snapshot.maneuvers[1].lanes[0].intValue, 1);
    XCTAssertEqual(snapshot.maneuvers[1].lanes[1].intValue, 2);

    XCTAssertEqual(snapshot.events.count, 1);
    XCTAssertEqual(snapshot.events.firstObject.type, OASRouteEventType.stop);
    XCTAssertEqual(snapshot.events.firstObject.locationIndex, 2);
    XCTAssertEqual(snapshot.events.firstObject.lastLocationIndex, -1);
    XCTAssertEqual(snapshot.events.firstObject.intValue, 0);
    XCTAssertEqualWithAccuracy(snapshot.events.firstObject.floatValue, 0, 0.001);
    XCTAssertEqualWithAccuracy(snapshot.events.firstObject.location.longitude, 0.001, 0.000000001);
    XCTAssertEqual(snapshot.summary.totalDistanceMeters, 111);
    XCTAssertEqual(snapshot.summary.totalTimeSeconds, 10);
    XCTAssertEqualObjects(snapshot.summary.profileId, @"car");
    XCTAssertEqual(snapshot.summary.routeService, OASRouteServiceType.osmand);
    XCTAssertEqualWithAccuracy(snapshot.summary.routingTimeSeconds, 0, 0.001);
    XCTAssertEqualWithAccuracy(snapshot.summary.calculationTimeSeconds, 0, 0.001);
    XCTAssertEqual(snapshot.summary.visitedSegments, 0);
    XCTAssertEqual(snapshot.summary.loadedTiles, 0);
    XCTAssertFalse(snapshot.summary.initialCalculation);
    // Both platform snapshot adapters intentionally avoid renderer work during route construction;
    // the fixture's deterministic statistics values are verified separately below.
    XCTAssertEqual(snapshot.statistics.count, 0);
    XCTAssertEqual(snapshot.currentRoutePointIndex, 2);
    XCTAssertEqual(snapshot.currentDirectionIndex, 2);
    XCTAssertEqual(snapshot.nextIntermediateIndex, 0);
    XCTAssertEqual(snapshot.intermediateRoutePointOffsets.count, 0);
}

- (void)testIOSStatisticsMatchAndroidFixtureWithDeterministicRendererBoundary
{
    // Live renderer styles remain platform-owned and may differ. A fixed classifier isolates the
    // portable grouping, ordering, color, and distance results required for cross-platform parity.
    __block BOOL defaultRendererCalled = NO;
    OARouteStatisticsComputer *computer = [[OARouteStatisticsComputer alloc]
        initWithCurrentRendererLookup:^NSDictionary<NSString *, NSNumber *> *(
            NSString *attribute, NSDictionary<NSString *, NSString *> *settings) {
            XCTAssertEqualObjects(attribute, @"routeInfo_surface");
            return @{@"asphalt" : @(-1)};
        }
        defaultRendererLookup:^NSDictionary<NSString *, NSNumber *> *(
            NSString *attribute, NSDictionary<NSString *, NSString *> *settings) {
            defaultRendererCalled = YES;
            return OAUndefinedRenderingAttribute();
        }];
    std::vector<std::shared_ptr<RouteSegmentResult>> route = {OAMakeFixtureSegment()};

    NSArray<OARouteStatistics *> *result = [OARouteStatisticsHelper
        calculateRouteStatistic:route
        attributeNames:@[@"routeInfo_surface"]
        statisticsComputer:computer];

    XCTAssertFalse(defaultRendererCalled);
    XCTAssertEqual(result.count, 1);
    OARouteStatistics *statistic = result.firstObject;
    XCTAssertEqualObjects(statistic.name, @"surface");
    XCTAssertEqual(statistic.elements.count, 1);
    XCTAssertEqualObjects(statistic.partition.allKeys, (@[@"asphalt"]));
    OARouteSegmentAttribute *element = statistic.elements.firstObject;
    XCTAssertEqualObjects(element.propertyName, @"asphalt");
    XCTAssertEqualObjects(element.getUserPropertyName, @"asphalt");
    XCTAssertEqual(element.color, -1);
    XCTAssertEqualWithAccuracy(element.distance, kFixtureDistanceMeters, 0.001);
    XCTAssertEqualWithAccuracy(statistic.partition[@"asphalt"].distance,
                               kFixtureDistanceMeters,
                               0.001);
    XCTAssertEqualWithAccuracy(statistic.totalDistance, kFixtureDistanceMeters, 0.001);
}

- (void)testEventOrderingAndTunnelRangeMatchAndroidBackend
{
    OARouteCalculationResult *route = [[OARouteCalculationResult alloc] initWithErrorMessage:@"error"];
    OAAlarmInfo *stop = OAMakeAlarm(AIT_STOP, 2);
    OAAlarmInfo *tunnel = OAMakeAlarm(AIT_TUNNEL, 0);
    tunnel.lastLocationIndex = 2;
    tunnel.intValue = 7;
    tunnel.floatValue = 42.5f;
    OAAlarmInfo *hazard = OAMakeAlarm(AIT_HAZARD, 1);
    [route.alarmInfo addObjectsFromArray:@[stop, tunnel, hazard]];

    NSArray<OALocationPointWrapper *> *result = [OASharedRouteDetailsProvider
        selectAlarmWrappersForRoute:route
        routingAlarmsEnabled:YES
        showCameras:NO
        speakSpeedCameras:NO
        showTunnels:YES
        speakTunnels:NO
        showPedestrian:NO
        speakPedestrian:NO
        showTrafficWarnings:YES
        speakTrafficWarnings:NO];

    XCTAssertEqual(result.count, 3);
    XCTAssertEqual(result[0].point, tunnel);
    XCTAssertEqual(result[1].point, hazard);
    XCTAssertEqual(result[2].point, stop);
    XCTAssertEqual(((OAAlarmInfo *) result[0].point).locationIndex, 0);
    XCTAssertEqual(((OAAlarmInfo *) result[0].point).lastLocationIndex, 2);
    XCTAssertEqual(((OAAlarmInfo *) result[0].point).intValue, 7);
    XCTAssertEqualWithAccuracy(((OAAlarmInfo *) result[0].point).floatValue, 42.5, 0.001);
    XCTAssertFalse(result[0].announce);
    XCTAssertFalse(result[1].announce);
    XCTAssertFalse(result[2].announce);
}

@end
