//
//  OAWeatherRasterLayer.m
//  OsmAnd Maps
//
//  Created by Alexey on 24.12.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAWeatherRasterLayer.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapRendererView.h"
#import "OAAutoObserverProxy.h"
#import "OAWeatherHelper.h"
#import "OAWeatherPlugin.h"
#import "OAWeatherToolbar.h"
#import "OAMapLayers.h"
#import "OAMapWidgetRegistry.h"
#import "OAPluginsHelper.h"
#import "OAAppData.h"
#import "OAObservable.h"
#import "OAOsmAndFormatter.h"

#include <OsmAndCore/Map/WeatherTileResourcesManager.h>
#include <OsmAndCore/Map/WeatherRasterLayerProvider.h>

@implementation OAWeatherRasterLayer
{
    std::shared_ptr<OsmAnd::WeatherTileResourcesManager> _resourcesManager;
    std::shared_ptr<OsmAnd::WeatherRasterLayerProvider> _provider;

    OAWeatherHelper *_weatherHelper;
    OAAutoObserverProxy *_weatherToolbarStateChangeObservable;
    BOOL _needsSettingsForToolbar;
    OAAutoObserverProxy* _weatherChangeObserver;
    OAAutoObserverProxy* _weatherUseOfflineDataChangeObserver;
    NSMutableArray<OAAutoObserverProxy *> *_layerChangeObservers;
    NSMutableArray<OAAutoObserverProxy *> *_alphaChangeObservers;
    
    QList<OsmAnd::BandIndex> _cachedBandIndexes;

    CGSize _cachedViewFrame;
    OsmAnd::PointI _cachedCenterPixel;
    BOOL _cachedAnyWidgetVisible;
    NSTimeInterval _lastUpdateTime;
    
    int64_t _timePeriodStart;
    int64_t _timePeriodEnd;
    int64_t _timePeriodStep;
    BOOL _requireTimePeriodChange;
    int64_t _dateTime;
}

- (instancetype) initWithMapViewController:(OAMapViewController *)mapViewController layerIndex:(int)layerIndex weatherLayer:(EOAWeatherLayer)weatherLayer date:(NSDate *)date
{
    self = [super initWithMapViewController:mapViewController layerIndex:layerIndex];
    if (self)
    {
        _weatherLayer = weatherLayer;
        _date = date;
    }
    return self;
}

- (NSString *) layerId
{
    return [NSString stringWithFormat:@"%@_%d", kWeatherRasterMapLayerId, (int)_weatherLayer];
}

- (void) initLayer
{
    _resourcesManager = self.app.resourcesManager->getWeatherResourcesManager();
    _weatherHelper = [OAWeatherHelper sharedInstance];

    _weatherToolbarStateChangeObservable = [[OAAutoObserverProxy alloc] initWith:self
                                                                     withHandler:@selector(onWeatherToolbarStateChanged)
                                                                      andObserve:[OARootViewController instance].mapPanel.weatherToolbarStateChangeObservable];
    _weatherChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                       withHandler:@selector(onWeatherChanged)
                                                        andObserve:self.app.data.weatherChangeObservable];
    _weatherUseOfflineDataChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                     withHandler:@selector(onWeatherLayerChanged)
                                                                      andObserve:self.app.data.weatherUseOfflineDataChangeObservable];
    _layerChangeObservers = [NSMutableArray array];
    _alphaChangeObservers = [NSMutableArray array];
    
    for (OAWeatherBand *band in [[OAWeatherHelper sharedInstance] bands])
    {
        [_layerChangeObservers addObject:[band createSwitchObserver:self handler:@selector(onWeatherLayerChanged)]];
        [_alphaChangeObservers addObject:[band createAlphaObserver:self handler:@selector(onWeatherLayerAlphaChanged:withKey:andValue:)]];
    }
}

- (void) deinitLayer
{
    if (_weatherToolbarStateChangeObservable)
    {
        [_weatherToolbarStateChangeObservable detach];
        _weatherToolbarStateChangeObservable = nil;
    }
    if (_weatherChangeObserver)
    {
        [_weatherChangeObserver detach];
        _weatherChangeObserver = nil;
    }
    if (_weatherUseOfflineDataChangeObserver)
    {
        [_weatherUseOfflineDataChangeObserver detach];
        _weatherUseOfflineDataChangeObserver = nil;
    }
    for (OAAutoObserverProxy *observer in _layerChangeObservers)
        [observer detach];

    for (OAAutoObserverProxy *observer in _alphaChangeObservers)
        [observer detach];
    
    [_layerChangeObservers removeAllObjects];
    [_alphaChangeObservers removeAllObjects];
}

