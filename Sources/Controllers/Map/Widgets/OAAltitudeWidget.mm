//
//  OAAltitudeWidget.mm
//  OsmAnd Maps
//
//  Created by Skalii on 19.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAAltitudeWidget.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OsmAndApp.h"
#import "OAOsmAndFormatter.h"
#import "OANativeUtilities.h"

#import "OsmAnd_Maps-Swift.h"

@implementation OAAltitudeWidget
{
    OsmAndAppInstance _app;
    EOAAltitudeWidgetType _widgetType;
    int _cachedAltitude;
}

- (instancetype)initWithType:(EOAAltitudeWidgetType)widgetType
                    customId:(NSString *)customId
                     appMode:(OAApplicationMode *)appMode
                widgetParams:(NSDictionary *)widgetParams
{
    self = [super init];
    if (self)
    {
        // TODO: refactor widget type
        self.widgetType = widgetType == EOAAltitudeWidgetTypeMapCenter ? OAWidgetType.altitudeMapCenter : OAWidgetType.altitudeMyLocation;
        _widgetType = widgetType;
        [self configurePrefsWithId:customId appMode:appMode widgetParams:widgetParams];
        _app = [OsmAndApp instance];
        _cachedAltitude = 0;

        [self setText:@"-" subtext:nil];

        if (_widgetType == EOAAltitudeWidgetTypeMyLocation)
            [self setIcon:@"widget_altitude_location"];
        else
            [self setIcon:@"widget_altitude_map_center"];
    }
    return self;
}

- (BOOL)updateInfo
{
    [self requestAltitude];
}

- (BOOL)updateAltitude:(float)altitude
{
    if (altitude > kMinAltitudeValue)
    {
        int newAltitude = (int) altitude;
        if ([self isUpdateNeeded] || _cachedAltitude != newAltitude)
        {
            _cachedAltitude = newAltitude;
            NSString *formattedAltitude = [OAOsmAndFormatter getFormattedAlt:_cachedAltitude];
            int index = [formattedAltitude lastIndexOf:@" "];
            if (index == -1)
                [self setText:formattedAltitude subtext:nil];
            else
                [self setText:[formattedAltitude substringToIndex:index] subtext:[formattedAltitude substringFromIndex:index + 1]];
        }
    }
    else if (_cachedAltitude != 0)
    {
        _cachedAltitude = 0;
        [self setText:@"-" subtext:nil];
    }
    return YES;
}

- (void)requestAltitude
{
    switch (_widgetType)
    {
        case EOAAltitudeWidgetTypeMyLocation:
        {
            CLLocation *loc = _app.locationServices.lastKnownLocation;
            if (loc && loc.verticalAccuracy >= 0)
            {
                [self updateAltitude:loc.altitude];
                return;
            }
            break;
        }
        case EOAAltitudeWidgetTypeMapCenter:
        {
            [OARootViewController.instance.mapPanel.mapViewController getAltitudeForMapCenter:^(float height) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self updateAltitude:height];
                });
            }];
            return;
        }
    }
    [self updateAltitude:kMinAltitudeValue];
}

- (BOOL) isMetricSystemDepended
{
    return YES;
}

@end
