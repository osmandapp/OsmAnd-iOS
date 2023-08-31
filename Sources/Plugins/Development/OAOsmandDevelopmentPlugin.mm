//
//  OAOsmandDevelopmentPlugin.m
//  OsmAnd Maps
//
//  Created by nnngrach on 31.05.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAOsmandDevelopmentPlugin.h"
#import "OAProducts.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAMapInfoController.h"
#import "OATextInfoWidget.h"
#import "OAFPSTextInfoWidget.h"
#import "OACameraTiltWidget.h"
#import "OACameraDistanceWidget.h"
#import "OAZoomLevelWidget.h"
#import "OATargetDistanceWidget.h"
#import "OAAltitudeWidget.h"
#import "OAMapWidgetRegistry.h"
#import "OARootViewController.h"
#import "OAIAPHelper.h"
#import "OAResourcesBaseViewController.h"

#import "OsmAnd_Maps-Swift.h"

#define PLUGIN_ID kInAppId_Addon_OsmandDevelopment
#define DEV_FPS @"fps"
#define DEV_CAMERA_TILT @"dev_camera_tilt"
#define DEV_CAMERA_DISTANCE @"dev_camera_distance"
#define DEV_ZOOM_LEVEL @"dev_zoom_level"
#define DEV_TARGET_DISTANCE @"dev_target_distance"

#define kEnable3dMaps @"enable_3d_maps"

@implementation OAOsmandDevelopmentPlugin
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    OACommonBoolean *_enable3dMap;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _enableHeightmap = [[[_settings registerBooleanPreference:@"show_heightmaps" defValue:NO] makeGlobal] makeShared];
        _enable3DMaps = [[[_settings registerBooleanPreference:@"enable_3d_maps" defValue:YES] makeGlobal] makeShared];
        _disableVertexHillshade3D = [[[_settings registerBooleanPreference:@"disable_vertex_hillshade_3d" defValue:YES] makeGlobal] makeShared];
        _generateSlopeFrom3DMaps = [[[_settings registerBooleanPreference:@"generate_slope_from_3d_maps" defValue:YES] makeGlobal] makeShared];
        _generateHillshadeFrom3DMaps = [[[_settings registerBooleanPreference:@"generate_hillshade_from_3d_maps" defValue:YES] makeGlobal] makeShared];
        
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.devFps appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.devCameraTilt appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.devCameraDistance appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.devZoomLevel appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.devTargetDistance appModes:@[]];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProfileSettingSet:) name:kNotificationSetProfileSetting object:nil];
    }
    return self;
}

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (BOOL) isEnableByDefault
{
    return NO;
}

- (void) registerLayers
{
//    [self registerWidget];
}

- (void) createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode
{
    OAWidgetInfoCreator *creator = [[OAWidgetInfoCreator alloc] initWithAppMode:appMode];

    OABaseWidgetView *fpsWidget = [self createMapWidgetForParams:OAWidgetType.devFps customId:nil];
    [delegate addWidget:[creator createWidgetInfoWithWidget:fpsWidget]];
    
    OABaseWidgetView *cameraTiltWidget = [self createMapWidgetForParams:OAWidgetType.devCameraTilt customId:nil];
    [delegate addWidget:[creator createWidgetInfoWithWidget:cameraTiltWidget]];
    
    OABaseWidgetView *cameraDistanceWidget = [self createMapWidgetForParams:OAWidgetType.devCameraDistance customId:nil];
    [delegate addWidget:[creator createWidgetInfoWithWidget:cameraDistanceWidget]];
    
    OABaseWidgetView *zoomLevelWidget = [self createMapWidgetForParams:OAWidgetType.devZoomLevel customId:nil];
    [delegate addWidget:[creator createWidgetInfoWithWidget:zoomLevelWidget]];
    
    OABaseWidgetView *targetDistanceWidget = [self createMapWidgetForParams:OAWidgetType.devTargetDistance customId:nil];
    [delegate addWidget:[creator createWidgetInfoWithWidget:targetDistanceWidget]];
}

- (OABaseWidgetView *)createMapWidgetForParams:(OAWidgetType *)widgetType customId:(NSString *)customId
{
    if (widgetType == OAWidgetType.devFps) {
        return [[OAFPSTextInfoWidget alloc] init];
    } else if (widgetType == OAWidgetType.devCameraTilt) {
        return [[OACameraTiltWidget alloc] init];
    } else if (widgetType == OAWidgetType.devCameraDistance) {
        return [[OACameraDistanceWidget alloc] init];
    } else if (widgetType == OAWidgetType.devZoomLevel) {
        return [[OAZoomLevelWidget alloc] init];
    } else if (widgetType == OAWidgetType.devTargetDistance) {
        return [[OATargetDistanceWidget alloc] init];
    }
    return nil;
}

