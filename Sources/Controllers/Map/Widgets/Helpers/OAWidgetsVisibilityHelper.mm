//
//  OAWidgetsVisibilityHelper.m
//  OsmAnd Maps
//
//  Created by Paul on 04.05.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAWidgetsVisibilityHelper.h"
#import "OAApplicationMode.h"
#import "OAMapLayers.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OARootViewController.h"
#import "OAMapInfoController.h"
#import "OAMapHudViewController.h"
#import "OAQuickActionHudViewController.h"
#import "OAMeasurementToolLayer.h"
#import "OAMapLayer.h"
#import "OAMapViewTrackingUtilities.h"
#import "OsmAnd_Maps-Swift.h"


@interface OAWidgetsVisibilityHelper ()

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet<OAApplicationMode *> *> *widgetsVisibilityMap;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet<OAApplicationMode *> *> *widgetsAvailabilityMap;

@end

@implementation OAWidgetsVisibilityHelper
{
    OAAppSettings *_settings;
    OARoutingHelper *_routingHelper;
    OAMapLayers *_mapLayers;
    OAMapInfoController *_mapInfoController;
    OAMapPanelViewController *_mapPanel;
}

+ (instancetype) sharedInstance
{
    static OAWidgetsVisibilityHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OAWidgetsVisibilityHelper alloc] init];
    });
    
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _settings = OAAppSettings.sharedManager;
        _routingHelper = OARoutingHelper.sharedInstance;
        _mapPanel = OARootViewController.instance.mapPanel;
        _mapLayers = _mapPanel.mapViewController.mapLayers;
        _mapInfoController = _mapPanel.hudViewController.mapInfoController;
    }
    return self;
}

- (BOOL)shouldShowQuickActionButton {
    return [self isQuickActionLayerOn] &&
    ![self isInChangeMarkerPositionMode] &&
    ![self isInGpxDetailsMode] &&
    ![self isInMeasurementToolMode] &&
    ![self isInPlanRouteMode] &&
    ![self isInTrackAppearanceMode] &&
    ![self isInTrackMenuMode] &&
    ![self isInRouteLineAppearanceMode] &&
    ![self isMapRouteInfoMenuVisible] &&
    ![self isInChoosingRoutesMode] &&
    ![self isInWaypointsChoosingMode] &&
    ![self isInFollowTrackMode] &&
    ![self isContextMenuFragmentVisible] &&
    ![self isMultiSelectionMenuFragmentVisible] &&
    ![self isInGpsFilteringMode] &&
    ![self isInWeatherForecastMode] &&
    ![self isSelectingTilesZone];
}

- (BOOL)shouldShowTopMapCenterCoordinatesWidget {
    return [_settings.showMapCenterCoordinatesWidget get] && [self shouldShowTopCoordinatesWidget];
}

- (BOOL)shouldShowTopCurrentLocationCoordinatesWidget {
    return [_settings.showCurrentLocationCoordinatesWidget get] && [self shouldShowTopCoordinatesWidget];
}

- (BOOL)shouldShowTopCoordinatesWidget {
    return [_mapPanel isTopControlsVisible] &&
//    [[_mapActivity getMapRouteInfoMenu] shouldShowTopControls] &&
    ![self isInTrackAppearanceMode] &&
    ![self isInRouteLineAppearanceMode] &&
    ![self isInChoosingRoutesMode] &&
    ![self isInWaypointsChoosingMode] &&
    ![self isInFollowTrackMode] &&
    ![self isInGpsFilteringMode] &&
    ![self isInWeatherForecastMode] &&
    ![self isSelectingTilesZone];
}

- (BOOL)shouldHideMapMarkersWidget {
    return !_settings.showMapMarkersBarWidget.get ||
    _mapInfoController.topTextViewVisible ||
    [_routingHelper isFollowingMode] ||
    [_routingHelper isRoutePlanningMode] ||
    [self isMapRouteInfoMenuVisible] ||
    [_mapPanel isTopToolbarActive] ||
    ![_mapPanel isTopControlsVisible] ||
    [self isInTrackAppearanceMode] ||
    [self isInPlanRouteMode] ||
    [self isInRouteLineAppearanceMode] ||
    [self isInGpsFilteringMode] ||
    [self isInWeatherForecastMode] ||
    [self isSelectingTilesZone];
}

