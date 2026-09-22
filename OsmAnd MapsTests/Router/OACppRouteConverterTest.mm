//
//  OACppRouteConverterTest.mm
//  OsmAnd MapsTests
//
//  The app's route model is built on OsmAndShared segments, and while the C++ router is the one
//  computing routes its result is converted into them by OACppRouteConverter. This checks that the
//  conversion loses nothing the app reads: the same routes the turn lanes test calculates are
//  converted and then compared segment by segment against the C++ ones they came from - the stretch
//  of road each covers, its times and distances, its manoeuvre, and the road itself down to its
//  points, types, names and restrictions, including the names and refs that are only resolved
//  through the region's encoding rules.
//

#import <XCTest/XCTest.h>
#import <CoreLocation/CoreLocation.h>
#import "OsmAndSharedWrapper.h"
#import "OACppRouteConverter.h"

#include <OsmAndCore/QtExtensions.h>
#include <routePlannerFrontEnd.h>
#include <routingContext.h>
#include <routingConfiguration.h>
#include <routeSegmentResult.h>
#include <binaryRead.h>
#include <turnType.h>
#include <vector>

@interface OACppRouteConverterTest : XCTestCase

@end

@implementation OACppRouteConverterTest
{
    std::shared_ptr<RoutePlannerFrontEnd> _fe;
    int _comparedSegments;
    int _comparedRoutes;
}

- (void)setUp
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *obfFilePath = [bundle pathForResource:@"Turn_lanes_test" ofType:@"obf" inDirectory:@"test-resources"];
    initBinaryMapFile(string(obfFilePath.UTF8String), true, true);

    _fe = std::make_shared<RoutePlannerFrontEnd>();
    _comparedSegments = 0;
    _comparedRoutes = 0;
}

- (void)testConvertedRouteIsTheSameRoute
{
    NSString *jsonFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"test_turn_lanes" ofType:@"json" inDirectory:@"test-resources"];
    NSString *sourceJsonText = [NSString stringWithContentsOfFile:jsonFilePath encoding:NSUTF8StringEncoding error:nil];
    XCTAssertTrue(sourceJsonText.length > 0);

    NSArray *sourceJson = [NSJSONSerialization JSONObjectWithData:[sourceJsonText dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    XCTAssertTrue([sourceJson isKindOfClass:NSArray.class]);

    for (NSDictionary *testCase in sourceJson)
    {
        if ([testCase[@"ignoreNative"] boolValue])
            continue;

        [self compareRoute:testCase];
    }

    // The fixture has to keep producing routes: a conversion that is never exercised passes anything.
    XCTAssertGreaterThan(_comparedRoutes, 10, @"Too few routes calculated to compare");
    XCTAssertGreaterThan(_comparedSegments, 100, @"Too few segments converted to compare");
    // The host's log goes nowhere on the Mac, so the totals are recorded as an activity instead.
    [XCTContext runActivityNamed:[NSString stringWithFormat:@"%d routes, %d segments converted", _comparedRoutes, _comparedSegments]
                           block:^(id<XCTActivity> activity) {}];
}

- (void)compareRoute:(NSDictionary *)testCase
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

    NSArray<OASRouteSegmentResult *> *converted = [OACppRouteConverter toSharedSegments:route];
    XCTAssertEqual(route.size(), converted.count, @"%@: segment count", testCase[@"testName"]);
    if (route.size() != converted.count)
        return;

    _comparedRoutes++;
    for (int i = 0; i < (int) route.size(); i++)
    {
        NSString *message = [NSString stringWithFormat:@"%@, segment %d", testCase[@"testName"], i];
        [self compareSegment:route[i] shared:converted[i] message:message];
        _comparedSegments++;
    }

    // Resolving a name through the region's rules is left to a pass of its own: the C++ road caches
    // an empty name for a rule it does not carry, which would show up as a road the copy is missing.
    for (int i = 0; i < (int) route.size(); i++)
    {
        NSString *message = [NSString stringWithFormat:@"%@, segment %d", testCase[@"testName"], i];
        [self compareNames:route[i] shared:converted[i] message:message];
    }

    // The road a segment sits on is shared with every other segment on the same road, as it is when
    // the shared planner builds them.
    for (int i = 1; i < (int) route.size(); i++)
    {
        if (route[i]->object == route[i - 1]->object)
            XCTAssertEqual([converted[i] getObject], [converted[i - 1] getObject], @"%@: road not shared", testCase[@"testName"]);
    }
}

