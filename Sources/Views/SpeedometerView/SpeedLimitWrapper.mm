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

#include "routeSegmentResult.h"

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

- (int)speedLimit
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
        NSLog(@"[test] alarm.intValue: %d", alarm.intValue);
        NSLog(@"[test] alarm.stringValue: %@", @(alarm.intValue).stringValue);
        return alarm.intValue;
    }
    return -1;
}

@end
