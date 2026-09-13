//
//  OARoutePlannerBenchmarkTest.mm
//  OsmAnd MapsTests
//
//  The same routes calculated two ways inside the app: by the C++ router the app uses today, the
//  way OARouteProvider drives it, and by the OsmAndShared planner. Prints wall time, segments,
//  distance, the segments the search settled, the tiles it loaded and the process footprint after
//  each, so the two can be put side by side on the device the app runs on. The report lands in the
//  result bundle (activity titles and an attachment), since the host's log goes nowhere on the Mac.
//
//  The maps are the app's installed regional obf files the routes name, one per route, opened the
//  way OARouteProvider opens them; the profile is the car one from the app's own routing.xml, the
//  complex mode and 256 MB for both planners, as in the jvm and Kotlin benchmarks. Not part of a
//  normal test run: it takes minutes and prints numbers. Run it on its own:
//
//    xcodebuild test -workspace OsmAnd.xcworkspace -scheme 'OsmAnd Maps' -configuration Release \
//      -destination 'platform=macOS,variant=Designed for iPad' ENABLE_TESTABILITY=YES \
//      -only-testing:'OsmAnd MapsTests/OARoutePlannerBenchmarkTest'
//
//  Release, because Debug links the -O0 core and the debug Kotlin framework. The test targets sign
//  with "iPhone Distribution" in Release, which a development Mac does not have: for the run, set
//  their Release signing to Automatic / Apple Development as in Debug.
//

#import <XCTest/XCTest.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "OsmAndApp.h"
#import "OsmAndSharedWrapper.h"

#include <OsmAndCore/QtExtensions.h>
#include <routePlannerFrontEnd.h>
#include <routingConfiguration.h>
#include <routingContext.h>
#include <routeSegmentResult.h>
#include <routeCalculationProgress.h>
#include <binaryRead.h>
#include <mach/mach.h>
#include <vector>
#include <memory>

static const int MEMORY_LIMIT_MB = 256;
static const int WARMUP_ROUNDS = 1;
static const int MEASURED_ROUNDS = 2;

typedef struct {
    const char *name;
    const char *map; // the installed obf whose name starts with this
    double startLat, startLon, endLat, endLon;
} BenchRoute;

static const char *NOORD_HOLLAND = "Netherlands_noord-holland_europe";
static const char *BAVARIA = "Germany_bayern_upper-bavaria_europe";
static const char *LOWER_AUSTRIA = "Austria_lower-austria_europe";

// The same list as in RoutePlannerBenchmarkTest in OsmAnd-shared and OsmAnd-java; keep them together.
// One regional map per route, as there: the base pass of the complex mode uses the map's own base subregions.
static const BenchRoute ROUTES[] = {
    {"amsterdam schiphol 17 km", NOORD_HOLLAND, 52.3791, 4.9003, 52.3105, 4.7683},
    {"amsterdam haarlem 20 km", NOORD_HOLLAND, 52.3791, 4.9003, 52.3874, 4.6462},
    {"amsterdam den helder 80 km", NOORD_HOLLAND, 52.3791, 4.9003, 52.9563, 4.7606},
    {"munich airport 35 km", BAVARIA, 48.1374, 11.5755, 48.3538, 11.7861},
    {"munich rosenheim 65 km", BAVARIA, 48.1374, 11.5755, 47.8561, 12.1289},
    {"munich garmisch 90 km", BAVARIA, 48.1374, 11.5755, 47.4917, 11.0954},
    {"vienna schwechat 20 km", LOWER_AUSTRIA, 48.2082, 16.3738, 48.1103, 16.5697},
    {"st poelten krems 30 km", LOWER_AUSTRIA, 48.2047, 15.6256, 48.4103, 15.6136},
    {"st poelten wr neustadt 70 km", LOWER_AUSTRIA, 48.2047, 15.6256, 47.8100, 16.2450},
};

@interface OARoutePlannerBenchmarkTest : XCTestCase
@end

@implementation OARoutePlannerBenchmarkTest
{
    NSArray<NSString *> *_obfFiles;
    NSString *_routingXml;
    std::shared_ptr<RoutingConfigurationBuilder> _cppBuilder;
    OASRoutingConfigurationBuilder *_sharedBuilder;
}

