//
//  OAAlarmInfo.h
//  OsmAnd
//
//  Created by Alexey Kulish on 30/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//
//  OsmAnd-java/src/net/osmand/plus/routing/AlarmInfo.java
//  git revision e5a489637a08d21827a1edd2cf6581339b5f748a

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "OALocationPoint.h"

struct RouteTypeRule;

typedef NS_ENUM(NSInteger, EOAAlarmInfoType)
{
    AIT_SPEED_CAMERA = 0,
    AIT_SPEED_LIMIT,
    AIT_BORDER_CONTROL,
    AIT_RAILWAY,
    AIT_TRAFFIC_CALMING,
    AIT_TOLL_BOOTH,
    AIT_STOP,
    AIT_PEDESTRIAN,
    AIT_HAZARD,
    AIT_MAXIMUM
};

@interface OAAlarmInfo : NSObject<OALocationPoint>

@property (nonatomic, readonly) EOAAlarmInfoType type;
@property (nonatomic, readonly) int locationIndex;
@property (nonatomic) int intValue;
@property (nonatomic) CLLocationCoordinate2D coordinate;

- (instancetype)initWithType:(EOAAlarmInfoType)type locationIndex:(int)locationIndex;

+ (OAAlarmInfo *) createSpeedLimit:(int)speed coordinate:(CLLocationCoordinate2D)coordinate;
+ (OAAlarmInfo *) createAlarmInfo:(RouteTypeRule&)ruleType locInd:(int)locInd coordinate:(CLLocationCoordinate2D)coordinate;

+ (int) getPriority:(EOAAlarmInfoType)type;
+ (NSString* ) getVisualName:(EOAAlarmInfoType)type;

- (int) updateDistanceAndGetPriority:(float)time distance:(float)distance;

@end
