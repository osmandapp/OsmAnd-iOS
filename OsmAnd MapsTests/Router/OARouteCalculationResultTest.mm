//
//  OARouteCalculationResultTest.mm
//  OsmAnd MapsTests
//
//  The app's route model is built on OsmAndShared segments. This runs the whole of that build over
//  real routes - the same fixture the turn lanes test calculates on - and checks that what comes
//  out holds together: a location for every point of every segment, a manoeuvre list that points
//  into those locations, distances and times that add up, and the segment lookups the widgets and
//  the voice prompts use answering for every position along the route.
//
//  It is the pipeline that `initWithSegmentResults:` runs - the locations, the directions, the
//  alarms and the street names - which nothing else exercises end to end.
//

#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import "OsmAndSharedWrapper.h"
#import "OACppRouteConverter.h"
#import "OARouteCalculationResult.h"
#import "OARouteDirectionInfo.h"
#import "OAApplicationMode.h"

#include <OsmAndCore/QtExtensions.h>
#include <routePlannerFrontEnd.h>
#include <routingContext.h>
#include <routingConfiguration.h>
#include <routeSegmentResult.h>
#include <binaryRead.h>
#include <vector>

@interface OARouteCalculationResultTest : XCTestCase

@end

@implementation OARouteCalculationResultTest
{
    std::shared_ptr<RoutePlannerFrontEnd> _fe;
    int _routes;
    int _directions;
}

- (void)setUp
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *obfFilePath = [bundle pathForResource:@"Turn_lanes_test" ofType:@"obf" inDirectory:@"test-resources"];
    initBinaryMapFile(string(obfFilePath.UTF8String), true, true);

    _fe = std::make_shared<RoutePlannerFrontEnd>();
    _routes = 0;
    _directions = 0;
}

