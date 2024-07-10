//
//  OACurrentSpeedWidget.m
//  OsmAnd Maps
//
//  Created by Paul on 15.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACurrentSpeedWidget.h"
#import "OACurrentPositionHelper.h"
#import "OsmAndApp.h"
#import "OAOsmAndFormatter.h"
#import "OALocationServices.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"

const static CLLocationSpeed LOW_SPEED_THRESHOLD_MPS = 6;
const static CLLocationSpeed UPDATE_THRESHOLD_MPS = .1f;
const static CLLocationSpeed LOW_SPEED_UPDATE_THRESHOLD_MPS = .015f; // Update more often while walking/running

@implementation OACurrentSpeedWidget
{
    OsmAndAppInstance _app;
    OACurrentPositionHelper *_currentPositionHelper;

    float _cachedSpeed;
}

- (instancetype)initWithCustomId:(NSString *)customId
                                  appMode:(OAApplicationMode *)appMode
                             widgetParams:(NSDictionary *)widgetParams
{
    OAWidgetType *type = OAWidgetType.currentSpeed;
    self = [super initWithType:type];
    if (self)
    {
        _app = OsmAndApp.instance;
        _currentPositionHelper = OACurrentPositionHelper.instance;
        [self configurePrefsWithId:customId appMode:appMode widgetParams:widgetParams];
        [self setIconForWidgetType:type];
        [self setText:nil subtext:nil];
        [self setMetricSystemDepended:YES];
    }
    return self;
}

- (BOOL)updateInfo
{
    CLLocation *lastKnownLocation = _app.locationServices.lastKnownLocation;
    CLLocationSpeed currentSpeed = lastKnownLocation ? lastKnownLocation.speed : -1;
    if (currentSpeed >= 0)
    {
        float updateThreshold = _cachedSpeed < LOW_SPEED_THRESHOLD_MPS
            ? LOW_SPEED_UPDATE_THRESHOLD_MPS
            : UPDATE_THRESHOLD_MPS;

        if ([self isUpdateNeeded] || ABS(currentSpeed - _cachedSpeed) > updateThreshold)
        {
            _cachedSpeed = currentSpeed;
            NSString *ds = [OAOsmAndFormatter getFormattedSpeed:currentSpeed];
            int ls = [ds indexOf:@" "];
            if (ls == -1)
                [self setText:ds subtext:nil];
            else
                [self setText:[ds substringToIndex:ls] subtext:[ds substringFromIndex:ls + 1]];

            return true;
        }
    }
    else if (_cachedSpeed != 0)
    {
        _cachedSpeed = 0;
        [self setText:[[self getWidgetPanel] isPanelVertical] ? @"-" : nil subtext:nil];
    }
    return false;
}

@end
