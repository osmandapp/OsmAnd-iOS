//
//  OACoordinatesGridLayer.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 25.04.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OACoordinatesGridLayer.h"
#import "OAAppSettings.h"
#import "OACoordinatesGridSettings.h"
#import "OsmAnd_Maps-Swift.h"
#import <OsmAndCore/Map/GridMarksProvider.h>
#import "OANativeUtilities.h"
#import "OAColors.h"
#import <OsmAndCore/TextRasterizer.h>
#import "OAMapRendererView.h"

#include <OsmAndCore/Map/MapRendererState.h>

static const CGFloat kDefaultMarginFactor = 8.0f;
static const OsmAnd::TextRasterizer::Style::TextAlignment kNoTextAlignment = static_cast<OsmAnd::TextRasterizer::Style::TextAlignment>(-1);

@implementation OACoordinatesGridLayer
{
    OAAppSettings *_settings;
    OACoordinatesGridSettings *_gridSettings;
    
    std::shared_ptr<OsmAnd::GridMarksProvider> _marksProvider;
    std::shared_ptr<OsmAnd::GridConfiguration> _gridConfiguration;
    
    NSString *_cachedGridFormatId;
    CoordinateGridFormatInfo *_cachedGridFormatInfo;
    float _defaultGranularity;
    ZoomRange _cachedZoomLimits;
    GridLabelsPosition _cachedLabelsPosition;
    CGFloat _cachedTextScale;
    int _cachedGridColorDay;
    int _cachedGridColorNight;
    BOOL _cachedGridEnabled;
    BOOL _cachedNightMode;
    
    OAMapInfoController *_mapInfoController;
    BOOL _marginFactorUpdateNeeded;
    
    OAAutoObserverProxy *_mapSettingsChangeObserver;
    OAAutoObserverProxy *_dayNightModeObserver;
}

- (NSString *)layerId
{
    return kCoordinatesGridLayerId;
}

- (void)initLayer
{
    [super initLayer];
    
    _settings = [OAAppSettings sharedManager];
    _gridSettings = [[OACoordinatesGridSettings alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onPreferenceChange) name:kNotificationSetProfileSetting object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onWidgetsLayoutDidChange) name:kWidgetsPanelsDidLayoutNotification object:nil];
    _mapSettingsChangeObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onPreferenceChange) andObserve:self.app.mapSettingsChangeObservable];
    _dayNightModeObserver = [[OAAutoObserverProxy alloc] initWith:self withHandler:@selector(onPreferenceChange) andObserve:OsmAndApp.instance.dayNightModeObservable];
}

- (BOOL)updateLayer
{
    if (![super updateLayer])
        return NO;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_mapInfoController)
            _mapInfoController = [OARootViewController instance].mapPanel.hudViewController.mapInfoController;
        
        [self updateGridSettings];
    });
    
    return YES;
}

- (void)resetLayer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [super resetLayer];
        [self.mapView removeKeyedSymbolsProvider:_marksProvider];
        _marksProvider.reset();
    });
}

- (void)deinitLayer
{
    [super deinitLayer];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationSetProfileSetting object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kWidgetsPanelsDidLayoutNotification object:nil];
    if (_mapSettingsChangeObserver)
    {
        [_mapSettingsChangeObserver detach];
        _mapSettingsChangeObserver = nil;
    }
    if (_dayNightModeObserver)
    {
        [_dayNightModeObserver detach];
        _dayNightModeObserver = nil;
    }
}

- (void)onPreferenceChange
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateGridSettings];
    });
}

- (void)onWidgetsLayoutDidChange
{
    _marginFactorUpdateNeeded = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateGridSettings];
    });
}

