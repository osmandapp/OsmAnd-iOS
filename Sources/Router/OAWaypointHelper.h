//
//  OAWaypointHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/helpers/WaypointHelper.java
//  git revision 81bf4ea094840169243f365fb46859ef375aa262

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAAppSettings.h"

#include <OsmAndCore.h>

struct RouteDataObject;

@class OARouteCalculationResult, OALocationPointWrapper, OAAlarmInfo;

@interface OAWaypointHelper : NSObject

@property (nonatomic) NSMutableArray<OALocationPointWrapper *> *deletedPoints;

+ (OAWaypointHelper *) sharedInstance;

- (NSArray<OALocationPointWrapper *> *) getWaypoints:(int)type;
- (void) locationChanged:(CLLocation *)location;
- (int) getRouteDistance:(OALocationPointWrapper *)point;
- (BOOL) isPointPassed:(OALocationPointWrapper *)point;
- (NSArray<OALocationPointWrapper *> *) getAllPoints;

- (void) removeVisibleLocationPoint:(OALocationPointWrapper *)lp;
- (void) removeVisibleLocationPoints:(NSMutableArray<OALocationPointWrapper *> *)points;

- (OALocationPointWrapper *) getMostImportantLocationPoint:(NSMutableArray<OALocationPointWrapper *> *)list;
- (BOOL) beforeTunnelEntrance:(int) currentRoute alarm:(OAAlarmInfo *)alarm;
- (OAAlarmInfo *) getMostImportantAlarm:(EOASpeedConstant)sc showCameras:(BOOL)showCameras;
- (void) enableWaypointType:(int)type enable:(BOOL)enable;

- (void) recalculatePoints:(int)type;

- (int) getSearchDeviationRadius:(int)type;
- (void) setSearchDeviationRadius:(int)type radius:(int)radius;

- (BOOL) isTypeConfigurable:(int)waypointType;
- (BOOL) isTypeVisible:(int)waypointType;
- (BOOL) isTypeEnabled:(int)type;

- (OAAlarmInfo *) calculateMostImportantAlarm:(const std::shared_ptr<RouteDataObject>)ro loc:(CLLocation *)loc mc:(EOAMetricsConstant)mc sc:(EOASpeedConstant)sc showCameras:(BOOL)showCameras;

- (void) announceVisibleLocations;

- (void) setNewRoute:(OARouteCalculationResult *)route;
- (BOOL) isRouteCalculated;
- (nullable OAAlarmInfo *)getSpeedLimitAlarm:(EOASpeedConstant)constants
                               whenExceeded:(BOOL)whenExceeded;
- (nullable OAAlarmInfo *)calculateSpeedLimitAlarm:(const std::shared_ptr<RouteDataObject>)object
                                         location:(nonnull CLLocation *)location
                                        constants:(EOASpeedConstant)constants
                                      whenExceeded:(BOOL)whenExceeded;

@end
