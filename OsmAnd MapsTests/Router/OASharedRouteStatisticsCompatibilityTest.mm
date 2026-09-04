//
//  OASharedRouteStatisticsCompatibilityTest.mm
//  OsmAnd MapsTests
//

#import <XCTest/XCTest.h>

#import "OARouteStatisticsHelper.h"
#import "OsmAndSharedWrapper.h"

#include <binaryRead.h>
#include <routeSegmentResult.h>

#include <cstdint>
#include <utility>
#include <vector>

namespace
{

NSDictionary<NSString *, NSNumber *> *OAUndefinedRenderingAttribute(void)
{
    return @{kUndefinedAttr : @(UINT32_MAX)};
}

std::shared_ptr<RouteSegmentResult> OAMakeRouteSegment(
    float distance,
    const std::vector<std::pair<std::string, std::string>> &routeTypes,
    const std::vector<double> &heightValues = {})
{
    std::shared_ptr<RoutingIndex> region = std::make_shared<RoutingIndex>();
    std::shared_ptr<RouteDataObject> road = std::make_shared<RouteDataObject>(region);
    for (const auto &routeType : routeTypes)
    {
        road->types.push_back((uint32_t) region->routeEncodingRules.size());
        region->routeEncodingRules.push_back(RouteTypeRule(routeType.first, routeType.second));
    }
    road->id = 1;
    road->pointsX = {1, 2};
    road->pointsY = {3, 4};
    road->heightDistanceArray = heightValues;

    std::shared_ptr<RouteSegmentResult> segment = std::make_shared<RouteSegmentResult>(road, 0, 1);
    segment->distance = distance;
    return segment;
}

NSString *OAAdditionalValue(NSString *additional, NSString *tag)
{
    NSString *prefix = [tag stringByAppendingString:@"="];
    NSRange start = [additional rangeOfString:prefix];
    if (start.location == NSNotFound)
        return nil;
    NSUInteger valueStart = NSMaxRange(start);
    NSRange remainder = NSMakeRange(valueStart, additional.length - valueStart);
    NSRange end = [additional rangeOfString:@";" options:0 range:remainder];
    return end.location == NSNotFound
        ? [additional substringFromIndex:valueStart]
        : [additional substringWithRange:NSMakeRange(valueStart, end.location - valueStart)];
}

} // namespace

@interface OASharedRouteStatisticsCompatibilityTest : XCTestCase

@end

@implementation OASharedRouteStatisticsCompatibilityTest

- (void)testSharedStatisticsPreserveMergingPartitionOrderColorsAndDistances
{
    std::vector<std::shared_ptr<RouteSegmentResult>> route = {
        OAMakeRouteSegment(2, {{"class", "z"}}),
        OAMakeRouteSegment(3, {{"class", "z"}}),
        OAMakeRouteSegment(5, {{"class", "a"}}),
        OAMakeRouteSegment(2, {{"class", "undefined"}}),
    };
    OARouteStatisticsComputer *computer = [[OARouteStatisticsComputer alloc]
        initWithCurrentRendererLookup:^NSDictionary<NSString *, NSNumber *> *(
            NSString *attribute, NSDictionary<NSString *, NSString *> *settings) {
            if ([attribute isEqualToString:@"routeInfo_missing"])
                return OAUndefinedRenderingAttribute();
            NSString *propertyName = OAAdditionalValue(settings[@"additional"], @"class");
            if (!propertyName || [propertyName isEqualToString:@"undefined"])
                return OAUndefinedRenderingAttribute();
            return @{propertyName : [propertyName isEqualToString:@"z"] ? @30 : @20};
        }
        defaultRendererLookup:^NSDictionary<NSString *, NSNumber *> *(
            NSString *attribute, NSDictionary<NSString *, NSString *> *settings) {
            return OAUndefinedRenderingAttribute();
        }];

    NSArray<OASRouteStatistic *> *result = [OARouteStatisticsHelper
        calculateRouteStatistic:route
        attributeNames:@[@"routeInfo_test", @"routeInfo_test", @"routeInfo_missing"]
        statisticsComputer:computer];

    XCTAssertEqual(result.count, 2);
    OASRouteStatistic *statistic = result.firstObject;
    XCTAssertEqualObjects(statistic.name, @"test");
    XCTAssertEqual(statistic.elements.count, 3);
    [self assertAttribute:statistic.elements[0] name:@"z" userName:@"z" color:30 distance:5];
    [self assertAttribute:statistic.elements[1] name:@"a" userName:@"a" color:20 distance:5];
    [self assertAttribute:statistic.elements[2]
                     name:kUndefinedAttr
                 userName:kUndefinedAttr
                    color:0
                 distance:2];
    XCTAssertEqualObjects(
        [statistic.partition valueForKey:@"userPropertyName"],
        (@[@"a", @"z", kUndefinedAttr]));
    [self assertAttribute:statistic.partition[0] name:@"a" userName:@"a" color:20 distance:5];
    [self assertAttribute:statistic.partition[1] name:@"z" userName:@"z" color:30 distance:5];
    [self assertAttribute:statistic.partition[2]
                     name:kUndefinedAttr
                 userName:kUndefinedAttr
                    color:0
                 distance:2];
    XCTAssertEqualWithAccuracy(statistic.totalDistanceMeters, 12, 0.001);
    XCTAssertEqualObjects(result[0].name, result[1].name);
    XCTAssertEqual(result[0].elements.count, result[1].elements.count);
}