- (void)updateGridSettings
{
    OAApplicationMode *appMode = [_settings.applicationMode get];
    BOOL updateAppearance = NO;
    BOOL zoomLevelsUpdated = NO;
    BOOL marginFactorUpdated = NO;
    BOOL forceConfigurationUpdate = NO;
    BOOL show = [_gridSettings isEnabled];
    if (show)
    {
        if (_gridConfiguration == nullptr || !_marksProvider)
        {
            forceConfigurationUpdate = _gridConfiguration != nullptr;
            _gridConfiguration = std::make_shared<OsmAnd::GridConfiguration>();
            [self initVariablesWithAppMode:appMode];
            updateAppearance = YES;
        }
        else
        {
            NSString *previousFormatId = _cachedGridFormatId;
            updateAppearance = [self updateVariablesWithAppMode:appMode];
            forceConfigurationUpdate = ![previousFormatId isEqualToString:_cachedGridFormatId];
            zoomLevelsUpdated = [self updateZoomLevelsWithAppMode:appMode];
            marginFactorUpdated = [self updateLabelsMarginFactor];
        }
        if (updateAppearance)
        {
            [self cleanupMarksProvider];
            [self updateGridAppearance];
        }
    }
    
    BOOL updated = updateAppearance || zoomLevelsUpdated || marginFactorUpdated;
    if (_gridConfiguration && (_cachedGridEnabled != show || updated))
    {
        _cachedGridEnabled = show;
        [self updateGridVisibility:_cachedGridEnabled force:forceConfigurationUpdate];
    }
}

- (void)initVariablesWithAppMode:(OAApplicationMode *)appMode
{
    NSString *formatId = [_gridSettings gridFormatIdForAppMode:appMode];
    _cachedGridFormatInfo = [CoordinateGridFormatBridge resolveInfo:formatId];
    _cachedGridFormatId = _cachedGridFormatInfo.formatId;
    _cachedLabelsPosition = (GridLabelsPosition)[_gridSettings gridLabelsPositionForAppMode:appMode];
    _cachedGridColorDay = [_gridSettings dayGridColor];
    _cachedGridColorNight = [_gridSettings nightGridColor];
    _cachedTextScale = [_gridSettings textScaleForAppMode:appMode];
    _cachedGridEnabled = [_gridSettings isEnabled];
    _cachedZoomLimits = [_gridSettings zoomLevelsWithRestrictionsForAppMode:appMode formatId:_cachedGridFormatId];
    _cachedNightMode = OADayNightHelper.instance.isNightMode;
}

- (BOOL)updateVariablesWithAppMode:(OAApplicationMode *)appMode
{
    BOOL updated = NO;
    NSString *newFormatId = [_gridSettings gridFormatIdForAppMode:appMode];
    CoordinateGridFormatInfo *newInfo = [CoordinateGridFormatBridge resolveInfo:newFormatId];
    NSString *resolvedId = newInfo.formatId;
    if (![_cachedGridFormatId isEqualToString:resolvedId])
    {
        _cachedGridFormatId = resolvedId;
        _cachedGridFormatInfo = newInfo;
        updated = YES;
    }
    
    int newGridColorDay = [_gridSettings dayGridColor];
    if (_cachedGridColorDay != newGridColorDay)
    {
        _cachedGridColorDay = newGridColorDay;
        updated = YES;
    }
    
    int newGridColorNight = [_gridSettings nightGridColor];
    if (_cachedGridColorNight != newGridColorNight)
    {
        _cachedGridColorNight = newGridColorNight;
        updated = YES;
    }
    
    CGFloat newTextScale = [_gridSettings textScaleForAppMode:appMode];
    if (fabs(_cachedTextScale - newTextScale) >= 0.0001f)
    {
        _cachedTextScale = newTextScale;
        updated = YES;
    }
    
    GridLabelsPosition newLabelsPosition = (GridLabelsPosition)[_gridSettings gridLabelsPositionForAppMode:appMode];
    if (_cachedLabelsPosition != newLabelsPosition)
    {
        _cachedLabelsPosition = newLabelsPosition;
        updated = YES;
    }
    
    BOOL newNightMode = OADayNightHelper.instance.isNightMode;
    if (_cachedNightMode != newNightMode)
    {
        _cachedNightMode = newNightMode;
        updated = YES;
    }
    
    return updated;
}

