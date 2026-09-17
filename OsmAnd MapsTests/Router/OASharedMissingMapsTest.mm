//
//  OASharedMissingMapsTest.mm
//  OsmAnd MapsTests
//
//  Behind the "Route with OsmAndShared" flag the maps a route needs are looked for among the files
//  the OsmAndShared planner reads, instead of among the ones the C++ planner has open. The check
//  itself is the same code either way; what is new is where it takes the maps from, and that is
//  what this is about: with the map of the region under the route among them nothing is missing,
//  and with only the map of somewhere else the region under the route is what has to be downloaded.
//
//  The check knows a map by its file name, so the fixture copied under a region's name is that
//  region's map as far as it is concerned. It is copied rather than used where it lies because its
//  own corner of the world is not in any region, and a point outside every region is not checked.
//

#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import "MissingMapsCalculator.h"
#import "OAMissingMapsResult.h"
#import "OARouteProvider.h"
#import "OARouteCalculationParams.h"
#import "OAApplicationMode.h"
#import "OAWorldRegion.h"
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"

// Two points of Kyiv, three kilometres apart: both in ukraine_kyiv-city_europe and ukraine_kyiv_europe.
static const CLLocationCoordinate2D kRouteStart = { 50.450001, 30.523333 };
static const CLLocationCoordinate2D kRouteEnd = { 50.47, 30.50 };

// The region the check names first for those points: the smallest area that has a map of its own.
static NSString * const kRegionUnderTheRoute = @"ukraine_kyiv-city_europe";

// The map that covers them, and the map of somewhere else entirely.
static NSString * const kRegionMap = @"Ukraine_kyiv_europe.obf";
static NSString * const kOtherRegionMap = @"Ukraine_lviv_europe.obf";

@interface OARouteProvider (OASharedMissingMapsTest)

- (OASRoutingConfiguration *) buildSharedRoutingConfig:(OASRoutingConfigurationBuilder *)builder
                                                params:(OARouteCalculationParams *)params
                                         generalRouter:(OASGeneralRouter *)generalRouter;

@end

@interface OASharedMissingMapsTest : XCTestCase

@end

@implementation OASharedMissingMapsTest
{
    OARouteProvider *_provider;
    MissingMapsCalculator *_calculator;
    NSString *_mapsDirectory;
    NSMutableArray<OASBinaryMapIndexReader *> *_readers;
}

- (void)setUp
{
    // The test host is the app itself and it starts in the background: the routing configuration the
    // provider asks for, and the region index the check reads, are only there once it has finished.
    NSDate *deadline = [NSDate dateWithTimeIntervalSinceNow:180];
    while (![OsmAndApp instance].initialized && deadline.timeIntervalSinceNow > 0)
        [NSRunLoop.currentRunLoop runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:0.1]];
    XCTAssertTrue([OsmAndApp instance].initialized, @"the app did not finish starting");
    XCTAssertGreaterThan([OsmAndApp.instance.worldRegion getWorldRegionsAtWithoutSort:kRouteStart.latitude
                                                                           longitude:kRouteStart.longitude].count,
                         0, @"the region index has no region where the route runs");

    _provider = [[OARouteProvider alloc] init];
    _calculator = [MissingMapsCalculator new];
    _readers = [NSMutableArray array];
    _mapsDirectory = [NSTemporaryDirectory() stringByAppendingPathComponent:@"OASharedMissingMapsTest"];
    [NSFileManager.defaultManager removeItemAtPath:_mapsDirectory error:nil];
    [NSFileManager.defaultManager createDirectoryAtPath:_mapsDirectory withIntermediateDirectories:YES attributes:nil error:nil];
}

- (void)tearDown
{
    for (OASBinaryMapIndexReader *reader in _readers)
        [reader close];
    [NSFileManager.defaultManager removeItemAtPath:_mapsDirectory error:nil];
}

