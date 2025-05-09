//
//  OACoordinatesGridSettings.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 23.04.2025.
//  Copyright © 2025 OsmAnd. All rights reserved.
//

#import "OACoordinatesGridSettings.h"
#import "OAAppSettings.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/Map/MapRendererState.h>

@implementation OACoordinatesGridSettings
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    NSInteger _supportedMaxZoom;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _supportedMaxZoom = 22;
    }
    return self;
}

- (void)toggleEnable
{
    [self setEnabled:![self isEnabled]];
}

- (BOOL)isEnabled
{
    return [self isEnabledForAppMode:[_settings.applicationMode get]];
}

- (BOOL)isEnabledForAppMode:(OAApplicationMode *)appMode
{
    return [_settings.mapSettingShowCoordinatesGrid get:appMode];
}

- (void)setEnabled:(BOOL)enabled
{
    [self setEnabled:enabled forAppMode:[_settings.applicationMode get]];
}

- (void)setEnabled:(BOOL)enabled forAppMode:(OAApplicationMode *)appMode
{
    [_settings.mapSettingShowCoordinatesGrid set:enabled mode:appMode];
    [self notifyChange];
}

- (int32_t)getGridFormatForAppMode:(OAApplicationMode *)appMode
{
    return [_settings.coordinateGridFormat get:appMode];
}

- (void)setGridFormat:(int32_t)format forAppMode:(OAApplicationMode *)appMode
{
    [_settings.coordinateGridFormat set:format mode:appMode];
    [self notifyChange];
}

- (int)getDayGridColor
{
    return [self getGridColor:NO];
}

- (int)getNightGridColor
{
    return [self getGridColor:YES];
}

- (int)getGridColor:(BOOL)nightMode
{
    return [self getGridColorForAppMode:[_settings.applicationMode get] nightMode:nightMode];
}

- (int)getGridColorForAppMode:(OAApplicationMode *)appMode nightMode:(BOOL)nightMode
{
    return nightMode ? [_settings.coordinatesGridColorNight get:appMode] : [_settings.coordinatesGridColorDay get:appMode];
}

- (void)setGridColor:(NSInteger)color forAppMode:(OAApplicationMode *)appMode nightMode:(BOOL)nightMode
{
    if (nightMode)
        [_settings.coordinatesGridColorNight set:(int32_t)color mode:appMode];
    else
        [_settings.coordinatesGridColorDay set:(int32_t)color mode:appMode];
    
    [self notifyChange];
}

- (void)resetColorsForAppMode:(OAApplicationMode *)appMode
{
    [_settings.coordinatesGridColorDay resetModeToDefault:appMode];
    [_settings.coordinatesGridColorNight resetModeToDefault:appMode];
    [self notifyChange];
}

- (int32_t)getGridLabelsPositionForAppMode:(OAApplicationMode *)appMode
{
    return [_settings.coordinatesGridLabelsPosition get:appMode];
}

- (void)setGridLabelsPosition:(int32_t)position forAppMode:(OAApplicationMode *)appMode
{
    [_settings.coordinatesGridLabelsPosition set:position mode:appMode];
    [self notifyChange];
}

- (ZoomRange)getZoomLevelsWithRestrictionsForAppMode:(OAApplicationMode *)appMode
{
    return [self getZoomLevelsWithRestrictionsForAppMode:appMode format:(GridFormat)[self getGridFormatForAppMode:appMode]];
}

- (ZoomRange)getZoomLevelsWithRestrictionsForAppMode:(OAApplicationMode *)appMode format:(GridFormat)format
{
    ZoomRange selected = [self getZoomLevelsForAppMode:appMode];
    ZoomRange supported = [self getSupportedZoomLevelsForFormat:format];
    NSInteger minZoom = MIN(MAX(selected.min, supported.min), supported.max);
    NSInteger maxZoom = MIN(MAX(selected.max, supported.min), supported.max);
    return (ZoomRange){.min = minZoom, .max = maxZoom};
}

- (ZoomRange)getZoomLevels
{
    return [self getZoomLevelsForAppMode:[_settings.applicationMode get]];
}

- (ZoomRange)getZoomLevelsForAppMode:(OAApplicationMode *)appMode
{
    int32_t minVal = [_settings.coordinateGridMinZoom get:appMode];
    int32_t maxVal = [_settings.coordinateGridMaxZoom get:appMode];
    return (ZoomRange){.min = minVal, .max = maxVal};
}

- (void)setZoomLevels:(ZoomRange)levels forAppMode:(OAApplicationMode *)appMode
{
    [_settings.coordinateGridMinZoom set:(int32_t)levels.min mode:appMode];
    [_settings.coordinateGridMaxZoom set:(int32_t)levels.max mode:appMode];
    [self notifyChange];
}

- (void)resetZoomLevelsForAppMode:(OAApplicationMode *)appMode
{
    [_settings.coordinateGridMinZoom resetModeToDefault:appMode];
    [_settings.coordinateGridMaxZoom resetModeToDefault:appMode];
    [self notifyChange];
}

- (ZoomRange)getSupportedZoomLevels
{
    return [self getSupportedZoomLevelsForAppMode:[_settings.applicationMode get]];
}

- (ZoomRange)getSupportedZoomLevelsForAppMode:(OAApplicationMode *)appMode
{
    return [self getSupportedZoomLevelsForFormat:(GridFormat)[self getGridFormatForAppMode:appMode]];
}

- (ZoomRange)getSupportedZoomLevelsForFormat:(GridFormat)gridFormat
{
    int32_t minZoom = 1;
    OsmAnd::GridConfiguration gridConfiguration;
    OAProjection proj = [GridFormatWrapper projectionFor:gridFormat];
    auto cppProj = static_cast<OsmAnd::GridConfiguration::Projection>(proj);
    gridConfiguration.setPrimaryProjection(cppProj);
    gridConfiguration.setSecondaryProjection(cppProj);
    OAFormat format = [GridFormatWrapper getFormatFor:gridFormat];
    auto cppForm = static_cast<OsmAnd::GridConfiguration::Format>(format);
    gridConfiguration.setPrimaryFormat(cppForm);
    gridConfiguration.setSecondaryFormat(cppForm);
    gridConfiguration.setProjectionParameters();
    OsmAnd::GridParameters params = gridConfiguration.gridParameters[0];
    OsmAnd::ZoomLevel min = params.minZoom;
    minZoom = min;
    return (ZoomRange){.min = minZoom, .max = _supportedMaxZoom};
}

- (float)getTextScaleForAppMode:(OAApplicationMode *)appMode
{
    return [_settings.textSize get:appMode] * [OARootViewController.instance.mapPanel.mapViewController displayDensityFactor];
}

- (void)notifyChange
{
    [_app.coordinatesGridSettingsObservable notifyEvent];
    [[OAMapButtonsHelper sharedInstance].quickActionButtonsChangedObservable notifyEvent];
}

@end
