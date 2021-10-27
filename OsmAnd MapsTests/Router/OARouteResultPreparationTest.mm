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
    std::shared_ptr<RoutingContext> _ctx;
}

- (void)setUp {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *obfFilePath = [bundle pathForResource:@"Turn_lanes_test" ofType:@"obf" inDirectory:@"test-resources"];
    initBinaryMapFile(string(obfFilePath.UTF8String), true, true);
    
    _fe = std::make_shared<RoutePlannerFrontEnd>();
    auto builder = [self getDefaultRoutingConfig];
    MAP_STR_STR params;
    params["car"] = "true";
    const auto config = builder->build("car", 30 * 3, params);
    _ctx = _fe->buildRoutingContext(config);
    _ctx->leftSideNavigation = false;
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
        [self testLanes:testCase];
}

- (void) testLanes:(NSDictionary *)testCase
{
    NSLog(@"Testing: %@", testCase[@"testName"]);
    CLLocation *start = [[CLLocation alloc] initWithLatitude:[testCase[@"startPoint"][@"latitude"] doubleValue] longitude:[testCase[@"startPoint"][@"longitude"] doubleValue]];
    CLLocation *end = [[CLLocation alloc] initWithLatitude:[testCase[@"endPoint"][@"latitude"] doubleValue] longitude:[testCase[@"endPoint"][@"longitude"] doubleValue]];
    int startX = get31TileNumberX(start.coordinate.longitude);
    int startY = get31TileNumberY(start.coordinate.latitude);
    int endX = get31TileNumberX(end.coordinate.longitude);
    int endY = get31TileNumberY(end.coordinate.latitude);
    vector<int> intX;
    vector<int> intY;
    const auto routeSegments = _fe->searchRoute(_ctx, startX, startY, endX, endY, intX, intY);
    
    NSMutableSet<NSNumber *> *reachedSegments = [NSMutableSet new];
    NSDictionary *expectedResults = testCase[@"expectedResults"];
    NSInteger prevSegment = -1;
    for (NSInteger i = 0; i <= routeSegments.size(); i++) {
        if (i == routeSegments.size() || routeSegments[i]->turnType != nullptr)
        {
            if (prevSegment >= 0)
            {
                NSString *lanes = [self getLanesString:routeSegments[prevSegment]];
                NSString *turn = [NSString stringWithUTF8String:routeSegments[prevSegment]->turnType->toXmlString().c_str()];
                NSString *turnLanes = [NSString stringWithFormat:@"%@:%@", turn, lanes];
                
                NSString *name = [NSString stringWithUTF8String:routeSegments[prevSegment]->description.c_str()];
                
                long segmentId = routeSegments[prevSegment]->object->id >> 6;
                NSString *expectedResult = expectedResults[@(segmentId).stringValue];
                if (expectedResult != nil && ![expectedResult isKindOfClass:NSNull.class])
                {
                    if(![expectedResult isEqualToString:turnLanes] &&
                       ![expectedResult isEqualToString:lanes] &&
                       ![expectedResult isEqualToString:turn])
                    {
                        XCTAssertEqualObjects(expectedResult, turnLanes, @"Segment %ld", segmentId);
                        NSLog(@"Test case %@ failed", testCase[@"testName"]);
                    }
                }
                
                NSLog(@"segmentId: %ld description: %@", segmentId, name);
            }
            prevSegment = i;
        }
        
        if (i < routeSegments.size())
        {
            [reachedSegments addObject:@(routeSegments[i]->object->id >> 6)];
        }
    }

    NSMutableSet<NSNumber *> *expectedSegments = [NSMutableSet new];
    for (NSString *key in expectedResults)
        [expectedSegments addObject:@(key.longLongValue)];
    for (NSNumber *expSegId in expectedSegments)
    {
        XCTAssertTrue([reachedSegments containsObject:expSegId], @"Expected segment %ld weren't reached in route segments %@", expSegId.longValue, [reachedSegments allObjects]);
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

@end
