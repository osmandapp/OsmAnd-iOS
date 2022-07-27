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
- (BOOL)isTrafficLight;
- (void)setTrafficLight:(BOOL)trafficLight;
- (CLLocationDistance)distanceFromLocation:(OASimulatedLocation *)location;
- (NSString *)getHighwayType;
- (void)setHighwayType:(NSString *)highwayType;
- (float)getSpeedLimit;
- (void)setSpeedLimit:(float)speedLimit;

@end

@interface OALocationSimulation : NSObject

- (BOOL) isRouteAnimating;
- (void) startStopRouteAnimation;
- (void) startAnimationThread:(NSArray<OASimulatedLocation *> *)directionsArray useLocationTime:(BOOL)useLocationTime coeff:(float)coeff;

@end
