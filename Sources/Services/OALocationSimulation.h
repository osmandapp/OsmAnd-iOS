//
//  OALocationSimulation.h
//  OsmAnd
//
//  Created by Alexey Kulish on 23/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface OALocationSimulation : NSObject

- (BOOL) isRouteAnimating;
- (void) startStopRouteAnimation;

@end

@interface OASimulatedLocation : CLLocation

- (instancetype)initWithSimulatedLocation:(OASimulatedLocation *)location;
- (instancetype)initWithLocation:(CLLocation *)location;
- (BOOL)isTrafficLight;
- (void)setTrafficLight:(BOOL)trafficLight;
- (CLLocationDistance)distanceFromLocation:(OASimulatedLocation *)location;

@end
