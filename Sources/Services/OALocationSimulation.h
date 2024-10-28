//
//  OALocationSimulation.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OALocation : CLLocation

@property (nonatomic) NSString *provider;

- (instancetype)initWithProvider:(NSString *)provider location:(CLLocation *)location;

@end

@interface OASimulatedLocation : CLLocation

- (instancetype)initWithSimulatedLocation:(OASimulatedLocation *)location;
- (instancetype)initWithLocation:(CLLocation *)location;
- (instancetype)initWithCoordinate:(CLLocationCoordinate2D)coordinate
    altitude:(CLLocationDistance)altitude
    horizontalAccuracy:(CLLocationAccuracy)hAccuracy
    verticalAccuracy:(CLLocationAccuracy)vAccuracy
    course:(CLLocationDirection)course
    courseAccuracy:(CLLocationDirectionAccuracy)courseAccuracy
    speed:(CLLocationSpeed)speed
    timestamp:(NSDate *)timestamp
    trafficLight:(BOOL)trafficLight
    highwayType:(NSString *)highwayType
    speedLimit:(float)speedLimit;

- (BOOL)isTrafficLight;
- (void)setTrafficLight:(BOOL)trafficLight;
- (CLLocationDistance)distanceFromLocation:(OASimulatedLocation *)location;
- (NSString *)getHighwayType;
- (void)setHighwayType:(NSString *)highwayType;
- (float)getSpeedLimit;
- (void)setSpeedLimit:(float)speedLimit;

- (OASimulatedLocation *) locationWithCoordinate:(CLLocationCoordinate2D)coordinate;
- (OASimulatedLocation *) locationWithAltitude:(CLLocationDistance)altitude;
- (OASimulatedLocation *) locationWithHorizontalAccuracy:(CLLocationAccuracy)horizontalAccuracy;
- (OASimulatedLocation *) locationWithVerticalAccuracy:(CLLocationAccuracy)verticalAccuracy;
- (OASimulatedLocation *) locationWithCourse:(CLLocationDirection)course;
- (OASimulatedLocation *) locationWithCourseAccuracy:(CLLocationDirectionAccuracy)courseAccuracy;
- (OASimulatedLocation *) locationWithSpeed:(CLLocationSpeed)speed;
- (OASimulatedLocation *) locationWithTimestamp:(NSDate *)timestamp;

@end

@interface OALocationSimulation : NSObject

- (BOOL) isRouteAnimating;
- (void) startStopRouteAnimation;
- (void) startAnimationThread:(NSArray<OASimulatedLocation *> *)directionsArray useLocationTime:(BOOL)useLocationTime coeff:(float)coeff;

@end