- (void)updateGridAppearance
{
    CoordinateGridFormatInfo *info = _cachedGridFormatInfo;
    if (!info)
        info = [CoordinateGridFormatBridge resolveInfo:_cachedGridFormatId];

    auto format = static_cast<OsmAnd::GridConfiguration::Format>(info.formatRaw);
    auto secondaryProjection = static_cast<OsmAnd::GridConfiguration::Projection>(info.projectionRaw);

    OsmAnd::ZoomLevel minZoom = static_cast<OsmAnd::ZoomLevel>(_cachedZoomLimits.min);
    OsmAnd::ZoomLevel maxZoom = static_cast<OsmAnd::ZoomLevel>(_cachedZoomLimits.max);
    int colorInt = _cachedNightMode ? _cachedGridColorNight : _cachedGridColorDay;
    OsmAnd::FColorARGB color = [colorFromARGB(colorInt) toFColorARGB];
    UIColor *haloUIColor = [OAUtilities isColorBright:colorFromARGB(colorInt)] ? [UIColor colorWithWhite:0 alpha:0.5] : [UIColor whiteColor];
    OsmAnd::FColorARGB haloColor = [haloUIColor toFColorARGB];
    
    _gridConfiguration->setPrimaryProjection(OsmAnd::GridConfiguration::Projection::WGS84);
    _gridConfiguration->setPrimaryFormat(format);
    _gridConfiguration->setPrimaryColor(color);
    _gridConfiguration->setPrimaryMinZoomLevel(minZoom);
    _gridConfiguration->setPrimaryMaxZoomLevel(maxZoom);
    _gridConfiguration->setSecondaryProjection(secondaryProjection);
    _gridConfiguration->setSecondaryFormat(format);

    if (info.hasProjectionParameters)
    {
        _gridConfiguration->setProjectionParameters();
        OsmAnd::PointD lonBounds(info.lonMin, info.lonMax);
        OsmAnd::PointD latBounds(info.latMin, info.latMax);
        OsmAnd::PointD semiMajor(info.semiMajor, info.invFlattening);
        OsmAnd::PointD refLonLat(info.refLon, info.refLat);
        OsmAnd::PointD falseEN(info.falseEasting, info.falseNorthing);
        OsmAnd::PointD scale(info.scaleFactor, info.scaleFactorY);
        _gridConfiguration->setSecondaryProjectionConstants(
            secondaryProjection, lonBounds, latBounds, semiMajor, refLonLat, falseEN, scale);

        OsmAnd::PointD tXY(info.translationsX, info.translationsY);
        OsmAnd::PointD tZW(info.translationsZ, info.translationsW);
        OsmAnd::PointD rXY(info.rotationsX, info.rotationsY);
        OsmAnd::PointD rZScale(info.rotationsZ, info.ellipsoidScale);
        _gridConfiguration->setSecondaryEllipsoidParameters(tXY, tZW, rXY, rZScale);
    }

    if (_defaultGranularity <= 0.f)
        _defaultGranularity = _gridConfiguration->secondaryGranularity;
    if (info.granularity != nil)
        _gridConfiguration->setSecondaryGranularity(info.granularity.floatValue);
    else
        _gridConfiguration->setSecondaryGranularity(_defaultGranularity);

    _gridConfiguration->setSecondaryColor(color);
    _gridConfiguration->setSecondaryMinZoomLevel(minZoom);
    _gridConfiguration->setSecondaryMaxZoomLevel(maxZoom);
    
    _marksProvider = std::make_shared<OsmAnd::GridMarksProvider>();
    auto primaryStyle = [self createMarksStyleWithColor:color haloColor:haloColor textAlignment:OsmAnd::TextRasterizer::Style::TextAlignment::Under];
    auto secondaryStyle = [self createMarksStyleWithColor:color haloColor:haloColor textAlignment:kNoTextAlignment];
    _marksProvider->setPrimaryStyle(primaryStyle, 2.0f * _cachedTextScale, true);
    NSString *mapLangCode = _settings.settingPrefMapLanguage.get;
    NSString *equator = OALocalizedStringForLocaleCode(mapLangCode, @"equator");
    NSString *primeMeridian = OALocalizedStringForLocaleCode(mapLangCode, @"prime_meridian");
    NSString *meridian180 = OALocalizedStringForLocaleCode(mapLangCode, @"meridian_180");
    _marksProvider->setPrimary(false, equator.UTF8String, "", primeMeridian.UTF8String, meridian180.UTF8String);
    _marksProvider->setSecondaryStyle(secondaryStyle, 2.0f * _cachedTextScale, _cachedLabelsPosition == GridLabelsPositionCenter);
    if (info.needSuffixes)
        _marksProvider->setSecondary(true, "N", "S", "E", "W");
    else
        _marksProvider->setSecondary(true, "", "", "", "");
}

