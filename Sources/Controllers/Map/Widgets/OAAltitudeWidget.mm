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
    void (^callback)(CGFloat) = ^(CGFloat height) {
        if (height != kMinAltitudeValue)
        {
            int newAltitude = (int) height;
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
    };
    [self getAltitudeInMeters:callback];
    return YES;
}

- (void)getAltitudeInMeters:(void (^ _Nonnull)(CGFloat height))callback
{
    switch (_widgetType)
    {
        case EOAAltitudeWidgetTypeMyLocation:
        {
            CLLocation *loc = _app.locationServices.lastKnownLocation;
            if (loc && loc.verticalAccuracy >= 0)
                callback(loc.altitude);
            else
                callback(kMinAltitudeValue);
            break;
        }
        case EOAAltitudeWidgetTypeMapCenter:
        {
            OsmAnd::PointI centerPoint = [OARootViewController instance].mapPanel.mapViewController.mapView.fixedPixel;
            CLLocationCoordinate2D centerLatLon = [OANativeUtilities getLatLonFromElevatedPixel:centerPoint];
            [OAMapUtils getAltitudeForLatLon:centerLatLon callback:callback];
            break;
        }
        default:
        {
            callback(kMinAltitudeValue);
        }
    }
}

- (BOOL) isMetricSystemDepended
{
    return YES;
}

@end
