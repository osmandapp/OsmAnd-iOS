//
//  OARouteCalculationResult.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/routing/RouteCalculationResult.java
//  git revision b7a6d89b18f881d5eec83a01d783e9efb33bbbd6

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAMapStyleSettings.h"
#import "OALocationPoint.h"
#import "OARouteProvider.h"

#include <CommonCollections.h>
#include <commonOsmAndCore.h>
#include <routeSegmentResult.h>

@class OARouteCalculationParams, OARouteDirectionInfo, OAAlarmInfo, QuadRect;

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
@property (nonatomic) NSMutableArray<OAAlarmInfo *> *alarmInfo;
@property (nonatomic, readonly) OAApplicationMode *appMode;
@property (nonatomic, readonly) NSString *errorMessage;
@property (nonatomic, readonly) float routingTime;
@property (nonatomic, readonly) int currentRoute;

@property (nonatomic, readonly) double routeRecalcDistance;
@property (nonatomic, readonly) double routeVisibleAngle;
@property (nonatomic, readonly) CLLocation *currentStraightAnglePoint;
@property (nonatomic, readonly) EOARouteService routeProvider;

- (instancetype) initWithErrorMessage:(NSString *)errorMessage;

- (instancetype) initWithLocations:(NSArray<CLLocation *> *)list directions:(NSArray<OARouteDirectionInfo *> *)directions params:(OARouteCalculationParams *)params waypoints:(NSArray<id<OALocationPoint>> *)waypoints addMissingTurns:(BOOL)addMissingTurns;

- (instancetype) initWithSegmentResults:(std::vector<std::shared_ptr<RouteSegmentResult>>&)list start:(CLLocation *)start end:(CLLocation *)end intermediates:(NSArray<CLLocation *> *)intermediates leftSide:(BOOL)leftSide routingTime:(float)routingTime waypoints:(NSArray<id<OALocationPoint>> *)waypoints mode:(OAApplicationMode *)mode;

- (std::vector<std::shared_ptr<RouteSegmentResult>>) getOriginalRoute;
- (std::vector<std::shared_ptr<RouteSegmentResult>>) getOriginalRoute:(int)startIndex;
- (QuadRect *) getLocationsRect;
+ (NSString *) toString:(std::shared_ptr<TurnType>)type shortName:(BOOL)shortName;

- (NSArray<CLLocation *> *) getImmutableAllLocations;
- (NSArray<OARouteDirectionInfo *> *) getImmutableAllDirections;
- (NSArray<CLLocation *> *) getRouteLocations;
- (std::shared_ptr<RouteSegmentResult>) getCurrentSegmentResult;
- (std::shared_ptr<RouteSegmentResult>) getNextStreetSegmentResult;
- (std::vector<std::shared_ptr<RouteSegmentResult>>) getUpcomingTunnel:(float)distToStart;
- (float) getCurrentMaxSpeed;
- (int) getWholeDistance;
- (BOOL) isCalculated;
- (BOOL) isEmpty;
- (void) updateCurrentRoute:(int)currentRoute;
- (void) passIntermediatePoint;
- (int) getNextIntermediate;
- (CLLocation *) getLocationFromRouteDirection:(OARouteDirectionInfo *)i;
- (OANextDirectionInfo *) getNextRouteDirectionInfo:(OANextDirectionInfo *)info fromLoc:(CLLocation *)fromLoc toSpeak:(BOOL)toSpeak;
- (OANextDirectionInfo *) getNextRouteDirectionInfoAfter:(OANextDirectionInfo *)prev next:(OANextDirectionInfo *)next toSpeak:(BOOL)toSpeak;
- (NSArray<OARouteDirectionInfo *> *) getRouteDirections;
- (CLLocation *) getNextRouteLocation;
- (int) getDistanceToPoint:(int)locationIndex;
- (int) getDistanceToFinish:(CLLocation *)fromLoc;
- (int) getDistanceToNextIntermediate:(CLLocation *)fromLoc;
- (int) getIndexOfIntermediate:(int)countFromLast;
- (int) getIntermediatePointsToPass;
- (long) getLeftTime:(CLLocation *)fromLoc;
- (long) getLeftTimeToNextIntermediate:(CLLocation *)fromLoc;
- (void) updateNextVisiblePoint:(int) nextPoint location:(CLLocation *) mp;
- (int) getDistanceFromPoint:(int) locationIndex;
- (BOOL) isPointPassed:(int)locationIndex;

@end
