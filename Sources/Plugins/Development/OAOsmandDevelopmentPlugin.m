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
#import "OAMapWidgetRegistry.h"
#import "OARootViewController.h"

#define PLUGIN_ID kInAppId_Addon_OsmandDevelopment
#define DEV_FPS @"fps"
#define DEV_CAMERA_TILT @"dev_camera_tilt"
#define DEV_CAMERA_DISTANCE @"dev_camera_distance"
#define DEV_ZOOM_LEVEL @"dev_zoom_level"
#define DEV_TARGET_DISTANCE @"dev_target_distance"

@implementation OAOsmandDevelopmentPlugin
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OAFPSTextInfoWidget *_fpsWidgetControl;
    OAMapWidgetRegInfo *_widget;
    OAMapWidgetRegistry *_mapWidgetRegistry;
    OACameraTiltWidget *_cameraTiltWidgetControl;
    OACameraDistanceWidget *_cameraDistanceWidgetControl;
    OAZoomLevelWidget *_zoomLevelWidgetControl;
    OATargetDistanceWidget *_targetDistanceWidgetControl;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        _mapWidgetRegistry = [OARootViewController instance].mapPanel.mapWidgetRegistry;
    }
    return self;
}

- (NSString *) getId
{
    return PLUGIN_ID;
}

- (BOOL)isEnableByDefault
{
    return NO;
}

- (void) registerLayers
{
    [self registerWidget];
}

- (void) registerWidget
{
    OAMapInfoController *mapInfoController = [self getMapInfoController];
    if (mapInfoController)
    {
        _fpsWidgetControl = [[OAFPSTextInfoWidget alloc] init];
        [mapInfoController registerSideWidget:_fpsWidgetControl imageId:@"widget_fps_day" message:OALocalizedString(@"map_widget_rendering_fps") key:DEV_FPS left:false priorityOrder:99];
        
        _cameraTiltWidgetControl = [[OACameraTiltWidget alloc] init];
        [mapInfoController registerSideWidget:_cameraTiltWidgetControl imageId:@"widget_developer_camera_tilt_day" message:OALocalizedString(@"map_widget_camera_tilt") key:DEV_CAMERA_TILT left:false priorityOrder:100];
        
        _cameraDistanceWidgetControl = [[OACameraDistanceWidget alloc] init];
        [mapInfoController registerSideWidget:_cameraDistanceWidgetControl imageId:@"widget_developer_camera_distance_day" message:OALocalizedString(@"map_widget_camera_distance") key:DEV_CAMERA_DISTANCE left:false priorityOrder:101];
        
        _zoomLevelWidgetControl = [[OAZoomLevelWidget alloc] init];
        [mapInfoController registerSideWidget:_zoomLevelWidgetControl imageId:@"widget_developer_map_zoom_day" message:OALocalizedString(@"map_widget_zoom_level") key:DEV_ZOOM_LEVEL left:false priorityOrder:102];
        
        _targetDistanceWidgetControl = [[OATargetDistanceWidget alloc] init];
        [mapInfoController registerSideWidget:_targetDistanceWidgetControl imageId:@"widget_developer_target_distance_day" message:OALocalizedString(@"map_widget_target_distance") key:DEV_TARGET_DISTANCE left:false priorityOrder:103];
    }
}

- (void) updateLayers
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isEnabled])
        {
            if (!_fpsWidgetControl)
                [self registerWidget];
            if (!_cameraTiltWidgetControl)
                [self registerWidget];
            if (!_cameraDistanceWidgetControl)
                [self registerWidget];
            if (!_zoomLevelWidgetControl)
                [self registerWidget];
            if (!_targetDistanceWidgetControl)
                [self registerWidget];
            [[OARootViewController instance].mapPanel recreateControls];
        }
        else
        {
            if (_fpsWidgetControl)
            {
                OAMapInfoController *mapInfoController = [self getMapInfoController];
                [mapInfoController removeSideWidget:_fpsWidgetControl];
                _widget = [_mapWidgetRegistry widgetByKey:PLUGIN_ID];
                _fpsWidgetControl = nil;
            }
            if (_cameraTiltWidgetControl)
            {
                OAMapInfoController *mapInfoController = [self getMapInfoController];
                [mapInfoController removeSideWidget:_cameraTiltWidgetControl];
                _widget = [_mapWidgetRegistry widgetByKey:DEV_CAMERA_TILT];
                _cameraTiltWidgetControl = nil;
            }
            if (_cameraDistanceWidgetControl)
            {
                OAMapInfoController *mapInfoController = [self getMapInfoController];
                [mapInfoController removeSideWidget:_cameraDistanceWidgetControl];
                _widget = [_mapWidgetRegistry widgetByKey:DEV_CAMERA_DISTANCE];
                _cameraDistanceWidgetControl = nil;
            }
            if (_zoomLevelWidgetControl)
            {
                OAMapInfoController *mapInfoController = [self getMapInfoController];
                [mapInfoController removeSideWidget:_zoomLevelWidgetControl];
                _widget = [_mapWidgetRegistry widgetByKey:DEV_ZOOM_LEVEL];
                _zoomLevelWidgetControl = nil;
            }
            if (_targetDistanceWidgetControl)
            {
                OAMapInfoController *mapInfoController = [self getMapInfoController];
                [mapInfoController removeSideWidget:_targetDistanceWidgetControl];
                _widget = [_mapWidgetRegistry widgetByKey:DEV_TARGET_DISTANCE];
                _targetDistanceWidgetControl = nil;
            }
            [_mapWidgetRegistry setVisibility:_widget visible:NO collapsed:NO];
            [[OARootViewController instance].mapPanel recreateControls];
        }
    });
}

- (NSString *) getName
{
    return OALocalizedString(@"debugging_and_development");
}

- (NSString *) getDescription
{
    return OALocalizedString(@"osmand_development_plugin_description");
}

@end