- (void)setUp
{
    NSString *resources = [[OsmAndApp instance].documentsPath stringByAppendingPathComponent:@"Resources"];
    NSMutableArray<NSString *> *files = [NSMutableArray array];
    for (NSString *name in [[NSFileManager defaultManager] contentsOfDirectoryAtPath:resources error:nil])
    {
        if ([name.lowercaseString hasSuffix:@".obf"] && ![name hasPrefix:@"World"])
            [files addObject:[resources stringByAppendingPathComponent:name]];
    }
    _obfFiles = [files sortedArrayUsingSelector:@selector(compare:)];
    XCTAssertTrue(_obfFiles.count > 0, @"no obf files in %@", resources);

    _routingXml = [[NSBundle mainBundle] pathForResource:@"routing" ofType:@"xml"];
    XCTAssertNotNil(_routingXml);

    _cppBuilder = parseRoutingConfigurationFromXml(_routingXml.UTF8String, "");
    _sharedBuilder = [OASRoutingConfiguration.companion parseFromFileFilePath:_routingXml filename:nil
                                                                        config:[[OASRoutingConfigurationBuilder alloc] init]];
    OASRouteResultPreparation.shared.PRINT_TO_CONSOLE_ROUTE_INFORMATION = NO;
}

- (NSString *)mapFor:(const BenchRoute &)route
{
    NSString *prefix = [NSString stringWithUTF8String:route.map];
    for (NSString *path in _obfFiles)
        if ([path.lastPathComponent hasPrefix:prefix])
            return path;
    return nil;
}

static double footprintMb()
{
    task_vm_info_data_t info;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    if (task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &info, &count) == KERN_SUCCESS)
        return info.phys_footprint / 1048576.0;
    return 0;
}

- (NSString *)runCpp:(const BenchRoute &)route map:(NSString *)map
{
    // as OARouteProvider.checkInitialized opens a map for the C++ router; the reader stays open across the rounds
    std::string mapPath(map.UTF8String);
    cacheBinaryMapFileIfNeeded(mapPath, true);
    initBinaryMapFile(mapPath, false, true);
    double best = 1e18;
    NSString *line = @"";
    for (int round = 0; round < WARMUP_ROUNDS + MEASURED_ROUNDS; round++)
    {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        RoutePlannerFrontEnd router;
        router.CALCULATE_MISSING_MAPS = false;
        MAP_STR_STR params;
        auto cf = _cppBuilder->build("car", MEMORY_LIMIT_MB, params);
        auto ctx = router.buildRoutingContext(cf, RouteCalculationMode::COMPLEX);
        ctx->progress = std::make_shared<RouteCalculationProgress>();
        ctx->setConditionalTime(cf->routeCalculationTime);
        std::vector<int> intX, intY;
        auto result = router.searchRoute(ctx,
                                         get31TileNumberX(route.startLon), get31TileNumberY(route.startLat),
                                         get31TileNumberX(route.endLon), get31TileNumberY(route.endLat),
                                         intX, intY);
        double ms = (CFAbsoluteTimeGetCurrent() - start) * 1000.0;
        if (round >= WARMUP_ROUNDS && ms < best)
        {
            best = ms;
            double km = 0;
            for (const auto &r : result)
                km += r->distance;
            line = result.empty()
                ? [NSString stringWithFormat:@"error: no route (segmentNotFound=%d)", ctx->progress->segmentNotFound]
                : [NSString stringWithFormat:@"%9lu %8.1f %9d %7d %8.0f MB", (unsigned long) result.size(), km / 1000,
                   ctx->progress->visitedSegments, ctx->progress->loadedTiles, footprintMb()];
        }
    }
    closeBinaryMapFile(mapPath);
    return [NSString stringWithFormat:@"%8.1f %@", best, line];
}

