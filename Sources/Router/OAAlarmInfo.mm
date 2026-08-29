//
//  OAAlarmInfo.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAAlarmInfo.h"
#import "Localization.h"
#import "OAPointDescription.h"
#import "OASharedRouteDetailsProvider.h"
#import "OsmAndSharedWrapper.h"

#include <routeTypeRule.h>

BOOL OARouteEventTypeEquals(OASRouteEventType *type, OASRouteEventType *expected)
{
    return type == expected || [type isEqual:expected];
}

static int OALegacyAlarmTypeValue(OASRouteEventType *type)
{
    // Keep OAAlarmInfo hash values stable. The removed iOS enum placed TUNNEL before HAZARD and MAXIMUM.
    if (OARouteEventTypeEquals(type, OASRouteEventType.speedCamera))
        return 0;
    if (OARouteEventTypeEquals(type, OASRouteEventType.speedLimit))
        return 1;
    if (OARouteEventTypeEquals(type, OASRouteEventType.borderControl))
        return 2;
    if (OARouteEventTypeEquals(type, OASRouteEventType.railway))
        return 3;
    if (OARouteEventTypeEquals(type, OASRouteEventType.trafficCalming))
        return 4;
    if (OARouteEventTypeEquals(type, OASRouteEventType.tollBooth))
        return 5;
    if (OARouteEventTypeEquals(type, OASRouteEventType.stop))
        return 6;
    if (OARouteEventTypeEquals(type, OASRouteEventType.pedestrian))
        return 7;
    if (OARouteEventTypeEquals(type, OASRouteEventType.tunnel))
        return 8;
    if (OARouteEventTypeEquals(type, OASRouteEventType.hazard))
        return 9;
    if (OARouteEventTypeEquals(type, OASRouteEventType.maximum))
        return 10;
    if (OARouteEventTypeEquals(type, OASRouteEventType.redLightCamera))
        return 11;
    return 0;
}

@interface OAAlarmInfo ()

@property (nonatomic, copy, readwrite) NSString *sourceTag;
@property (nonatomic, copy, readwrite) NSString *sourceValue;

@end

@implementation OAAlarmInfo

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _type = OASRouteEventType.speedCamera;
        _lastLocationIndex = -1;
    }
    return self;
}

- (instancetype) initWithType:(OASRouteEventType *)type locationIndex:(int)locationIndex
{
    self = [self init];
    if (self)
    {
        _type = type;
        _locationIndex = locationIndex;
    }
    return self;
}

+ (OAAlarmInfo *) createSpeedLimit:(int)speed coordinate:(CLLocationCoordinate2D)coordinate speedMetersPerSecond:(float)speedMetersPerSecond
{
    return [OASharedRouteDetailsProvider createSpeedLimit:speed
                                                 latitude:coordinate.latitude
                                                longitude:coordinate.longitude
                                     speedMetersPerSecond:speedMetersPerSecond];
}

+ (OAAlarmInfo *) createAlarmInfo:(RouteTypeRule&)ruleType locInd:(int)locInd coordinate:(CLLocationCoordinate2D)coordinate
{
    NSString *tag = [NSString stringWithUTF8String:ruleType.getTag().c_str()];
    NSString *value = [NSString stringWithUTF8String:ruleType.getValue().c_str()];
    OAAlarmInfo *alarm = [OASharedRouteDetailsProvider createAlarmInfoWithTag:tag
                                                                        value:value
                                                                locationIndex:locInd
                                                                     latitude:coordinate.latitude
                                                                    longitude:coordinate.longitude];
    alarm.sourceTag = tag;
    alarm.sourceValue = value;
    return alarm;
}

- (int) updateDistanceAndGetPriority:(float)time distance:(float)distance
{
    return [OASRouteEventHelper.shared updateDistanceAndGetPriorityType:self.type
                                                            timeSeconds:time
                                                          distanceMeters:distance];
}

+ (int) getPriority:(OASRouteEventType *)type
{
    return type.androidPriority;
}

+ (NSString* ) getName:(OASRouteEventType *)type
{
    return type.name ?: @"";
}

+ (NSString* ) getVisualName:(OASRouteEventType *)type
{
    if (OARouteEventTypeEquals(type, OASRouteEventType.speedCamera))
        return OALocalizedString(@"traffic_warning_speed_camera");
    if (OARouteEventTypeEquals(type, OASRouteEventType.speedLimit))
        return OALocalizedString(@"traffic_warning_speed_limit");
    if (OARouteEventTypeEquals(type, OASRouteEventType.borderControl))
        return OALocalizedString(@"traffic_warning_border_control");
    if (OARouteEventTypeEquals(type, OASRouteEventType.railway))
        return OALocalizedString(@"traffic_warning_railways");
    if (OARouteEventTypeEquals(type, OASRouteEventType.trafficCalming))
        return OALocalizedString(@"traffic_warning_calming");
    if (OARouteEventTypeEquals(type, OASRouteEventType.tollBooth))
        return OALocalizedString(@"traffic_warning_payment");
    if (OARouteEventTypeEquals(type, OASRouteEventType.stop))
        return OALocalizedString(@"traffic_warning_stop");
    if (OARouteEventTypeEquals(type, OASRouteEventType.pedestrian))
        return OALocalizedString(@"traffic_warning_pedestrian");
    if (OARouteEventTypeEquals(type, OASRouteEventType.hazard))
        return OALocalizedString(@"traffic_warning_hazard");
    if (OARouteEventTypeEquals(type, OASRouteEventType.tunnel))
        return OALocalizedString(@"tunnel_warning");
    if (OARouteEventTypeEquals(type, OASRouteEventType.maximum))
        return OALocalizedString(@"traffic_warning");
    if (OARouteEventTypeEquals(type, OASRouteEventType.redLightCamera))
        return OALocalizedString(@"traffic_warning_red_light_camera");
    return @"";
}

- (BOOL) isTrafficCamera
{
    return [self.type isTrafficCamera];
}

- (NSUInteger) hash
{
    return (OALegacyAlarmTypeValue(_type) << 16) + _locationIndex;
}

- (BOOL) isEqual:(id)obj
{
    if (self == obj)
        return YES;
    
    if (!obj)
        return NO;
    
    if (![self isKindOfClass:[obj class]])
        return NO;
    
    return [self hash] == [obj hash];
}

#pragma mark - OALocationPoint

- (double) getLatitude
{
    return _coordinate.latitude;
}

- (double) getLongitude
{
    return _coordinate.longitude;
}

- (UIColor *) getColor
{
    return nil;
}

- (BOOL) isVisible
{
    return NO;
}

- (OAPointDescription *) getPointDescription
{
    return [[OAPointDescription alloc] initWithType:POINT_TYPE_ALARM name:[self.class getVisualName:_type]];
}

@end
