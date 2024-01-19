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

@implementation OAOsmandDevelopmentPlugin
{
    OsmAndAppInstance _app;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];

        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.devFps appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.devCameraTilt appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.devCameraDistance appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.devZoomLevel appModes:@[]];
        [OAWidgetsAvailabilityHelper regWidgetVisibilityWithWidgetType:OAWidgetType.devTargetDistance appModes:@[]];
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

- (NSArray<NSString *> *) getWidgetIds
{
    return @[OAWidgetType.devFps.id, OAWidgetType.devCameraTilt.id, OAWidgetType.devCameraDistance, OAWidgetType.devZoomLevel.id, OAWidgetType.devTargetDistance.id];
}

- (void) createWidgets:(id<OAWidgetRegistrationDelegate>)delegate appMode:(OAApplicationMode *)appMode
{
    OAWidgetInfoCreator *creator = [[OAWidgetInfoCreator alloc] initWithAppMode:appMode];

    OABaseWidgetView *fpsWidget = [self createMapWidgetForParams:OAWidgetType.devFps customId:nil appMode:appMode];
    [delegate addWidget:[creator createWidgetInfoWithWidget:fpsWidget]];
    
    OABaseWidgetView *cameraTiltWidget = [self createMapWidgetForParams:OAWidgetType.devCameraTilt customId:nil appMode:appMode];
    [delegate addWidget:[creator createWidgetInfoWithWidget:cameraTiltWidget]];
    
    OABaseWidgetView *cameraDistanceWidget = [self createMapWidgetForParams:OAWidgetType.devCameraDistance customId:nil appMode:appMode];
    [delegate addWidget:[creator createWidgetInfoWithWidget:cameraDistanceWidget]];
    
    OABaseWidgetView *zoomLevelWidget = [self createMapWidgetForParams:OAWidgetType.devZoomLevel customId:nil appMode:appMode];
    [delegate addWidget:[creator createWidgetInfoWithWidget:zoomLevelWidget]];
    
    OABaseWidgetView *targetDistanceWidget = [self createMapWidgetForParams:OAWidgetType.devTargetDistance customId:nil appMode:appMode];
    [delegate addWidget:[creator createWidgetInfoWithWidget:targetDistanceWidget]];
}

- (OABaseWidgetView *)createMapWidgetForParams:(OAWidgetType *)widgetType
                                      customId:(NSString *)customId
                                       appMode:(OAApplicationMode *)appMode
{
    if (widgetType == OAWidgetType.devFps) {
        return [[OAFPSTextInfoWidget alloc] initWithСustomId:customId appMode:appMode];
    } else if (widgetType == OAWidgetType.devCameraTilt) {
        return [[OACameraTiltWidget alloc] initWithСustomId:customId appMode:appMode];
    } else if (widgetType == OAWidgetType.devCameraDistance) {
        return [[OACameraDistanceWidget alloc]initWithСustomId:customId appMode:appMode];
    } else if (widgetType == OAWidgetType.devZoomLevel) {
        return [[OAZoomLevelWidget alloc] initWithСustomId:customId appMode:appMode];
    } else if (widgetType == OAWidgetType.devTargetDistance) {
        return [[OATargetDistanceWidget alloc]initWithСustomId:customId appMode:appMode];
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

@end
