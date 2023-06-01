//
//  OARouteCalculationResult.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/routing/RouteCalculationResult.java
//  git revision c82795b138c00d4a8da4ef53ada17fcd0380a6a4

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OALocationPoint.h"
#import "OAAppSettings.h"

@class OASimulatedLocation, OAAlarmInfo, OAApplicationMode, OARouteDirectionInfo, OARouteCalculationParams, QuadRect;

@interface OANextDirectionInfo : NSObject

@property (nonatomic) OARouteDirectionInfo *directionInfo;
@property (nonatomic) int distanceTo;
@property (nonatomic) BOOL intermediatePoint;
@property (nonatomic) NSString *pointName;
@property (nonatomic) int imminent;
@property (nonatomic) int directionInfoInd;

@end

@interface OARouteCalculationResult : NSObject

@property (nonatomic) NSMutableArray<id<OALocationPoint>> *locationPoints;
@property (nonatomic) NSMutableArray<OASimulatedLocation *> *simulatedLocations;
@property (nonatomic) NSMutableArray<OAAlarmInfo *> *alarmInfo;
@property (nonatomic, readonly) OAApplicationMode *appMode;
@property (nonatomic, readonly) NSString *errorMessage;
@property (nonatomic, readonly) float routingTime;
@property (nonatomic, readonly) int currentRoute;

@property (nonatomic, readonly) double routeRecalcDistance;
@property (nonatomic, readonly) double routeVisibleAngle;
@property (nonatomic, readonly) bool initialCalculation;
@property (nonatomic, readonly) CLLocation *currentStraightAnglePoint;
@property (nonatomic, readonly) EOARouteService routeProvider;

- (instancetype) initWithErrorMessage:(NSString *)errorMessage;

- (instancetype) initWithLocations:(NSArray<CLLocation *> *)list directions:(NSArray<OARouteDirectionInfo *> *)directions params:(OARouteCalculationParams *)params waypoints:(NSArray<id<OALocationPoint>> *)waypoints addMissingTurns:(BOOL)addMissingTurns;

- (QuadRect *) getLocationsRect;

- (NSArray<CLLocation *> *) getImmutableAllLocations;
- (NSArray<OASimulatedLocation *> *)getImmutableSimulatedLocations;
- (NSArray<OARouteDirectionInfo *> *) getImmutableAllDirections;
- (NSArray<CLLocation *> *) getRouteLocations;
- (int) getRouteDistanceToFinish:(int)posFromCurrentIndex;
- (float) getCurrentMaxSpeed:(int)profile;
- (int) getWholeDistance;
- (BOOL) isCalculated;
- (BOOL) isEmpty;
- (BOOL) isInitialCalculation;
- (void) updateCurrentRoute:(int)currentRoute;
- (void) passIntermediatePoint;
- (int) getNextIntermediate;
- (CLLocation *) getLocationFromRouteDirection:(OARouteDirectionInfo *)i;
- (OANextDirectionInfo *) getNextRouteDirectionInfo:(OANextDirectionInfo *)info fromLoc:(CLLocation *)fromLoc toSpeak:(BOOL)toSpeak;
- (OANextDirectionInfo *) getNextRouteDirectionInfoAfter:(OANextDirectionInfo *)prev next:(OANextDirectionInfo *)next toSpeak:(BOOL)toSpeak;
- (NSArray<OARouteDirectionInfo *> *) getRouteDirections;
- (CLLocation *) getNextRouteLocation;
- (CLLocation *) getNextRouteLocation:(int)after;
- (CLLocation *) getRouteLocationByDistance:(int)meters;
- (BOOL) directionsAvailable;
- (OARouteDirectionInfo *) getCurrentDirection;
- (int) getDistanceToPoint:(int)locationIndex;
- (int) getDistanceFromStart;
- (int) getDistanceToFinish:(CLLocation *)fromLoc;
- (int) getCurrentStraightAngleRoute;
- (int) getDistanceToNextIntermediate:(CLLocation *)fromLoc;
- (int) getIndexOfIntermediate:(int)countFromLast;
- (int) getIntermediatePointsToPass;
- (long) getLeftTime:(CLLocation *)fromLoc;
- (long) getLeftTimeToNextTurn:(CLLocation *)fromLoc;
- (int) getLeftTimeToNextDirection:(CLLocation *)fromLoc;
- (long) getLeftTimeToNextIntermediate:(CLLocation *)fromLoc;
- (void) updateNextVisiblePoint:(int) nextPoint location:(CLLocation *) mp;
- (int) getDistanceFromPoint:(int) locationIndex;
- (BOOL) isPointPassed:(int)locationIndex;

@end