- (void)compareSegment:(const std::shared_ptr<RouteSegmentResult> &)cpp
                shared:(OASRouteSegmentResult *)shared
               message:(NSString *)message
{
    XCTAssertEqual(cpp->getStartPointIndex(), [shared getStartPointIndex], @"%@: start point index", message);
    XCTAssertEqual(cpp->getEndPointIndex(), [shared getEndPointIndex], @"%@: end point index", message);
    XCTAssertEqual(cpp->getGpxPointIndex(), [shared getGpxPointIndex], @"%@: gpx point index", message);
    XCTAssertEqualWithAccuracy(cpp->distance, [shared getDistance], 0.001, @"%@: distance", message);
    XCTAssertEqualWithAccuracy(cpp->segmentTime, [shared getSegmentTime], 0.001, @"%@: segment time", message);
    XCTAssertEqualWithAccuracy(cpp->routingTime, [shared getRoutingTime], 0.001, @"%@: routing time", message);
    XCTAssertEqualWithAccuracy(cpp->segmentSpeed, [shared getSegmentSpeed], 0.001, @"%@: segment speed", message);
    XCTAssertEqualWithAccuracy(cpp->getStartPoint().lat, [shared getStartPoint].latitude, 1e-7, @"%@: start latitude", message);
    XCTAssertEqualWithAccuracy(cpp->getStartPoint().lon, [shared getStartPoint].longitude, 1e-7, @"%@: start longitude", message);
    XCTAssertEqualWithAccuracy(cpp->getEndPoint().lat, [shared getEndPoint].latitude, 1e-7, @"%@: end latitude", message);
    XCTAssertEqualWithAccuracy(cpp->getEndPoint().lon, [shared getEndPoint].longitude, 1e-7, @"%@: end longitude", message);
    XCTAssertEqualWithAccuracy(cpp->getBearingBegin(), [shared getBearingBegin], 0.001, @"%@: bearing begin", message);
    XCTAssertEqualWithAccuracy(cpp->getBearingEnd(), [shared getBearingEnd], 0.001, @"%@: bearing end", message);
    XCTAssertEqual(cpp->hasExitInfo(), [shared hasExitInfo], @"%@: exit info", message);
    XCTAssertEqualObjects([self string:cpp->description], [shared getDescriptionFull:NO], @"%@: description", message);

    // The roads that meet the segment at its points: the exit information is read off them.
    int capacity = abs(cpp->getEndPointIndex() - cpp->getStartPointIndex()) + 1;
    for (int point = 0; point < capacity; point++)
    {
        int roadIndex = cpp->getStartPointIndex() + point;
        const auto cppAttached = cpp->getAttachedRoutes(roadIndex);
        NSArray<OASRouteSegmentResult *> *sharedAttached = [shared getAttachedRoutesRouteInd:roadIndex];
        XCTAssertEqual((int) cppAttached.size(), (int) sharedAttached.count, @"%@: attached road count at point %d", message, point);
        for (int k = 0; k < (int) cppAttached.size() && k < (int) sharedAttached.count; k++)
        {
            XCTAssertEqual(cppAttached[k]->object->id, [sharedAttached[k] getObject].id, @"%@: attached road %d at point %d", message, k, point);
            XCTAssertEqual(cppAttached[k]->getStartPointIndex(), [sharedAttached[k] getStartPointIndex],
                           @"%@: attached road %d at point %d start", message, k, point);
        }
    }

    [self compareTurnType:cpp->turnType shared:[shared getTurnType] message:message];
    [self compareObject:cpp->object shared:[shared getObject] message:message];
}

