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
#import "OAMapViewController.h"
#import "OAMapViewTrackingUtilities.h"
#import "OALocationServices.h"
#import "OAMapHudViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "OAMapLayers.h"
#import "OAMapInfoController.h"
#import "OAOsmAndFormatter.h"
#import "OAIAPHelper.h"
#import "OAWeatherToolbar.h"
#import "OAAppData.h"

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
            [rulerControlWeak setIcon:@"widget_hidden"];
        } else {
            [rulerControlWeak setIcon:@"widget_ruler_circle"];
        }
        [[OARootViewController instance].mapPanel.hudViewController.mapInfoController updateRuler];
    };
    OAAppSettings *settings = [OAAppSettings sharedManager];
    BOOL circlesShown = settings.rulerMode.get == RULER_MODE_NO_CIRCLES;
    [rulerControl setIcon:circlesShown ? @"widget_hidden" : @"widget_ruler_circle"];
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
    __block NSDate *cachedDate;

    NSMeasurementFormatter *formatter = [NSMeasurementFormatter new];
    formatter.unitStyle = NSFormattingUnitStyleShort;
    formatter.locale = NSLocale.autoupdatingCurrentLocale;
    __block NSString *cachedBandUnit = [formatter displayStringFromUnit:[[OAWeatherBand withWeatherBand:band] getBandUnit]];

    weatherControl.updateInfoFunction = ^BOOL{
        OAMapViewController *mapCtrl = [OARootViewController instance].mapPanel.mapViewController;
                                        
        OsmAnd::PointI target31 = mapCtrl.mapView.target31;
        OsmAnd::ZoomLevel zoom = mapCtrl.mapView.zoomLevel;
        NSDate *date = mapCtrl.mapLayers.weatherDate;
        NSString *bandUnit = [formatter displayStringFromUnit:[[OAWeatherBand withWeatherBand:band] getBandUnit]];
        BOOL needToUpdate = ![cachedBandUnit isEqualToString:bandUnit];

        if (cachedTarget31 == target31 && cachedZoom == zoom && cachedDate && [cachedDate isEqualToDate:date] && !needToUpdate)
            return false;

        cachedTarget31 = target31;
        cachedZoom = zoom;
        cachedDate = date;
        cachedBandUnit = bandUnit;

        OsmAnd::WeatherTileResourcesManager::ValueRequest _request;
        _request.dateTime = date.timeIntervalSince1970 * 1000;
        _request.point31 = target31;
        _request.zoom = zoom;
        _request.band = (OsmAnd::BandIndex)band;
        _request.localData = _app.data.weatherUseOfflineData;

        OsmAnd::WeatherTileResourcesManager::ObtainValueAsyncCallback _callback =
            [selfWeak, cachedValue, band, needToUpdate, bandUnit, undefined, weatherControlWeak]
            (const bool succeeded,
                OsmAnd::PointI requestedPoint31,
                int64_t requestedTime,
                const double value,
                const std::shared_ptr<OsmAnd::Metric>& metric)
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (succeeded)
                    {
                        if (![cachedValue[0] isEqual:@(value)] || needToUpdate)
                        {
                            cachedValue[0] = @(value);
                            const auto bandValue = [OsmAndApp instance].resourcesManager->getWeatherResourcesManager()->getConvertedBandValue(band, value);
                            const auto bandValueStr = [OsmAndApp instance].resourcesManager->getWeatherResourcesManager()->getFormattedBandValue(band, bandValue, true);

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
//                            [selfWeak setMapCenterMarkerVisibility:YES];
                        }
                    }
                    else if (cachedValue[0] != undefined)
                    {
                        cachedValue[0] = undefined;
                        [weatherControlWeak setText:nil subtext:nil];
//                        [selfWeak setMapCenterMarkerVisibility:NO];
                    }
                });
            };
            
        _app.resourcesManager->getWeatherResourcesManager()->obtainValueAsync(_request, _callback);
    
        return true;
    };
    
    [weatherControl setText:nil subtext:nil];
    NSString *iconName;
    if (band == WEATHER_BAND_TEMPERATURE)
    {
        iconName = @"widget_weather_temperature";
    }
    else if (band == WEATHER_BAND_PRESSURE)
    {
        iconName = @"widget_weather_air_pressure";
    }
    else if (band == WEATHER_BAND_WIND_SPEED)
    {
        iconName = @"widget_weather_wind";
    }
    else if (band == WEATHER_BAND_CLOUD)
    {
        iconName = @"widget_weather_clouds";
    }
    else if (band == WEATHER_BAND_PRECIPITATION)
    {
        iconName = @"widget_weather_precipitation";
    }

    [weatherControl setIcon:iconName];
    return weatherControl;
}

@end
