//
//  SpeedLimitWrapper.mm
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 21.05.2024.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "SpeedLimitWrapper.h"
#import "OsmAndApp.h"
#import "OARoutingHelper.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAWaypointHelper.h"
#import "OAAlarmInfo.h"
#import "OACurrentPositionHelper.h"
#import "OAOsmAndFormatter.h"

@implementation SpeedLimitWrapper
{
    OAMapViewTrackingUtilities *_trackingUtilities;
    OALocationServices *_locationProvider;
    OARoutingHelper *_rh;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAWaypointHelper *_wh;
    OACurrentPositionHelper *_currentPositionHelper;
    
    NSString *_imgId;
    NSString *_textString;
    NSString *_bottomTextString;
    
    BOOL _carPlayMode;
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
    _rh = [OARoutingHelper sharedInstance];
    _app = [OsmAndApp instance];
    _trackingUtilities = [OAMapViewTrackingUtilities instance];
    _locationProvider = _app.locationServices;
    _wh = [OAWaypointHelper sharedInstance];
    _currentPositionHelper = [OACurrentPositionHelper instance];
}

- (NSString *)speedLimitText
{
    BOOL isVisible = [_settings.showScreenAlerts get] && [_settings.showSpeedLimitWarnings get];
    if (!isVisible)
    {
        return nil;
    }
    
    BOOL trafficWarnings = [_settings.showTrafficWarnings get];
    BOOL cams = [_settings.showCameras get];
    if (([_rh isFollowingMode] || [_trackingUtilities isMapLinkedToLocation]) && (trafficWarnings || cams))
    {
        OAAlarmInfo *alarm;
        if([_rh isFollowingMode] && ![OARoutingHelper isDeviatedFromRoute] && ![_rh getCurrentGPXRoute])
        {
            alarm = [_wh getMostImportantAlarm:[_settings.speedSystem get] showCameras:cams];
        }
        else
        {
            CLLocation *loc = _app.locationServices.lastKnownLocation;
            const auto ro = [_currentPositionHelper getLastKnownRouteSegment:loc];
            if (loc && ro)
            {
                alarm = [_wh calculateMostImportantAlarm:ro loc:loc mc:[_settings.metricSystem get] sc:[_settings.speedSystem get] showCameras:cams];
            }
        }
        if (alarm && alarm.type == AIT_SPEED_LIMIT)
        {
            return @(alarm.intValue).stringValue;
        }
    }
    return nil;
}

@end
