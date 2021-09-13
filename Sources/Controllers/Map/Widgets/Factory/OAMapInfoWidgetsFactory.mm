//
//  OAMapInfoWidgetsFactory.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapInfoWidgetsFactory.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OATextInfoWidget.h"
#import "OAUtilities.h"
#import "OARulerWidget.h"
#import "OARootViewController.h"
#import "OAMapViewTrackingUtilities.h"
#import "OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapInfoController.h"
#import "OAOsmAndFormatter.h"

#include <OsmAndCore/Utilities.h>

@implementation OAMapInfoWidgetsFactory
{
    OsmAndAppInstance _app;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
    }
    return self;
}

- (OATextInfoWidget *) createAltitudeControl
{
    OATextInfoWidget *altitudeControl = [[OATextInfoWidget alloc] init];
    __weak OATextInfoWidget *altitudeControlWeak = altitudeControl;
    int __block cachedAlt = 0;
    altitudeControl.updateInfoFunction = ^BOOL{
        // draw speed
        CLLocation *loc = _app.locationServices.lastKnownLocation;
        if (loc && loc.verticalAccuracy >= 0)
        {
            CLLocationDistance compAlt = loc.altitude;
            if (cachedAlt != (int) compAlt)
            {
                cachedAlt = (int) compAlt;
                NSString *ds = [OAOsmAndFormatter.instance getFormattedAlt:cachedAlt];
                int ls = [ds indexOf:@" "];
                if (ls == -1)
                    [altitudeControlWeak setText:ds subtext:nil];
                else
                    [altitudeControlWeak setText:[ds substringToIndex:ls] subtext:[ds substringFromIndex:ls + 1]];
                
                return true;
            }
        }
        else if (cachedAlt != 0)
        {
            cachedAlt = 0;
            [altitudeControlWeak setText:nil subtext:nil];
            return true;
        }
        return false;

    };
    
    [altitudeControl setText:nil subtext:nil];
    [altitudeControl setIcons:@"widget_altitude_day" widgetNightIcon:@"widget_altitude_night"];
    return altitudeControl;
}

- (OATextInfoWidget *) createRulerControl
{
    NSString *title = @"-";
    OATextInfoWidget *rulerControl = [[OATextInfoWidget alloc] init];
    __weak OATextInfoWidget *rulerControlWeak = rulerControl;
    rulerControl.updateInfoFunction = ^BOOL{
        CLLocation *currentLocation = _app.locationServices.lastKnownLocation;
        CLLocation *centerLocation = [[OARootViewController instance].mapPanel.mapViewController getMapLocation];
        if (currentLocation && centerLocation) {
            OAMapViewTrackingUtilities *trackingUtilities = [OAMapViewTrackingUtilities instance];
            if ([trackingUtilities isMapLinkedToLocation]) {
                [rulerControlWeak setText:[OAOsmAndFormatter.instance getFormattedDistance:0] subtext:nil];
            }
            else {
                NSString *distance = [OAOsmAndFormatter.instance getFormattedDistance:OsmAnd::Utilities::distance(currentLocation.coordinate.longitude, currentLocation.coordinate.latitude,
                                                                                                        centerLocation.coordinate.longitude, centerLocation.coordinate.latitude)];
                NSUInteger ls = [distance rangeOfString:@" " options:NSBackwardsSearch].location;
                [rulerControlWeak setText:[distance substringToIndex:ls] subtext:[distance substringFromIndex:ls + 1]];
            }
        }
        else
        {
            [rulerControlWeak setText:title subtext:nil];
        }
        return YES;
    };
    rulerControl.onClickFunction = ^(id sender) {
        OAAppSettings *settings = [OAAppSettings sharedManager];
        EOARulerWidgetMode mode = settings.rulerMode.get;
        if (mode == RULER_MODE_DARK)
            [settings.rulerMode set:RULER_MODE_LIGHT];
        else if (mode == RULER_MODE_LIGHT)
            [settings.rulerMode set:RULER_MODE_NO_CIRCLES];
        else if (mode == RULER_MODE_NO_CIRCLES)
            [settings.rulerMode set:RULER_MODE_DARK];
        
        if (settings.rulerMode.get == RULER_MODE_NO_CIRCLES) {
            [rulerControlWeak setIcons:@"widget_ruler_circle_hide_day" widgetNightIcon:@"widget_ruler_circle_hide_night"];
        } else {
            [rulerControlWeak setIcons:@"widget_ruler_circle_day" widgetNightIcon:@"widget_ruler_circle_night"];
        }
        [[OARootViewController instance].mapPanel.hudViewController.mapInfoController updateRuler];
    };
    OAAppSettings *settings = [OAAppSettings sharedManager];
    BOOL circlesShown = settings.rulerMode.get == RULER_MODE_NO_CIRCLES;
    [rulerControl setIcons:circlesShown ? @"widget_ruler_circle_hide_day" : @"widget_ruler_circle_day"
           widgetNightIcon:circlesShown ?  @"widget_ruler_circle_hide_night" : @"widget_ruler_circle_night"];
    return rulerControl;
}

@end
