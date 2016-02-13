//
//  OASmartNaviWatchNavigationControllerTest.m
//  OsmAnd
//
//  Created by egloff on 04/02/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "OASmartNaviWatchNavigationController.h"

@interface OASmartNaviWatchNavigationControllerTest : XCTestCase

@end

@implementation OASmartNaviWatchNavigationControllerTest

- (void)setUp {
    [super setUp];


}

- (void)tearDown {
    [super tearDown];
}

- (void)testSetActiveRoute {
    
    OASmartNaviWatchNavigationController* navigationController = [[OASmartNaviWatchNavigationController alloc] init];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:46.774478 longitude:9.230276];
    [navigationController setActiveRouteForLocation:location];
    XCTAssertFalse([navigationController hasActiveRoute:location]);    
    
}

- (void)testGetBasicBearing {
    
    OASmartNaviWatchNavigationController* navigationController = [[OASmartNaviWatchNavigationController alloc] init];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(46.774478, 9.230276);
    float course = 30;

    CLLocation *location = [[CLLocation alloc] initWithCoordinate:coordinate altitude:1000 horizontalAccuracy:5 verticalAccuracy:5 course:course speed:2 timestamp:[NSDate date]];
    
    float result = [navigationController getBearingFrom:location toCoordinate:coordinate];
    
    XCTAssertEqual(360-course, result);
}

- (void)testAdvancedBearing {
    
    OASmartNaviWatchNavigationController* navigationController = [[OASmartNaviWatchNavigationController alloc] init];
    CLLocationCoordinate2D coordinate1 = CLLocationCoordinate2DMake(46.774478, 9.230276);
    CLLocationCoordinate2D coordinate2 = CLLocationCoordinate2DMake(47.774478, 10.230276);

    float course = 0;
    
    // no course information
    CLLocation *location1 = [[CLLocation alloc] initWithCoordinate:coordinate1 altitude:1000 horizontalAccuracy:5 verticalAccuracy:5 course:course speed:2 timestamp:[NSDate date]];
    
    float bearingWithoutCourse = [navigationController getBearingFrom:location1 toCoordinate:coordinate2];

    XCTAssertTrue(bearingWithoutCourse != 0);

    course = 30;
    
    // course of 30 degrees
    CLLocation *location2 = [[CLLocation alloc] initWithCoordinate:coordinate1 altitude:1000 horizontalAccuracy:5 verticalAccuracy:5 course:course speed:2 timestamp:[NSDate date]];
    
    float bearingWithCourse = [navigationController getBearingFrom:location2 toCoordinate:coordinate2];
    
    
    XCTAssertEqual(bearingWithCourse+course, bearingWithoutCourse);
}

@end
