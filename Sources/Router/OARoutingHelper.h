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
#import "OACommonTypes.h"
#import "OAResultMatcher.h"

#include <vector>

@protocol OARouteInformationListener <NSObject>

@required
- (void) newRouteIsCalculated:(BOOL)newRoute;
- (void) routeWasUpdated;
- (void) routeWasCancelled;
- (void) routeWasFinished;

@end

@protocol OARouteCalculationProgressCallback <NSObject>

@required
// set visibility
- (void) startProgress;
- (void) updateProgress:(int)progress;
- (void) requestPrivateAccessRouting;
- (void) finish;

@end

@class OARouteCalculationResult, OARouteDirectionInfo, OAGPXRouteParamsBuilder, OAVoiceRouter, OANextDirectionInfo, OAGPXTrackAnalysis, OARouteCalculationParams, OARouteProvider, OARoutingEnvironment, OALocationsHolder, OAGpxRouteApproximation;

struct GpxPoint;
struct GpxRouteApproximation;
struct TurnType;
struct RouteSegmentResult;

@interface OARoutingHelper : NSObject

+ (OARoutingHelper *)sharedInstance;

- (void) setAppMode:(OAApplicationMode *)mode;
- (OAApplicationMode *) getAppMode;

- (OARouteProvider *) getRouteProvider;

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
- (NSString *) getCurrentName:(std::vector<std::shared_ptr<TurnType>>&)next;
- (OABBox) getBBox;

- (std::vector<std::shared_ptr<RouteSegmentResult>>) getUpcomingTunnel:(float)distToStart;
- (NSArray<CLLocation *> *) getCurrentCalculatedRoute;
- (OARouteCalculationResult *) getRoute;
- (OAGPXTrackAnalysis *) getTrackAnalysis;
- (int) getLeftDistance;
- (int) getLeftDistanceNextIntermediate;
- (long) getLeftTime;
- (long) getLeftTimeNextIntermediate;
- (NSArray<OARouteDirectionInfo *> *) getRouteDirections;
- (CLLocation *) getLocationFromRouteDirection:(OARouteDirectionInfo *)i;
- (CLLocation *) getLastProjection;
- (CLLocation *) getLastFixedLocation;
- (OAGPXRouteParamsBuilder *) getCurrentGPXRoute;
- (void) setGpxParams:(OAGPXRouteParamsBuilder *)params;
- (CLLocation *) getFinalLocation;

- (void) addListener:(id<OARouteInformationListener>)l;
- (BOOL) removeListener:(id<OARouteInformationListener>)lt;
- (void) addProgressBar:(id<OARouteCalculationProgressCallback>)progressRoute;

- (CLLocation *) setCurrentLocation:(CLLocation *)currentLocation returnUpdatedLocation:(BOOL)returnUpdatedLocation;
- (void) setFinalAndCurrentLocation:(CLLocation *)finalLocation intermediatePoints:(NSArray<CLLocation *> *)intermediatePoints currentLocation:(CLLocation *)currentLocation;
- (void) clearCurrentRoute:(CLLocation *)newFinalLocation newIntermediatePoints:(NSArray<CLLocation *> *)newIntermediatePoints;
- (void) recalculateRouteDueToSettingsChange;
- (void) notifyIfRouteIsCalculated;
- (std::shared_ptr<RouteSegmentResult>) getCurrentSegmentResult;
- (BOOL) isPublicTransportMode;

- (void) startRouteCalculationThread:(OARouteCalculationParams *)params paramsChanged:(BOOL)paramsChanged updateProgress:(BOOL)updateProgress;

- (OARoutingEnvironment *) getRoutingEnvironment:(OAApplicationMode *)mode start:(CLLocation *)start end:(CLLocation *)end;
- (std::vector<std::shared_ptr<GpxPoint>>) generateGpxPoints:(OARoutingEnvironment *)env gctx:(std::shared_ptr<GpxRouteApproximation>)gctx locationsHolder:(OALocationsHolder *)locationsHolder;
- (std::shared_ptr<GpxRouteApproximation>) calculateGpxApproximation:(OARoutingEnvironment *)env
														   gctx:(std::shared_ptr<GpxRouteApproximation>)gctx
														 points:(std::vector<std::shared_ptr<GpxPoint>> &)points
												  resultMatcher:(OAResultMatcher<OAGpxRouteApproximation *> *)resultMatcher;

+ (NSString *) formatStreetName:(NSString *)name ref:(NSString *)ref destination:(NSString *)destination towards:(NSString *)towards;

+ (void) applyApplicationSettings:(OARouteCalculationParams *) params  appMode:(OAApplicationMode *) mode;

+ (NSInteger) getGpsTolerance;
+ (double) getArrivalDistanceFactor;

+ (double) getDefaultAllowedDeviation:(OAApplicationMode *)mode posTolerance:(double)posTolerance;
+ (double) getPosTolerance:(double)accuracy;

@end
