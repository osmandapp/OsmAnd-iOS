//
//  OASharedRoutingTest.mm
//  OsmAnd MapsTests
//
//  Behind the "Route with OsmAndShared" flag OARouteProvider calculates a route with the
//  OsmAndShared planner instead of the C++ one. Both are set up by the provider out of the same
//  settings and the same application mode - the same routing.xml, the same routing parameters, the
//  same memory limit, the same avoided roads - so over the same map file they are asked for the same
//  route, and this checks that they answer with the same one: the same roads, covered along the same
//  stretch and of the same length, the same points to drive along, and the same manoeuvres.
//
//  The manoeuvres are where the two do not always agree. The C++ preparation is what this move
//  replaces, and on two of these routes it announces one manoeuvre more or less than the java
//  preparation OsmAndShared is a copy of; both are named below with what differs, and the test holds
//  them to differing, so that a name goes when the difference does.
//

#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import "OARouteProvider.h"
#import "OARouteCalculationParams.h"
#import "OARouteCalculationResult.h"
#import "OARouteDirectionInfo.h"
#import "OAApplicationMode.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"
#import "OACppRouteConverter.h"

#include <OsmAndCore/QtExtensions.h>
#include <routePlannerFrontEnd.h>
#include <routingContext.h>
#include <routingConfiguration.h>
#include <routeSegmentResult.h>
#include <routeCalculationProgress.h>
#include <binaryRead.h>
#include <vector>

@interface OARouteProvider (OASharedRoutingTest)

- (OARouteCalculationResult *) calcSharedRouteImpl:(OARouteCalculationParams *)params
                                      calcGPXRoute:(BOOL)calcGPXRoute
                                           readers:(NSArray<OASBinaryMapIndexReader *> *)readers;

@end

@interface OASharedRoutingTest : XCTestCase

@end

@implementation OASharedRoutingTest
{
    OARouteProvider *_provider;
    NSArray<OASBinaryMapIndexReader *> *_readers;
    NSDictionary<NSString *, NSString *> *_knownManoeuvreDifferences;
    int _routes;
    int _directions;
}

- (void)setUp
{
    // The test host is the app itself and it starts in the background: the routing configuration and
    // the regions the provider asks for are only there once it has finished.
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:180];
    while (![OsmAndApp instance].initialized && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    XCTAssertTrue([OsmAndApp instance].initialized, @"the app did not finish starting");

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *obfFilePath = [bundle pathForResource:@"Turn_lanes_test" ofType:@"obf" inDirectory:@"test-resources"];
    initBinaryMapFile(string(obfFilePath.UTF8String), true, true);

    _provider = [[OARouteProvider alloc] init];
    _readers = @[[[OASBinaryMapIndexReader alloc] initWithFilePath:obfFilePath]];
    _knownManoeuvreDifferences = @{
        @"10.Ringweg Oost u-turn" : @"the C++ preparation heads the route with a \"Head toward\" the java one does not",
        @"32.2 Motorway TR - Turn Left" : @"the java preparation announces a keep right the C++ one does not"
    };
    _routes = 0;
    _directions = 0;
}

- (void)tearDown
{
    for (OASBinaryMapIndexReader *reader in _readers)
        [reader close];
}

- (void)testSharedPlannerRoutesAsTheCppOne
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

    XCTAssertGreaterThan(_routes, 10, @"Too few routes calculated");
    XCTAssertGreaterThan(_directions, 20, @"Too few manoeuvres calculated");
    [XCTContext runActivityNamed:[NSString stringWithFormat:@"%d routes, %d manoeuvres", _routes, _directions]
                           block:^(id<XCTActivity> activity) {}];
}

