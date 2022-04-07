//
//  OAMapInfoWidgetsFactory.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAMapInfoWidgetsFactory.h"
#import "OsmAndApp.h"
#import "OATextInfoWidget.h"
#import "OARootViewController.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAMapHudViewController.h"
#import "OAMapRendererView.h"
#import "OAMapLayers.h"
#import "OAMapInfoController.h"
#import "OAOsmAndFormatter.h"
#import "OAIAPHelper.h"

#include <OsmAndCore/Map/WeatherTileResourcesManager.h>


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
                NSString *ds = [OAOsmAndFormatter getFormattedAlt:cachedAlt];
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
                [rulerControlWeak setText:[OAOsmAndFormatter getFormattedDistance:0] subtext:nil];
            }
            else {
                NSString *distance = [OAOsmAndFormatter getFormattedDistance:OsmAnd::Utilities::distance(currentLocation.coordinate.longitude, currentLocation.coordinate.latitude,
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

- (OATextInfoWidget *) createWeatherControl:(EOAWeatherBand)band
{
    OATextInfoWidget *weatherControl = [[OATextInfoWidget alloc] init];
    __weak OATextInfoWidget *weatherControlWeak = weatherControl;
    __weak OAMapInfoWidgetsFactory *selfWeak = self;
    NSNumber *undefined = @(-10000);
    NSMutableArray *cachedValue = @[undefined].mutableCopy;
    OsmAnd::PointI __block cachedTarget31 = OsmAnd::PointI(0, 0);
    OsmAnd::ZoomLevel __block cachedZoom = OsmAnd::ZoomLevel::InvalidZoomLevel;
    weatherControl.updateInfoFunction = ^BOOL{

        BOOL enabled = _app.data.weather;
        if (!enabled)
        {
            if (cachedValue[0] != undefined)
                [weatherControlWeak setText:nil subtext:nil];
            
            [selfWeak setMapCenterMarkerVisibility:NO];
            
            return false;
        }
        
        OAMapViewController *mapCtrl = [OARootViewController instance].mapPanel.mapViewController;
                                        
        OsmAnd::PointI target31 = mapCtrl.mapView.target31;
        OsmAnd::ZoomLevel zoom = mapCtrl.mapView.zoomLevel;
        
        if (cachedTarget31 == target31 && cachedZoom == zoom)
            return false;

        cachedTarget31 = target31;
        cachedZoom = zoom;

        OsmAnd::WeatherTileResourcesManager::ValueRequest _request;
        _request.dataTime = QDateTime::fromNSDate(mapCtrl.mapLayers.weatherDate).toUTC();
        _request.point31 = target31;
        _request.zoom = zoom;
        _request.band = (OsmAnd::BandIndex)band;

        OsmAnd::WeatherTileResourcesManager::ObtainValueAsyncCallback _callback =
            [selfWeak, cachedValue, band, undefined, weatherControlWeak]
            (const bool succeeded,
                const double value,
                const std::shared_ptr<OsmAnd::Metric>& metric)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (succeeded)
                    {
                        if (![cachedValue[0] isEqual:@(value)])
                        {
                            cachedValue[0] = @(value);
                            const auto bandValue = [OsmAndApp instance].resourcesManager->getWeatherResourcesManager()->getConvertedBandValue(band, value);
                            const auto bandValueStr = [OsmAndApp instance].resourcesManager->getWeatherResourcesManager()->getFormattedBandValue(band, bandValue, true);

                            NSMeasurementFormatter *formatter = [NSMeasurementFormatter new];
                            formatter.locale = NSLocale.autoupdatingCurrentLocale;

                            NSString *bandUnit = [formatter stringFromUnit:[[OAWeatherBand withWeatherBand:band] getBandUnit]];

                            BOOL unitsWithBigFont = band == WEATHER_BAND_TEMPERATURE;
                            if (unitsWithBigFont)
                            {
                                NSString *fullText = [NSString stringWithFormat:@"%@ %@", bandValueStr.toNSString(), bandUnit];
                                [weatherControlWeak setText:fullText subtext:nil];
                            }
                            else
                            {
                                [weatherControlWeak setText:bandValueStr.toNSString() subtext:bandUnit];
                            }
                            [selfWeak setMapCenterMarkerVisibility:YES];
                        }
                    }
                    else if (cachedValue[0] != undefined)
                    {
                        cachedValue[0] = undefined;
                        [weatherControlWeak setText:nil subtext:nil];
                        [selfWeak setMapCenterMarkerVisibility:NO];
                    }
                });
            };
            
        _app.resourcesManager->getWeatherResourcesManager()->obtainValueAsync(_request, _callback);
    
        return true;
    };
    
    [weatherControl setText:nil subtext:nil];
    NSString *iconNameDay;
    NSString *iconNameNight;
    if (band == WEATHER_BAND_TEMPERATURE)
    {
        iconNameDay = @"widget_weather_temperature_day";
        iconNameNight = @"widget_weather_temperature_night";
    }
    else if (band == WEATHER_BAND_PRESSURE)
    {
        iconNameDay = @"widget_weather_air_pressure_day";
        iconNameNight = @"widget_weather_air_pressure_night";
    }
    else if (band == WEATHER_BAND_WIND_SPEED)
    {
        iconNameDay = @"widget_weather_wind_day";
        iconNameNight = @"widget_weather_wind_night";
    }
    else if (band == WEATHER_BAND_CLOUD)
    {
        iconNameDay = @"widget_weather_clouds_day";
        iconNameNight = @"widget_weather_clouds_night";
    }
    else if (band == WEATHER_BAND_PRECIPITATION)
    {
        iconNameDay = @"widget_weather_precipitation_day";
        iconNameNight = @"widget_weather_precipitation_night";
    }

    [weatherControl setIcons:iconNameDay widgetNightIcon:iconNameNight];
    return weatherControl;
}

- (void) setMapCenterMarkerVisibility:(BOOL)visible
{
    UIView *targetView;
    UIView *view = [OARootViewController instance].mapPanel.mapViewController.view;
    if (view)
    {
        for (UIView *v in view.subviews)
        {
            if (v.tag == 2222)
                targetView = v;
        }
        if (targetView.tag != 2222)
        {
            double w = 20;
            double h = 20;
            targetView = [[UIView alloc] initWithFrame:{view.frame.size.width / 2.0 - w / 2.0, view.frame.size.height / 2.0 - h / 2.0, w, h}];
            targetView.backgroundColor = UIColor.clearColor;
            targetView.tag = 2222;

            CAShapeLayer *shape = [CAShapeLayer layer];
            [shape setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake(2, 2, w - 4, h - 4)] CGPath]];
            shape.strokeColor = UIColor.redColor.CGColor;
            shape.fillColor = UIColor.clearColor.CGColor;
            [targetView.layer addSublayer:shape];
        }
        if (targetView)
        {
            if (visible)
                [view addSubview:targetView];
            else
                [targetView removeFromSuperview];
        }
    }
}

@end
