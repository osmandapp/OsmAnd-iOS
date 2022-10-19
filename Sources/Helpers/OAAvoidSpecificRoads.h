//
//  OAAvoidSpecificRoads.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OAAvoidRoadInfo.h"

@protocol OAStateChangedListener;

struct RouteDataObject;

@interface OAAvoidSpecificRoads : NSObject

+ (OAAvoidSpecificRoads *) instance;

- (void) loadImpassableRoads;
- (void) initRouteObjects:(BOOL)force;

- (NSArray<OAAvoidRoadInfo *> *) getImpassableRoads;

- (CLLocation *) getLocation:(int64_t)roadId;
- (void) addImpassableRoad:(CLLocation *)loc skipWritingSettings:(BOOL)skipWritingSettings appModeKey:(NSString *)appModeKey;

- (void) removeImpassableRoad:(OAAvoidRoadInfo *)roadInfo;
- (OAAvoidRoadInfo *) getRoadInfoById:(unsigned long long)id;

- (void) addListener:(id<OAStateChangedListener>)l;
- (void) removeListener:(id<OAStateChangedListener>)l;

- (long) getLastModifiedTime;
- (void) setLastModifiedTime:(long)lastModifiedTime;

@end
