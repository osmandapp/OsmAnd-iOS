//
//  OASharedRouteEventBackendCompatibilityTest.mm
//  OsmAnd MapsTests
//

#import <XCTest/XCTest.h>

#import "OAAlarmInfo.h"
#import "OALocationPointWrapper.h"
#import "OARouteCalculationResult.h"
#import "OARouteCalculationResultSnapshotAdapter.h"
#import "OASharedRouteDetailsProvider.h"
#import "OsmAndSharedWrapper.h"

#include <binaryRead.h>

@interface OASharedRouteEventBackendCompatibilityTest : XCTestCase

@end

@implementation OASharedRouteEventBackendCompatibilityTest

- (void)testAllAlarmTypesRoundTripWithoutChangingBackendValues
{
    for (OASRouteEventType *type in OASRouteEventType.entries)
    {
        OAAlarmInfo *source = [self alarmWithType:type
                                           index:7
                                        latitude:51.5
                                       longitude:-0.1];
        source.lastLocationIndex = 9;
        source.intValue = 12;
        source.floatValue = 34.5f;

        OASRouteEvent *event = [OARouteCalculationResultSnapshotAdapter copyEvent:source];
        OAAlarmInfo *result = [OARouteCalculationResultSnapshotAdapter copyAlarmInfo:event];

        XCTAssertNotNil(event);
        XCTAssertNotNil(result);
        XCTAssertEqualObjects(result.type, source.type);
        XCTAssertEqual(result.locationIndex, 7);
        XCTAssertEqual(result.lastLocationIndex, 9);
        XCTAssertEqual(result.intValue, 12);
        XCTAssertEqualWithAccuracy(result.floatValue, 34.5f, 0.001f);
        XCTAssertEqualWithAccuracy(result.coordinate.latitude, 51.5, 0.000001);
        XCTAssertEqualWithAccuracy(result.coordinate.longitude, -0.1, 0.000001);
    }
}

