//
//  OARouteResultPreparationTest.m
//  OsmAnd MapsTests
//
//  Created by Paul on 25.09.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OARouteProvider.h"
#import "OARouteCalculationParams.h"
#import "OsmAndApp.h"
#import "OAUtilities.h"
#import <CoreLocation/CoreLocation.h>

#include <OsmAndCore/QtExtensions.h>
#include <routePlannerFrontEnd.h>
#include <routingContext.h>
#include <routeSegmentResult.h>
#include <turnType.h>
#include <binaryRead.h>
#include <vector>

@interface OARouteResultPreparationTest : XCTestCase

@end

@implementation OARouteResultPreparationTest
{
    std::shared_ptr<RoutePlannerFrontEnd> _fe;
}

- (void)setUp {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *obfFilePath = [bundle pathForResource:@"Turn_lanes_test" ofType:@"obf" inDirectory:@"test-resources"];
    initBinaryMapFile(string(obfFilePath.UTF8String), true, true);

    _fe = std::make_shared<RoutePlannerFrontEnd>();
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testTurnLanes
{
    NSString *jsonFilePath = [[NSBundle bundleForClass:[self class]] pathForResource:@"test_turn_lanes" ofType:@"json" inDirectory:@"test-resources"];

    NSError *err = nil;
    NSString *sourceJsonText = [NSString stringWithContentsOfFile:jsonFilePath encoding:NSUTF8StringEncoding error:&err];
    XCTAssertNil(err);
    XCTAssertNotNil(sourceJsonText);
    XCTAssertTrue(sourceJsonText.length > 0);

    NSError *error;
    NSDictionary *sourceJson = [NSJSONSerialization JSONObjectWithData:[sourceJsonText dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
    XCTAssertNil(error);
    // this is not a turn lanes test
    if (![sourceJson isKindOfClass:NSArray.class])
        return;

    for (NSDictionary *testCase in sourceJson)
    {
        if ([testCase[@"ignoreNative"] boolValue])
            continue;
        [self testLanes:testCase];
    }
}

- (void) testLanes:(NSDictionary *)testCase
{
    NSLog(@"Testing: %@", testCase[@"testName"]);
    const auto ctx = [self buildRoutingContext:testCase[@"params"]];
    CLLocation *start = [[CLLocation alloc] initWithLatitude:[testCase[@"startPoint"][@"latitude"] doubleValue] longitude:[testCase[@"startPoint"][@"longitude"] doubleValue]];
    CLLocation *end = [[CLLocation alloc] initWithLatitude:[testCase[@"endPoint"][@"latitude"] doubleValue] longitude:[testCase[@"endPoint"][@"longitude"] doubleValue]];
    int startX = get31TileNumberX(start.coordinate.longitude);
    int startY = get31TileNumberY(start.coordinate.latitude);
    int endX = get31TileNumberX(end.coordinate.longitude);
    int endY = get31TileNumberY(end.coordinate.latitude);
    vector<int> intX;
    vector<int> intY;
    const auto routeSegments = _fe->searchRoute(ctx, startX, startY, endX, endY, intX, intY);

    NSDictionary *expectedResults = testCase[@"expectedResults"];
    NSMutableSet<NSString *> *reachedSegmentsWithStartPoint = [NSMutableSet new];
    NSMutableDictionary<NSNumber *, NSValue *> *reachedSegments = [NSMutableDictionary new];
    NSMutableSet<NSNumber *> *checkedSegments = [NSMutableSet new];
    NSInteger prevSegment = -1;
    for (NSInteger i = 0; i <= routeSegments.size(); i++) {
        if (i == routeSegments.size() || routeSegments[i]->turnType != nullptr)
        {
            if (prevSegment >= 0)
            {
                auto segment = routeSegments[prevSegment];
                NSString *lanes = [self getLanesString:segment];
                NSString *turn = [NSString stringWithUTF8String:segment->turnType->toXmlString().c_str()];
                NSString *turnLanes = [NSString stringWithFormat:@"%@:%@", turn, lanes];
                NSString *name = [NSString stringWithUTF8String:segment->description.c_str()];
                bool skipToSpeak = segment->turnType->isSkipToSpeak();
                long segmentId = segment->object->id >> 6;

                if (skipToSpeak)
                    turnLanes = [@"[MUTE] " stringByAppendingString:turnLanes];

                NSString *expectedResult = nil;
                NSInteger startPoint = -1;
                NSInteger segmentStartPoint = segment->getStartPointIndex();
                for (NSString *roadInfo in expectedResults)
                {
                    if ([self getRoadId:roadInfo] != segmentId)
                        continue;
                    NSInteger roadStartPoint = [self getRoadStartPoint:roadInfo];
                    if (roadStartPoint == segmentStartPoint)
                    {
                        expectedResult = expectedResults[roadInfo];
                        startPoint = roadStartPoint;
                        break;
                    }
                    if (roadStartPoint < 0 && expectedResult == nil)
                    {
                        expectedResult = expectedResults[roadInfo];
                        startPoint = roadStartPoint;
                    }
                }

                if (expectedResult != nil && ![expectedResult isKindOfClass:NSNull.class])
                {
                    if (startPoint < 0 || segment->getStartPointIndex() == startPoint)
                    {
                        if (![expectedResult isEqualToString:turnLanes] &&
                            ![expectedResult isEqualToString:lanes] &&
                            ![expectedResult isEqualToString:turn])
                        {
                            XCTAssertEqualObjects(expectedResult, turnLanes, @"Segment %ld", segmentId);
                        }
                    }
                }

                NSLog(@"segmentId: %ld description: %@", segmentId, name);
            }
            prevSegment = i;
            if (i < routeSegments.size())
                [checkedSegments addObject:@(routeSegments[i]->object->id >> 6)];
        }

        if (i < routeSegments.size())
        {
            long segmentId = routeSegments[i]->object->id >> 6;
            int startPointIndex = routeSegments[i]->getStartPointIndex();
            [reachedSegmentsWithStartPoint addObject:[NSString stringWithFormat:@"%ld:%d", segmentId, startPointIndex]];
            reachedSegments[@(segmentId)] = [NSValue valueWithPointer:routeSegments[i].get()];
        }
    }

    for (NSString *roadInfo in expectedResults)
    {
        long segmentId = [self getRoadId:roadInfo];
        NSInteger startPoint = [self getRoadStartPoint:roadInfo];
        XCTAssertTrue(startPoint < 0 ? reachedSegments[@(segmentId)] != nil : [reachedSegmentsWithStartPoint containsObject:roadInfo],
                      @"Segment %@ was not reached in %@", roadInfo, reachedSegmentsWithStartPoint);

        if (![checkedSegments containsObject:@(segmentId)])
        {
            NSString *expectedResult = expectedResults[roadInfo];
            if (![self isEmptyExpectedValue:expectedResult])
                XCTAssertEqualObjects(expectedResult, @"NULL", @"Segment %ld", segmentId);
        }
    }

    NSDictionary *expectedExits = testCase[@"expectedExits"];
    for (NSString *roadInfo in expectedExits)
    {
        long segmentId = [self getRoadId:roadInfo];
        NSValue *segmentValue = reachedSegments[@(segmentId)];
        XCTAssertNotNil(segmentValue, @"Segment %ld was not reached", segmentId);
        if (segmentValue == nil)
            continue;

        auto segment = static_cast<RouteSegmentResult *>(segmentValue.pointerValue);
        NSString *expectedRef = expectedExits[roadInfo];
        bool hasExitInfo = segment->hasExitInfo();
        if ([self isEmptyExpectedValue:expectedRef])
        {
            XCTAssertFalse(hasExitInfo, @"Segment %ld has unexpected exit info", segmentId);
        }
        else
        {
            NSString *actualRef = [NSString stringWithUTF8String:segment->object->getExitRef().c_str()];
            XCTAssertTrue(hasExitInfo && [expectedRef isEqualToString:actualRef], @"Segment %ld exit mismatch", segmentId);
        }
    }
}

- (NSString *) getLanesString:(const std::shared_ptr<RouteSegmentResult> &)segment
{
    auto lanes = segment->turnType->getLanes();
    return [NSString stringWithUTF8String:TurnType::toString(lanes).c_str()];
}

- (std::shared_ptr<RoutingConfigurationBuilder>) getDefaultRoutingConfig
{
    float tm = [[NSDate date] timeIntervalSince1970];
    @try
    {
        return parseRoutingConfigurationFromXml([[[NSBundle mainBundle] pathForResource:@"routing" ofType:@"xml"] UTF8String], "");
    }
    @finally
    {
        float te = [[NSDate date] timeIntervalSince1970];
        if (te - tm > 30)
            NSLog(@"Defalt routing config init took %f ms", (te - tm));
    }
}

- (std::shared_ptr<RoutingContext>)buildRoutingContext:(NSDictionary<NSString *, NSString *> *)testParams
{
    auto builder = [self getDefaultRoutingConfig];
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
    const auto config = builder->build(vehicle, 30 * 3, params);
    const auto ctx = _fe->buildRoutingContext(config);
    ctx->leftSideNavigation = false;
    return ctx;
}

- (long)getRoadId:(NSString *)roadInfo
{
    NSArray<NSString *> *parts = [roadInfo componentsSeparatedByString:@":"];
    return parts.firstObject.longLongValue;
}

- (NSInteger)getRoadStartPoint:(NSString *)roadInfo
{
    NSArray<NSString *> *parts = [roadInfo componentsSeparatedByString:@":"];
    return parts.count > 1 ? parts[1].integerValue : -1;
}

- (BOOL)isEmptyExpectedValue:(NSString *)value
{
    return value == nil || [value isKindOfClass:NSNull.class] || value.length == 0;
}

@end