- (void) resetLayer
{
    _provider.reset();
    [self.mapView resetProviderFor:self.layerIndex];
}

- (BOOL) updateLayer
{
    if (![super updateLayer])
        return NO;
    
    if (_dateTime == 0)
        [self setDateTime:[[NSDate now] timeIntervalSince1970] * 1000 goForward:YES resetPeriod:NO];
//        [self setDateTime:[[NSDate now] timeIntervalSince1970] * 1000 goForward:NO resetPeriod:NO];

    if ([[OAPluginsHelper getPlugin:OAWeatherPlugin.class] isEnabled])
    {
        [self updateOpacitySliderVisibility];

        QList<OsmAnd::BandIndex> bands = [_weatherHelper getVisibleBands];
        if ((!self.app.data.weather && !_needsSettingsForToolbar) || bands.empty())
            return NO;
        
        BOOL wasBandsChanged = bands != _cachedBandIndexes;
        _cachedBandIndexes = bands;

        //[self showProgressHUD];

        OsmAnd::WeatherLayer layer;
        switch (_weatherLayer) {
            case WEATHER_LAYER_LOW:
                layer = OsmAnd::WeatherLayer::Low;
                break;
            case WEATHER_LAYER_HIGH:
                layer = OsmAnd::WeatherLayer::High;
                break;
            default:
                layer = OsmAnd::WeatherLayer::Low;
                break;
        }
        if (!_provider || wasBandsChanged)
        {
            _requireTimePeriodChange = NO;
            _provider = std::make_shared<OsmAnd::WeatherRasterLayerProvider>(_resourcesManager, layer, _timePeriodStart, _timePeriodEnd, _timePeriodStep, bands, self.app.data.weatherUseOfflineData);
            [self.mapView setProvider:_provider forLayer:self.layerIndex];

            OsmAnd::MapLayerConfiguration config;
            config.setOpacityFactor(1.0f);
            [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        }
        if (_requireTimePeriodChange)
        {
            _requireTimePeriodChange = NO;
            _provider->setDateTime(_timePeriodStart, _timePeriodEnd, _timePeriodStep);
            [self.mapView changeTimePeriod];
        }
        [self.mapView setDateTime:_dateTime];
        //[self hideProgressHUD];

        return YES;
    }
    return NO;
}

- (void) setDateTime:(int64_t)dateTime goForward:(BOOL)goForward resetPeriod:(BOOL)resetPeriod
{
    if (_timePeriodStart == 0)
        _timePeriodStart = [[NSDate now] timeIntervalSince1970] * 1000;
    
    int64_t dayStart = [OAOsmAndFormatter getStartOfDayForTime:_timePeriodStart / 1000] * 1000;
    int64_t dayEnd = dayStart + DAY_IN_MILLISECONDS;
    if (dateTime < dayStart || dayStart > dayEnd)
    {
        dayStart = [OAOsmAndFormatter getStartOfDayForTime:dayStart];
        dayEnd = dayStart + DAY_IN_MILLISECONDS;
    }
    
    int64_t todayStep = HOUR_IN_MILLISECONDS;
    int64_t nextStep = todayStep * 3;
    int64_t startOfToday = [OAOsmAndFormatter getStartOfToday] * 1000;
    int64_t step = dayStart == startOfToday ? todayStep : nextStep;
    int64_t switchStepTime = ((int64_t)([[NSDate now] timeIntervalSince1970] * 1000 + DAY_IN_MILLISECONDS)) / nextStep * nextStep;
    if (switchStepTime > startOfToday && switchStepTime >= dayStart + todayStep && switchStepTime <= dayEnd - nextStep)
    {
        if (dateTime < switchStepTime) 
        {
            dayEnd = switchStepTime;
            step = todayStep;
        } 
        else
        {
            dayStart = switchStepTime;
        }
    }
    
    int64_t prevTime = (dateTime - dayStart) / step * step + dayStart;
    int64_t nextTime = prevTime + step;
    if (goForward)
    {
        if (resetPeriod || _timePeriodStep != step
            || (_timePeriodStart > dayStart && prevTime < _timePeriodStart)
            || (_timePeriodEnd < dayEnd && nextTime > _timePeriodEnd))
        {
            _timePeriodStart = MAX(prevTime, dayStart);
            _timePeriodEnd = MIN(nextTime + FORECAST_ANIMATION_DURATION_HOURS * HOUR_IN_MILLISECONDS, dayEnd);
            _timePeriodStep = step;
            _requireTimePeriodChange = YES;
        }
    }
    else
    {
        int64_t nearestTime = dateTime - prevTime < nextTime - dateTime ? prevTime : nextTime;
        if (resetPeriod || _timePeriodStep != step
            || (_timePeriodStart > dayStart && nearestTime <= _timePeriodStart)
            || (_timePeriodEnd < dayEnd && nearestTime >= _timePeriodEnd))
        {
            _timePeriodStart = MAX(nearestTime - step, dayStart);
            _timePeriodEnd = MIN(nearestTime + step, dayEnd);
            _timePeriodStep = step;
            _requireTimePeriodChange = YES;
        }
    }
    _dateTime = dateTime;
}

- (void)onWeatherToolbarStateChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL needsSettingsForToolbar = [[OARootViewController instance].mapPanel.hudViewController needsSettingsForWeatherToolbar];
        if (_needsSettingsForToolbar != needsSettingsForToolbar)
        {
            _date = self.mapViewController.mapLayers.weatherDate;
            _needsSettingsForToolbar = needsSettingsForToolbar;
            [self updateWeatherLayerAlpha];
        }
    });
}

