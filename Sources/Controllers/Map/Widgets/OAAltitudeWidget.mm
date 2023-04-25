//
//  OAAltitudeWidget.mm
//  OsmAnd Maps
//
//  Created by Skalii on 19.04.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAAltitudeWidget.h"
#import "OARootViewController.h"
#import "OAMapRendererView.h"
#import "OsmAndApp.h"
#import "OAOsmAndFormatter.h"
#import "OANativeUtilities.h"

@implementation OAAltitudeWidget
{
    OsmAndAppInstance _app;
    EOAAltitudeWidgetType _widgetType;
    int _cachedAltitude;
}

- (instancetype)initWithType:(EOAAltitudeWidgetType)widgetType
{
    self = [super init];
    if (self)
    {
        _widgetType = widgetType;
        _app = [OsmAndApp instance];
        _cachedAltitude = 0;

        [self setText:@"-" subtext:nil];

        if (_widgetType == EOAAltitudeWidgetTypeMyLocation)
            [self setIcons:@"widget_altitude_location_day" widgetNightIcon:@"widget_altitude_location_night"];
        else
            [self setIcons:@"widget_altitude_map_center_day" widgetNightIcon:@"widget_altitude_map_center_night"];
    }
    return self;
}

- (BOOL)updateInfo
{
    double altitude = [self getAltitudeInMeters];
    if (altitude != kMinAltitudeValue)
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

- (double)getAltitudeInMeters
{
    switch (_widgetType)
    {
        case EOAAltitudeWidgetTypeMyLocation:
        {
            CLLocation *loc = _app.locationServices.lastKnownLocation;
            if (loc && loc.verticalAccuracy >= 0)
                return loc.altitude;
            break;
        }
        case EOAAltitudeWidgetTypeMapCenter:
        {
            OsmAnd::PointI screenPoint = [OARootViewController instance].mapPanel.mapViewController.mapView.fixedPixel;
            return [OANativeUtilities getAltitudeForPixelPoint:screenPoint];
        }
    }
    return kMinAltitudeValue;
}

- (BOOL) isMetricSystemDepended
{
    return YES;
}

@end