- (void)compareTurnType:(const std::shared_ptr<TurnType> &)cpp shared:(OASTurnType *)shared message:(NSString *)message
{
    if (cpp == nullptr)
    {
        XCTAssertNil(shared, @"%@: turn type", message);
        return;
    }
    XCTAssertNotNil(shared, @"%@: turn type", message);
    if (shared == nil)
        return;

    XCTAssertEqual(cpp->getValue(), shared.value, @"%@: turn value", message);
    XCTAssertEqual(cpp->getExitOut(), shared.exitOut, @"%@: turn exit", message);
    XCTAssertEqualWithAccuracy(cpp->getTurnAngle(), shared.turnAngle, 0.001, @"%@: turn angle", message);
    XCTAssertEqual(cpp->isSkipToSpeak(), shared.isSkipToSpeak, @"%@: turn skip to speak", message);
    XCTAssertEqual(cpp->isPossibleLeftTurn(), shared.isPossibleLeftTurn, @"%@: turn possible left", message);
    XCTAssertEqual(cpp->isPossibleRightTurn(), shared.isPossibleRightTurn, @"%@: turn possible right", message);
    XCTAssertEqual(cpp->isLeftSide(), [shared isLeftSide], @"%@: turn left side", message);

    const auto &lanes = cpp->getLanes();
    XCTAssertEqual((int) lanes.size(), shared.lanes != nil ? shared.lanes.size : 0, @"%@: lane count", message);
    for (int i = 0; i < (int) lanes.size() && shared.lanes != nil && i < shared.lanes.size; i++)
        XCTAssertEqual(lanes[i], [shared.lanes getIndex:i], @"%@: lane %d", message, i);
}

- (void)compareObject:(const std::shared_ptr<RouteDataObject> &)cpp shared:(OASRouteDataObject *)shared message:(NSString *)message
{
    XCTAssertNotNil(shared, @"%@: road", message);
    if (shared == nil)
        return;

    XCTAssertEqual(cpp->id, shared.id, @"%@: road id", message);
    XCTAssertEqual(cpp->getPointsLength(), [shared getPointsLength], @"%@: road point count", message);
    for (int i = 0; i < cpp->getPointsLength() && i < [shared getPointsLength]; i++)
    {
        XCTAssertEqual((int) cpp->pointsX[i], [shared getPoint31XTileI:i], @"%@: road point %d x", message, i);
        XCTAssertEqual((int) cpp->pointsY[i], [shared getPoint31YTileI:i], @"%@: road point %d y", message, i);
    }

    [self compareInts:cpp->types shared:shared.types message:[message stringByAppendingString:@": road types"]];
    for (int i = 0; i < cpp->getPointsLength(); i++)
    {
        [self compareInts:(i < (int) cpp->pointTypes.size() ? cpp->pointTypes[i] : vector<uint32_t>())
                   shared:shared.pointTypes != nil && i < shared.pointTypes.size ? [shared.pointTypes getIndex:i] : nil
                  message:[NSString stringWithFormat:@"%@: point %d types", message, i]];
        [self compareInts:(i < (int) cpp->pointNameTypes.size() ? cpp->pointNameTypes[i] : vector<uint32_t>())
                   shared:shared.pointNameTypes != nil && i < shared.pointNameTypes.size ? [shared.pointNameTypes getIndex:i] : nil
                  message:[NSString stringWithFormat:@"%@: point %d name types", message, i]];

        const vector<string> &pointNames = i < (int) cpp->pointNames.size() ? cpp->pointNames[i] : vector<string>();
        OASKotlinArray<NSString *> *sharedNames = shared.pointNames != nil && i < shared.pointNames.size ? [shared.pointNames getIndex:i] : nil;
        XCTAssertEqual((int) pointNames.size(), sharedNames != nil ? sharedNames.size : 0, @"%@: point %d name count", message, i);
        for (int k = 0; k < (int) pointNames.size() && sharedNames != nil && k < sharedNames.size; k++)
            XCTAssertEqualObjects([self string:pointNames[k]], [sharedNames getIndex:k], @"%@: point %d name %d", message, i, k);
    }

    XCTAssertEqual((int) cpp->names.size(), shared.names != nil ? [shared.names size] : 0, @"%@: road name count", message);
    for (const auto &name : cpp->names)
        XCTAssertEqualObjects([self string:name.second], [shared.names getKey:name.first], @"%@: road name %d", message, name.first);

    XCTAssertEqual((int) cpp->namesIds.size(), shared.nameIds != nil ? shared.nameIds.size : 0, @"%@: road name id count", message);
    for (int i = 0; i < (int) cpp->namesIds.size() && shared.nameIds != nil && i < shared.nameIds.size; i++)
        XCTAssertEqual((int) cpp->namesIds[i].first, [shared.nameIds getIndex:i], @"%@: road name id %d", message, i);

    XCTAssertEqual((int) cpp->restrictions.size(), [shared getRestrictionLength], @"%@: restriction count", message);
    for (int i = 0; i < (int) cpp->restrictions.size() && i < [shared getRestrictionLength]; i++)
    {
        XCTAssertEqual((int64_t) cpp->restrictions[i].to, [shared getRestrictionIdI:i], @"%@: restriction %d to", message, i);
        XCTAssertEqual((int) cpp->restrictions[i].type, [shared getRestrictionTypeI:i], @"%@: restriction %d type", message, i);
        XCTAssertEqual((int64_t) cpp->restrictions[i].via, [shared getRestrictionViaI:i], @"%@: restriction %d via", message, i);
    }

    const auto heights = cpp->calculateHeightArray();
    OASKotlinFloatArray *sharedHeights = [shared calculateHeightArrayCurrentLocation:nil];
    XCTAssertEqual((int) heights.size(), sharedHeights != nil ? sharedHeights.size : 0, @"%@: height count", message);
    for (int i = 0; i < (int) heights.size() && sharedHeights != nil && i < sharedHeights.size; i++)
        XCTAssertEqualWithAccuracy(heights[i], [sharedHeights getIndex:i], 0.01, @"%@: height %d", message, i);

    // These read the region's encoding rules, so they only agree when the rules were rebuilt right.
    XCTAssertEqualObjects([self string:cpp->getHighway()], [self orEmpty:[shared getHighway]], @"%@: highway", message);
    XCTAssertEqual(cpp->getOneway(), [shared getOneway], @"%@: oneway", message);
    XCTAssertEqual(cpp->roundabout(), [shared roundabout], @"%@: roundabout", message);
    XCTAssertEqual(cpp->tunnel(), [shared tunnel], @"%@: tunnel", message);
    XCTAssertEqualObjects([self string:cpp->getExitRef()], [self orEmpty:[shared getExitRef]], @"%@: exit ref", message);
    XCTAssertEqualObjects([self string:cpp->getExitName()], [self orEmpty:[shared getExitName]], @"%@: exit name", message);
}

