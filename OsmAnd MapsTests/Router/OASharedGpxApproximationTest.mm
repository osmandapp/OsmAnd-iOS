//
//  OASharedGpxApproximationTest.mm
//  OsmAnd MapsTests
//
//  Behind the "Route with OsmAndShared" flag a track is attached to the roads underneath it by the
//  OsmAndShared planner instead of the C++ one. Both are set up by the provider out of the same
//  settings and the same application mode, so over the same map file and the same track they are
//  asked for the same thing, and this checks that they answer with the same roads: the same points
//  kept, each reaching the next over the same stretches of the same roads, and the same route
//  underneath the whole track.
//
//  The tracks are the routes of the turn lanes fixture, thinned to a point every 15 metres - the
//  same way the planner benchmarks make a track out of a route.
//

#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import "OARouteProvider.h"
#import "OARouteCalculationParams.h"
#import "OARouteCalculationResult.h"
#import "OAGpxRouteApproximation.h"
#import "OALocationsHolder.h"
#import "OAApplicationMode.h"
#import "OAResultMatcher.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"
#import "OACppRouteConverter.h"

#include <OsmAndCore/QtExtensions.h>
#include <routePlannerFrontEnd.h>
#include <gpxRouteApproximation.h>
#include <routingContext.h>
#include <routingConfiguration.h>
#include <routeSegmentResult.h>
#include <routeCalculationProgress.h>
#include <binaryRead.h>
#include <vector>

// A point every this many metres, the spacing the planner benchmarks thin a route to
static const double kTrackSpacing = 15;

// How far from the track a road may be and still be taken, as the snap-to-road screen starts out
static const float kPointApproximation = 50;

@interface OARouteProvider (OASharedGpxApproximationTest)

- (OASRoutingConfiguration *) buildSharedRoutingConfig:(OASRoutingConfigurationBuilder *)builder
                                                params:(OARouteCalculationParams *)params
                                         generalRouter:(OASGeneralRouter *)generalRouter;

@end

@interface OASharedGpxApproximationTest : XCTestCase

@end

@implementation OASharedGpxApproximationTest
{
    OARouteProvider *_provider;
    NSArray<OASBinaryMapIndexReader *> *_readers;
    int _tracks;
    int _points;
    int _segments;
}

- (void)setUp
{
    // The test host is the app itself and it starts in the background: the routing configuration the
    // provider asks for is only there once it has finished.
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:180];
    while (![OsmAndApp instance].initialized && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    XCTAssertTrue([OsmAndApp instance].initialized, @"the app did not finish starting");

    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *obfFilePath = [bundle pathForResource:@"Turn_lanes_test" ofType:@"obf" inDirectory:@"test-resources"];
    initBinaryMapFile(string(obfFilePath.UTF8String), true, true);

    _provider = [[OARouteProvider alloc] init];
    _readers = @[[[OASBinaryMapIndexReader alloc] initWithFilePath:obfFilePath]];
    _tracks = 0;
    _points = 0;
    _segments = 0;
}

- (void)tearDown
{
    for (OASBinaryMapIndexReader *reader in _readers)
        [reader close];
}

