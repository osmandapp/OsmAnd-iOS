//
//  OAWaypointHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/helpers/WaypointHelper.java
//  git revision ac6b6bf788e2205b61fbdd0cb61addcad2fae327

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
- (NSArray<OALocationPointWrapper *> *) getAllPoints;

- (void) removeVisibleLocationPoint:(OALocationPointWrapper *)lp;
- (void) removeVisibleLocationPoints:(NSMutableArray<OALocationPointWrapper *> *)points;

- (OALocationPointWrapper *) getMostImportantLocationPoint:(NSMutableArray<OALocationPointWrapper *> *)list;
- (OAAlarmInfo *) getMostImportantAlarm:(EOAMetricsConstant)mc showCameras:(BOOL)showCameras;
- (void) enableWaypointType:(int)type enable:(BOOL)enable;

- (void) recalculatePoints:(int)type;

- (int) getSearchDeviationRadius:(int)type;
- (void) setSearchDeviationRadius:(int)type radius:(int)radius;

- (BOOL) isTypeConfigurable:(int)waypointType;
- (BOOL) isTypeVisible:(int)waypointType;
- (BOOL) isTypeEnabled:(int)type;

- (OAAlarmInfo *) calculateMostImportantAlarm:(std::shared_ptr<RouteDataObject>)ro loc:(CLLocation *)loc mc:(EOAMetricsConstant)mc showCameras:(BOOL)showCameras;

- (void) announceVisibleLocations;

- (void) setNewRoute:(OARouteCalculationResult *)route;
- (BOOL) isRouteCalculated;

@end
