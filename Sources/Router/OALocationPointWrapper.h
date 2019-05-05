//
//  OALocationPointWrapper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 22/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd/src/net/osmand/plus/helpers/WaypointHelper.java
//  git revision ac6b6bf788e2205b61fbdd0cb61addcad2fae327

#import <Foundation/Foundation.h>

static int const LPW_TARGETS = 0;
static int const LPW_WAYPOINTS = 1;
static int const LPW_POI = 2;
static int const LPW_FAVORITES = 3;
static int const LPW_ALARMS = 4;
static int const LPW_MAX = 5;
static int const LPW_ANY = 6;
static NSArray<NSNumber *> const *LPW_SEARCH_RADIUS_VALUES = @[ @50, @100, @200, @500, @1000, @2000, @5000 ];
static double const LPW_DISTANCE_IGNORE_DOUBLE_SPEEDCAMS = 150.0;

@protocol OALocationPoint;
@class OARouteCalculationResult;

@interface OALocationPointWrapper : NSObject

@property (nonatomic) id<OALocationPoint> point;
@property (nonatomic) float deviationDistance;
@property (nonatomic) BOOL deviationDirectionRight;
@property (nonatomic) int routeIndex;
@property (nonatomic) BOOL announce;
@property (nonatomic) OARouteCalculationResult *route;
@property (nonatomic) int type;

- (instancetype) initWithRouteCalculationResult:(OARouteCalculationResult *)rt type:(int)type point:(id<OALocationPoint>)point deviationDistance:(float)deviationDistance routeIndex:(int)routeIndex;

- (UIImage *) getImage:(BOOL)nightMode;

@end
