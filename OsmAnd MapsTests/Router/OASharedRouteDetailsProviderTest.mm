//
//  OASharedRouteDetailsProviderTest.mm
//  OsmAnd MapsTests
//

#import <XCTest/XCTest.h>

#import "OARouteDirectionInfo.h"
#import "OASharedRouteDetailsProvider.h"
#import "OsmAndSharedWrapper.h"

#include <turnType.h>

@interface OASharedRouteDetailsProviderTest : XCTestCase

@end

@implementation OASharedRouteDetailsProviderTest

- (void)testCalculatesAndroidCompatibleCumulativeDistances
{
    NSArray<CLLocation *> *locations = @[
        [[CLLocation alloc] initWithLatitude:0 longitude:0],
        [[CLLocation alloc] initWithLatitude:0 longitude:1],
        [[CLLocation alloc] initWithLatitude:1 longitude:1],
    ];

    XCTAssertEqualObjects(
        [OASharedRouteDetailsProvider calculateDistancesToFinish:locations],
        (@[@221893, @110574, @0]));
    XCTAssertEqualObjects([OASharedRouteDetailsProvider calculateDistancesToFinish:@[]], @[]);
    XCTAssertEqualObjects(
        [OASharedRouteDetailsProvider calculateDistancesToFinish:@[locations.firstObject]],
        (@[@0]));
}

- (void)testUpdatesManeuversWithInclusiveAndroidTimeToFinish
{
    NSArray<OARouteDirectionInfo *> *directions = @[
        [self directionWithOffset:0 averageSpeed:12],
        [self directionWithOffset:2 averageSpeed:7],
        [self directionWithOffset:3 averageSpeed:1],
    ];

    [OASharedRouteDetailsProvider updateDirectionDistancesAndTimes:directions
                                           distanceToFinishMeters:@[@450, @300, @125, @0]];

    XCTAssertEqual(directions[0].distance, 325);
    XCTAssertEqual(directions[1].distance, 125);
    XCTAssertEqual(directions[2].distance, 0);
    XCTAssertEqual([directions[0] getExpectedTime], 27);
    XCTAssertEqual([directions[1] getExpectedTime], 18);
    XCTAssertEqual([directions[2] getExpectedTime], 0);
    XCTAssertEqual(directions[0].afterLeftTime, 45);
    XCTAssertEqual(directions[1].afterLeftTime, 18);
    XCTAssertEqual(directions[2].afterLeftTime, 0);
}

- (void)testSignedDistanceLookupReturnsOriginalLocationInstances
{
    NSMutableArray<CLLocation *> *locations = [NSMutableArray array];
    for (int index = 0; index <= 4; index++)
    {
        [locations addObject:[[CLLocation alloc] initWithLatitude:0 longitude:index * 0.001]];
    }

    XCTAssertEqual(
        [OASharedRouteDetailsProvider getRouteLocationByDistance:locations
                                         currentRoutePointIndex:2
                                                distanceMeters:100],
        locations[3]);
    XCTAssertEqual(
        [OASharedRouteDetailsProvider getRouteLocationByDistance:locations
                                         currentRoutePointIndex:2
                                                distanceMeters:-100],
        locations[1]);
    XCTAssertEqual(
        [OASharedRouteDetailsProvider getRouteLocationByDistance:locations
                                         currentRoutePointIndex:2
                                                distanceMeters:0],
        locations[1]);
    XCTAssertNil(
        [OASharedRouteDetailsProvider getRouteLocationByDistance:locations
                                         currentRoutePointIndex:2
                                                distanceMeters:1000]);
    XCTAssertNil(
        [OASharedRouteDetailsProvider getRouteLocationByDistance:locations
                                         currentRoutePointIndex:(int) locations.count
                                                distanceMeters:100]);
}

- (OARouteDirectionInfo *)directionWithOffset:(int)offset averageSpeed:(float)averageSpeed
{
    OARouteDirectionInfo *direction = [[OARouteDirectionInfo alloc]
        initWithAverageSpeed:averageSpeed
        turnType:TurnType::ptrStraight()];
    direction.routePointOffset = offset;
    return direction;
}

@end