- (void)testCreatesAndroidCompatibleEventsFromRouteTags
{
    NSArray<NSDictionary<NSString *, id> *> *cases = @[
        @{@"tag": @"highway", @"value": @"speed_camera", @"type": OASRouteEventType.speedCamera},
        @{@"tag": @"highway", @"value": @"stop", @"type": OASRouteEventType.stop},
        @{@"tag": @"enforcement", @"value": @"traffic_signals", @"type": OASRouteEventType.redLightCamera},
        @{@"tag": @"barrier", @"value": @"toll_booth", @"type": OASRouteEventType.tollBooth},
        @{@"tag": @"barrier", @"value": @"border_control", @"type": OASRouteEventType.borderControl},
        @{@"tag": @"traffic_calming", @"value": @"bump", @"type": OASRouteEventType.trafficCalming},
        @{@"tag": @"hazard", @"value": @"falling_rocks", @"type": OASRouteEventType.hazard},
        @{@"tag": @"railway", @"value": @"level_crossing", @"type": OASRouteEventType.railway},
        @{@"tag": @"crossing", @"value": @"uncontrolled", @"type": OASRouteEventType.pedestrian},
    ];

    for (NSDictionary<NSString *, id> *testCase in cases)
    {
        OAAlarmInfo *alarm = [OASharedRouteDetailsProvider
            createAlarmInfoWithTag:testCase[@"tag"]
            value:testCase[@"value"]
            locationIndex:7
            latitude:51.5
            longitude:-0.1];

        XCTAssertNotNil(alarm);
        XCTAssertEqualObjects(alarm.type, testCase[@"type"]);
        XCTAssertEqual(alarm.locationIndex, 7);
        XCTAssertEqual(alarm.lastLocationIndex, -1);
        XCTAssertEqualWithAccuracy(alarm.coordinate.latitude, 51.5, 0.000001);
        XCTAssertEqualWithAccuracy(alarm.coordinate.longitude, -0.1, 0.000001);
    }

    for (NSString *island in @[@"island", @"choked_island", @"painted_island"])
    {
        XCTAssertNil([OASharedRouteDetailsProvider createAlarmInfoWithTag:@"traffic_calming"
                                                                   value:island
                                                           locationIndex:0
                                                                latitude:0
                                                               longitude:0]);
    }
    NSArray<NSDictionary<NSString *, NSString *> *> *unsupported = @[
        @{@"tag": @"highway", @"value": @"residential"},
        @{@"tag": @"enforcement", @"value": @"speed_camera"},
        @{@"tag": @"barrier", @"value": @"gate"},
        @{@"tag": @"railway", @"value": @"tram"},
        @{@"tag": @"crossing", @"value": @"traffic_signals"},
        @{@"tag": @"Highway", @"value": @"speed_camera"},
        @{@"tag": @"unknown", @"value": @"stop"},
    ];
    for (NSDictionary<NSString *, NSString *> *testCase in unsupported)
    {
        XCTAssertNil([OASharedRouteDetailsProvider createAlarmInfoWithTag:testCase[@"tag"]
                                                                    value:testCase[@"value"]
                                                            locationIndex:0
                                                                 latitude:0
                                                                longitude:0]);
    }
    XCTAssertNil([OASharedRouteDetailsProvider createAlarmInfoWithTag:@"highway"
                                                                value:nil
                                                        locationIndex:0
                                                             latitude:0
                                                            longitude:0]);
    XCTAssertNil([OASharedRouteDetailsProvider createAlarmInfoWithTag:nil
                                                                value:@"stop"
                                                        locationIndex:0
                                                             latitude:0
                                                            longitude:0]);
    XCTAssertEqualObjects(
        [OASharedRouteDetailsProvider createAlarmInfoWithTag:@"traffic_calming"
                                                       value:nil
                                               locationIndex:0
                                                    latitude:0
                                                   longitude:0].type,
        OASRouteEventType.trafficCalming);
    XCTAssertEqualObjects(
        [OASharedRouteDetailsProvider createAlarmInfoWithTag:@"hazard"
                                                       value:nil
                                               locationIndex:0
                                                    latitude:0
                                                   longitude:0].type,
        OASRouteEventType.hazard);

    RouteTypeRule stopRule("highway", "stop");
    OAAlarmInfo *legacyEntryPoint = [OAAlarmInfo createAlarmInfo:stopRule
                                                          locInd:3
                                                      coordinate:CLLocationCoordinate2DMake(1, 2)];
    XCTAssertEqualObjects(legacyEntryPoint.type, OASRouteEventType.stop);
    XCTAssertEqual(legacyEntryPoint.locationIndex, 3);
}

- (void)testCreatesSpeedLimitThroughSharedBackend
{
    OAAlarmInfo *alarm = [OAAlarmInfo createSpeedLimit:50
                                           coordinate:CLLocationCoordinate2DMake(1.25, -2.5)
                                 speedMetersPerSecond:13.9f];

    XCTAssertEqualObjects(alarm.type, OASRouteEventType.speedLimit);
    XCTAssertEqual(alarm.locationIndex, 0);
    XCTAssertEqual(alarm.lastLocationIndex, -1);
    XCTAssertEqual(alarm.intValue, 50);
    XCTAssertEqualWithAccuracy(alarm.floatValue, 13.9f, 0.001f);
    XCTAssertEqualWithAccuracy(alarm.coordinate.latitude, 1.25, 0.000001);
    XCTAssertEqualWithAccuracy(alarm.coordinate.longitude, -2.5, 0.000001);
}