- (void)compareNames:(const std::shared_ptr<RouteSegmentResult> &)cpp
              shared:(OASRouteSegmentResult *)shared
             message:(NSString *)message
{
    // The two street name and destination name lookups that walk the following segments are not
    // compared: the C++ ones do not do what java's do. C++ looks ahead for a street name only when
    // it already has one (`streetName.size() > 0` where java asks whether it is empty), so it never
    // inherits a name from the road after an unnamed one, and its destination lookup compares the
    // next road's destination name where java compares its destination ref. Both are the port
    // drifting, and the shared classes are the ones that agree with android.
    string lang = "";
    XCTAssertEqualObjects([self string:cpp->getRef(lang, false)],
                          [self orEmpty:[shared getRefLang:@"" transliterate:NO]],
                          @"%@: ref", message);
    XCTAssertEqualObjects([self string:cpp->object->getName(lang, false)],
                          [self orEmpty:[[shared getObject] getNameLang:@"" transliterate:NO]],
                          @"%@: road name", message);
    XCTAssertEqualObjects([self string:cpp->object->getRef(lang, false, true)],
                          [self orEmpty:[[shared getObject] getRefLang:@"" transliterate:NO direction:YES]],
                          @"%@: road ref", message);
}

- (void)compareInts:(const vector<uint32_t> &)cpp shared:(OASKotlinIntArray *)shared message:(NSString *)message
{
    XCTAssertEqual((int) cpp.size(), shared != nil ? shared.size : 0, @"%@: count", message);
    for (int i = 0; i < (int) cpp.size() && shared != nil && i < shared.size; i++)
        XCTAssertEqual((int) cpp[i], [shared getIndex:i], @"%@ %d", message, i);
}

- (NSString *)string:(const string &)value
{
    NSString *res = [NSString stringWithUTF8String:value.c_str()];
    return res ? res : @"";
}

- (NSString *)orEmpty:(NSString *)value
{
    return value ? value : @"";
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