- (NSString *)runShared:(const BenchRoute &)route map:(NSString *)map
{
    NSArray<OASBinaryMapIndexReader *> *readers = @[[[OASBinaryMapIndexReader alloc] initWithFilePath:map]];
    double best = 1e18;
    NSString *line = @"";
    for (int round = 0; round < WARMUP_ROUNDS + MEASURED_ROUNDS; round++)
    {
        CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
        OASRoutingConfigurationRoutingMemoryLimits *limits =
            [[OASRoutingConfigurationRoutingMemoryLimits alloc] initWithMemoryLimitMb:MEMORY_LIMIT_MB nativeMemoryLimitMb:MEMORY_LIMIT_MB];
        OASRoutingConfiguration *config = [_sharedBuilder buildRouter:@"car" memoryLimits:limits
                                                               params:(OASMutableDictionary<NSString *, NSString *> *) [NSMutableDictionary dictionary]];
        OASRoutePlannerFrontEnd *fe = [[OASRoutePlannerFrontEnd alloc] init];
        OASRoutingContext *ctx = [fe buildRoutingContextConfig:config map:readers rm:nil];
        OASRouteCalcResult *result = [fe searchRouteCtx:ctx
                                                  start:[[OASKLatLon alloc] initWithLatitude:route.startLat longitude:route.startLon]
                                                    end:[[OASKLatLon alloc] initWithLatitude:route.endLat longitude:route.endLon]
                                          intermediates:nil];
        double ms = (CFAbsoluteTimeGetCurrent() - start) * 1000.0;
        if (round >= WARMUP_ROUNDS && ms < best)
        {
            best = ms;
            NSString *error = [result getError_];
            if (error)
            {
                line = [NSString stringWithFormat:@"error: %@", error];
            }
            else
            {
                double km = 0;
                for (OASRouteSegmentResult *s in result.detailed)
                    km += [s getDistance];
                line = [NSString stringWithFormat:@"%9lu %8.1f %9d %7d %8.0f MB", (unsigned long) result.detailed.count, km / 1000,
                        ctx.calculationProgress.visitedSegments, ctx.calculationProgress.loadedTiles, footprintMb()];
            }
        }
    }
    for (OASBinaryMapIndexReader *reader in readers)
        [reader close];
    return [NSString stringWithFormat:@"%8.1f %@", best, line];
}

- (void)testBenchmarkRoutes
{
    NSMutableString *report = [NSMutableString string];
    [report appendFormat:@"\n### route planner in the app on %@ (%@): C++ router as OARouteProvider drives it, shared planner; %d warmup / %d measured, best time\n",
     [UIDevice currentDevice].model, [NSProcessInfo processInfo].operatingSystemVersionString, WARMUP_ROUNDS, MEASURED_ROUNDS];
    [report appendFormat:@"  maps: %@\n", [[_obfFiles valueForKey:@"lastPathComponent"] componentsJoinedByString:@", "]];
    [report appendFormat:@"  %-30s %-6s %8s %9s %8s %9s %7s %11s\n", "route", "by", "ms", "segments", "km", "visited", "tiles", "footprint"];
    for (const BenchRoute &route : ROUTES)
    {
        NSString *map = [self mapFor:route];
        if (!map)
        {
            [report appendFormat:@"  %-30s map not found: %s\n", route.name, route.map];
            continue;
        }
        NSString *cpp = [self runCpp:route map:map];
        [report appendFormat:@"  %-30s %-6s %@\n", route.name, "cpp", cpp];
        NSString *shared = [self runShared:route map:map];
        [report appendFormat:@"  %-30s %-6s %@\n", route.name, "shared", shared];
        // NSLog from the test host reaches nothing when the host runs on the Mac; the result bundle keeps
        // activity titles and attachments: xcrun xcresulttool get test-results activities --path <xcresult>
        for (NSString *line in @[[NSString stringWithFormat:@"BENCH %s cpp %@", route.name, cpp],
                                 [NSString stringWithFormat:@"BENCH %s shared %@", route.name, shared]])
            [XCTContext runActivityNamed:line block:^(id<XCTActivity> _Nonnull activity) {}];
    }
    XCTAttachment *attachment = [XCTAttachment attachmentWithString:report];
    attachment.name = @"route planner benchmark";
    attachment.lifetime = XCTAttachmentLifetimeKeepAlways;
    [self addAttachment:attachment];
    XCTAssertTrue(report.length > 0);
}

@end