- (void)testRendererClassifierUsesCurrentThenDefaultAndKeepsAndroidFilters
{
    __block BOOL currentCalled = NO;
    __block BOOL defaultCalled = NO;
    OARouteStatisticsComputer *computer = [[OARouteStatisticsComputer alloc]
        initWithCurrentRendererLookup:^NSDictionary<NSString *, NSNumber *> *(
            NSString *attribute, NSDictionary<NSString *, NSString *> *settings) {
            currentCalled = YES;
            XCTAssertEqualObjects(attribute, @"routeInfo_roadClass");
            XCTAssertEqualObjects(settings[@"tag"], @"highway");
            XCTAssertEqualObjects(settings[@"value"], @"primary");
            XCTAssertEqualObjects(settings[@"additional"], @"surface=asphalt;");
            return OAUndefinedRenderingAttribute();
        }
        defaultRendererLookup:^NSDictionary<NSString *, NSNumber *> *(
            NSString *attribute, NSDictionary<NSString *, NSString *> *settings) {
            defaultCalled = YES;
            return @{@"primary" : @123};
        }];
    std::vector<std::shared_ptr<RouteSegmentResult>> route = {
        OAMakeRouteSegment(7, {{"highway", "primary"}, {"surface", "asphalt"}}),
    };

    NSArray<OASRouteStatistic *> *result = [OARouteStatisticsHelper
        calculateRouteStatistic:route
        attributeNames:@[@"routeInfo_roadClass"]
        statisticsComputer:computer];

    XCTAssertTrue(currentCalled);
    XCTAssertTrue(defaultCalled);
    XCTAssertEqual(result.count, 1);
    [self assertAttribute:result.firstObject.elements.firstObject
                     name:@"primary"
                 userName:@"primary"
                    color:123
                 distance:7];
}

- (void)testSharedSlopeCalculationUsesAndroidTwentyToOneHundredBoundary
{
    NSMutableArray<NSString *> *additionalFilters = [NSMutableArray new];
    OARouteStatisticsComputer *computer = [[OARouteStatisticsComputer alloc]
        initWithCurrentRendererLookup:^NSDictionary<NSString *, NSNumber *> *(
            NSString *attribute, NSDictionary<NSString *, NSString *> *settings) {
            NSString *additional = settings[@"additional"];
            [additionalFilters addObject:additional];
            NSString *propertyName = OAAdditionalValue(additional, @"steepness");
            return @{propertyName : @0};
        }
        defaultRendererLookup:^NSDictionary<NSString *, NSNumber *> *(
            NSString *attribute, NSDictionary<NSString *, NSString *> *settings) {
            return OAUndefinedRenderingAttribute();
        }];
    std::vector<std::shared_ptr<RouteSegmentResult>> route = {
        OAMakeRouteSegment(110, {}, {0, 0, 110, 44}),
    };

    NSArray<OASRouteStatistic *> *result = [OARouteStatisticsHelper
        calculateRouteStatistic:route
        attributeNames:@[@"routeInfo_steepness"]
        statisticsComputer:computer];

    XCTAssertEqualObjects(additionalFilters, (@[
        @"steepness=-3_0;",
        @"steepness=20_100;",
        @"steepness=-3_0;",
    ]));
    OASRouteStatistic *statistic = result.firstObject;
    XCTAssertEqualObjects(statistic.name, @"steepness");
    XCTAssertEqual(statistic.elements.count, 3);
    [self assertAttribute:statistic.elements[0]
                     name:@"-3_0"
                 userName:@"-4% .. 0%"
                    color:0
                 distance:50];
    [self assertAttribute:statistic.elements[1]
                     name:@"20_100"
                 userName:@"20% .. 40%"
                    color:0
                 distance:10];
    [self assertAttribute:statistic.elements[2]
                     name:@"-3_0"
                 userName:@"-4% .. 0%"
                    color:0
                 distance:50];
    XCTAssertEqualObjects(
        [statistic.partition valueForKey:@"userPropertyName"],
        (@[@"-4% .. 0%", @"20% .. 40%"]));
    XCTAssertEqualWithAccuracy(statistic.totalDistanceMeters, 110, 0.001);
}

- (void)assertAttribute:(OASRouteStatisticElement *)attribute
                   name:(NSString *)name
               userName:(NSString *)userName
                  color:(NSInteger)color
               distance:(float)distance
{
    XCTAssertEqualObjects(attribute.propertyName, name);
    XCTAssertEqualObjects(attribute.userPropertyName, userName);
    XCTAssertEqual(attribute.color, color);
    XCTAssertEqualWithAccuracy(attribute.distanceMeters, distance, 0.001);
}

@end
