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
    NSMutableDictionary<NSString *, NSValue *> *_supportedZoomByFormatId;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _supportedMaxZoom = 22;
        _supportedZoomByFormatId = [NSMutableDictionary new];
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
    [[OAMapButtonsHelper sharedInstance] refreshQuickActionButtons];
}

- (NSString *)gridFormatIdForAppMode:(OAApplicationMode *)appMode
{
    return [_settings.coordinateGridFormat get:appMode];
}

- (void)setGridFormatId:(NSString *)formatId forAppMode:(OAApplicationMode *)appMode
{
    [_settings.coordinateGridFormat set:formatId mode:appMode];
}

- (int)dayGridColor
{
    return [self getGridColor:NO];
}

- (int)nightGridColor
{
    return [self getGridColor:YES];
}

- (int)getGridColor:(BOOL)nightMode
{
    return [self getGridColorForAppMode:[_settings.applicationMode get] nightMode:nightMode];
}

- (int)getGridColorForAppMode:(OAApplicationMode *)appMode nightMode:(BOOL)nightMode
{
    BOOL isMapsPlusProAvailable = [OAIAPHelper isMapsPlusAvailable] || [OAIAPHelper isOsmAndProAvailable];
    if (!isMapsPlusProAvailable)
        return nightMode ? _settings.coordinatesGridColorNight.defValue : _settings.coordinatesGridColorDay.defValue;
    
    return nightMode ? [_settings.coordinatesGridColorNight get:appMode] : [_settings.coordinatesGridColorDay get:appMode];
}

- (void)setGridColor:(NSInteger)color forAppMode:(OAApplicationMode *)appMode nightMode:(BOOL)nightMode
{
    if (nightMode)
        [_settings.coordinatesGridColorNight set:(int32_t)color mode:appMode];
    else
        [_settings.coordinatesGridColorDay set:(int32_t)color mode:appMode];
}

- (void)resetColorsForAppMode:(OAApplicationMode *)appMode
{
    [_settings.coordinatesGridColorDay resetModeToDefault:appMode];
    [_settings.coordinatesGridColorNight resetModeToDefault:appMode];
}

- (int32_t)gridLabelsPositionForAppMode:(OAApplicationMode *)appMode
{
    return [_settings.coordinatesGridLabelsPosition get:appMode];
}

- (void)setGridLabelsPosition:(int32_t)position forAppMode:(OAApplicationMode *)appMode
{
    [_settings.coordinatesGridLabelsPosition set:position mode:appMode];
}

- (NSString *)resolvedGridFormatIdForAppMode:(OAApplicationMode *)appMode
{
    NSString *formatId = [self gridFormatIdForAppMode:appMode];
    CoordinateGridFormatInfo *info = [CoordinateGridFormatBridge resolveInfo:formatId];
    return info.formatId ?: @"builtin:ddd";
}

- (ZoomRange)zoomLevelsWithRestrictionsForAppMode:(OAApplicationMode *)appMode
{
    NSString *formatId = [self resolvedGridFormatIdForAppMode:appMode];
    return [self zoomLevelsWithRestrictionsForAppMode:appMode formatId:formatId];
}

- (ZoomRange)zoomLevelsWithRestrictionsForAppMode:(OAApplicationMode *)appMode
                                            formatId:(NSString *)formatId
{
    ZoomRange selected = [self getZoomLevelsForAppMode:appMode];
    ZoomRange supported = [self supportedZoomLevelsForFormatId:formatId];
    NSInteger minZoom = MIN(MAX(selected.min, supported.min), supported.max);
    NSInteger maxZoom = MIN(MAX(selected.max, supported.min), supported.max);
    return (ZoomRange){ .min = minZoom, .max = maxZoom };
}

- (ZoomRange)getSupportedZoomLevelsForAppMode:(OAApplicationMode *)appMode
{
    return [self supportedZoomLevelsForFormatId:[self resolvedGridFormatIdForAppMode:appMode]];
}

- (ZoomRange)supportedZoomLevelsForFormatId:(NSString *)formatId
{
    NSValue *cached = _supportedZoomByFormatId[formatId];
    if (cached)
    {
        ZoomRange r;
        [cached getValue:&r];
        return r;
    }
    ZoomRange calculated = [self calculateSupportedZoomLevelsForFormatId:formatId];
    NSValue *value = [NSValue valueWithBytes:&calculated objCType:@encode(ZoomRange)];
    _supportedZoomByFormatId[formatId] = value;
    return calculated;
}

- (ZoomRange)calculateSupportedZoomLevelsForFormatId:(NSString *)formatId
{
    CoordinateGridFormatInfo *info = [CoordinateGridFormatBridge resolveInfo:formatId];
    int32_t minZoom = 1;
    int32_t maxZoom = (int32_t)_supportedMaxZoom;

    OsmAnd::GridConfiguration gridConfiguration;
    auto proj = static_cast<OsmAnd::GridConfiguration::Projection>(info.projectionRaw);
    auto form = static_cast<OsmAnd::GridConfiguration::Format>(info.formatRaw);
    gridConfiguration.setPrimaryProjection(proj);
    gridConfiguration.setSecondaryProjection(proj);
    gridConfiguration.setPrimaryFormat(form);
    gridConfiguration.setSecondaryFormat(form);
    gridConfiguration.setProjectionParameters();

    OsmAnd::GridParameters params = gridConfiguration.gridParameters[0];
    minZoom = (int32_t)params.minZoom;

    int maxFloat = (int)params.maxZoomForFloat;
    int maxMixed = (int)params.maxZoomForMixed;
    int fromParams = MAX(maxFloat, maxMixed);
    if (fromParams > 0)
        maxZoom = MIN(maxZoom, fromParams);

    return (ZoomRange){ .min = minZoom, .max = maxZoom };
}

- (ZoomRange)zoomLevels
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
}

- (void)resetZoomLevelsForAppMode:(OAApplicationMode *)appMode
{
    [_settings.coordinateGridMinZoom resetModeToDefault:appMode];
    [_settings.coordinateGridMaxZoom resetModeToDefault:appMode];
}

- (ZoomRange)supportedZoomLevels
{
    return [self getSupportedZoomLevelsForAppMode:[_settings.applicationMode get]];
}

- (float)textScaleForAppMode:(OAApplicationMode *)appMode
{
    return [_settings.textSize get:appMode] * [OARootViewController.instance.mapPanel.mapViewController displayDensityFactor];
}

@end
