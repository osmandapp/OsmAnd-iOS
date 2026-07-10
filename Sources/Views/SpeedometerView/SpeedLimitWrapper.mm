//
//  SpeedLimitWrapper.mm
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 21.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "SpeedLimitWrapper.h"
#import "OsmAndApp.h"
#import "OALocationServices.h"
#import "OAWaypointHelper.h"
#import "OAAlarmInfo.h"
#import "OACurrentPositionHelper.h"
#import "OARoutingHelper.h"
#import "OARoutingHelper+cpp.h"
#import "OAOsmAndFormatter.h"

#include "routeSegmentResult.h"

@implementation SpeedLimitData

- (instancetype)initWithValue:(int)value text:(nullable NSString *)text
{
    self = [super init];
    if (self)
    {
        _value = value;
        _text = [text copy];
    }
    return self;
}

@end

@implementation SpeedLimitWrapper
{
    OAAppSettings *_settings;
    OAWaypointHelper *_wh;
    OACurrentPositionHelper *_currentPositionHelper;
    OARoutingHelper *_routingHelper;
}

- (instancetype)init {
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _wh = [OAWaypointHelper sharedInstance];
    _currentPositionHelper = [OACurrentPositionHelper instance];
    _routingHelper = [OARoutingHelper sharedInstance];
}

- (SpeedLimitData *)speedLimitData
{
    OAAlarmInfo *alarm = [self speedLimitAlarm];
    if (!alarm)
        return [[SpeedLimitData alloc] initWithValue:-1 text:nil];

    NSString *text = nil;
    if (alarm.floatValue > 0)
    {
        NSMutableArray<NSString *> *valueUnitArray = [NSMutableArray array];
        [OAOsmAndFormatter getFormattedSpeed:alarm.floatValue valueUnitArray:valueUnitArray];
        if (valueUnitArray.count > 0)
            text = valueUnitArray.firstObject;
    }

    return [[SpeedLimitData alloc] initWithValue:alarm.intValue text:text ?: [NSString stringWithFormat:@"%d", alarm.intValue]];
}

- (nullable OAAlarmInfo *)speedLimitAlarm
{
    EOASpeedConstant speedFormat = [_settings.speedSystem get];
    BOOL whenExceeded = [_settings.showSpeedLimitWarning get] == EOASpeedLimitWarningStateWhenExceeded;
    
    OAAlarmInfo *alarm = [_wh getSpeedLimitAlarm:speedFormat whenExceeded:whenExceeded];
    if (!alarm)
    {
        CLLocation *lastKnownLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
        if (lastKnownLocation)
        {
            const auto& current = _routingHelper.getCurrentSegmentResult;
            std::shared_ptr<RouteDataObject> dataObject;
            if (current)
                dataObject = current->object;
            else
                dataObject = [_currentPositionHelper getLastKnownRouteSegment:lastKnownLocation];

            if (dataObject)
                alarm = [_wh calculateSpeedLimitAlarm:dataObject location:lastKnownLocation constants:speedFormat whenExceeded:whenExceeded];
        }
    }
    if (alarm)
    {
        return alarm;
    }
    return nil;
}

@end
