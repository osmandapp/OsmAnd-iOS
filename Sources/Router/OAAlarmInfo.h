//
//  OAAlarmInfo.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/routing/AlarmInfo.java
//  git revision 3e56dd2fab949d706355e82d7122b20d104202d0

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OALocationPoint.h"

struct RouteTypeRule;
@class OASRouteEventType;

FOUNDATION_EXPORT BOOL OARouteEventTypeEquals(OASRouteEventType *type, OASRouteEventType *expected);

@interface OAAlarmInfo : NSObject<OALocationPoint>

@property (nonatomic, strong, readonly) OASRouteEventType *type;
@property (nonatomic, readonly) int locationIndex;
@property (nonatomic) int lastLocationIndex;
@property (nonatomic) int intValue;
@property (nonatomic) float floatValue;
@property (nonatomic) CLLocationCoordinate2D coordinate;

- (instancetype) initWithType:(OASRouteEventType *)type locationIndex:(int)locationIndex;

+ (OAAlarmInfo *) createSpeedLimit:(int)speed coordinate:(CLLocationCoordinate2D)coordinate speedMetersPerSecond:(float)speedMetersPerSecond;
+ (OAAlarmInfo *) createAlarmInfo:(RouteTypeRule&)ruleType locInd:(int)locInd coordinate:(CLLocationCoordinate2D)coordinate;

+ (int) getPriority:(OASRouteEventType *)type;
+ (NSString* ) getName:(OASRouteEventType *)type;
+ (NSString* ) getVisualName:(OASRouteEventType *)type;

- (int) updateDistanceAndGetPriority:(float)time distance:(float)distance;

- (BOOL) isTrafficCamera;

@end
