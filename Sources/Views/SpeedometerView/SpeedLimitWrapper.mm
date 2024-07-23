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

@implementation SpeedLimitWrapper
{
    OAAppSettings *_settings;
    OAWaypointHelper *_wh;
    OACurrentPositionHelper *_currentPositionHelper;
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
}

- (NSString *)speedLimitText
{
    EOASpeedConstant speedFormat = [_settings.speedSystem get];
    BOOL whenExceeded = [_settings.showSpeedLimitWarning get] == EOASpeedLimitWarningStateWhenExceeded;
    
    OAAlarmInfo *alarm = [_wh getSpeedLimitAlarm:speedFormat whenExceeded:whenExceeded];
    if (!alarm)
    {
        CLLocation *lastKnownLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
        if (lastKnownLocation)
        {
            std::shared_ptr<RouteDataObject> road;
            road = [_currentPositionHelper getLastKnownRouteSegment:lastKnownLocation];
            if (road)
            {
                alarm = [_wh calculateSpeedLimitAlarm:road location:lastKnownLocation constants:speedFormat whenExceeded:whenExceeded];
            }
        }
    }
    if (alarm)
    {
        return @(alarm.intValue).stringValue;
    }
    return nil;
}

@end