- (void)testRouteResultIsBuiltFromSharedSegments
{
    NSString *jsonFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"test_turn_lanes" ofType:@"json" inDirectory:@"test-resources"];
    NSString *sourceJsonText = [NSString stringWithContentsOfFile:jsonFilePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *sourceJson = [NSJSONSerialization JSONObjectWithData:[sourceJsonText dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    XCTAssertTrue([sourceJson isKindOfClass:NSArray.class]);

    for (NSDictionary *testCase in sourceJson)
    {
        if ([testCase[@"ignoreNative"] boolValue])
            continue;

        [self checkRoute:testCase];
    }

    XCTAssertGreaterThan(_routes, 10, @"Too few routes built");
    XCTAssertGreaterThan(_directions, 20, @"Too few manoeuvres built");
    [XCTContext runActivityNamed:[NSString stringWithFormat:@"%d routes, %d manoeuvres", _routes, _directions]
                           block:^(id<XCTActivity> activity) {}];
}

- (void)checkRoute:(NSDictionary *)testCase
{
    const auto ctx = [self buildRoutingContext:testCase[@"params"]];
    CLLocation *start = [[CLLocation alloc] initWithLatitude:[testCase[@"startPoint"][@"latitude"] doubleValue]
                                                   longitude:[testCase[@"startPoint"][@"longitude"] doubleValue]];
    CLLocation *end = [[CLLocation alloc] initWithLatitude:[testCase[@"endPoint"][@"latitude"] doubleValue]
                                                 longitude:[testCase[@"endPoint"][@"longitude"] doubleValue]];
    vector<int> intX;
    vector<int> intY;
    auto route = _fe->searchRoute(ctx, get31TileNumberX(start.coordinate.longitude), get31TileNumberY(start.coordinate.latitude),
                                  get31TileNumberX(end.coordinate.longitude), get31TileNumberY(end.coordinate.latitude), intX, intY);
    if (route.empty())
        return;

    NSString *name = testCase[@"testName"];
    NSArray<OASRouteSegmentResult *> *segments = [OACppRouteConverter toSharedSegments:route];
    OARouteCalculationResult *result = [[OARouteCalculationResult alloc] initWithSegmentResults:segments
                                                                                         start:start
                                                                                           end:end
                                                                                 intermediates:@[]
                                                                                      leftSide:NO
                                                                                   routingTime:0
                                                                                     waypoints:nil
                                                                                          mode:[OAApplicationMode CAR]
                                                                    calculateFirstAndLastPoint:YES
                                                                            initialCalculation:NO];
    _routes++;

    XCTAssertTrue([result isCalculated], @"%@: not calculated", name);
    NSArray<CLLocation *> *locations = [result getImmutableAllLocations];
    XCTAssertGreaterThan(locations.count, 1u, @"%@: locations", name);
    XCTAssertGreaterThan([result getWholeDistance], 0, @"%@: whole distance", name);

    // The route starts and ends where it was asked to, within the distance that makes the first and
    // last point be introduced at all.
    XCTAssertLessThan([locations.firstObject distanceFromLocation:start], 20.0, @"%@: start", name);
    XCTAssertLessThan([locations.lastObject distanceFromLocation:end], 20.0, @"%@: end", name);

    // One location per point of every segment, and the segments behind them are the route again.
    NSArray<OASRouteSegmentResult *> *original = [result getOriginalRoute];
    XCTAssertEqual(route.size(), original.count, @"%@: original route", name);
    for (int i = 0; i < (int) original.count; i++)
        XCTAssertEqual(route[i]->object->id, [original[i] getObject].id, @"%@: original road %d", name, i);

    NSArray<OARouteDirectionInfo *> *directions = [result getRouteDirections];
    XCTAssertGreaterThan(directions.count, 0u, @"%@: directions", name);
    int previousOffset = -1;
    for (OARouteDirectionInfo *info in directions)
    {
        _directions++;
        XCTAssertNotNil(info.turnType, @"%@: manoeuvre without a turn type", name);
        XCTAssertGreaterThanOrEqual(info.routePointOffset, 0, @"%@: manoeuvre before the route", name);
        XCTAssertLessThan(info.routePointOffset, (int) locations.count, @"%@: manoeuvre past the route", name);
        XCTAssertGreaterThan(info.routePointOffset, previousOffset, @"%@: manoeuvres out of order", name);
        XCTAssertGreaterThan(info.averageSpeed, 0, @"%@: manoeuvre without a speed", name);
        previousOffset = info.routePointOffset;
    }

    // What the widgets and the voice prompts ask for, at every position the route passes through.
    for (int i = 0; i < (int) locations.count; i++)
    {
        [result updateCurrentRoute:i];
        OASRouteSegmentResult *current = [result getCurrentSegmentResult];
        XCTAssertNotNil(current, @"%@: no segment at %d", name, i);
        XCTAssertNotNil([current getObject], @"%@: no road at %d", name, i);
        XCTAssertGreaterThanOrEqual([result getCurrentMaxSpeed:0], 0, @"%@: max speed at %d", name, i);
        XCTAssertNotNil([result getUpcomingTunnel:250], @"%@: tunnel lookup at %d", name, i);
        XCTAssertGreaterThanOrEqual([result getDistanceToFinish:locations[i]], 0, @"%@: distance to finish at %d", name, i);

        OANextDirectionInfo *next = [result getNextRouteDirectionInfo:[[OANextDirectionInfo alloc] init] fromLoc:locations[i] toSpeak:NO];
        if (next != nil && next.directionInfo != nil)
            XCTAssertNotNil(next.directionInfo.turnType, @"%@: next manoeuvre without a turn type at %d", name, i);
    }
}

- (std::shared_ptr<RoutingContext>)buildRoutingContext:(NSDictionary<NSString *, NSString *> *)testParams
{
    auto builder = parseRoutingConfigurationFromXml([[[NSBundle mainBundle] pathForResource:@"routing" ofType:@"xml"] UTF8String], "");
    MAP_STR_STR params;
    for (NSString *key in testParams)
    {
        id value = testParams[key];
        if ([value isKindOfClass:NSString.class])
            params[key.UTF8String] = ((NSString *)value).UTF8String;
    }
    params["car"] = "true";
    string vehicle = "car";
    auto vehicleIt = params.find("vehicle");
    if (vehicleIt != params.end() && !vehicleIt->second.empty())
        vehicle = vehicleIt->second;

    const auto ctx = _fe->buildRoutingContext(builder->build(vehicle, 30 * 3, params));
    ctx->leftSideNavigation = false;
    return ctx;
}

@end
