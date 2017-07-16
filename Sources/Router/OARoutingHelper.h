//
//  OARoutingHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 09/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAApplicationMode.h"

@protocol OARouteInformationListener <NSObject>

@optional
- (void) newRouteIsCalculated:(BOOL)newRoute;
- (void) routeWasCancelled;
- (void) routeWasFinished;

@end

@protocol OARouteCalculationProgressCallback <NSObject>

@required
// set visibility
- (void) updateProgress:(int)progress;
- (void) requestPrivateAccessRouting;
- (void) finish;

@end

@interface OARoutingHelper : NSObject

+ (OARoutingHelper *)sharedInstance;

- (void) setAppMode:(OAMapVariantType)mode;
- (OAMapVariantType) getAppMode;

- (BOOL) isFollowingMode;
- (NSString *) getLastRouteCalcError;
- (NSString *) getLastRouteCalcErrorShort;
- (void) setPauseNaviation:(BOOL) b;
- (BOOL) isPauseNavigation;
- (void) setFollowingMode:(BOOL)follow;
- (BOOL) isRoutePlanningMode;
- (void) setRoutePlanningMode:(BOOL)isRoutePlanningMode;
- (BOOL) isRouteCalculated;
- (BOOL) isRouteBeingCalculated;

- (void) setFinalAndCurrentLocation:(CLLocation *)finalLocation intermediatePoints:(NSArray<CLLocation *> *)intermediatePoints currentLocation:(CLLocation *)currentLocation;

+ (NSString *) formatStreetName:(NSString *)name ref:(NSString *)ref destination:(NSString *)destination towards:(NSString *)towards;

@end
