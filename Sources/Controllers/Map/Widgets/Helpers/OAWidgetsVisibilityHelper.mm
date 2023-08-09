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
#import "OAFloatingButtonsHudViewController.h"
#import "OATrackMenuAppearanceHudViewController.h"
#import "OAMeasurementToolLayer.h"
#import "OAMapLayer.h"
#import "OAMapViewTrackingUtilities.h"
#import "OsmAnd_Maps-Swift.h"

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
//    !isInConfigureMapOptionMode() &&
    [self shouldShowFabButton];
}

- (BOOL)shouldShowMap3DButton
{
    return //isInConfigureMapOptionMode() ||
    [self shouldShowFabButton];
}

- (BOOL)shouldShowFabButton
{
    return ![self isInChangeMarkerPositionMode]
    && ![self isInGpxDetailsMode]
    && ![self isInMeasurementToolMode]
    && ![self isInPlanRouteMode]
    && ![self isInTrackAppearanceMode]
    && ![self isInTrackMenuMode]
    && ![self isInRouteLineAppearanceMode]
    && ![self isMapRouteInfoMenuVisible]
    && ![self isInChoosingRoutesMode]
    && ![self isInWaypointsChoosingMode]
    && ![self isInFollowTrackMode]
    && ![self isContextMenuFragmentVisible]
    && ![self isMultiSelectionMenuFragmentVisible]
    && ![self isInGpsFilteringMode]
    && ![self isInWeatherForecastMode]
    && ![self isSelectingTilesZone];
}

- (BOOL)shouldShowTopMapCenterCoordinatesWidget
{
    BOOL shouldShow = [self shouldShowTopCoordinatesWidget];
    if (shouldShow)
    {
        for (NSString *component in [[_settings.mapInfoControls get] componentsSeparatedByString:SETTINGS_SEPARATOR])
        {
            if ([component hasPrefix:@"coordinates_map_center"])
                return YES;
        }
    }
    return [_settings.showMapCenterCoordinatesWidget get] && [_settings.quickActionIsOn get];
//    return [self shouldShowTopCoordinatesWidget]
//    && ([[[_settings.mapInfoControls get] componentsSeparatedByString:SETTINGS_SEPARATOR] containsObject:@"coordinates_map_center"]
//        || ([_settings.showMapCenterCoordinatesWidget get] && [_settings.quickActionIsOn get]));
}

- (BOOL)shouldShowTopCurrentLocationCoordinatesWidget
{
    BOOL shouldShow = [self shouldShowTopCoordinatesWidget];
    if (shouldShow)
    {
        for (NSString *component in [[_settings.mapInfoControls get] componentsSeparatedByString:SETTINGS_SEPARATOR])
        {
            if ([component hasPrefix:@"coordinates_current_location"])
                return YES;
        }
    }
    return [_settings.showCurrentLocationCoordinatesWidget get] && [_settings.quickActionIsOn get];
//    return [self shouldShowTopCoordinatesWidget]
//    && ([[[_settings.mapInfoControls get] componentsSeparatedByString:SETTINGS_SEPARATOR] containsObject:@"coordinates_current_location"]
//        || ([_settings.showCurrentLocationCoordinatesWidget get] && [_settings.quickActionIsOn get]));
}

- (BOOL)shouldShowTopCoordinatesWidget
{
    return //!mapActivity.shouldHideTopControls() &&
    [_mapPanel isTopControlsVisible] && //mapActivity.getMapRouteInfoMenu().shouldShowTopControls()
    ![_mapPanel isTopToolbarActive] &&
    ![self isInTrackAppearanceMode] &&
    ![self isInRouteLineAppearanceMode] &&
    ![self isInChoosingRoutesMode] &&
    ![self isInWaypointsChoosingMode] &&
    ![self isInFollowTrackMode] &&
    ![self isInGpsFilteringMode] &&
    ![self isInWeatherForecastMode] &&
    ![self isSelectingTilesZone];
//    && !isInConfigureMapOptionMode();
}

- (BOOL)shouldHideMapMarkersWidget
{
    return /*!_settings.showMapMarkersBarWidget.get ||
//    _mapInfoController.topTextViewVisible ||
    [_routingHelper isFollowingMode] ||
    [_routingHelper isRoutePlanningMode] ||*/
    [self isMapRouteInfoMenuVisible] ||
    [_mapPanel isTopToolbarActive] ||
    ![_mapPanel isTopControlsVisible] || //mapActivity.shouldHideTopControls()
    [self isInTrackAppearanceMode] ||
    [self isInPlanRouteMode] ||
    [self isInRouteLineAppearanceMode] ||
    [self isInGpsFilteringMode] ||
    [self isInWeatherForecastMode] ||
    [self isSelectingTilesZone];
//    || isInConfigureMapOptionMode();
}

