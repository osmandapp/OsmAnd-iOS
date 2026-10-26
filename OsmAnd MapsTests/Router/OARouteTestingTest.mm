//
//  OARouteTestingTest.mm
//  OsmAnd MapsTests
//
//  The iOS side of RouteTestingTest.java: the routes of test_routing.json calculated by the C++ planner
//  the app uses, each over its own map and Routing_test_archive.obf, and checked for the roads they must
//  and must not go along.
//

#import <XCTest/XCTest.h>

#include <OsmAndCore/QtExtensions.h>
#include <routePlannerFrontEnd.h>
#include <routingContext.h>
#include <routingConfiguration.h>
#include <routeSegmentResult.h>
#include <binaryRead.h>
#include <vector>

@interface OARouteTestingTest : XCTestCase

@end

@implementation OARouteTestingTest
{
    std::shared_ptr<RoutingConfigurationBuilder> _builder;
    NSString *_routingDir;
}

- (void)setUp
{
    NSString *routingPath = [[NSBundle mainBundle] pathForResource:@"routing" ofType:@"xml"];
    _builder = parseRoutingConfigurationFromXml(routingPath.UTF8String, "");
    XCTAssertTrue(_builder != nullptr, @"Could not load routing.xml from %@", routingPath);
    _routingDir = [[NSBundle bundleForClass:[self class]].resourcePath stringByAppendingPathComponent:@"test-resources/routing"];
}

- (void)testRouting
{
    if (!_builder)
        return; // setUp has already reported it
    NSString *jsonFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"test_routing" ofType:@"json" inDirectory:@"test-resources"];
    NSData *data = [NSData dataWithContentsOfFile:jsonFilePath];
    XCTAssertNotNil(data, @"test_routing.json is missing");
    NSArray *testEntries = data ? [NSJSONSerialization JSONObjectWithData:data options:0 error:nil] : nil;
    XCTAssertTrue([testEntries isKindOfClass:NSArray.class]);

    for (NSDictionary *te in testEntries)
    {
        if ([te[@"ignore"] boolValue] || [te[@"ignoreNative"] boolValue])
            continue;
        // native keeps opened files for the whole process, and routing of later tests would read roads from them
        vector<string> mapFiles;
        if (te[@"params"][@"map"])
            mapFiles.push_back([_routingDir stringByAppendingPathComponent:te[@"params"][@"map"]].UTF8String);
        mapFiles.push_back([_routingDir stringByAppendingPathComponent:@"Routing_test_archive.obf"].UTF8String);
        for (const auto &file : mapFiles)
            XCTAssertTrue(initBinaryMapFile(file, true, true) != nullptr, @"%@: could not open %s", te[@"testName"], file.c_str());

        [self checkRoute:te];

        for (const auto &file : mapFiles)
            closeBinaryMapFile(file);
    }
    BOOL stop = YES;
}

- (void)checkRoute:(NSDictionary *)te
{
    NSString *name = te[@"testName"];
    NSDictionary<NSString *, id> *testParams = te[@"params"];
    MAP_STR_STR params;
    for (NSString *key in testParams)
        params[key.UTF8String] = [testParams[key] description].UTF8String;
    string vehicle = params.count("vehicle") ? params["vehicle"] : "car";

    int startX = get31TileNumberX([te[@"startPoint"][@"longitude"] doubleValue]);
    int startY = get31TileNumberY([te[@"startPoint"][@"latitude"] doubleValue]);
    int endX = get31TileNumberX([te[@"endPoint"][@"longitude"] doubleValue]);
    int endY = get31TileNumberY([te[@"endPoint"][@"latitude"] doubleValue]);
    vector<int> intX, intY;
    for (NSString *key in @[@"transitPoint1", @"transitPoint2", @"transitPoint3"])
    {
        if (te[key])
        {
            intX.push_back(get31TileNumberX([te[key][@"longitude"] doubleValue]));
            intY.push_back(get31TileNumberY([te[key][@"latitude"] doubleValue]));
        }
    }

    for (int planRoadDirection = -1; planRoadDirection <= 1; planRoadDirection++)
    {
        if (params.count("wrongPlanRoadDirection") && params["wrongPlanRoadDirection"] == std::to_string(planRoadDirection))
            continue;
        auto config = _builder->build(vehicle, 30 * 3, params);
        if (params.count("routeCalculationTime"))
            config->routeCalculationTime = std::stoll(params["routeCalculationTime"]) / 1000; // conditional, ms in the json
        if (params.count("heuristicCoefficient"))
            config->heurCoefficient = std::stof(params["heuristicCoefficient"]);
        config->planRoadDirection = planRoadDirection;

        auto fe = std::make_shared<RoutePlannerFrontEnd>();
        if (params.count("hh") && params["hh"] == "true")
        {
            fe->setDefaultRoutingConfig();
            fe->USE_ONLY_HH_ROUTING = true;
        }
        auto ctx = fe->buildRoutingContext(config);
        ctx->leftSideNavigation = false;
        ctx->setConditionalTime(config->routeCalculationTime);
        auto routeSegments = fe->searchRoute(ctx, startX, startY, endX, endY, intX, intY);

        NSDictionary<NSString *, id> *expectedResults = te[@"expectedResults"];
        if (!expectedResults)
            break; // a test on hanging routing

        NSMutableSet<NSNumber *> *reachedSegments = [NSMutableSet set];
        NSMutableSet<NSString *> *reachedSegmentPoints = [NSMutableSet set];
        for (const auto &seg : routeSegments)
        {
            int64_t id = seg->object->id >> 6;
            [reachedSegments addObject:@(id)];
            for (int point = MIN(seg->getStartPointIndex(), seg->getEndPointIndex()); point <= MAX(seg->getStartPointIndex(), seg->getEndPointIndex()); point++)
                [reachedSegmentPoints addObject:[NSString stringWithFormat:@"%lld:%d", id, point]];
        }
        [self checkEtaTime:routeSegments params:params name:name];

        for (NSString *key in expectedResults)
        {
            NSArray<NSString *> *parts = [key componentsSeparatedByString:@":"];
            NSNumber *id = @(parts[0].longLongValue);
            if ([expectedResults[key] isEqual:@"visitedSegments"])
            {
                XCTAssertLessThan(ctx->progress->visitedSegments, id.intValue, @"%@: visited segments", name);
                continue;
            }
            BOOL expected = [expectedResults[key] boolValue];
            BOOL reached = parts.count > 1 ? [reachedSegmentPoints containsObject:key] : [reachedSegments containsObject:id];
            XCTAssertEqual(reached, expected, @"%@ (planRoadDirection %d): %@ expected %@ in route segments %@",
                           name, planRoadDirection, key, expected ? @"reached" : @"not reached", reachedSegments.allObjects);
        }
    }
}

- (void)checkEtaTime:(const vector<std::shared_ptr<RouteSegmentResult>> &)routeSegments params:(MAP_STR_STR &)params name:(NSString *)name
{
    if (!params.count("minEtaTime") && !params.count("maxEtaTime"))
        return;
    float etaTime = 0;
    for (const auto &seg : routeSegments)
        etaTime += seg->segmentTime;
    if (params.count("minEtaTime"))
        XCTAssertGreaterThanOrEqual(etaTime, std::stof(params["minEtaTime"]), @"%@: eta time", name);
    if (params.count("maxEtaTime"))
        XCTAssertLessThanOrEqual(etaTime, std::stof(params["maxEtaTime"]), @"%@: eta time", name);
}

@end