- (void)testSelectsAndOrdersAlarmsUsingAndroidSettings
{
    OARouteCalculationResult *route = [[OARouteCalculationResult alloc] initWithErrorMessage:@"error"];
    OAAlarmInfo *stop = [self alarmWithType:OASRouteEventType.stop index:4 latitude:0 longitude:0.04];
    OAAlarmInfo *tunnel = [self alarmWithType:OASRouteEventType.tunnel index:3 latitude:0 longitude:0.03];
    OAAlarmInfo *pedestrian = [self alarmWithType:OASRouteEventType.pedestrian index:2 latitude:0 longitude:0.02];
    OAAlarmInfo *camera = [self alarmWithType:OASRouteEventType.speedCamera index:1 latitude:0 longitude:0.01];
    OAAlarmInfo *hazard = [self alarmWithType:OASRouteEventType.hazard index:4 latitude:0 longitude:0.05];
    [route.alarmInfo addObjectsFromArray:@[stop, tunnel, pedestrian, camera, hazard]];

    NSArray<OALocationPointWrapper *> *result = [OASharedRouteDetailsProvider
        selectAlarmWrappersForRoute:route
        routingAlarmsEnabled:YES
        showCameras:NO
        speakSpeedCameras:YES
        showTunnels:NO
        speakTunnels:YES
        showPedestrian:YES
        speakPedestrian:NO
        showTrafficWarnings:YES
        speakTrafficWarnings:NO];

    XCTAssertEqual(result.count, 5);
    XCTAssertEqual(result[0].point, camera);
    XCTAssertEqual(result[1].point, pedestrian);
    XCTAssertEqual(result[2].point, tunnel);
    XCTAssertEqual(result[3].point, stop);
    XCTAssertEqual(result[4].point, hazard);
    XCTAssertTrue(result[0].announce);
    XCTAssertFalse(result[1].announce);
    XCTAssertTrue(result[2].announce);
    XCTAssertFalse(result[3].announce);
    XCTAssertFalse(result[4].announce);
    for (OALocationPointWrapper *wrapper in result)
    {
        XCTAssertEqual(wrapper.route, route);
        XCTAssertEqual(wrapper.type, LPW_ALARMS);
        XCTAssertEqual(wrapper.routeIndex, ((OAAlarmInfo *) wrapper.point).locationIndex);
    }

    NSArray<OALocationPointWrapper *> *disabledResult = [OASharedRouteDetailsProvider
        selectAlarmWrappersForRoute:route
        routingAlarmsEnabled:NO
        showCameras:YES
        speakSpeedCameras:YES
        showTunnels:YES
        speakTunnels:YES
        showPedestrian:YES
        speakPedestrian:YES
        showTrafficWarnings:YES
        speakTrafficWarnings:YES];
    XCTAssertEqual(disabledResult.count, 0);
}

- (void)testSuppressesAndroidCameraAndRailwayDuplicates
{
    OARouteCalculationResult *route = [[OARouteCalculationResult alloc] initWithErrorMessage:@"error"];
    OAAlarmInfo *camera1 = [self alarmWithType:OASRouteEventType.speedCamera index:1 latitude:0 longitude:0];
    OAAlarmInfo *camera2 = [self alarmWithType:OASRouteEventType.redLightCamera index:2 latitude:0 longitude:0.001];
    OAAlarmInfo *camera3 = [self alarmWithType:OASRouteEventType.speedCamera index:3 latitude:0 longitude:0.002];
    OAAlarmInfo *railway1 = [self alarmWithType:OASRouteEventType.railway index:4 latitude:0 longitude:0.0100];
    OAAlarmInfo *railway2 = [self alarmWithType:OASRouteEventType.railway index:5 latitude:0 longitude:0.0102];
    OAAlarmInfo *railway3 = [self alarmWithType:OASRouteEventType.railway index:6 latitude:0 longitude:0.0105];
    [route.alarmInfo addObjectsFromArray:@[camera1, camera2, camera3, railway1, railway2, railway3]];

    NSArray<OALocationPointWrapper *> *result = [OASharedRouteDetailsProvider
        selectAlarmWrappersForRoute:route
        routingAlarmsEnabled:YES
        showCameras:YES
        speakSpeedCameras:NO
        showTunnels:NO
        speakTunnels:NO
        showPedestrian:NO
        speakPedestrian:NO
        showTrafficWarnings:NO
        speakTrafficWarnings:NO];

    XCTAssertEqual(result.count, 4);
    XCTAssertEqual(result[0].point, camera1);
    XCTAssertEqual(result[1].point, camera3);
    XCTAssertEqual(result[2].point, railway1);
    XCTAssertEqual(result[3].point, railway3);
}

- (OAAlarmInfo *)alarmWithType:(OASRouteEventType *)type
                         index:(int)index
                      latitude:(double)latitude
                     longitude:(double)longitude
{
    OAAlarmInfo *alarm = [[OAAlarmInfo alloc] initWithType:type locationIndex:index];
    alarm.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
    return alarm;
}

@end
