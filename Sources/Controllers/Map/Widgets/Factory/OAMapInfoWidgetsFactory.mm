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
                NSString *ds = [_app getFormattedAlt:cachedAlt];
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

@end