- (BOOL)shouldShowBottomMenuButtons {
    return [_mapPanel isTopControlsVisible] &&
    ![self isInMovingMarkerMode] &&
    ![self isInGpxDetailsMode] &&
    ![self isInMeasurementToolMode] &&
    ![self isInPlanRouteMode] &&
    ![self isInChoosingRoutesMode] &&
    ![self isInWaypointsChoosingMode] &&
    ![self isInFollowTrackMode] &&
    ![self isInTrackAppearanceMode] &&
    ![self isInRouteLineAppearanceMode] &&
    ![self isInGpsFilteringMode] &&
    ![self isInWeatherForecastMode] &&
    ![self isSelectingTilesZone];
}

- (BOOL)shouldShowZoomButtons {
    BOOL additionalDialogsHide = ![self isInGpxApproximationMode] &&
    ![self isInTrackAppearanceMode] &&
    ![self isInChoosingRoutesMode] &&
    ![self isInWaypointsChoosingMode] &&
    ![self isInRouteLineAppearanceMode] &&
    ![self isInGpsFilteringMode] &&
    ![self isSelectingTilesZone];
    BOOL showTopControls = [_mapPanel isTopControlsVisible] || ([self isInTrackMenuMode] && ![self isPortrait]);
    return showTopControls &&
    ![self isInFollowTrackMode] &&
    (additionalDialogsHide || ![self isPortrait]);
}

- (BOOL)shouldHideCompass {
    return ![_mapPanel isTopControlsVisible] ||
    [self isTrackDetailsMenuOpened] ||
    [self isInPlanRouteMode] ||
    [self isInChoosingRoutesMode] ||
    [self isInTrackAppearanceMode] ||
    [self isInWaypointsChoosingMode] ||
    [self isInFollowTrackMode] ||
    [self isInRouteLineAppearanceMode] ||
    [self isInGpsFilteringMode] ||
    [self isSelectingTilesZone];
}

- (BOOL)shouldShowTopButtons {
    return [_mapPanel isTopControlsVisible] &&
    ![self isTrackDetailsMenuOpened] &&
    ![self isInPlanRouteMode] &&
    ![self isInChoosingRoutesMode] &&
    ![self isInTrackAppearanceMode] &&
    ![self isInWaypointsChoosingMode] &&
    ![self isInFollowTrackMode] &&
    ![self isInRouteLineAppearanceMode] &&
    ![self isInGpsFilteringMode] &&
    ![self isInWeatherForecastMode] &&
    ![self isSelectingTilesZone];
}

- (BOOL)shouldShowBackToLocationButton {
    BOOL additionalDialogsHide = ![self isInTrackAppearanceMode] &&
    ![self isInGpxApproximationMode] &&
    ![self isInChoosingRoutesMode] &&
    ![self isInWaypointsChoosingMode] &&
    ![self isInFollowTrackMode] &&
    ![self isInRouteLineAppearanceMode] &&
    ![self isInGpsFilteringMode] &&
    ![self isSelectingTilesZone];
    BOOL showTopControls = [_mapPanel isTopControlsVisible] || ([self isInTrackMenuMode] && ![self isPortrait]);
    return showTopControls &&
    ![self isInPlanRouteMode] &&
    !([self isMapLinkedToLocation] && [_routingHelper isFollowingMode]) &&
    (additionalDialogsHide || ![self isPortrait]);
}

- (BOOL) shouldShowElevationProfileWidget {
    return _settings.showElevationProfileWidget.get && [self isRouteCalculated] && [OAWidgetType.elevationProfile isPurchased] && ![self isInChangeMarkerPositionMode] && ![self isInMeasurementToolMode] && ![self isInChoosingRoutesMode] && ![self isInWaypointsChoosingMode] && ![self isInPlanRouteMode] && ![self isSelectingTilesZone];
}

- (BOOL) shouldShowDownloadMapWidget {
    return ![self isInRouteLineAppearanceMode] && ![self isInGpsFilteringMode] && ![self isInWeatherForecastMode] && ![self isSelectingTilesZone];
}

- (BOOL) isQuickActionLayerOn {
    return _mapPanel.hudViewController.quickActionController.isQuickActionFloatingButtonVisible;
}

- (BOOL) isMapRouteInfoMenuVisible {
    return _mapPanel.isRouteInfoVisible;
}