- (void)testTheRegionUnderTheRouteIsNotMissingWithItsMap
{
    OASRouteCalculationProgress *progress = [[OASRouteCalculationProgress alloc] init];
    OAMissingMapsResult *result = [_calculator checkIfThereAreMissingSharedMaps:[self contextOver:kRegionMap progress:progress]
                                                                          start:[self locationAt:kRouteStart]
                                                                        targets:@[[self locationAt:kRouteEnd]]
                                                                checkHHEditions:YES];

    XCTAssertNil(result, @"the map of the region the route runs in is there, so there is nothing to download");
    XCTAssertFalse([progress hasMixedOrMissingMaps], @"the routing status was raised over a map that is there");
}

- (void)testTheRegionUnderTheRouteIsMissingWithoutIt
{
    OASRouteCalculationProgress *progress = [[OASRouteCalculationProgress alloc] init];
    OAMissingMapsResult *result = [_calculator checkIfThereAreMissingSharedMaps:[self contextOver:kOtherRegionMap progress:progress]
                                                                          start:[self locationAt:kRouteStart]
                                                                        targets:@[[self locationAt:kRouteEnd]]
                                                                checkHHEditions:YES];

    XCTAssertNotNil(result, @"only the map of another region is there, so the route is not covered");
    XCTAssertEqualObjects(result.missingMaps, @[kRegionUnderTheRoute], @"the region to download");
    XCTAssertEqual(result.mapsToUpdate.count, 0, @"nothing was out of date, only absent");
    XCTAssertEqual(result.usedMaps.count, 0, @"no map of the route was used");
    XCTAssertEqual(result.state, EOAMissingMapsStateMissingAtStartOrEnd, @"the start and the target themselves have no map");
    XCTAssertEqualObjects(result.profile, @"car", @"the profile the editions are matched against comes from the shared config");
    XCTAssertEqual(result.points.count, 2, @"the start and the one target");
    XCTAssertTrue([[result getErrorMessage] containsString:kRegionUnderTheRoute], @"%@", [result getErrorMessage]);
    XCTAssertTrue([progress hasMixedOrMissingMaps], @"the routing status the HH search reads was not raised");
}

// A routing context over one map file, set up the way the provider sets one up for a route.
- (OASRoutingContext *) contextOver:(NSString *)mapName progress:(OASRouteCalculationProgress *)progress
{
    OARouteCalculationParams *params = [[OARouteCalculationParams alloc] init];
    params.mode = [OAApplicationMode CAR];
    params.start = [self locationAt:kRouteStart];
    params.end = [self locationAt:kRouteEnd];

    OASRoutingConfigurationBuilder *builder = [OsmAndApp.instance getSharedRoutingConfigForMode:params.mode];
    OASGeneralRouter *generalRouter = [OsmAndApp.instance getSharedRouter:builder mode:params.mode];
    XCTAssertNotNil(generalRouter);
    OASRoutingConfiguration *cf = [_provider buildSharedRoutingConfig:builder params:params generalRouter:generalRouter];

    OASRoutePlannerFrontEnd *router = [[OASRoutePlannerFrontEnd alloc] init];
    OASRoutingContext *ctx = [router buildRoutingContextConfig:cf map:@[[self readerNamed:mapName]] rm:OASRouteCalculationMode.normal];
    ctx.calculationProgress = progress;
    return ctx;
}

// The fixture map under the name of a region, which is how the check learns what a map covers.
- (OASBinaryMapIndexReader *) readerNamed:(NSString *)mapName
{
    NSString *fixturePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"Turn_lanes_test" ofType:@"obf" inDirectory:@"test-resources"];
    NSString *path = [_mapsDirectory stringByAppendingPathComponent:mapName];
    NSError *error = nil;
    if (![NSFileManager.defaultManager fileExistsAtPath:path])
        [NSFileManager.defaultManager copyItemAtPath:fixturePath toPath:path error:&error];
    XCTAssertNil(error, @"could not put the map where the test reads it");

    OASBinaryMapIndexReader *reader = [[OASBinaryMapIndexReader alloc] initWithFilePath:path];
    [_readers addObject:reader];
    return reader;
}

- (CLLocation *) locationAt:(CLLocationCoordinate2D)coordinate
{
    return [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
}

@end
