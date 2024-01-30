//
//  OAMaxSpeedWidget.m
//  OsmAnd Maps
//
//  Created by Paul on 15.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAMaxSpeedWidget.h"
#import "OAMapViewTrackingUtilities.h"
#import "OARoutingHelper.h"
#import "OACurrentPositionHelper.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAMaxSpeedWidget
{
    OAMapViewTrackingUtilities *_trackingUtilities;
    OARoutingHelper *_routingHelper;
    OsmAndAppInstance _app;
    OACurrentPositionHelper *_currentPositionHelper;
    
    float _cachedSpeed;
}

- (instancetype _Nonnull)initWithCustomId:(NSString *_Nullable)customId
                                  appMode:(OAApplicationMode * _Nonnull)appMode
{
    self = [super initWithType:OAWidgetType.maxSpeed];
    if (self) {
        [self configurePrefsWithId:customId appMode:appMode widgetParams:nil];
        [self setIconForWidgetType:OAWidgetType.maxSpeed];
        [self setText:nil subtext:nil];
        _trackingUtilities = OAMapViewTrackingUtilities.instance;
        _routingHelper = OARoutingHelper.sharedInstance;
        _currentPositionHelper = OACurrentPositionHelper.instance;
        _app = OsmAndApp.instance;
        [self setMetricSystemDepended:YES];
    }
    return self;
}

- (BOOL)updateInfo
{
    float mx = 0;
    if ((!_routingHelper || ![_routingHelper isFollowingMode] || [OARoutingHelper isDeviatedFromRoute] || [_routingHelper getCurrentGPXRoute]) && [_trackingUtilities isMapLinkedToLocation])
    {
        CLLocation *lastKnownLocation = _app.locationServices.lastKnownLocation;
        std::shared_ptr<RouteDataObject> road;
        if (lastKnownLocation)
        {
            road = [_currentPositionHelper getLastKnownRouteSegment:lastKnownLocation];
            if (road)
                mx = road->getMaximumSpeed(road->bearingVsRouteDirection(lastKnownLocation.course));
        }
    }
    else if (_routingHelper)
    {
        mx = [_routingHelper getCurrentMaxSpeed];
    }
    else
    {
        mx = 0;
    }
    if ([self isUpdateNeeded] || _cachedSpeed != mx)
    {
        _cachedSpeed = mx;
        if (_cachedSpeed == 0)
        {
            [self setText:nil subtext:nil];
        }
        else if (_cachedSpeed == 40.f /*RouteDataObject::NONE_MAX_SPEED*/)
        {
            [self setText:OALocalizedString(@"shared_string_none").lowerCase subtext:@""];
        }
        else
        {
            NSString *ds = [OAOsmAndFormatter getFormattedSpeed:_cachedSpeed];
            int ls = [ds indexOf:@" "];
            if (ls == -1)
                [self setText:ds subtext:nil];
            else
                [self setText:[ds substringToIndex:ls] subtext:[ds substringFromIndex:ls + 1]];
        }
        return true;
    }
    return false;
}

@end