- (BOOL) isInMovingMarkerMode {
//    MapQuickActionLayer *quickActionLayer = [mapLayers getMapQuickActionLayer];
//    BOOL isInMovingMarkerMode = quickActionLayer != nil && [quickActionLayer isInMovingMarkerMode];
    return /*isInMovingMarkerMode ||*/ [self isInChangeMarkerPositionMode] || [self isInAddGpxPointMode];
}

- (BOOL) isInGpxDetailsMode {
    return [_mapPanel isContextMenuVisible] && _mapPanel.activeTargetType == OATargetGPX;
}

- (BOOL) isInAddGpxPointMode {
    return [_mapPanel isContextMenuVisible];
}

- (BOOL) isInChangeMarkerPositionMode {
    return [_mapPanel isContextMenuVisible] && _mapPanel.activeTargetType == OATargetChangePosition;
}

- (BOOL) isInMeasurementToolMode {
    return [_mapLayers.routePlanningLayer isVisible];
}

- (BOOL) isInPlanRouteMode {
    // TODO: Implement markers route planning
    return NO; /*[[mapLayers getMapMarkersLayer] isInPlanRouteMode];*/
}

- (BOOL) isInTrackAppearanceMode {
    return [self isInGpxDetailsMode];/*[[mapLayers getGpxLayer] isInTrackAppearanceMode];*/
}

- (BOOL) isInGpxApproximationMode {
    return /*[[mapLayers getMeasurementToolLayer] isTapsDisabled]*/ NO;
}

- (BOOL) isInTrackMenuMode {
    return /*[mapActivity getTrackMenuFragment] != nil && [[mapActivity getTrackMenuFragment] isVisible];*/ [self isInGpxDetailsMode];
}

- (BOOL) isInChoosingRoutesMode {
    return NO /*[MapRouteInfoMenu chooseRoutesVisible]*/;
}

- (BOOL) isInWaypointsChoosingMode {
    return NO /*[MapRouteInfoMenu waypointsVisible]*/;
}

- (BOOL) isInRouteLineAppearanceMode {
    return _mapLayers.routePreviewLayer.isVisible;
}

- (BOOL) isInFollowTrackMode {
    return NO; /*[MapRouteInfoMenu followTrackVisible];*/
}

- (BOOL) isDashboardVisible {
    return [_mapPanel isDashboardVisible];
}

- (BOOL) isContextMenuFragmentVisible {
    return _mapPanel.isContextMenuVisible;
}

- (BOOL)isMultiSelectionMenuFragmentVisible {
    return _mapPanel.isTargetMultiMenuViewVisible;
}

- (BOOL)isInGpsFilteringMode {
    return NO; /*[mapActivity getGpsFilterFragment] != nil;*/
}

- (BOOL)isInWeatherForecastMode {
    return _mapPanel.activeTargetType == OATargetWeatherToolbar;
}

- (BOOL)isSelectingTilesZone {
    return _mapPanel.activeTargetType == OATargetMapDownload;
}

- (BOOL)isMapLinkedToLocation {
    return [OAMapViewTrackingUtilities.instance isMapLinkedToLocation];
}

- (BOOL)isTrackDetailsMenuOpened {
    return NO; /*[[mapActivity getTrackDetailsMenu] isVisible];*/
}

- (BOOL) isPortrait
{
    return !OAUtilities.isLandscapeIpadAware;
}

- (BOOL)isRouteCalculated {
    return [_routingHelper isRouteCalculated];
}

- (void)updateControlsVisibilityWithTopControlsVisible:(BOOL)topControlsVisible
                                 bottomControlsVisible:(BOOL)bottomControlsVisible {
//    int topControlsVisibility = topControlsVisible ? View.VISIBLE : View.GONE;
//    [AndroidUiHelper setVisibilityWithActivity:mapActivity visibility:topControlsVisibility
//                                           ids:R.id.map_center_info, R.id.map_left_widgets_panel, R.id.map_right_widgets_panel, nil];
//    int bottomControlsVisibility = bottomControlsVisible ? View.VISIBLE : View.GONE;
//    [AndroidUiHelper setVisibilityWithActivity:mapActivity visibility:bottomControlsVisibility
//                                           ids:R.id.bottom_controls_container, nil];
}

@end