- (BOOL)updateZoomLevelsWithAppMode:(OAApplicationMode *)appMode
{
    ZoomRange newZoomLimits = [_gridSettings zoomLevelsWithRestrictionsForAppMode:appMode formatId:_cachedGridFormatId];
    if (_cachedZoomLimits.min != newZoomLimits.min || _cachedZoomLimits.max != newZoomLimits.max)
    {
        _cachedZoomLimits = newZoomLimits;
        if (_gridConfiguration)
        {
            OsmAnd::ZoomLevel minZoom = static_cast<OsmAnd::ZoomLevel>(_cachedZoomLimits.min);
            OsmAnd::ZoomLevel maxZoom = static_cast<OsmAnd::ZoomLevel>(_cachedZoomLimits.max);
            _gridConfiguration->setPrimaryMinZoomLevel(minZoom);
            _gridConfiguration->setPrimaryMaxZoomLevel(maxZoom);
            _gridConfiguration->setSecondaryMinZoomLevel(minZoom);
            _gridConfiguration->setSecondaryMaxZoomLevel(maxZoom);
            return YES;
        }
    }
    
    return NO;
}

- (BOOL)updateLabelsMarginFactor
{
    if (_marginFactorUpdateNeeded)
    {
        if (_mapInfoController && _mapInfoController.topPanelController && _mapInfoController.bottomPanelController)
        {
            CGFloat topFactor = kDefaultMarginFactor;
            CGFloat bottomFactor = kDefaultMarginFactor;
            CGFloat screenHeight = [OAUtilities calculateScreenHeight];
            if ([_mapInfoController.topPanelController hasWidgets])
            {
                CGFloat topWidgetsHeight = [_mapInfoController.topPanelController calculateContentSize].height;
                if (topWidgetsHeight > 0)
                {
                    CGFloat calculated = (screenHeight * 0.8f) / topWidgetsHeight;
                    topFactor = MIN(calculated, kDefaultMarginFactor);
                }
            }
            if ([_mapInfoController.bottomPanelController hasWidgets])
            {
                CGFloat bottomWidgetsHeight = [_mapInfoController.bottomPanelController calculateContentSize].height;
                if (bottomWidgetsHeight > 0)
                {
                    CGFloat calculated = (screenHeight * 0.8f) / bottomWidgetsHeight;
                    bottomFactor = MIN(calculated, kDefaultMarginFactor);
                }
            }
            
            _gridConfiguration->setPrimaryTopMarginFactor(topFactor);
            _gridConfiguration->setSecondaryTopMarginFactor(topFactor);
            _gridConfiguration->setPrimaryBottomMarginFactor(bottomFactor);
            _gridConfiguration->setSecondaryBottomMarginFactor(bottomFactor);
            _marginFactorUpdateNeeded = NO;
            return YES;
        }
    }
    
    return NO;
}

- (OsmAnd::TextRasterizer::Style)createMarksStyleWithColor:(const OsmAnd::FColorARGB &)color haloColor:(const OsmAnd::FColorARGB &)haloColor textAlignment:(OsmAnd::TextRasterizer::Style::TextAlignment)textAlignment
{
    OsmAnd::TextRasterizer::Style style;
    style.setColor(OsmAnd::ColorARGB(color));
    style.setHaloColor(OsmAnd::ColorARGB(haloColor));
    style.setHaloRadius((int)(3.0f * _cachedTextScale));
    style.setSize(16.0f * _cachedTextScale);
    style.setBold(true);
    if (textAlignment != kNoTextAlignment)
        style.setTextAlignment(textAlignment);
    
    return style;
}

- (void)updateGridVisibility:(BOOL)visible force:(BOOL)force
{
    _gridConfiguration->setPrimaryGrid(visible);
    _gridConfiguration->setSecondaryGrid(visible);
    self.mapView.renderer->setGridConfiguration(*_gridConfiguration, force);
    if (visible)
        self.mapView.renderer->addSymbolsProvider(_marksProvider);
    else
        self.mapView.renderer->removeSymbolsProvider(_marksProvider);
}

- (void)cleanupMarksProvider
{
    if (_marksProvider)
    {
        [self.mapView removeKeyedSymbolsProvider:_marksProvider];
        _marksProvider = nullptr;
    }
}

@end
