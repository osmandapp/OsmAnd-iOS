//
//  OAMissingMapsHelper.h
//  OsmAnd
//
//  Created by nnngrach on 14.07.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAWorldRegion.h"
#import "OARouteCalculationParams.h"

@interface OAMissingMapsHelper : NSObject

- (instancetype) initWithParams:(OARouteCalculationParams *)params;

- (BOOL) isAnyPointOnWater:(NSArray<CLLocation *> *) points;
- (NSArray<CLLocation *> *) getDistributedPathPoints:(NSArray<CLLocation *> *) points;
- (NSArray<CLLocation *> *) getStartFinishIntermediatePoints;
- (NSArray<CLLocation *> *) findOnlineRoutePoints;
- (NSArray<OAWorldRegion *> *) getMissingMaps:(NSArray<CLLocation *> *) points;
- (NSArray<CLLocation *> *) removeDensePoints:(NSArray<CLLocation *> *) routeLocation;

@end