- (void)checkRoute:(NSDictionary *)testCase
{
    NSString *name = testCase[@"testName"];
    OARouteCalculationParams *params = [self paramsFor:testCase];

    OARouteCalculationResult *cpp = [self cppRoute:params];
    if (!cpp.isCalculated)
        return; // the fixture has cases with no route between the two points; they are not this test's subject

    OARouteCalculationResult *shared = [_provider calcSharedRouteImpl:params calcGPXRoute:NO readers:_readers];
    XCTAssertTrue(shared.isCalculated, @"%@: no route from the OsmAndShared planner (%@)", name, shared.errorMessage);
    if (!shared.isCalculated)
        return;

    _routes++;

    // the same roads, entered and left at the same place and for the same length. The place rather
    // than the point index: one of these roads carries the same point twice, and the two
    // preparations do not pick the same one of the two.
    NSArray<OASRouteSegmentResult *> *cppRoute = [cpp getOriginalRoute];
    NSArray<OASRouteSegmentResult *> *sharedRoute = [shared getOriginalRoute];
    XCTAssertEqual(sharedRoute.count, cppRoute.count, @"%@: segments", name);
    for (int i = 0; i < MIN(sharedRoute.count, cppRoute.count); i++)
    {
        OASRouteSegmentResult *c = cppRoute[i];
        OASRouteSegmentResult *s = sharedRoute[i];
        XCTAssertEqual([s getObject].id, [c getObject].id, @"%@: road of segment %d", name, i);
        [self comparePoint:[s getStartPoint] with:[c getStartPoint] message:[NSString stringWithFormat:@"%@: start of segment %d", name, i]];
        [self comparePoint:[s getEndPoint] with:[c getEndPoint] message:[NSString stringWithFormat:@"%@: end of segment %d", name, i]];
        XCTAssertEqual(abs([s getEndPointIndex] - [s getStartPointIndex]), abs([c getEndPointIndex] - [c getStartPointIndex]),
                       @"%@: points of segment %d", name, i);
        // the distances differ in their last digits: the two associate the same arithmetic differently
        XCTAssertEqualWithAccuracy([s getDistance], [c getDistance], MAX(0.05, [c getDistance] * 0.0002),
                                   @"%@: distance of segment %d", name, i);
    }

    // and the same route for the app: the same points to drive along, and the same length
    NSArray<CLLocation *> *cppLocations = [cpp getImmutableAllLocations];
    NSArray<CLLocation *> *sharedLocations = [shared getImmutableAllLocations];
    XCTAssertEqual(sharedLocations.count, cppLocations.count, @"%@: locations", name);
    for (int i = 0; i < MIN(sharedLocations.count, cppLocations.count); i++)
        XCTAssertLessThan([sharedLocations[i] distanceFromLocation:cppLocations[i]], 0.5, @"%@: location %d", name, i);
    XCTAssertEqualWithAccuracy([shared getWholeDistance], [cpp getWholeDistance], 2.0, @"%@: whole distance", name);

    [self compareDirections:[shared getRouteDirections] with:[cpp getRouteDirections] name:name];
}

- (void)compareDirections:(NSArray<OARouteDirectionInfo *> *)sharedDirections
                     with:(NSArray<OARouteDirectionInfo *> *)cppDirections
                     name:(NSString *)name
{
    NSString *difference = _knownManoeuvreDifferences[name];
    if (difference)
    {
        XCTAssertNotEqual(sharedDirections.count, cppDirections.count, @"%@: %@ - no longer", name, difference);
        return;
    }

    XCTAssertEqual(sharedDirections.count, cppDirections.count, @"%@: manoeuvres", name);
    for (int i = 0; i < MIN(sharedDirections.count, cppDirections.count); i++)
    {
        OARouteDirectionInfo *c = cppDirections[i];
        OARouteDirectionInfo *s = sharedDirections[i];
        XCTAssertEqual(s.turnType.value, c.turnType.value, @"%@: manoeuvre %d", name, i);
        XCTAssertEqual(s.routePointOffset, c.routePointOffset, @"%@: manoeuvre %d point", name, i);
        XCTAssertEqualObjects(s.getDescriptionRoute, c.getDescriptionRoute, @"%@: manoeuvre %d description", name, i);
        _directions++;
    }
}