- (void) updateLayers
{
    dispatch_async(dispatch_get_main_queue(), ^{
//        if ([self isEnabled])
//        {
//
//            if (!_altitudeWidgetMapCenter && [self isHeightmapEnabled])
//                [self registerAltitudeMapCenterWidget];
//            else if (_altitudeWidgetMapCenter && ![self isHeightmapEnabled])
//                [self unregisterAltitudeMapCenterWidget];
//
//            [[OARootViewController instance].mapPanel recreateControls];
//        }
//        else
//        {
//            OAMapWidgetRegistry *mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
//            OAMapWidgetRegInfo *widget;
//            if (_fpsWidgetControl)
//            {
//                OAMapInfoController *mapInfoController = [self getMapInfoController];
//                [mapInfoController removeSideWidget:_fpsWidgetControl];
//                widget = [mapWidgetRegistry widgetByKey:DEV_FPS];
//                _fpsWidgetControl = nil;
//            }
//            if (_cameraTiltWidgetControl)
//            {
//                OAMapInfoController *mapInfoController = [self getMapInfoController];
//                [mapInfoController removeSideWidget:_cameraTiltWidgetControl];
//                widget = [mapWidgetRegistry widgetByKey:DEV_CAMERA_TILT];
//                _cameraTiltWidgetControl = nil;
//            }
//            if (_cameraDistanceWidgetControl)
//            {
//                OAMapInfoController *mapInfoController = [self getMapInfoController];
//                [mapInfoController removeSideWidget:_cameraDistanceWidgetControl];
//                widget = [mapWidgetRegistry widgetByKey:DEV_CAMERA_DISTANCE];
//                _cameraDistanceWidgetControl = nil;
//            }
//            if (_zoomLevelWidgetControl)
//            {
//                OAMapInfoController *mapInfoController = [self getMapInfoController];
//                [mapInfoController removeSideWidget:_zoomLevelWidgetControl];
//                widget = [mapWidgetRegistry widgetByKey:DEV_ZOOM_LEVEL];
//                _zoomLevelWidgetControl = nil;
//            }
//            if (_targetDistanceWidgetControl)
//            {
//                OAMapInfoController *mapInfoController = [self getMapInfoController];
//                [mapInfoController removeSideWidget:_targetDistanceWidgetControl];
//                widget = [mapWidgetRegistry widgetByKey:DEV_TARGET_DISTANCE];
//                _targetDistanceWidgetControl = nil;
//            }
//            if (_altitudeWidgetMapCenter)
//                [self unregisterAltitudeMapCenterWidget];
//            if (widget)
//                [mapWidgetRegistry setVisibility:widget visible:NO collapsed:NO];
//            [[OARootViewController instance].mapPanel recreateControls];
//        }
    });
}

- (void) registerAltitudeMapCenterWidget
{
//    _altitudeWidgetMapCenter = [[OAAltitudeWidget alloc] initWithType:EOAAltitudeWidgetTypeMapCenter];
//    [[self getMapInfoController] registerSideWidget:_altitudeWidgetMapCenter
//                                            imageId:@"widget_altitude_map_center_day"
//                                            message:OALocalizedString(@"map_widget_altitude_map_center")
//                                        description:OALocalizedString(@"map_widget_altitude_map_center_desc")
//                                                key:ALTITUDE_MAP_CENTER
//                                               left:NO
//                                      priorityOrder:24];
}

- (void) unregisterAltitudeMapCenterWidget
{
//    [[self getMapInfoController] removeSideWidget:_altitudeWidgetMapCenter];
//    _altitudeWidgetMapCenter = nil;
}

- (NSString *) getName
{
    return OALocalizedString(@"debugging_and_development");
}

- (NSString *) getDescription
{
    return OALocalizedString(@"osmand_development_plugin_description");
}

// If enabled:
// * heightmap-related setting should be available for configuration
// * heightmaps should be available for downloads
- (BOOL) isHeightmapEnabled
{
    return [self isHeightmapAllowed] && [_enableHeightmap get];
}

- (BOOL) isHeightmapAllowed
{
    return [OAIAPHelper isOsmAndProAvailable];
}

// If enabled, map should be rendered with elevation data (in 3D)
- (BOOL) is3DMapsEnabled
{
    return [self isHeightmapEnabled] && [_enable3DMaps get];
}

- (BOOL) isDisableVertexHillshade3D
{
    return [self isHeightmapEnabled] && [_disableVertexHillshade3D get];
}

- (BOOL) isGenerateSlopeFrom3DMaps
{
    return [self isHeightmapEnabled] && [_generateSlopeFrom3DMaps get];
}

- (BOOL) isGenerateHillshadeFrom3DMaps
{
    return [self isHeightmapEnabled] && [_generateHillshadeFrom3DMaps get];
}

- (void) onProfileSettingSet:(NSNotification *)notification
{
    OACommonPreference *obj = notification.object;
    if (obj == _enableHeightmap)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onEnable3DMapsChanged];
            [self onDisableVertexHillshade3DChanged];
            [self onGenerateSlopeFrom3DMapsChanged];
            [self onGenerateHillshadeFrom3DMapsChanged];
        });
    }
    else if (obj == _enable3DMaps)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onEnable3DMapsChanged];
        });
    }
    else if (obj == _disableVertexHillshade3D)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onDisableVertexHillshade3DChanged];
        });
    }
    else if (obj == _generateSlopeFrom3DMaps)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onGenerateSlopeFrom3DMapsChanged];
        });
    }
    else if (obj == _generateHillshadeFrom3DMaps)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self onGenerateHillshadeFrom3DMapsChanged];
        });
    }
}

- (void) onEnable3DMapsChanged
{
    [OARootViewController.instance.mapPanel.mapViewController recreateHeightmapProvider];
}

- (void) onDisableVertexHillshade3DChanged
{
    [OARootViewController.instance.mapPanel.mapViewController updateElevationConfiguration];
}

- (void) onGenerateSlopeFrom3DMapsChanged
{
    [_app.data setTerrainType:_app.data.terrainType];
}

- (void) onGenerateHillshadeFrom3DMapsChanged
{
    [_app.data setTerrainType:_app.data.terrainType];
}

@end
