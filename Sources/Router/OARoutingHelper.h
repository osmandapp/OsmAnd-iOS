//
//  OARoutingHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 09/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OACommonTypes.h"

@class OAApplicationMode, OAGPXMutableDocument, OAWptPt;

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

@class OARouteCalculationResult, OARouteDirectionInfo, OAGPXRouteParamsBuilder, OAVoiceRouter, OANextDirectionInfo, OAGPXTrackAnalysis, OARouteCalculationParams, OARouteProvider, OARoutingEnvironment, OALocationsHolder, OAGpxRouteApproximation, OAGPXDocument, OAObservable, OACurrentStreetName;

@interface OARoutingHelper : NSObject

+ (OARoutingHelper *)sharedInstance;

@property (readonly) OAObservable *routingModeChangedObservable;

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
- (OACurrentStreetName *) getCurrentName:(OANextDirectionInfo *)next;
- (OABBox) getBBox;

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
- (int) calculateCurrentRoute:(CLLocation *)currentLocation posTolerance:(float)posTolerance routeNodes:(NSArray<CLLocation *> *)routeNodes currentRoute:(int)currentRoute updateAndNotify:(BOOL)updateAndNotify;

- (void) addListener:(id<OARouteInformationListener>)l;
- (BOOL) removeListener:(id<OARouteInformationListener>)lt;
- (void) addProgressBar:(id<OARouteCalculationProgressCallback>)progressRoute;

- (void)updateLocation:(CLLocation *)currentLocation;
- (CLLocation *) setCurrentLocation:(CLLocation *)currentLocation returnUpdatedLocation:(BOOL)returnUpdatedLocation;
- (void) setFinalAndCurrentLocation:(CLLocation *)finalLocation intermediatePoints:(NSArray<CLLocation *> *)intermediatePoints currentLocation:(CLLocation *)currentLocation;
- (void) clearCurrentRoute:(CLLocation *)newFinalLocation newIntermediatePoints:(NSArray<CLLocation *> *)newIntermediatePoints;
- (void) recalculateRouteDueToSettingsChange;
- (void) notifyIfRouteIsCalculated;
- (BOOL) isPublicTransportMode;

- (void) startRouteCalculationThread:(OARouteCalculationParams *)params paramsChanged:(BOOL)paramsChanged updateProgress:(BOOL)updateProgress;

- (OARoutingEnvironment *) getRoutingEnvironment:(OAApplicationMode *)mode start:(CLLocation *)start end:(CLLocation *)end;

- (OAGPXDocument *) generateGPXFileWithRoute:(NSString *)name;

+ (void) applyApplicationSettings:(OARouteCalculationParams *) params  appMode:(OAApplicationMode *) mode;

+ (NSInteger) getGpsTolerance;
+ (double) getArrivalDistanceFactor;

+ (double) getDefaultAllowedDeviation:(OAApplicationMode *)mode posTolerance:(double)posTolerance;
+ (double) getPosTolerance:(double)accuracy;

- (OAGPXMutableDocument *)approximateGpxFile:(OAGPXDocument *)gpxFile
                         calculatedTimeSpeed:(NSMutableArray<NSNumber *> *)calculatedTimeSpeed
                                         env:(OARoutingEnvironment *)env
                                        gctx:(OAGpxRouteApproximation *)gctx
                             locationsHolder:(OALocationsHolder *)locationsHolder
               shouldNetworkApproximateRoute:(BOOL)shouldNetworkApproximateRoute
                                      points:(NSArray<OAWptPt *> *)points
                                     appMode:(OAApplicationMode *)appMode
                          routingGpxFileName:(NSString *)routingGpxFileName;

@end
