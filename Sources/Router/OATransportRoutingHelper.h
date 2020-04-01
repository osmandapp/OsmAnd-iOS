//
//  OATransportRoutingHelper.h
//  OsmAnd Maps
//
//  Created by Paul on 17.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "OARoutingHelper.h"

@protocol OATransportRouteCalculationProgressCallback <NSObject>

@required

- (void) start;
- (void) updateProgress:(int)progress;
- (void) finish;

@end

@class OARouteCalculationResult;
@class OATransportRouteResultSegment;
@class OAApplicationMode;

@interface OATransportRoutingHelper : NSObject

+ (OATransportRoutingHelper *) sharedInstance;

@property (nonatomic) NSDictionary<NSArray<OATransportRouteResultSegment *> *, OARouteCalculationResult *> *walkingRouteSegments;

@property (nonatomic, readonly) CLLocation *startLocation;
@property (nonatomic, readonly) CLLocation *endLocation;
@property (nonatomic) OAApplicationMode *applicationMode;

- (void) setFinalAndCurrentLocation:(CLLocation *) finalLocation currentLocation:(CLLocation *)currentLocation;
- (void) addListener:(id<OARouteInformationListener>)l;

- (void) clearCurrentRoute:(CLLocation *) newFinalLocation;
- (void) recalculateRouteDueToSettingsChange;

@end

