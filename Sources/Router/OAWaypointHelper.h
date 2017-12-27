//
//  OAWaypointHelper.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@class OARouteCalculationResult, OALocationPointWrapper;

@interface OAWaypointHelper : NSObject

+ (OAWaypointHelper *) sharedInstance;

- (NSArray<OALocationPointWrapper *> *) getWaypoints:(int)type;
- (void) locationChanged:(CLLocation *)location;
- (int) getRouteDistance:(OALocationPointWrapper *)point;
- (void) removeVisibleLocationPoint:(OALocationPointWrapper *)lp;
- (void) removeVisibleLocationPoints:(NSMutableArray<OALocationPointWrapper *> *)points;

- (void) setNewRoute:(OARouteCalculationResult *)route;

@end