- (void)comparePoint:(OASKLatLon *)shared with:(OASKLatLon *)cpp message:(NSString *)message
{
    XCTAssertEqualWithAccuracy(shared.latitude, cpp.latitude, 1e-6, @"%@", message);
    XCTAssertEqualWithAccuracy(shared.longitude, cpp.longitude, 1e-6, @"%@", message);
}

- (OARouteCalculationParams *) paramsFor:(NSDictionary *)testCase
{
    OARouteCalculationParams *params = [[OARouteCalculationParams alloc] init];
    params.start = [[CLLocation alloc] initWithLatitude:[testCase[@"startPoint"][@"latitude"] doubleValue]
                                              longitude:[testCase[@"startPoint"][@"longitude"] doubleValue]];
    params.end = [[CLLocation alloc] initWithLatitude:[testCase[@"endPoint"][@"latitude"] doubleValue]
                                            longitude:[testCase[@"endPoint"][@"longitude"] doubleValue]];
    params.mode = [OAApplicationMode CAR];
    params.leftSide = NO;
    params.calculationProgress = std::make_shared<RouteCalculationProgress>();
    return params;
}

// The C++ side of the same request, set up the way findVectorMapsRoute sets it up, but over the one
// map file of the fixture instead of the installed maps.
- (OARouteCalculationResult *) cppRoute:(OARouteCalculationParams *)params
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    auto builder = [OsmAndApp.instance getRoutingConfigForMode:params.mode];
    auto generalRouter = [OsmAndApp.instance getRouter:builder mode:params.mode];
    XCTAssertTrue(generalRouter != nullptr);
    auto cf = [_provider initOsmAndRoutingConfig:builder params:params generalRouter:generalRouter];

    auto router = std::make_shared<RoutePlannerFrontEnd>();
    router->setUseFastRecalculation(settings.useFastRecalculation);
    router->CALCULATE_MISSING_MAPS = false;
    if (![settings.useOldRouting get])
        router->setDefaultRoutingConfig();

    auto ctx = router->buildRoutingContext(cf, RouteCalculationMode::NORMAL);
    ctx->progress = params.calculationProgress;
    ctx->leftSideNavigation = params.leftSide;
    ctx->setConditionalTime(cf->routeCalculationTime);

    std::shared_ptr<RoutingContext> complexCtx = nullptr;
    if ([params.mode isDerivedRoutingFrom:[OAApplicationMode CAR]] && !settings.disableComplexRouting
        && !router->getRecalculationEnd(ctx.get()))
    {
        complexCtx = router->buildRoutingContext(cf, RouteCalculationMode::COMPLEX);
        complexCtx->progress = params.calculationProgress;
        complexCtx->leftSideNavigation = params.leftSide;
        complexCtx->setConditionalTime(cf->routeCalculationTime);
    }

    vector<int> intX;
    vector<int> intY;
    const auto &searchCtx = complexCtx ? complexCtx : ctx;
    auto route = router->searchRoute(searchCtx, get31TileNumberX(params.start.coordinate.longitude),
                                     get31TileNumberY(params.start.coordinate.latitude),
                                     get31TileNumberX(params.end.coordinate.longitude),
                                     get31TileNumberY(params.end.coordinate.latitude), intX, intY);
    if (route.empty())
        return [[OARouteCalculationResult alloc] initWithErrorMessage:@"no route"];

    return [[OARouteCalculationResult alloc] initWithSegmentResults:[OACppRouteConverter toSharedSegments:route]
                                                              start:params.start
                                                                end:params.end
                                                      intermediates:params.intermediates
                                                           leftSide:params.leftSide
                                                        routingTime:searchCtx->progress->routingCalculatedTime
                                                          waypoints:nil
                                                               mode:params.mode
                                         calculateFirstAndLastPoint:YES
                                                 initialCalculation:NO];
}

@end