- (void)testSharedApproximationAttachesTheSameRoads
{
    NSString *jsonFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"test_turn_lanes" ofType:@"json" inDirectory:@"test-resources"];
    NSString *sourceJsonText = [NSString stringWithContentsOfFile:jsonFilePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *sourceJson = [NSJSONSerialization JSONObjectWithData:[sourceJsonText dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    XCTAssertTrue([sourceJson isKindOfClass:NSArray.class]);

    for (NSDictionary *testCase in sourceJson)
    {
        if ([testCase[@"ignoreNative"] boolValue])
            continue;

        [self checkTrack:testCase];
    }

    XCTAssertGreaterThan(_tracks, 10, @"Too few tracks approximated");
    XCTAssertGreaterThan(_segments, 100, @"Too few roads attached");
    [XCTContext runActivityNamed:[NSString stringWithFormat:@"%d tracks, %d track points, %d roads", _tracks, _points, _segments]
                           block:^(id<XCTActivity> activity) {}];
}

- (void)checkTrack:(NSDictionary *)testCase
{
    NSString *name = testCase[@"testName"];
    OARouteCalculationParams *params = [self paramsFor:testCase];
    NSArray<CLLocation *> *track = [self trackFor:params];
    if (track.count < 2)
        return; // the fixture has cases with no route between the two points; they are not this test's subject

    OALocationsHolder *locations = [[OALocationsHolder alloc] initWithLocations:track];
    OAGpxRouteApproximation *cpp = [self cppApproximation:locations params:params];
    XCTAssertNotNil(cpp, @"%@: no approximation from the C++ planner", name);
    OAGpxRouteApproximation *shared = [self sharedApproximation:locations params:params];
    XCTAssertNotNil(shared, @"%@: no approximation from the OsmAndShared planner", name);
    if (!cpp || !shared)
        return;

    _tracks++;

    XCTAssertEqual(shared.finalPoints.count, cpp.finalPoints.count, @"%@: track points", name);
    for (NSUInteger i = 0; i < MIN(shared.finalPoints.count, cpp.finalPoints.count); i++)
    {
        OASGpxPoint *c = cpp.finalPoints[i];
        OASGpxPoint *s = shared.finalPoints[i];
        [self comparePoint:s.loc with:c.loc message:[NSString stringWithFormat:@"%@: track point %lu", name, (unsigned long) i]];
        XCTAssertEqual(s.targetInd, c.targetInd, @"%@: target of track point %lu", name, (unsigned long) i);
        [self compareRoute:s.routeToTarget
                      with:c.routeToTarget
                   message:[NSString stringWithFormat:@"%@: route of track point %lu", name, (unsigned long) i]];
        _points++;
    }

    [self compareRoute:shared.fullRoute with:cpp.fullRoute message:[NSString stringWithFormat:@"%@: whole track", name]];
}

- (void)compareRoute:(NSArray<OASRouteSegmentResult *> *)shared
                with:(NSArray<OASRouteSegmentResult *> *)cpp
             message:(NSString *)message
{
    XCTAssertEqual(shared.count, cpp.count, @"%@: roads", message);
    for (NSUInteger i = 0; i < MIN(shared.count, cpp.count); i++)
    {
        OASRouteSegmentResult *c = cpp[i];
        OASRouteSegmentResult *s = shared[i];
        XCTAssertEqual([s getObject].id, [c getObject].id, @"%@: road %lu", message, (unsigned long) i);
        [self comparePoint:[s getStartPoint] with:[c getStartPoint] message:[NSString stringWithFormat:@"%@: start of road %lu", message, (unsigned long) i]];
        [self comparePoint:[s getEndPoint] with:[c getEndPoint] message:[NSString stringWithFormat:@"%@: end of road %lu", message, (unsigned long) i]];
        // the distances differ in their last digits: the two associate the same arithmetic differently
        XCTAssertEqualWithAccuracy([s getDistance], [c getDistance], MAX(0.05, [c getDistance] * 0.0002),
                                   @"%@: length of road %lu", message, (unsigned long) i);
        _segments++;
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

// A track to attach back to the roads it was made of: the C++ route between the two points, thinned
// to a point every kTrackSpacing metres.
- (NSArray<CLLocation *> *) trackFor:(OARouteCalculationParams *)params
{
    auto builder = [OsmAndApp.instance getRoutingConfigForMode:params.mode];
    auto generalRouter = [OsmAndApp.instance getRouter:builder mode:params.mode];
    XCTAssertTrue(generalRouter != nullptr);
    auto cf = [_provider initOsmAndRoutingConfig:builder params:params generalRouter:generalRouter];

    auto router = std::make_shared<RoutePlannerFrontEnd>();
    router->CALCULATE_MISSING_MAPS = false;
    auto ctx = router->buildRoutingContext(cf, RouteCalculationMode::NORMAL);
    ctx->progress = params.calculationProgress;
    ctx->setConditionalTime(cf->routeCalculationTime);

    vector<int> intX;
    vector<int> intY;
    auto route = router->searchRoute(ctx, get31TileNumberX(params.start.coordinate.longitude),
                                     get31TileNumberY(params.start.coordinate.latitude),
                                     get31TileNumberX(params.end.coordinate.longitude),
                                     get31TileNumberY(params.end.coordinate.latitude), intX, intY);
    if (route.empty())
        return @[];

    OARouteCalculationResult *result = [[OARouteCalculationResult alloc] initWithSegmentResults:[OACppRouteConverter toSharedSegments:route]
                                                                                          start:params.start
                                                                                            end:params.end
                                                                                  intermediates:nil
                                                                                       leftSide:params.leftSide
                                                                                    routingTime:0
                                                                                      waypoints:nil
                                                                                           mode:params.mode
                                                                     calculateFirstAndLastPoint:YES
                                                                             initialCalculation:NO];

    NSArray<CLLocation *> *locations = [result getImmutableAllLocations];
    NSMutableArray<CLLocation *> *track = [NSMutableArray array];
    CLLocation *previous = nil;
    for (CLLocation *location in locations)
    {
        if (!previous || [location distanceFromLocation:previous] >= kTrackSpacing)
        {
            [track addObject:location];
            previous = location;
        }
    }
    if (locations.lastObject && track.lastObject != locations.lastObject)
        [track addObject:locations.lastObject];

    return track;
}

// The C++ side of the same request, set up the way OAGpxApproximator and OARouteProvider set it up,
// but over the one map file of the fixture instead of the installed maps. The search runs here
// rather than through the provider: the test bundle links its own copy of the C++ core, and only
// that copy has the fixture open.
- (OAGpxRouteApproximation *) cppApproximation:(OALocationsHolder *)locations params:(OARouteCalculationParams *)params
{
    auto builder = [OsmAndApp.instance getRoutingConfigForMode:params.mode];
    auto generalRouter = [OsmAndApp.instance getRouter:builder mode:params.mode];
    auto cf = [_provider initOsmAndRoutingConfig:builder params:params generalRouter:generalRouter];

    auto router = std::make_shared<RoutePlannerFrontEnd>();
    router->CALCULATE_MISSING_MAPS = false;
    auto ctx = router->buildRoutingContext(cf, RouteCalculationMode::NORMAL);
    ctx->setConditionalTime(cf->routeCalculationTime);

    auto gctx = std::make_shared<GpxRouteApproximation>(ctx.get());
    gctx->ctx->progress = std::make_shared<RouteCalculationProgress>();
    gctx->ctx->config->minPointApproximation = kPointApproximation;

    auto points = router->generateGpxPoints(gctx, locations.getLatLonList);
    router->setUseGeometryBasedApproximation(true);
    router->searchGpxRoute(gctx, points, nullptr);

    return [OACppRouteConverter toSharedApproximation:gctx];
}

- (OAGpxRouteApproximation *) sharedApproximation:(OALocationsHolder *)locations params:(OARouteCalculationParams *)params
{
    OASRoutingConfigurationBuilder *builder = [OsmAndApp.instance getSharedRoutingConfigForMode:params.mode];
    OASGeneralRouter *generalRouter = [OsmAndApp.instance getSharedRouter:builder mode:params.mode];
    XCTAssertNotNil(generalRouter);
    OASRoutingConfiguration *cf = [_provider buildSharedRoutingConfig:builder params:params generalRouter:generalRouter];

    OASRoutePlannerFrontEnd *router = [[OASRoutePlannerFrontEnd alloc] init];
    OASRoutePlannerFrontEnd.companion.CALCULATE_MISSING_MAPS = NO;
    OASRoutingContext *ctx = [router buildRoutingContextConfig:cf map:_readers rm:OASRouteCalculationMode.normal];
    OARoutingEnvironment *env = [[OARoutingEnvironment alloc] initWithSharedRouter:router context:ctx];

    OASGpxRouteApproximation *gctx = [[OASGpxRouteApproximation alloc] initWithCtx:ctx];
    gctx.ctx.calculationProgress = [[OASRouteCalculationProgress alloc] init];
    gctx.ctx.config.minPointApproximation = kPointApproximation;

    NSArray<OASGpxPoint *> *points = [_provider generateSharedGpxPoints:env gctx:gctx locationsHolder:locations];
    OAGpxRouteApproximation *approximation = nil;
    [_provider calculateSharedGpxApproximation:env
                                          gctx:gctx
                                        points:points
                         useExternalTimestamps:NO
                                 resultMatcher:[self matcher:&approximation]];
    return approximation;
}

- (OAResultMatcher<OAGpxRouteApproximation *> *) matcher:(OAGpxRouteApproximation * __strong *)result
{
    return [[OAResultMatcher alloc] initWithPublishFunc:^BOOL(OAGpxRouteApproximation *__autoreleasing *approximation) {
        *result = (approximation && *approximation) ? *approximation : nil;
        return YES;
    } cancelledFunc:^BOOL {
        return NO;
    }];
}

@end
