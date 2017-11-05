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

@required
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

@class OARouteCalculationResult, OARouteDirectionInfo, OAGPXRouteParamsBuilder, OAVoiceRouter, OANextDirectionInfo;

@interface OARoutingHelper : NSObject

+ (OARoutingHelper *)sharedInstance;

- (void) setAppMode:(OAApplicationMode *)mode;
- (OAApplicationMode *) getAppMode;

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
- (OAVoiceRouter *) getVoiceRouter;
+ (BOOL) isDeviatedFromRoute;
- (double) getRouteDeviation;
- (OANextDirectionInfo *) getNextRouteDirectionInfo:(OANextDirectionInfo *)info toSpeak:(BOOL)toSpeak;
- (OANextDirectionInfo *) getNextRouteDirectionInfoAfter:(OANextDirectionInfo *)previous to:(OANextDirectionInfo *)to toSpeak:(BOOL)toSpeak;
- (float) getCurrentMaxSpeed;

- (NSArray<CLLocation *> *) getCurrentCalculatedRoute;
- (OARouteCalculationResult *) getRoute;
- (int) getLeftDistance;
- (int) getLeftDistanceNextIntermediate;
- (int) getLeftTime;
- (NSArray<OARouteDirectionInfo *> *) getRouteDirections;
- (CLLocation *) getLocationFromRouteDirection:(OARouteDirectionInfo *)i;
- (CLLocation *) getLastProjection;
- (OAGPXRouteParamsBuilder *) getCurrentGPXRoute;
- (void) setGpxParams:(OAGPXRouteParamsBuilder *)params;

- (void) addListener:(id<OARouteInformationListener>)l;
- (BOOL) removeListener:(id<OARouteInformationListener>)lt;
- (void) setProgressBar:(id<OARouteCalculationProgressCallback>)progressRoute;

- (CLLocation *) setCurrentLocation:(CLLocation *)currentLocation returnUpdatedLocation:(BOOL)returnUpdatedLocation;
- (void) setFinalAndCurrentLocation:(CLLocation *)finalLocation intermediatePoints:(NSArray<CLLocation *> *)intermediatePoints currentLocation:(CLLocation *)currentLocation;
- (void) clearCurrentRoute:(CLLocation *)newFinalLocation newIntermediatePoints:(NSArray<CLLocation *> *)newIntermediatePoints;
- (void) recalculateRouteDueToSettingsChange;
- (void) notifyIfRouteIsCalculated;

+ (NSString *) formatStreetName:(NSString *)name ref:(NSString *)ref destination:(NSString *)destination towards:(NSString *)towards;

@end
