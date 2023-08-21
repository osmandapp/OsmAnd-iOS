//
//  OAWeatherWidget.m
//  OsmAnd Maps
//
//  Created by Paul on 08.06.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAWeatherWidget.h"
#import "OsmAnd_Maps-Swift.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAMapLayers.h"
#import "OsmAndApp.h"
#import "OAAppData.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/Map/WeatherTileResourcesManager.h>

@interface OAWeatherWidget ()

@property (nonatomic, assign) EOAWeatherBand band;
@property (nonatomic) double undefined;
@property (nonatomic) double cachedValue;

@end

@implementation OAWeatherWidget
{
    OsmAnd::PointI _cachedTarget31;
    OsmAnd::PointI _cachedFixedPixel;
    OsmAnd::ZoomLevel _cachedZoom;
    NSDate *_cachedDate;
    CGSize _cachedViewFrame;
    
    NSMeasurementFormatter *_formatter;
    NSString *_cachedBandUnit;
    
    OsmAndAppInstance _app;
}

- (instancetype) initWithType:(OAWidgetType *)type band:(EOAWeatherBand)band
{
    self = [super initWithType:type];
    if (self) {
        [self setIcons:type];
        _app = OsmAndApp.instance;
        _band = band;
        _undefined = -10000.0;
        _cachedValue = _undefined;
        _formatter = [[NSMeasurementFormatter alloc] init];
        _formatter.unitStyle = NSFormattingUnitStyleShort;
        _formatter.locale = NSLocale.autoupdatingCurrentLocale;
        _cachedBandUnit = [_formatter displayStringFromUnit:[[OAWeatherBand withWeatherBand:band] getBandUnit]];
    }
    return self;
}

- (BOOL)updateInfo
{
    OAMapViewController *mapCtrl = [OARootViewController instance].mapPanel.mapViewController;
                                    
    OsmAnd::PointI target31 = mapCtrl.mapView.target31;
    OsmAnd::PointI fixedPixel = mapCtrl.mapView.fixedPixel;
    OsmAnd::ZoomLevel zoom = mapCtrl.mapView.zoomLevel;
    NSDate *date = mapCtrl.mapLayers.weatherDate;
    NSLog(@"%@", [[OAWeatherBand withWeatherBand:_band] getBandUnit]);
    NSString *bandUnit = [_formatter displayStringFromUnit:[[OAWeatherBand withWeatherBand:_band] getBandUnit]];
    BOOL needToUpdate = ![_cachedBandUnit isEqualToString:bandUnit];
    CGSize viewFrame = mapCtrl.view.frame.size;
    BOOL frameChanged = !CGSizeEqualToSize(_cachedViewFrame, viewFrame);

    if (_cachedTarget31 == target31 && _cachedFixedPixel == fixedPixel && _cachedZoom == zoom && !frameChanged && _cachedDate && [_cachedDate isEqualToDate:date] && !needToUpdate)
        return false;

    if (frameChanged)
    {
        [self setMapCenterMarkerVisibility:NO];
        [self setMapCenterMarkerVisibility:YES];
    }

    _cachedTarget31 = target31;
    _cachedFixedPixel = fixedPixel;
    _cachedZoom = zoom;
    _cachedDate = date;
    _cachedBandUnit = bandUnit;
    _cachedViewFrame = viewFrame;

    CGFloat scale = mapCtrl.view.contentScaleFactor;
    OsmAnd::PointI elevated31 = [OANativeUtilities get31FromElevatedPixel:OsmAnd::PointI(viewFrame.width / 2.0 * scale, viewFrame.height / 2.0 * scale)];

    OsmAnd::WeatherTileResourcesManager::ValueRequest _request;
    _request.clientId = QStringLiteral("OAWeatherWidget");
    _request.dateTime = date.timeIntervalSince1970 * 1000;
    _request.point31 = elevated31;
    _request.zoom = zoom;
    _request.band = (OsmAnd::BandIndex)_band;
    _request.localData = _app.data.weatherUseOfflineData;
    _request.abortIfNotRecent = true;
    
    __weak OAWeatherWidget *selfWeak = self;
    
    OsmAnd::WeatherTileResourcesManager::ObtainValueAsyncCallback _callback =
        [selfWeak, needToUpdate, bandUnit]
        (const bool succeeded,
            OsmAnd::PointI requestedPoint31,
            int64_t requestedTime,
            const double value,
            const std::shared_ptr<OsmAnd::Metric>& metric)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (succeeded)
                {
                    if (selfWeak.cachedValue != value || needToUpdate)
                    {
                        selfWeak.cachedValue = value;
                        const auto bandValue = [OsmAndApp instance].resourcesManager->getWeatherResourcesManager()->getConvertedBandValue(selfWeak.band, value);
                        const auto bandValueStr = [OsmAndApp instance].resourcesManager->getWeatherResourcesManager()->getFormattedBandValue(selfWeak.band, bandValue, true);

                        BOOL unitsWithBigFont = selfWeak.band == WEATHER_BAND_TEMPERATURE;
                        if (unitsWithBigFont)
                        {
                            NSString *fullText = [NSString stringWithFormat:@"%@ %@", bandValueStr.toNSString(), bandUnit];
                            [selfWeak setText:fullText subtext:nil];
                        }
                        else
                        {
                            [selfWeak setText:bandValueStr.toNSString() subtext:bandUnit];
                        }
                        [selfWeak setMapCenterMarkerVisibility:YES];
                    }
                }
                else if (selfWeak.cachedValue != selfWeak.undefined)
                {
                    selfWeak.cachedValue = selfWeak.undefined;
                    [selfWeak setText:nil subtext:nil];
                    [selfWeak setMapCenterMarkerVisibility:NO];
                }
            });
        };
        
    _app.resourcesManager->getWeatherResourcesManager()->obtainValueAsync(_request, _callback);

    return true;
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