- (void) onWeatherChanged
{
    [self updateWeatherLayer];
}

- (void) updateDate:(NSDate *)date
{
    _date = date;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            [self updateWeatherLayer];
        }];
    });
}

- (void) onWeatherLayerChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            [self updateWeatherLayer];
        }];
    });
}

- (void) onWeatherLayerAlphaChanged:(id)observer withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            OsmAnd::MapLayerConfiguration config;
            config.setOpacityFactor([value floatValue]);
            [self.mapView setMapLayerConfiguration:self.layerIndex configuration:config forcedUpdate:NO];
        }];
    });
    [self updateWeatherLayerAlpha];
}

- (void) updateWeatherLayer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            if (![self updateLayer])
            {
                //[self.mapView resetProviderFor:0];
                [self.mapView resetProviderFor:self.layerIndex];
                _provider.reset();
            }
        }];
    });
}

- (void) updateWeatherLayerAlpha
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapViewController runWithRenderSync:^{
            _resourcesManager->setBandSettings([_weatherHelper getBandSettings]);
            [self updateWeatherLayer];
        }];
    });
}

- (void) updateOpacitySliderVisibility
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //TODO [[OARootViewController instance].mapPanel updateWeatherView];
    });
}

- (void) onMapFrameRendered
{
    if (CACurrentMediaTime() - _lastUpdateTime < 0.5)
        return;

    _lastUpdateTime = CACurrentMediaTime();

    dispatch_async(dispatch_get_main_queue(), ^{

        OAMapViewController *mapCtrl = [OARootViewController instance].mapPanel.mapViewController;

        CGSize viewFrame = mapCtrl.view.frame.size;
        BOOL frameChanged = !CGSizeEqualToSize(_cachedViewFrame, viewFrame);
        OsmAnd::PointI centerPixel = mapCtrl.mapView.getCenterPixel;
        BOOL centerPixelChanged = _cachedCenterPixel != centerPixel;
        BOOL anyWidgetVisible = OAMapWidgetRegistry.sharedInstance.isAnyWeatherWidgetVisible;

        if (!centerPixelChanged && !frameChanged && _cachedAnyWidgetVisible == anyWidgetVisible)
            return;

        if (!anyWidgetVisible)
        {
            [self setMapCenterMarkerVisibility:NO];
        }
        else if (anyWidgetVisible)
        {
            [self setMapCenterMarkerVisibility:NO];
            [self setMapCenterMarkerVisibility:YES];
        }

        _cachedCenterPixel = centerPixel;
        _cachedViewFrame = viewFrame;
        _cachedAnyWidgetVisible = anyWidgetVisible;

    });
}

- (void) setMapCenterMarkerVisibility:(BOOL)visible
{
    UIView *targetView;
    OAMapViewController *mapCtrl = [OARootViewController instance].mapPanel.mapViewController;
    UIView *view = mapCtrl.view;
    if (view)
    {
        for (UIView *v in view.subviews)
        {
            if (v.tag == 2222)
                targetView = v;
        }
        double w = 20;
        double h = 20;
        if (targetView.tag != 2222 && visible)
        {
            targetView = [[UIView alloc] initWithFrame:{0, 0, w, h}];
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
            {
                CGFloat screenScale = mapCtrl.displayDensityFactor;
                OsmAnd::PointI centerPixel = mapCtrl.mapView.getCenterPixel;
                targetView.frame = {centerPixel.x / screenScale - w / 2.0, centerPixel.y / screenScale - h / 2.0, w, h};
                [view addSubview:targetView];
            }
            else
            {
                [targetView removeFromSuperview];
            }
        }
    }
}

@end
