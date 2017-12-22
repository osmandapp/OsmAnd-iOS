//
//  OALocationPointWrapper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 22/12/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

static int const LPW_TARGETS = 0;
static int const LPW_WAYPOINTS = 1;
static int const LPW_POI = 2;
static int const LPW_FAVORITES = 3;
static int const LPW_ALARMS = 4;
static int const LPW_MAX = 5;
static int const LPW_SEARCH_RADIUS_VALUES[7] = { 50, 100, 200, 500, 1000, 2000, 5000 };

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

- (UIImage *) getImage:(BOOL)nightMode;

@end