+ (BOOL)isMapMarkerBarWidgetEnabled
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    OAApplicationMode *appMode = [settings.applicationMode get];
    NSArray<OAWidgetsPanel *> *panels = [OAWidgetsPanel.topPanel getMergedPanels];

    OAMapWidgetRegistry *widgetRegistry = [OAMapWidgetRegistry sharedInstance];
    NSMutableOrderedSet<OAMapWidgetInfo *> *enabledWidgets = [widgetRegistry getWidgetsForPanel:appMode
                                                                                    filterModes:kWidgetModeEnabled
                                                                                         panels:panels];

    for (OAMapWidgetInfo *widgetInfo in enabledWidgets)
    {
        if ([widgetInfo.key containsString:@"map_markers_top"]) {
            return YES;
        }
    }
    return NO;
}

- (BOOL)shouldShowBottomMenuButtons
{
    return [_mapPanel isTopControlsVisible] && //mapActivity.shouldHideTopControls()
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
//    && !isInConfigureMapOptionMode();
}

- (BOOL)shouldShowZoomButtons
{
    BOOL additionalDialogsHide = ![self isInGpxApproximationMode] &&
    ![self isInTrackAppearanceMode] &&
    ![self isInChoosingRoutesMode] &&
    ![self isInWaypointsChoosingMode] &&
    ![self isInRouteLineAppearanceMode] &&
    ![self isInGpsFilteringMode] &&
    ![self isSelectingTilesZone];
    BOOL showTopControls = [_mapPanel isTopControlsVisible] /*!mapActivity.shouldHideTopControls()*/ || ([self isInTrackMenuMode] && ![self isPortrait]);
    return showTopControls &&
    ![self isInFollowTrackMode] &&
//    !isInConfigureMapOptionMode() &&
    (additionalDialogsHide || ![self isPortrait]);
}

- (BOOL)shouldHideCompass
{
    return ![_mapPanel isTopControlsVisible] || //mapActivity.shouldHideTopControls()
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
    return [_mapPanel isTopControlsVisible] && //!mapActivity.shouldHideTopControls()
//    !isInAttachToRoads() &&
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
//    && !isInConfigureMapOptionMode();
}

- (BOOL)shouldShowBackToLocationButton
{
    BOOL additionalDialogsHide = ![self isInTrackAppearanceMode] &&
    ![self isInGpxApproximationMode] &&
    ![self isInChoosingRoutesMode] &&
    ![self isInWaypointsChoosingMode] &&
    ![self isInFollowTrackMode] &&
    ![self isInRouteLineAppearanceMode] &&
    ![self isInGpsFilteringMode] &&
    ![self isSelectingTilesZone];
    BOOL showTopControls = [_mapPanel isTopControlsVisible] /*!mapActivity.shouldHideTopControls()*/ || ([self isInTrackMenuMode] && ![self isPortrait]);
    return showTopControls &&
    ![self isInPlanRouteMode] &&
//     !isInConfigureMapOptionMode() &&
    !([self isMapLinkedToLocation] && [_routingHelper isFollowingMode]) &&
    (additionalDialogsHide || ![self isPortrait]);
}

- (BOOL) shouldShowElevationProfileWidget
{
    return [self isRouteCalculated] && [OAWidgetType.elevationProfile isPurchased] &&
    ![self isInChangeMarkerPositionMode] &&
    ![self isInMeasurementToolMode] &&
    ![self isInChoosingRoutesMode] &&
    ![self isInWaypointsChoosingMode] &&
    ![self isInPlanRouteMode] &&
    ![self isSelectingTilesZone] &&
    ![self isTrackDetailsMenuOpened];
/*
     && !isDashboardVisible()
     && !isInGpxDetailsMode()
     && !isInTrackAppearanceMode()
     && !isInTrackMenuMode()
     && !isMapRouteInfoMenuVisible()
     && !isInRouteLineAppearanceMode()
     && !isInFollowTrackMode()
     && !isContextMenuFragmentVisible()
     && !isMultiSelectionMenuFragmentVisible();
*/
}

- (BOOL) shouldShowDownloadMapWidget
{
    return ![self isInRouteLineAppearanceMode] &&
    ![self isInGpsFilteringMode] &&
    ![self isInWeatherForecastMode] &&
    ![self isSelectingTilesZone];
//    && !isInConfigureMapOptionMode();
}

- (BOOL) isQuickActionLayerOn {
    return _mapPanel.hudViewController.floatingButtonsController.isQuickActionFloatingButtonVisible;
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

/*private boolean isInAttachToRoads() {
    if (isInMeasurementToolMode()) {
        for (Fragment fragment : mapActivity.getSupportFragmentManager().getFragments()) {
            if (fragment instanceof SnapTrackWarningFragment || fragment instanceof GpxApproximationFragment) {
                return true;
            }
        }
    }
    return false;
}*/

- (BOOL) isInPlanRouteMode {
    // TODO: Implement markers route planning
    return NO; /*[[mapLayers getMapMarkersLayer] isInPlanRouteMode];*/
}

- (BOOL) isInTrackAppearanceMode {
    return [_mapPanel isContextMenuVisible] && [_mapPanel.scrollableHudViewController isKindOfClass:OATrackMenuAppearanceHudViewController.class];/*[[mapLayers getGpxLayer] isInTrackAppearanceMode];*/
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

/*public boolean isInConfigureMapOptionMode() {
    return mapActivity.getConfigureMapOptionFragment() != null;
}*/

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
