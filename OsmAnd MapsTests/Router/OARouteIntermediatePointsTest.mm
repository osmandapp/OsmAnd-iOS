//
//  OARouteIntermediatePointsTest.mm
//  OsmAnd MapsTests
//
//  Intermediate destinations of a calculated route: their distance and time, and their rows in Route Details.
//

#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import "OsmAndSharedWrapper.h"
#import "OARouteDetailsViewController.h"
#import "OARouteCalculationResult.h"
#import "OARouteCalculationParams.h"
#import "OARouteDirectionInfo.h"
#import "OARTargetPoint.h"
#import "OAApplicationMode.h"

@interface OARouteIntermediatePointsTest : XCTestCase

@end

@implementation OARouteIntermediatePointsTest

- (void)testIntermediateTimeEndsAtStartOfItsManeuver
{
    NSMutableArray<CLLocation *> *locations = [NSMutableArray array];
    for (int i = 0; i <= 10; i++)
        [locations addObject:[[CLLocation alloc] initWithLatitude:0.001 * i longitude:0]];
    OARouteCalculationParams *params = [[OARouteCalculationParams alloc] init];
    params.start = locations.firstObject;
    params.end = locations.lastObject;
    params.intermediates = @[locations[4]];
    params.mode = [OAApplicationMode CAR];
    OARouteCalculationResult *route = [[OARouteCalculationResult alloc] initWithLocations:locations
                                                                              directions:@[[self direction:0 speed:7.8], [self direction:4 speed:7.8], [self direction:8 speed:7.8]]
                                                                                  params:params
                                                                               waypoints:nil
                                                                         addMissingTurns:NO];

    NSArray<OARouteDirectionInfo *> *directions = [route getImmutableAllDirections];
    XCTAssertEqual(directions.count, 3);
    // below .5 a truncated step time equals the rounded one
    double firstStepTime = directions[0].distance / directions[0].averageSpeed;
    XCTAssertGreaterThanOrEqual(firstStepTime - floor(firstStepTime), 0.5);
    long timeToIntermediate = [directions[0] getExpectedTime];
    XCTAssertEqual([route getLeftTimeToNextIntermediate:nil intermediateIndexOffset:0], timeToIntermediate);

    NSArray<OAIntermediatePointInfo *> *infos = [route getIntermediatePointInfos];
    XCTAssertEqual(infos.count, 1);
    XCTAssertEqual(infos[0].routePointOffset, 4);
    XCTAssertEqual(infos[0].distance, directions[0].distance);
    XCTAssertEqual(infos[0].time, timeToIntermediate);
}

- (void)testInsertsIntermediateDestinationsBeforeNextManeuver
{
    NSArray<OARouteDirectionInfo *> *directions = @[[self direction:0 distance:100],
                                                   [self direction:10 distance:100],
                                                   [self direction:20 distance:0]];
    NSArray<OAIntermediatePointInfo *> *intermediateInfos = @[
        [[OAIntermediatePointInfo alloc] initWithRoutePointOffset:5 distance:50 time:5],
        [[OAIntermediatePointInfo alloc] initWithRoutePointOffset:10 distance:100 time:10]];
    OARTargetPoint *first = [[OARTargetPoint alloc] initWithPoint:[[CLLocation alloc] initWithLatitude:1 longitude:1] name:nil index:0];
    OARTargetPoint *second = [[OARTargetPoint alloc] initWithPoint:[[CLLocation alloc] initWithLatitude:2 longitude:2] name:nil index:1];

    NSArray<OARouteDirectionItem *> *items = [OARouteDirectionItem buildRouteDirectionItems:directions
                                                                      intermediatePointInfos:intermediateInfos
                                                                          intermediatePoints:@[first, second]];

    XCTAssertEqual(items.count, 5);
    XCTAssertFalse(items[0].isIntermediate);
    XCTAssertEqual(items[0].directionIndex, 0);
    XCTAssertTrue(items[1].isIntermediate);
    XCTAssertEqual(items[1].targetPoint, first);
    XCTAssertEqual(items[1].intermediateIndex, 0);
    XCTAssertEqual(items[1].intermediatePointInfo.distance, 50);
    XCTAssertEqual(items[1].intermediatePointInfo.time, 5);
    XCTAssertTrue(items[2].isIntermediate);
    XCTAssertEqual(items[2].targetPoint, second);
    XCTAssertEqual(items[2].intermediateIndex, 1);
    XCTAssertEqual(items[2].intermediatePointInfo.distance, 100);
    XCTAssertFalse(items[3].isIntermediate);
    XCTAssertEqual(items[3].direction, directions[1]);
    XCTAssertEqual(items[3].directionIndex, 1);
    XCTAssertFalse(items[4].isIntermediate);
    XCTAssertEqual(items[4].directionIndex, 2);
}

- (void)testKeepsRouteIntermediateWhenTargetMetadataIsUnavailable
{
    NSArray<OARouteDirectionItem *> *items = [OARouteDirectionItem buildRouteDirectionItems:@[[self direction:0 distance:100], [self direction:10 distance:0]]
                                                                      intermediatePointInfos:@[[[OAIntermediatePointInfo alloc] initWithRoutePointOffset:5 distance:50 time:5]]
                                                                          intermediatePoints:@[]];

    XCTAssertEqual(items.count, 3);
    XCTAssertTrue(items[1].isIntermediate);
    XCTAssertNil(items[1].targetPoint);
}

- (void)testAppendsIntermediateDestinationsAfterLastManeuver
{
    NSArray<OARouteDirectionItem *> *items = [OARouteDirectionItem buildRouteDirectionItems:@[[self direction:0 distance:100]]
                                                                      intermediatePointInfos:@[[[OAIntermediatePointInfo alloc] initWithRoutePointOffset:5 distance:50 time:5]]
                                                                          intermediatePoints:@[]];

    XCTAssertEqual(items.count, 2);
    XCTAssertFalse(items[0].isIntermediate);
    XCTAssertTrue(items[1].isIntermediate);
}

- (OARouteDirectionInfo *)direction:(int)routePointOffset distance:(int)distance
{
    OARouteDirectionInfo *direction = [self direction:routePointOffset speed:10];
    direction.distance = distance;
    return direction;
}

- (OARouteDirectionInfo *)direction:(int)routePointOffset speed:(float)speed
{
    OARouteDirectionInfo *direction = [[OARouteDirectionInfo alloc] initWithAverageSpeed:speed turnType:[OASTurnType.companion straight]];
    direction.routePointOffset = routePointOffset;
    return direction;
}

@end
