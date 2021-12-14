//
//  OAMapPanelViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapPanelViewController.h"

#import "OsmAndApp.h"
#import "UIViewController+OARootViewController.h"
#import "OAMapHudViewController.h"
#import "OAMapillaryImageViewController.h"
#import "OARouteDetailsGraphViewController.h"
#import "OARouteDetailsViewController.h"
#import "OAMapViewController.h"
#import "OAAutoObserverProxy.h"
#import "OALog.h"
#import "OAIAPHelper.h"
#import "OAGPXItemViewController.h"
#import "OAGPXDatabase.h"
#import <UIViewController+JASidePanel.h>
#import "OADestinationCardsViewController.h"
#import "OAPluginPopupViewController.h"
#import "OATargetDestinationViewController.h"
#import "OATargetHistoryItemViewController.h"
#import "OATargetAddressViewController.h"
#import "OAToolbarViewController.h"
#import "OADiscountHelper.h"
#import "OARouteInfoView.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OAMapActions.h"
#import "OARTargetPoint.h"
#import "OARouteTargetViewController.h"
#import "OARouteTargetSelectionViewController.h"
#import "OAPointDescription.h"
#import "OAMapWidgetRegistry.h"
#import "OALocationSimulation.h"
#import "OAColors.h"
#import "OAImpassableRoadSelectionViewController.h"
#import "OAImpassableRoadViewController.h"
#import "OAAvoidSpecificRoads.h"
#import "OAWaypointsViewController.h"
#import "OAQuickActionHudViewController.h"
#import "OARouteSettingsViewController.h"
#import "OARouteAvoidSettingsViewController.h"
#import "OARoutePreferencesParameters.h"
#import "OATransportRoutingHelper.h"
#import "OAMainSettingsViewController.h"
#import "OABaseScrollableHudViewController.h"
#import "OATopCoordinatesWidget.h"
#import "OAParkingPositionPlugin.h"
#import "OAFavoritesHelper.h"
#import "OADownloadMapWidget.h"

#import <EventKit/EventKit.h>

#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OADestinationViewController.h"
#import "OADestination.h"
#import "OAMapSettingsViewController.h"
#import "OAQuickSearchViewController.h"
#import "OAPOIType.h"
#import "OADefaultFavorite.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OASavingTrackHelper.h"
#import "PXAlertView.h"
#import "OATrackIntervalDialogView.h"
#import "OAParkingViewController.h"
#import "OAFavoriteViewController.h"
#import "OAPOIViewController.h"
#import "OAWikiMenuViewController.h"
#import "OAWikiWebViewController.h"
#import "OAGPXWptViewController.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAUtilities.h"
#import "OAGPXListViewController.h"
#import "OAFavoriteListViewController.h"
#import "OADestinationsHelper.h"
#import "OAHistoryItem.h"
#import "OAGPXEditWptViewController.h"
#import "OAPOI.h"
#import "OAPOILocationType.h"
#import "OAAnalyticsHelper.h"
#import "OATargetMultiView.h"
#import "OAReverseGeocoder.h"
#import "OAAddress.h"
#import "OABuilding.h"
#import "OAStreet.h"
#import "OAStreetIntersection.h"
#import "OACity.h"
#import "OATargetTurnViewController.h"
#import "OAConfigureMenuViewController.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAMapLayers.h"
#import "OAFavoritesLayer.h"
#import "OAImpassableRoadsLayer.h"
#import "OACarPlayActiveViewController.h"
#import "OASearchUICore.h"
#import "OASearchPhrase.h"
#import "OAQuickSearchHelper.h"

#import <UIAlertView+Blocks.h>
#import <UIAlertView-Blocks/RIButtonItem.h>

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/Road.h>
#include <OsmAndCore/CachingRoadLocator.h>
#include <OsmAndCore/IFavoriteLocation.h>
#include <OsmAndCore/IFavoriteLocationsCollection.h>
#include <OsmAndCore/ICU.h>

#import "OASizes.h"
#import "OADirectionAppearanceViewController.h"
#import "OAHistoryViewController.h"
#import "OAEditPointViewController.h"
#import "OAGPXDocument.h"
#import "OARoutePlanningHudViewController.h"
#import "OAPOIUIFilter.h"
#import "OATrackMenuAppearanceHudViewController.h"
#import "OAMapRulerView.h"

#define _(name) OAMapPanelViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

#define kMaxRoadDistanceInMeters 1000

typedef enum
{
    EOATargetPoint = 0,
    EOATargetBBOX,
    
} EOATargetMode;

@interface OAMapPanelViewController () <OADestinationViewControllerProtocol, OAParkingDelegate, OAWikiMenuDelegate, OAGPXWptViewControllerDelegate, OAToolbarViewControllerProtocol, OARouteCalculationProgressCallback, OATransportRouteCalculationProgressCallback, OARouteInformationListener, OAGpxWptEditingHandlerDelegate>

@property (nonatomic) OAMapHudViewController *hudViewController;
@property (nonatomic) OAMapillaryImageViewController *mapillaryController;
@property (nonatomic) OADestinationViewController *destinationViewController;

@property (strong, nonatomic) OATargetPointView* targetMenuView;
@property (strong, nonatomic) OATargetMultiView* targetMultiMenuView;
@property (strong, nonatomic) UIButton* shadowButton;

@property (strong, nonatomic) OARouteInfoView* routeInfoView;

@end

@implementation OAMapPanelViewController
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OASavingTrackHelper *_recHelper;
    OARoutingHelper *_routingHelper;
    OAMapViewTrackingUtilities *_mapViewTrackingUtilities;

    OAAutoObserverProxy* _addonsSwitchObserver;
    OAAutoObserverProxy* _destinationRemoveObserver;
    OAAutoObserverProxy* _mapillaryChangeObserver;

    BOOL _mapNeedsRestore;
    OAMapMode _mainMapMode;
    OsmAnd::PointI _mainMapTarget31;
    float _mainMapZoom;
    float _mainMapAzimuth;
    float _mainMapEvelationAngle;
    
    NSString *_formattedTargetName;
    double _targetLatitude;
    double _targetLongitude;
    double _targetZoom;
    EOATargetMode _targetMode;

    OADestination *_targetDestination;

    OADashboardViewController *_dashboard;
    OAQuickSearchViewController *_searchViewController;
    UILongPressGestureRecognizer *_shadowLongPress;

    BOOL _customStatusBarStyleNeeded;
    UIStatusBarStyle _customStatusBarStyle;
    
    BOOL _mapStateSaved;
        
    NSMutableArray<OAToolbarViewController *> *_toolbars;
    BOOL _topControlsVisible;
    
    BOOL _reopenSettings;
    OAApplicationMode *_targetAppMode;
    
    OACarPlayActiveViewController *_carPlayActiveController;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _app = [OsmAndApp instance];

    _settings = [OAAppSettings sharedManager];
    _recHelper = [OASavingTrackHelper sharedInstance];
    _mapActions = [[OAMapActions alloc] init];
    _routingHelper = [OARoutingHelper sharedInstance];
    _mapViewTrackingUtilities = [OAMapViewTrackingUtilities instance];
    _mapWidgetRegistry = [[OAMapWidgetRegistry alloc] init];
    
    _addonsSwitchObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                      withHandler:@selector(onAddonsSwitch:withKey:andValue:)
                                                       andObserve:_app.addonsSwitchObservable];

    _destinationRemoveObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onDestinationRemove:withKey:)
                                                            andObserve:_app.data.destinationRemoveObservable];
    
    _mapillaryChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onMapillaryChanged)
                                                          andObserve:_app.data.mapillaryChangeObservable];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMapGestureAction:) name:kNotificationMapGestureAction object:nil];

    [_routingHelper addListener:self];
    [_routingHelper addProgressBar:self];
    [OATransportRoutingHelper.sharedInstance addProgressBar:self];
    
    _toolbars = [NSMutableArray array];
    _topControlsVisible = YES;
}

// Used if the app was initiated via CarPlay
- (void) setMapViewController:(OAMapViewController *)mapViewController
{
    _mapViewController = mapViewController;
}

- (void) loadView
{
    OALog(@"Creating Map Panel views...");
    
    // Create root view
    UIView* rootView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = rootView;
    
    // Setup route info menu
    self.routeInfoView = [[OARouteInfoView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, 140.0)];

    // Instantiate map view controller
    if (!_mapViewController)
    {
        _mapViewController = [[OAMapViewController alloc] init];
        [self addChildViewController:_mapViewController];
        [self.view addSubview:_mapViewController.view];
        _mapViewController.view.frame = self.view.frame;
        _mapViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }

    // Setup target point menu
    self.targetMenuView = [[OATargetPointView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, DeviceScreenHeight)];
    self.targetMenuView.menuViewDelegate = self;
    [self.targetMenuView setMapViewInstance:_mapViewController.view];
    [self.targetMenuView setParentViewInstance:self.view];
    self.targetMenuView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self resetActiveTargetMenu];

    // Setup target multi menu
    self.targetMultiMenuView = [[OATargetMultiView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, 140.0)];

    [self updateHUD:NO];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_mapNeedsRestore)
    {
        _mapNeedsRestore = NO;
        [self restoreMapAfterReuse];
    }
    [_destinationViewController refreshView];
    self.sidePanelController.recognizesPanGesture = NO; //YES;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.targetMenuView setNavigationController:self.navigationController];

    BOOL carPlayActive = OsmAndApp.instance.carPlayActive;
    if ([_mapViewController parentViewController] != self && !carPlayActive)
        [self doMapRestore];
    
    if (carPlayActive)
        [self onCarPlayConnected];
    
    [[OADiscountHelper instance] checkAndDisplay];
}

- (void) viewWillLayoutSubviews
{
    if ([self contextMenuMode] && ![self.targetMenuView needsManualContextMode])
    {
        [self doUpdateContextMenuToolbarLayout];
    }
    else
    {
        OAToolbarViewController *topToolbar = [self getTopToolbar];
        if (topToolbar)
            [topToolbar updateFrame:YES];
        else
            [self updateToolbar];
    }
    
    if (_shadowButton)
        _shadowButton.frame = [self shadowButtonRect];
    
    if (_shadeView)
        _shadeView.frame = CGRectMake(0 - OAUtilities.getLeftMargin, 0, DeviceScreenWidth, DeviceScreenHeight);
}
 
@synthesize mapViewController = _mapViewController;

- (void) doUpdateContextMenuToolbarLayout
{
    CGFloat contextMenuToolbarHeight = [self.targetMenuView toolbarHeight];
    [self.hudViewController updateContextMenuToolbarLayout:contextMenuToolbarHeight animated:YES];
}

- (void) updateHUD:(BOOL)animated
{
    if (!_destinationViewController)
    {
        _destinationViewController = [[OADestinationViewController alloc] initWithNibName:@"OADestinationViewController" bundle:nil];
        _destinationViewController.delegate = self;
        _destinationViewController.destinationDelegate = self;
        
        if ([OADestinationsHelper instance].sortedDestinations.count > 0 && [_settings.distanceIndication get] == TOP_BAR_DISPLAY && [_settings.distanceIndicationVisibility get])
            [self showToolbar:_destinationViewController];
    }
    else if ([_settings.distanceIndication get] == TOP_BAR_DISPLAY)
        [self showToolbar:_destinationViewController];
    
    // Inflate new HUD controller
    if (!self.hudViewController)
    {
        self.hudViewController = [[OAMapHudViewController alloc] initWithNibName:@"OAMapHudViewController"
                                                                                             bundle:nil];
        self.hudViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addChildViewController:self.hudViewController];
        
        // Switch views
        self.hudViewController.view.frame = self.view.frame;
        [self.view addSubview:self.hudViewController.view];
    }
    
    if (!self.mapillaryController)
    {
        self.mapillaryController = [[OAMapillaryImageViewController alloc] initWithNibName:@"OAMapillaryImageViewController" bundle:nil];
        
        self.mapillaryController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addChildViewController:self.mapillaryController];
        
        // Switch views
        self.mapillaryController.view.frame = self.view.frame;
        [self.view addSubview:self.mapillaryController.view];
        
        [self.mapillaryController.view setHidden:YES];
    }
    
    _mapViewController.view.frame = self.view.frame;
    
    [self updateToolbar];

    [self.rootViewController setNeedsStatusBarAppearanceUpdate];
}

- (void)setupScrollableHud:(OABaseScrollableHudViewController *)controller {
    _scrollableHudViewController = controller;
    _scrollableHudViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addChildViewController:_scrollableHudViewController];
    _scrollableHudViewController.view.frame = self.view.bounds;
    [self.view addSubview:_scrollableHudViewController.view];
    [_hudViewController.quickActionController updateViewVisibility];
    [self enterContextMenuMode];
}

- (void) showScrollableHudViewController:(OABaseScrollableHudViewController *)controller
{
    self.sidePanelController.recognizesPanGesture = NO;
    [self setupScrollableHud:controller];
}

- (void) hideScrollableHudViewController
{
    self.sidePanelController.recognizesPanGesture = YES;
    if (_scrollableHudViewController != nil && self.view == _scrollableHudViewController.view.superview)
    {
        [_scrollableHudViewController.view removeFromSuperview];
        [_scrollableHudViewController removeFromParentViewController];
        _scrollableHudViewController = nil;
    }
    [_hudViewController.quickActionController updateViewVisibility];
    [self resetActiveTargetMenu];
    [self restoreFromContextMenuMode];
}

- (void)showPlanRouteViewController:(OARoutePlanningHudViewController *)controller
{
    _activeTargetType = OATargetRoutePlanning;
    [self showScrollableHudViewController:controller];
}

- (void) refreshToolbar
{
    [_destinationViewController refreshView];
    if ([OADestinationsHelper instance].sortedDestinations.count > 0 && [_settings.distanceIndicationVisibility get] && [_settings.distanceIndication get] == TOP_BAR_DISPLAY)
        [self showToolbar:_destinationViewController];
    else
        [self hideToolbar:_destinationViewController];
}

- (void) updateOverlayUnderlayView
{
    [self.hudViewController updateOverlayUnderlayView];
}

- (BOOL) isOverlayUnderlayViewVisible
{
    return [self.hudViewController isOverlayUnderlayViewVisible];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    if (_dashboard || !_mapillaryController.view.hidden || (_destinationViewController && _destinationViewController.view.superview))
        return UIStatusBarStyleLightContent;
    else if (_targetMenuView != nil && (_targetMenuView.targetPoint.type == OATargetImpassableRoadSelection ||
                                        _targetMenuView.targetPoint.type == OATargetRouteDetails ||
                                        _targetMenuView.targetPoint.type == OATargetRouteDetailsGraph ||
                                        _targetMenuView.targetPoint.type == OATargetTransportRouteDetails))
        return UIStatusBarStyleDefault;
    
    if (_customStatusBarStyleNeeded)
        return _customStatusBarStyle;

    UIStatusBarStyle style;
    if (!self.hudViewController)
        style = UIStatusBarStyleDefault;
    
    style = self.hudViewController.preferredStatusBarStyle;
    
    return [self.targetMenuView getStatusBarStyle:[self contextMenuMode] defaultStyle:style];
}

- (void) onMapillaryChanged
{
    if (!_app.data.mapillary)
        [_mapillaryController hideMapillaryView];
}

- (BOOL) hasGpxActiveTargetType
{
    return _activeTargetType == OATargetGPX || _activeTargetType == OATargetRouteStartSelection || _activeTargetType == OATargetRouteFinishSelection || _activeTargetType == OATargetRouteIntermediateSelection || _activeTargetType == OATargetImpassableRoadSelection || _activeTargetType == OATargetHomeSelection || _activeTargetType == OATargetWorkSelection || _activeTargetType == OATargetRouteDetails || _activeTargetType == OATargetRouteDetailsGraph;
}

- (void) onAddonsSwitch:(id)observable withKey:(id)key andValue:(id)value
{
    NSString *productIdentifier = key;
    if ([productIdentifier isEqualToString:kInAppId_Addon_Srtm])
    {
        [_app.data.mapLayerChangeObservable notifyEvent];
    }
}

- (void) saveMapStateIfNeeded
{
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    if ([_mapViewController parentViewController] == self) {
        
        _mapNeedsRestore = YES;
        _mainMapMode = _app.mapMode;
        _mainMapTarget31 = renderView.target31;
        _mainMapZoom = renderView.zoom;
        _mainMapAzimuth = renderView.azimuth;
        _mainMapEvelationAngle = renderView.elevationAngle;
    }
}

- (void) saveMapStateNoRestore
{
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;

    _mapNeedsRestore = NO;
    _mainMapMode = _app.mapMode;
    _mainMapTarget31 = renderView.target31;
    _mainMapZoom = renderView.zoom;
    _mainMapAzimuth = renderView.azimuth;
    _mainMapEvelationAngle = renderView.elevationAngle;
}

- (void) prepareMapForReuse:(Point31)destinationPoint zoom:(CGFloat)zoom newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated
{
    [self saveMapStateIfNeeded];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;

    if (isnan(zoom))
        zoom = renderView.zoom;
    if (zoom > 22.0f)
        zoom = 22.0f;
    
    [_mapViewController goToPosition:destinationPoint
                             andZoom:zoom
                            animated:animated];
    
    renderView.azimuth = newAzimuth;
    renderView.elevationAngle = newElevationAngle;
}

- (void) prepareMapForReuse:(UIView *)destinationView mapBounds:(OAGpxBounds)mapBounds newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated
{
    [self saveMapStateIfNeeded];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    if (mapBounds.topLeft.latitude != DBL_MAX) {
        
        const OsmAnd::LatLon latLon(mapBounds.center.latitude, mapBounds.center.longitude);
        Point31 center = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
        
        float metersPerPixel = [_mapViewController calculateMapRuler];
        
        double distanceH = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.bottomRight.longitude, mapBounds.topLeft.latitude);
        double distanceV = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.topLeft.longitude, mapBounds.bottomRight.latitude);
        
        CGSize mapSize;
        if (destinationView)
            mapSize = destinationView.bounds.size;
        else
            mapSize = self.view.bounds.size;
        
        CGFloat newZoomH = distanceH / (mapSize.width * metersPerPixel);
        CGFloat newZoomV = distanceV / (mapSize.height * metersPerPixel);
        CGFloat newZoom = log2(MAX(newZoomH, newZoomV));
        
        CGFloat zoom = renderView.zoom - newZoom;
        if (isnan(zoom))
            zoom = renderView.zoom;
        if (zoom > 22.0f)
            zoom = 22.0f;
        
        [_mapViewController goToPosition:center
                                 andZoom:zoom
                                animated:animated];
    }
    
    
    renderView.azimuth = newAzimuth;
    renderView.elevationAngle = newElevationAngle;
}

- (CGFloat) getZoomForBounds:(OAGpxBounds)mapBounds mapSize:(CGSize)mapSize
{
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    if (mapBounds.topLeft.latitude == DBL_MAX)
        return renderView.zoom;

    float metersPerPixel = [_mapViewController calculateMapRuler];
    
    double distanceH = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.bottomRight.longitude, mapBounds.topLeft.latitude);
    double distanceV = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.topLeft.longitude, mapBounds.bottomRight.latitude);
    
    CGFloat newZoomH = distanceH / (mapSize.width * metersPerPixel);
    CGFloat newZoomV = distanceV / (mapSize.height * metersPerPixel);
    CGFloat newZoom = log2(MAX(newZoomH, newZoomV));
    
    CGFloat zoom = renderView.zoom - newZoom;
    if (isnan(zoom))
        zoom = renderView.zoom;
    if (zoom > 22.0f)
        zoom = 22.0f;
    
    return zoom;
}

- (void) doMapReuse:(UIViewController *)destinationViewController destinationView:(UIView *)destinationView
{
    CGRect newFrame = CGRectMake(0, 0, destinationView.bounds.size.width, destinationView.bounds.size.height);
    if (!CGRectEqualToRect(_mapViewController.view.frame, newFrame))
        _mapViewController.view.frame = newFrame;

    [_mapViewController willMoveToParentViewController:nil];
    
    [destinationViewController addChildViewController:_mapViewController];
    [destinationView addSubview:_mapViewController.view];
    [_mapViewController didMoveToParentViewController:self];
    [destinationView bringSubviewToFront:_mapViewController.view];
    
    _mapViewController.minimap = YES;
}

- (void) modifyMapAfterReuse:(Point31)destinationPoint zoom:(CGFloat)zoom azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated
{
    _mapNeedsRestore = NO;
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    renderView.azimuth = azimuth;
    renderView.elevationAngle = elevationAngle;
    [_mapViewController goToPosition:destinationPoint andZoom:zoom animated:YES];
    
    _mapViewController.minimap = NO;
}

- (void) modifyMapAfterReuse:(OAGpxBounds)mapBounds azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated
{
    _mapNeedsRestore = NO;
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    renderView.azimuth = azimuth;
    renderView.elevationAngle = elevationAngle;
    
    if (mapBounds.topLeft.latitude != DBL_MAX) {
        
        const OsmAnd::LatLon latLon(mapBounds.center.latitude, mapBounds.center.longitude);
        Point31 center = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
        
        float metersPerPixel = [_mapViewController calculateMapRuler];
        
        double distanceH = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.bottomRight.longitude, mapBounds.topLeft.latitude);
        double distanceV = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.topLeft.longitude, mapBounds.bottomRight.latitude);
        
        CGSize mapSize = self.view.bounds.size;
        
        CGFloat newZoomH = distanceH / (mapSize.width * metersPerPixel);
        CGFloat newZoomV = distanceV / (mapSize.height * metersPerPixel);
        CGFloat newZoom = log2(MAX(newZoomH, newZoomV));
        
        CGFloat zoom = renderView.zoom - newZoom;
        if (isnan(zoom))
            zoom = renderView.zoom;
        if (zoom > 22.0f)
            zoom = 22.0f;
        
        [_mapViewController goToPosition:center
                                 andZoom:zoom
                                animated:animated];
    }
    
    _mapViewController.minimap = NO;
}

- (void) restoreMapAfterReuse
{
    _app.mapMode = _mainMapMode;
    
    OAMapRendererView* mapView = (OAMapRendererView*)_mapViewController.view;
    mapView.target31 = _mainMapTarget31;
    mapView.zoom = _mainMapZoom;
    mapView.azimuth = _mainMapAzimuth;
    mapView.elevationAngle = _mainMapEvelationAngle;
    
    _mapViewController.minimap = NO;
}

- (void) restoreMapAfterReuseAnimated
{
    _app.mapMode = _mainMapMode;
 
    if (_mainMapMode == OAMapModeFree || _mainMapMode == OAMapModeUnknown)
    {
        OAMapRendererView* mapView = (OAMapRendererView*)_mapViewController.view;
        mapView.azimuth = _mainMapAzimuth;
        mapView.elevationAngle = _mainMapEvelationAngle;
        [_mapViewController goToPosition:[OANativeUtilities convertFromPointI:_mainMapTarget31] andZoom:_mainMapZoom animated:YES];
    }
    
    _mapViewController.minimap = NO;
}

- (void) doMapRestore
{
    [_mapViewController hideTempGpxTrack];
    
    _mapViewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    
    [_mapViewController willMoveToParentViewController:nil];
    
    [self addChildViewController:_mapViewController];
    [self.view addSubview:_mapViewController.view];
    [_mapViewController didMoveToParentViewController:self];
    [self.view sendSubviewToBack:_mapViewController.view];
}

- (void) swapStartAndFinish
{
    [_routeInfoView switchStartAndFinish];
}

- (void) hideContextMenu
{
    [self targetHideMenu:.2 backButtonClicked:NO onComplete:^{
        [_hudViewController.quickActionController updateViewVisibility];
    }];
}

- (BOOL) isContextMenuVisible
{
    return (_targetMenuView && _targetMenuView.superview && !_targetMenuView.hidden)
        || (_targetMultiMenuView && _targetMultiMenuView.superview)
        || (_scrollableHudViewController && _scrollableHudViewController.view.superview);
}

- (BOOL) isRouteInfoVisible
{
    return _routeInfoView && _routeInfoView.superview;
}

- (void) closeDashboard
{
    [self closeDashboardWithDuration:.3];
}

- (void) closeDashboardWithDuration:(CGFloat)duration
{
    if (_dashboard)
    {
        if ([_dashboard isKindOfClass:[OAMapSettingsViewController class]])
            [self updateOverlayUnderlayView];
        
        NSObject* lastMapSettingsCtrl = [self.childViewControllers lastObject];
        if (lastMapSettingsCtrl && [lastMapSettingsCtrl isKindOfClass:OADashboardViewController.class])
            [((OADashboardViewController *)lastMapSettingsCtrl) hide:YES animated:YES duration:duration];
        
        [self destroyShadowButton];
        
        if ([_dashboard isKindOfClass:[OAWaypointsViewController class]] && _routeInfoView.superview)
            [self createShadowButton:@selector(closeRouteInfo) withLongPressEvent:nil topView:_routeInfoView];
        
        if (_targetAppMode && _reopenSettings)
        {
            OAMainSettingsViewController *settingsVC = [[OAMainSettingsViewController alloc] initWithTargetAppMode:_targetAppMode];
            [OARootViewController.instance.navigationController pushViewController:settingsVC animated:NO];
        }
        _targetAppMode = nil;
        _reopenSettings = NO;
        
        _dashboard = nil;

        [self.targetMenuView quickShow];

        self.sidePanelController.recognizesPanGesture = NO; //YES;
    }
}

- (void) closeRouteInfo
{
    [self closeRouteInfo:nil];
}

- (void) closeRouteInfo:(void (^)(void))onComplete
{
    [self closeRouteInfoWithTopControlsVisibility:YES bottomsControlHeight:@0 onComplete:onComplete];
}

- (void) closeRouteInfoWithTopControlsVisibility:(BOOL)topControlsVisibility bottomsControlHeight:(NSNumber *)bottomsControlHeight onComplete:(void (^)(void))onComplete
{
    if (self.routeInfoView.superview)
    {
        [self.routeInfoView hide:YES duration:.2 onComplete:^{
            [self setTopControlsVisible:topControlsVisibility];
            if (bottomsControlHeight)
                [self setBottomControlsVisible:YES menuHeight:bottomsControlHeight.floatValue animated:YES];
            [_hudViewController.quickActionController updateViewVisibility];
            if (onComplete)
                onComplete();
        }];
        
        [self destroyShadowButton];
        
        self.sidePanelController.recognizesPanGesture = NO; //YES;
    }
}

- (void) closeRouteInfoForSelectPoint:(void (^)(void))onComplete
{
    if (self.routeInfoView.superview)
    {
        [self setBottomControlsVisible:YES menuHeight:0 animated:YES];
        
        [self.routeInfoView hide:YES duration:.2 onComplete:^{
            [self setTopControlsVisible:NO];
            [_hudViewController.quickActionController updateViewVisibility];
            if (onComplete)
                onComplete();
        }];
        
        [self destroyShadowButton];
        
        self.sidePanelController.recognizesPanGesture = NO; //YES;
    }
}

- (CGRect) shadowButtonRect
{
    return self.view.frame;
}

- (void) removeGestureRecognizers
{
    for (UIGestureRecognizer *recognizer in self.view.gestureRecognizers)
    {
        if (![recognizer.name isEqualToString:kLeftPannelGestureRecognizer])
            [self.view removeGestureRecognizer:recognizer];
    }
}

- (void) mapSettingsButtonClick:(id)sender
{
    [self mapSettingsButtonClick:sender mode:nil];
}

- (void) mapSettingsButtonClick:(id)sender mode:(OAApplicationMode *)targetMode
{
    [OAAnalyticsHelper logEvent:@"configure_map_open"];
    
    _targetAppMode = targetMode;
    _reopenSettings = _targetAppMode != nil;
    
    [self removeGestureRecognizers];
    
    _dashboard = [[OAMapSettingsViewController alloc] init];
    [_dashboard show:self parentViewController:nil animated:YES];
    
    [self createShadowButton:@selector(closeDashboard) withLongPressEvent:nil topView:_dashboard.view];
    
    [self.targetMenuView quickHide];

    self.sidePanelController.recognizesPanGesture = NO;
}


- (void) showMapStylesScreen
{
    [OAAnalyticsHelper logEvent:@"configure_map_styles_open"];
    
    _targetAppMode = nil;
    _reopenSettings = _targetAppMode != nil;
    
    [self removeGestureRecognizers];
    
    _dashboard = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenMapType];
    [_dashboard show:self parentViewController:nil animated:YES];
    
    [self createShadowButton:@selector(closeDashboard) withLongPressEvent:nil topView:_dashboard.view];
    
    [self.targetMenuView quickHide];

    self.sidePanelController.recognizesPanGesture = NO;
}

- (void) showConfigureScreen
{
    [self showConfigureScreen:nil];
}

- (void) showConfigureScreen:(OAApplicationMode *)targetMode
{
    [OAAnalyticsHelper logEvent:@"configure_screen_open"];
    
    _targetAppMode = targetMode;
    _reopenSettings = _targetAppMode != nil;
    
    [self removeGestureRecognizers];
    
    _dashboard = [[OAConfigureMenuViewController alloc] init];
    [_dashboard show:self parentViewController:nil animated:YES];
    
    [self createShadowButton:@selector(closeDashboard) withLongPressEvent:nil topView:_dashboard.view];
    
    [self.targetMenuView quickHide];
    
    self.sidePanelController.recognizesPanGesture = NO;
}

- (void) showWaypoints
{
    [OAAnalyticsHelper logEvent:@"waypoints_open"];
    
    [self removeGestureRecognizers];
    
    _dashboard = [[OAWaypointsViewController alloc] init];
    [_dashboard show:self parentViewController:nil animated:YES];
    
    [self createShadowButton:@selector(closeDashboard) withLongPressEvent:nil topView:_dashboard.view];
    
    [self.targetMenuView quickHide];
    
    self.sidePanelController.recognizesPanGesture = NO;
}

- (void) showRoutePreferences
{
    [OAAnalyticsHelper logEvent:@"route_preferences_open"];
    
//    [self removeGestureRecognizers];
//
//    _dashboard = [[OARoutePreferencesViewController alloc] init];
//    [_dashboard show:self parentViewController:nil animated:YES];
//
//    [self createShadowButton:@selector(closeDashboard) withLongPressEvent:nil topView:_dashboard.view];
//
//    [self.targetMenuView quickHide];
//
//    self.sidePanelController.recognizesPanGesture = NO;
    OARouteSettingsViewController *routePrefs = [[OARouteSettingsViewController alloc] init];
    [self presentViewController:routePrefs animated:YES completion:nil];
}

- (void) showRouteInfo
{
    [self showRouteInfo:YES];
}

- (void) showRouteInfo:(BOOL)fullMenu
{
    [OAAnalyticsHelper logEvent:@"route_info_open"];

    [self removeGestureRecognizers];

    if (self.targetMenuView.superview)
    {
        [self hideTargetPointMenu:.2 onComplete:^{
            [self showRouteInfoInternal:fullMenu];
        }];
    }
    else
    {
        [self showRouteInfoInternal:fullMenu];
    }
}

- (void) showRouteInfoInternal:(BOOL)fullMenu
{
    CGRect frame = self.routeInfoView.frame;
    frame.origin.y = DeviceScreenHeight + 10.0;
    self.routeInfoView.frame = frame;
    
    [self.routeInfoView.layer removeAllAnimations];
    if ([self.view.subviews containsObject:self.routeInfoView])
        [self.routeInfoView removeFromSuperview];
    
    [self.view addSubview:self.routeInfoView];
    
    self.sidePanelController.recognizesPanGesture = NO;
    [_hudViewController.quickActionController updateViewVisibility];
    [self.routeInfoView show:YES fullMenu:fullMenu onComplete:^{
        self.sidePanelController.recognizesPanGesture = NO;
    }];
    
    [self createShadowButton:@selector(closeRouteInfo) withLongPressEvent:nil topView:_routeInfoView];
}

- (void) updateRouteInfo
{
    if (self.routeInfoView.superview)
        [self.routeInfoView updateMenu];
}

- (void) addWaypoint
{
    [self.routeInfoView addWaypoint];
}

- (void) searchButtonClick:(id)sender
{
    [self openSearch];
}

- (void) openSearch
{
    [self openSearch:OAQuickSearchType::REGULAR];
}

- (void) openSearch:(NSObject *)object location:(CLLocation *)location
{
    [self openSearch:OAQuickSearchType::REGULAR location:location tabIndex:1 searchQuery:@"" object:object];
}

- (void) openSearch:(OAQuickSearchType)searchType
{
    [self openSearch:searchType location:nil tabIndex:-1];
}

- (void) openSearch:(OAQuickSearchType)searchType location:(CLLocation *)location tabIndex:(NSInteger)tabIndex
{
    [self openSearch:searchType location:location tabIndex:tabIndex searchQuery:nil object:nil];
}

- (void) openSearch:(OAQuickSearchType)searchType location:(CLLocation *)location tabIndex:(NSInteger)tabIndex searchQuery:(NSString *)searchQuery object:(NSObject *)object
{
    [OAAnalyticsHelper logEvent:@"search_open"];
    
    [self removeGestureRecognizers];
    
    OAMapRendererView* mapView = (OAMapRendererView*)_mapViewController.view;
    BOOL isMyLocationVisible = [_mapViewController isMyLocationVisible];
    
    BOOL searchNearMapCenter = NO;
    OsmAnd::PointI searchLocation;
    
    CLLocation* newLocation = [OsmAndApp instance].locationServices.lastKnownLocation;
    OsmAnd::PointI myLocation;
    double distanceFromMyLocation = 0;
    if (location)
    {
        searchLocation = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.coordinate.latitude, location.coordinate.longitude));
        searchNearMapCenter = YES;
    }
    else if (newLocation)
    {
        myLocation = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(newLocation.coordinate.latitude, newLocation.coordinate.longitude));
        if (!isMyLocationVisible)
        {
            distanceFromMyLocation = OsmAnd::Utilities::distance31(myLocation, mapView.target31);
            if (distanceFromMyLocation > 15000)
            {
                searchNearMapCenter = YES;
                searchLocation = mapView.target31;
            }
            else
            {
                searchLocation = myLocation;
            }
        }
        else
        {
            searchLocation = myLocation;
        }
    }
    else
    {
        searchNearMapCenter = YES;
        searchLocation = mapView.target31;
    }
    
    if (!_searchViewController || location || searchQuery)
        _searchViewController = [[OAQuickSearchViewController alloc] init];
    
    _searchViewController.myLocation = searchLocation;
    _searchViewController.distanceFromMyLocation = distanceFromMyLocation;
    _searchViewController.searchNearMapCenter = searchNearMapCenter;
    _searchViewController.searchType = searchType;

    if (object)
    {
        NSString *objectLocalizedName = searchQuery;
        OASearchUICore *searchUICore = [[OAQuickSearchHelper instance] getCore];
        OASearchResult *sr;
        OASearchPhrase *phrase;
        BOOL filterByName = NO;

        if ([object isKindOfClass:[OAPOICategory class]])
        {
            objectLocalizedName = ((OAPOICategory *) object).nameLocalized;
            phrase = [searchUICore resetPhrase:[NSString stringWithFormat:@"%@ ", objectLocalizedName]];
        }
        else if ([object isKindOfClass:[OAPOIUIFilter class]])
        {
            OAPOIUIFilter *filter = (OAPOIUIFilter *) object;
            filterByName = [filter.filterId isEqualToString:BY_NAME_FILTER_ID];
            objectLocalizedName = filterByName ? filter.filterByName : filter.name;
            phrase = [searchUICore resetPhrase];
        }

        if (phrase)
        {
            sr = [[OASearchResult alloc] initWithPhrase:phrase];
            sr.localeName = objectLocalizedName;
            sr.object = object;
            sr.priority = SEARCH_AMENITY_TYPE_PRIORITY;
            sr.priorityDistance = 0;
            sr.objectType = POI_TYPE;
            [searchUICore selectSearchResult:sr];
        }

        searchQuery = [NSString stringWithFormat:@"%@ ",
                filterByName ? ((OAPOIUIFilter *) object).filterByName : objectLocalizedName.trim];
    }

    if (searchQuery)
        _searchViewController.searchQuery = searchQuery;

    if (tabIndex != -1)
        _searchViewController.tabIndex = tabIndex;

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:_searchViewController];
    navController.navigationBarHidden = YES;
    navController.automaticallyAdjustsScrollViewInsets = NO;
    navController.edgesForExtendedLayout = UIRectEdgeNone;

    [self presentViewController:navController animated:YES completion:nil];
}

- (void) setRouteTargetPoint:(BOOL)target intermediate:(BOOL)intermediate latitude:(double)latitude longitude:(double)longitude pointDescription:(OAPointDescription *)pointDescription
{
    if (!target && !intermediate)
    {
        [[OATargetPointsHelper sharedInstance] setStartPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:YES name:pointDescription];
    }
    else
    {
        [[OATargetPointsHelper sharedInstance] navigateToPoint:[[CLLocation alloc] initWithLatitude:latitude longitude:longitude] updateRoute:YES intermediate:(!intermediate ? -1 : (int)[[OATargetPointsHelper sharedInstance] getIntermediatePoints].count) historyName:pointDescription];
    }
    if (self.routeInfoView.superview)
    {
        [self.routeInfoView update];
    }
}

- (void) processNoSymbolFound:(CLLocationCoordinate2D)coord forceHide:(BOOL)forceHide
{
    if (forceHide)
    {
        if ([self.targetMenuView forceHideIfSupported] && !self.scrollableHudViewController)
            [self targetHideContextPinMarker];
    }
    else
        [self.targetMenuView hideByMapGesture];

    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.type = OATargetNone;
    targetPoint.location = coord;
    [self processTargetPoint:targetPoint];
}

- (void) onMapGestureAction:(NSNotification *)notification
{
    [self.targetMenuView hideByMapGesture];
}

- (NSString *) convertHTML:(NSString *)html
{
    NSScanner *myScanner;
    NSString *text = nil;
    myScanner = [NSScanner scannerWithString:html];
    
    while ([myScanner isAtEnd] == NO) {
        
        [myScanner scanUpToString:@"<" intoString:NULL] ;
        
        [myScanner scanUpToString:@">" intoString:&text] ;
        
        html = [html stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];
    }
    //
    html = [html stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    return html;
}

- (void) applyTargetPointController:(OATargetPoint *)targetPoint
{
    OATargetMenuViewController *controller = [OATargetMenuViewController createMenuController:targetPoint activeTargetType:_activeTargetType activeViewControllerState:_activeViewControllerState headerOnly:YES];
    if (controller)
    {
        targetPoint.ctrlAttrTypeStr = [controller getAttributedTypeStr];
        targetPoint.ctrlTypeStr = [controller getTypeStr];
    }
}

- (void) reopenContextMenu
{
    if (!self.targetMenuView.superview)
    {
        [self showTargetPointMenu:YES showFullMenu:NO];
    }
}

- (void) showContextMenuWithPoints:(NSArray<OATargetPoint *> *)targetPoints
{
    if (self.isNewContextMenuDisabled)
        return;
    NSMutableArray<OATargetPoint *> *validPoints = [NSMutableArray array];
    for (OATargetPoint *targetPoint in targetPoints)
    {
        if ([self processTargetPoint:targetPoint])
            [validPoints addObject:targetPoint];
    }
    
    if (validPoints.count == 0)
    {
        return;
    }
    else if (validPoints.count == 1)
    {
        [self showContextMenu:validPoints[0]];
    }
    else
    {
        for (OATargetPoint *targetPoint in validPoints)
            [self applyTargetPointController:targetPoint];

        [self showMultiContextMenu:validPoints];
    }
}

- (void) showMultiContextMenu:(NSArray<OATargetPoint *> *)points
{
    [self showMultiPointMenu:points onComplete:^{
        
    }];
}

- (BOOL) isNewContextMenuDisabled
{
    return _activeTargetType == OATargetImpassableRoadSelection
    || _activeTargetType == OATargetRouteDetailsGraph
    || _activeTargetType == OATargetRouteDetails
    || _activeTargetType == OATargetRoutePlanning
    || _activeTargetType == OATargetGPX;
}

- (void) showContextMenu:(OATargetPoint *)targetPoint saveState:(BOOL)saveState
{
    if (self.isNewContextMenuDisabled)
        return;
    
    if (targetPoint.type == OATargetMapillaryImage)
    {
        [_mapillaryController showImage:targetPoint.targetObj];
        [self applyTargetPoint:targetPoint];
        [self goToTargetPointMapillary];
        [self hideMultiMenuIfNeeded];
        [self setNeedsStatusBarAppearanceUpdate];
        return;
    }
    else if (targetPoint.type == OATargetMapDownload)
    {
        [_mapViewController highlightRegion:((OADownloadMapObject *)targetPoint.targetObj).worldRegion];
    }
    else
    {
        [_mapViewController hideRegionHighlight];
    }
    // show context marker on map
    [_mapViewController showContextPinMarker:targetPoint.location.latitude longitude:targetPoint.location.longitude animated:YES];
    
    [self applyTargetPoint:targetPoint];
    [_targetMenuView setTargetPoint:targetPoint];
    [self showTargetPointMenu:saveState showFullMenu:NO onComplete:^{
        
        if (targetPoint.centerMap)
            [self goToTargetPointDefault];
        
        if (_targetMenuView.needsManualContextMode)
            [self enterContextMenuMode];
    }];
}

- (void) showContextMenu:(OATargetPoint *)targetPoint
{
    if (targetPoint.type == OATargetGPX)
    {
        return [self openTargetViewWithGPX:targetPoint.targetObj
                              trackHudMode:EOATrackMenuHudMode
                                     state:[OATrackMenuViewControllerState withPinLocation:targetPoint.location]];
    }
    else
    {
        return [self showContextMenu:targetPoint saveState:YES];
    }
}

- (void) updateContextMenu:(OATargetPoint *)targetPoint
{
    // show context marker on map
    [_mapViewController showContextPinMarker:targetPoint.location.latitude longitude:targetPoint.location.longitude animated:YES];
    
    [self applyTargetPoint:targetPoint];
    [_targetMenuView setTargetPoint:targetPoint];
    [self.targetMenuView applyTargetObjectChanges];
    if (targetPoint.centerMap)
        [self goToTargetPointDefault];
}

- (BOOL) processTargetPoint:(OATargetPoint *)targetPoint
{
    if (!_activeTargetType)
        return YES;
    
    BOOL isNone = targetPoint.type == OATargetNone;
    BOOL isWaypoint = targetPoint.type == OATargetWpt;
    
    switch (_activeTargetType)
    {
        // while we are in view GPX mode - waypoints can be pressed only
        case OATargetGPX:
        {
            if (!isWaypoint && !isNone)
            {
                [_mapViewController hideContextPinMarker];
                return NO;
            }
            break;
        }
        case OATargetRouteStartSelection:
        case OATargetRouteFinishSelection:
        case OATargetRouteIntermediateSelection:
        case OATargetWorkSelection:
        case OATargetHomeSelection:
        {
            [_mapViewController hideContextPinMarker];
            
            OAPointDescription *pointDescription = nil;
            if (!isNone)
                pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:targetPoint.title];
                
            if (_activeTargetType == OATargetRouteStartSelection)
            {
                [[OATargetPointsHelper sharedInstance] setStartPoint:[[CLLocation alloc] initWithLatitude:targetPoint.location.latitude longitude:targetPoint.location.longitude] updateRoute:YES name:pointDescription];
            }
            else if (_activeTargetType == OATargetHomeSelection)
            {
                [[OATargetPointsHelper sharedInstance] setHomePoint:[[CLLocation alloc] initWithLatitude:targetPoint.location.latitude longitude:targetPoint.location.longitude] description:pointDescription];
            }
            else if (_activeTargetType == OATargetWorkSelection)
            {
                [[OATargetPointsHelper sharedInstance] setWorkPoint:[[CLLocation alloc] initWithLatitude:targetPoint.location.latitude longitude:targetPoint.location.longitude] description:pointDescription];
            }
            else
            {
                [[OATargetPointsHelper sharedInstance] navigateToPoint:[[CLLocation alloc] initWithLatitude:targetPoint.location.latitude longitude:targetPoint.location.longitude] updateRoute:YES intermediate:(_activeTargetType != OATargetRouteIntermediateSelection ? -1 : (int)[[OATargetPointsHelper sharedInstance] getIntermediatePoints].count) historyName:pointDescription];
            }

            [self hideTargetPointMenu];
            [self showRouteInfo:NO];
            
            return NO;
        }
        case OATargetImpassableRoadSelection:
        {
            [_mapViewController hideContextPinMarker];
            
            [[OAAvoidSpecificRoads instance] addImpassableRoad:[[CLLocation alloc] initWithLatitude:targetPoint.location.latitude longitude:targetPoint.location.longitude] skipWritingSettings:NO appModeKey:nil];
            
            [self.targetMenuView requestFullMode];
            
            return NO;
        }

        default:
            break;
    }
    
    return YES;
}

- (void) applyTargetPoint:(OATargetPoint *)targetPoint
{
    _targetDestination = nil;
    
    _targetMenuView.isAddressFound = targetPoint.addressFound;
    _formattedTargetName = targetPoint.title;

    if (targetPoint.type == OATargetDestination || targetPoint.type == OATargetParking)
    {
        _targetDestination = targetPoint.targetObj;
    }
    else if (targetPoint.type == OATargetWpt)
    {
        if ([targetPoint.targetObj isKindOfClass:[OAGpxWptItem class]])
        {
            OAGpxWptItem *item = (OAGpxWptItem *)targetPoint.targetObj;
            _mapViewController.foundWpt = item.point;
            _mapViewController.foundWptGroups = item.groups;
            _mapViewController.foundWptDocPath = item.docPath;
        }
    }
    _targetMode = EOATargetPoint;
    _targetLatitude = targetPoint.location.latitude;
    _targetLongitude = targetPoint.location.longitude;
    _targetZoom = 0.0;
}

- (NSString *) findRoadNameByLat:(double)lat lon:(double)lon
{
    return [[OAReverseGeocoder instance] lookupAddressAtLat:lat lon:lon];
}

- (void) goToTargetPointDefault
{
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    renderView.azimuth = 0.0;
    renderView.elevationAngle = 90.0;
    renderView.zoom = kDefaultFavoriteZoomOnShow;
    
    _mainMapAzimuth = 0.0;
    _mainMapEvelationAngle = 90.0;
    _mainMapZoom = kDefaultFavoriteZoomOnShow;
    
    [self targetGoToPoint];
}

- (void) goToTargetPointMapillary
{
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    renderView.azimuth = 0.0;
    renderView.elevationAngle = 90.0;
    renderView.zoom = kDefaultMapillaryZoomOnShow;
    
    _mainMapAzimuth = 0.0;
    _mainMapEvelationAngle = 90.0;
    _mainMapZoom = kDefaultMapillaryZoomOnShow;
    
    [self targetGoToPoint];
}

- (void) createShadowButton:(SEL)action withLongPressEvent:(SEL)withLongPressEvent topView:(UIView *)topView
{
    if (_shadowButton && [self.view.subviews containsObject:_shadowButton])
        [self destroyShadowButton];
    
    self.shadowButton = [[UIButton alloc] initWithFrame:[self shadowButtonRect]];
    [_shadowButton setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:0]];
    [_shadowButton addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    if (withLongPressEvent) {
        _shadowLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:withLongPressEvent];
        [_shadowButton addGestureRecognizer:_shadowLongPress];
    }
    
    [self.view insertSubview:self.shadowButton belowSubview:topView];
}

- (void) destroyShadowButton
{
    if (_shadowButton)
    {
        [_shadowButton removeFromSuperview];
        if (_shadowLongPress) {
            [_shadowButton removeGestureRecognizer:_shadowLongPress];
            _shadowLongPress = nil;
        }
        self.shadowButton = nil;
    }
}

- (void)shadowTargetPointLongPress:(UILongPressGestureRecognizer*)gesture
{
    if (![self.targetMenuView preHide])
        return;

    if ( gesture.state == UIGestureRecognizerStateEnded )
        [_mapViewController simulateContextMenuPress:gesture];
}

- (void) showTopControls
{
    [self.hudViewController showTopControls];
    
    _topControlsVisible = YES;
}

- (void) hideTopControls
{
    [self.hudViewController hideTopControls];

    _topControlsVisible = NO;
}

- (void) setTopControlsVisible:(BOOL)visible
{
    [self setTopControlsVisible:visible customStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void) setTopControlsVisible:(BOOL)visible customStatusBarStyle:(UIStatusBarStyle)customStatusBarStyle
{
    if (visible)
    {
        [self showTopControls];
        _customStatusBarStyleNeeded = NO;
        [self setNeedsStatusBarAppearanceUpdate];
    }
    else
    {
        [self hideTopControls];
        _customStatusBarStyle = customStatusBarStyle;
        _customStatusBarStyleNeeded = YES;
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (BOOL) isTopControlsVisible
{
    return _topControlsVisible;
}

- (BOOL) contextMenuMode
{
    if (self.hudViewController)
        return self.hudViewController.contextMenuMode;
    else
        return NO;
}

- (void) enterContextMenuMode
{
    self.hudViewController.mapModeButtonType = EOAMapModeButtonRegular;
    [self.hudViewController enterContextMenuMode];
}

- (void) restoreFromContextMenuMode
{
    [self.hudViewController restoreFromContextMenuMode];
}

- (void) showBottomControls:(CGFloat)menuHeight animated:(BOOL)animated
{
    [self.hudViewController showBottomControls:menuHeight animated:animated];
}

- (void) hideBottomControls:(CGFloat)menuHeight animated:(BOOL)animated
{
    [self.hudViewController hideBottomControls:menuHeight animated:animated];
}

- (void) setBottomControlsVisible:(BOOL)visible menuHeight:(CGFloat)menuHeight animated:(BOOL)animated
{
    if (visible)
        [self showBottomControls:menuHeight animated:animated];
    else
        [self hideBottomControls:menuHeight animated:animated];
}

- (void) restoreActiveTargetMenu
{
    switch (_activeTargetType)
    {
        case OATargetGPX:
            [_mapViewController hideContextPinMarker];
            [self openTargetViewWithGPX:_activeTargetObj];
            break;
            
        default:
            break;
    }
}

- (void) resetActiveTargetMenu
{
    if ([self hasGpxActiveTargetType] && _activeTargetObj && [_activeTargetObj isKindOfClass:OAGPX.class])
        ((OAGPX *)_activeTargetObj).newGpx = NO;
    
    _activeTargetActive = NO;
    _activeTargetObj = nil;
    _activeTargetType = OATargetNone;
    _activeViewControllerState = nil;

    _targetMenuView.activeTargetType = _activeTargetType;
    
    [self restoreFromContextMenuMode];
}

- (void) onDestinationRemove:(id)observable withKey:(id)key
{
    //OADestination *destination = key;
    dispatch_async(dispatch_get_main_queue(), ^{
        _targetDestination = nil;
        [_mapViewController hideContextPinMarker];
    });
}

- (void) createShade
{
    if (_shadeView)
    {
        [_shadeView removeFromSuperview];
        _shadeView = nil;
    }
    
    _shadeView = [[UIView alloc] initWithFrame:CGRectMake(0.0 - OAUtilities.getLeftMargin, 0.0, DeviceScreenWidth, DeviceScreenHeight)];
    _shadeView.backgroundColor = UIColorFromRGBA(0x00000060);
    _shadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _shadeView.alpha = 0.0;
}

- (void) removeShade
{
    [_shadeView removeFromSuperview];
    _shadeView = nil;
}

-(BOOL) gpxModeActive
{
    return (_activeTargetActive && _activeTargetType == OATargetGPX);
}

- (void) onHandleIncomingURL:(NSString *)ext
 {
     if (_searchViewController)
         [_searchViewController dismissViewControllerAnimated:YES completion:nil];
     if (_hudViewController)
         [_hudViewController.quickActionController hideActionsSheetAnimated];
 }

#pragma mark - OATargetPointViewDelegate

- (void) targetResetCustomStatusBarStyle
{
    _customStatusBarStyleNeeded = NO;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void) targetViewEnableMapInteraction
{
    if (self.shadowButton)
        self.shadowButton.hidden = YES;
}

- (void) targetViewDisableMapInteraction
{
    if (self.shadowButton)
        self.shadowButton.hidden = NO;
}

- (void) targetZoomIn
{
    [_mapViewController animatedZoomIn];
}

- (void) targetZoomOut
{
    [_mapViewController animatedZoomOut];
    [_mapViewController calculateMapRuler];
}

- (void) navigate:(OATargetPoint *)targetPoint
{
    [_mapActions navigate:targetPoint];
}

- (void) navigateFrom:(OATargetPoint *)targetPoint
{
    [_mapActions enterRoutePlanningMode:[[CLLocation alloc] initWithLatitude:targetPoint.location.latitude
                                                                   longitude:targetPoint.location.longitude]
                               fromName:targetPoint.pointDescription checkDisplayedGpx:NO];
}

- (void) targetPointAddFavorite
{
    [self targetHideContextPinMarker];
    [self targetHideMenu:.3 backButtonClicked:YES onComplete:nil];
    
    OAPOI *poi = nil;
    if ([self.targetMenuView.targetPoint.targetObj isKindOfClass:OAPOI.class])
        poi = self.targetMenuView.targetPoint.targetObj;
    
    OAEditPointViewController *controller =
            [[OAEditPointViewController alloc] initWithLocation:self.targetMenuView.targetPoint.location
                                                          title:self.targetMenuView.targetPoint.title
                                                    customParam:self.targetMenuView.targetPoint.titleAddress
                                                      pointType:EOAEditPointTypeFavorite
                                                targetMenuState:nil
                                                            poi:poi];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void) targetPointEditFavorite:(OAFavoriteItem *)item
{
    [self targetHideContextPinMarker];
    [self targetHideMenu:.3 backButtonClicked:YES onComplete:nil];
    OAEditPointViewController *controller = [[OAEditPointViewController alloc] initWithFavorite:item];
    [self presentViewController:controller animated:YES completion:nil];
}

- (void) targetPointShare
{
}

- (void) addMapMarker:(double)lat lon:(double)lon description:(NSString *)descr
{
    OADestination *destination = [[OADestination alloc] initWithDesc:descr latitude:lat longitude:lon];
    
    UIColor *color = [_destinationViewController addDestination:destination];
    if (color)
    {
        [_mapViewController hideContextPinMarker];
        [[OADestinationsHelper instance] moveDestinationOnTop:destination wasSelected:NO];
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"cannot_add_destination") message:OALocalizedString(@"cannot_add_marker_desc") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil
          ] show];
    }
}

- (void) targetPointDirection
{
    if (_targetDestination)
    {
        if (self.targetMenuView.targetPoint.type != OATargetDestination && self.targetMenuView.targetPoint.type != OATargetParking)
            return;
        
        if (self.targetMenuView.targetPoint.type == OATargetParking)
        {
            OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPlugin getPlugin:OAParkingPositionPlugin.class];
            if (plugin)
                [plugin clearParkingPosition];
            [self targetHideContextPinMarker];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[OADestinationsHelper instance] addHistoryItem:_targetDestination];
                [[OADestinationsHelper instance] removeDestination:_targetDestination];
            });
        }
    }
    else if (self.targetMenuView.targetPoint.type == OATargetImpassableRoad)
    {
        OAAvoidSpecificRoads *avoidRoads = [OAAvoidSpecificRoads instance];
        OAAvoidRoadInfo *roadInfo = self.targetMenuView.targetPoint.targetObj;
        if (roadInfo)
        {
            [avoidRoads removeImpassableRoad:roadInfo];
            [_mapViewController hideContextPinMarker];
        }
    }
    else if (self.targetMenuView.targetPoint.type != OATargetParking)
    {
        OADestination *destination = [[OADestination alloc] initWithDesc:_formattedTargetName latitude:_targetLatitude longitude:_targetLongitude];

        UIColor *color = [_destinationViewController addDestination:destination];
        if (color)
        {
            [_mapViewController hideContextPinMarker];
            [[OADestinationsHelper instance] moveDestinationOnTop:destination wasSelected:NO];
        }
        else
        {
            [[[UIAlertView alloc] initWithTitle:OALocalizedString(@"cannot_add_destination") message:OALocalizedString(@"cannot_add_marker_desc") delegate:nil cancelButtonTitle:OALocalizedString(@"shared_string_ok") otherButtonTitles:nil
              ] show];
        }
    }
    
    [self hideTargetPointMenu];
}

- (void) targetPointParking
{
    OAParkingViewController *parking = [[OAParkingViewController alloc] initWithCoordinate:CLLocationCoordinate2DMake(_targetLatitude, _targetLongitude)];
    parking.parkingDelegate = self;
    
    [self.targetMenuView setCustomViewController:parking needFullMenu:YES];
    [self.targetMenuView updateTargetPointType:OATargetParking];
}

- (void) targetPointAddWaypoint
{
    if ([_mapViewController hasWptAt:CLLocationCoordinate2DMake(_targetLatitude, _targetLongitude)])
        return;
    
    NSMutableArray *names = [NSMutableArray array];
    NSMutableArray *paths = [NSMutableArray array];
    
    OAAppSettings *settings = [OAAppSettings sharedManager];
    for (NSString *filePath in settings.mapSettingVisibleGpx.get)
    {
        OAGPX *gpx = [[OAGPXDatabase sharedDb] getGPXItem:filePath];
        NSString *path = [_app.gpxPath stringByAppendingPathComponent:gpx.gpxFilePath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path])
        {
            [names addObject:[filePath.lastPathComponent stringByDeletingPathExtension]];
            [paths addObject:path];
        }
    }
    
    // Ask for track where to add waypoint
    if (names.count > 0)
    {
        if ([self hasGpxActiveTargetType])
        {
            if (_activeTargetObj)
            {
                OAGPX *gpx = (OAGPX *)_activeTargetObj;
                NSString *path = [_app.gpxPath stringByAppendingPathComponent:gpx.gpxFilePath];
                [self targetPointAddWaypoint:path];
            }
            else
            {
                [self targetPointAddWaypoint:nil];
            }
            return;
        }
        
        [names insertObject:OALocalizedString(@"gpx_curr_new_track") atIndex:0];
        [paths insertObject:@"" atIndex:0];
        
        if (names.count > 5)
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:OALocalizedString(@"gpx_select_track") cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"shared_string_cancel")] otherButtonItems: nil];
            
            for (int i = 0; i < names.count; i++)
            {
                NSString *name = names[i];
                [alert addButtonItem:[RIButtonItem itemWithLabel:name action:^{
                    NSString *gpxFileName = paths[i];
                    if (gpxFileName.length == 0)
                        gpxFileName = nil;
                    
                    [self targetPointAddWaypoint:gpxFileName];
                }]];
            }
            [alert show];
        }
        else
        {
            NSMutableArray *images = [NSMutableArray array];
            for (int i = 0; i < names.count; i++)
                [images addObject:@"icon_info"];
            
            [PXAlertView showAlertWithTitle:OALocalizedString(@"gpx_select_track")
                                    message:nil
                                cancelTitle:OALocalizedString(@"shared_string_cancel")
                                otherTitles:names
                                  otherDesc:nil
                                otherImages:images
                                 completion:^(BOOL cancelled, NSInteger buttonIndex) {
                                     if (!cancelled)
                                     {
                                         NSInteger trackId = buttonIndex;
                                         NSString *gpxFileName = paths[trackId];
                                         if (gpxFileName.length == 0)
                                             gpxFileName = nil;
                                         
                                         [self targetPointAddWaypoint:gpxFileName];
                                     }
                                 }];
        }
        
    }
    else
    {
        [self targetPointAddWaypoint:nil];
    }
}

- (void) targetPointAddWaypoint:(NSString *)gpxFileName
                       location:(CLLocationCoordinate2D)location
                          title:(NSString *)title
{
    [self targetHideContextPinMarker];
    [self targetHideMenu:.3 backButtonClicked:YES onComplete:nil];
    
    OAPOI *poi = nil;
    if ([self.targetMenuView.targetPoint.targetObj isKindOfClass:OAPOI.class])
        poi = self.targetMenuView.targetPoint.targetObj;
    
    OAEditPointViewController *controller = [[OAEditPointViewController alloc] initWithLocation:location
                                                                                          title:title
                                                                                    customParam:gpxFileName
                                                                                      pointType:EOAEditPointTypeWaypoint
                                                                                targetMenuState:_activeViewControllerState
                                                                                            poi:poi];
    controller.gpxWptDelegate = self;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void) targetPointAddWaypoint:(NSString *)gpxFileName
{
    [self targetPointAddWaypoint:gpxFileName
                        location:self.targetMenuView.targetPoint.location
                           title:self.targetMenuView.targetPoint.title];
}

- (void) targetPointEditWaypoint:(OAGpxWptItem *)item
{
    [self targetHideContextPinMarker];
    [self targetHideMenu:.3 backButtonClicked:YES onComplete:nil];
    item.groups = _mapViewController.foundWptGroups;
    OAEditPointViewController *controller = [[OAEditPointViewController alloc] initWithGpxWpt:item];
    controller.gpxWptDelegate = self;
    [self presentViewController:controller animated:YES completion:nil];
}

- (void) targetHideContextPinMarker
{
    [_mapViewController hideContextPinMarker];
}

- (void) targetHide
{
    [_mapViewController hideContextPinMarker];
    [self hideTargetPointMenu];
}

- (void) targetHideMenu:(CGFloat)animationDuration backButtonClicked:(BOOL)backButtonClicked onComplete:(void (^)(void))onComplete
{
    if (backButtonClicked)
    {
        if (_activeTargetType != OATargetNone && !_activeTargetActive)
            animationDuration = .1;
        
        [self hideTargetPointMenuAndPopup:animationDuration onComplete:onComplete];
    }
    else
    {
        [self hideTargetPointMenu:animationDuration onComplete:onComplete];
    }
}

- (void) targetOpenRouteSettings
{
    [self targetHideMenu:.3 backButtonClicked:YES onComplete:nil];
    if (!self.targetMenuView.skipOpenRouteSettings)
        [self showRoutePreferences];
    else
        self.targetMenuView.skipOpenRouteSettings = NO;
}

- (void) targetOpenPlanRoute
{
    [self targetHideContextPinMarker];
    [self targetHideMenu:.3 backButtonClicked:YES onComplete:nil];
    [self showPlanRouteViewController:[[OARoutePlanningHudViewController alloc] initWithInitialPoint:[[CLLocation alloc]
                                                                                    initWithLatitude:_targetLatitude
                                                                                           longitude:_targetLongitude]]];
}

- (void) targetGoToPoint
{
    OsmAnd::LatLon latLon(_targetLatitude, _targetLongitude);
    _mainMapTarget31 = OsmAnd::Utilities::convertLatLonTo31(latLon);

    Point31 targetPoint31 = [OANativeUtilities convertFromPointI:
            OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_targetLatitude, _targetLongitude))];
    [_mapViewController goToPosition:targetPoint31 animated:NO];
}

- (void) targetGoToGPX
{
    if (_activeTargetObj)
        [self displayGpxOnMap:_activeTargetObj];
    else
        [self displayGpxOnMap:[[OASavingTrackHelper sharedInstance] getCurrentGPX]];
}

- (void) targetViewHeightChanged:(CGFloat)height animated:(BOOL)animated
{
    if ((![self.targetMenuView isLandscape] && self.targetMenuView.showFullScreen) || (self.targetMenuView.targetPoint.type == OATargetImpassableRoadSelection && !_routingHelper.isRouteCalculated))
        return;
    
    Point31 targetPoint31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_targetLatitude, _targetLongitude))];
    [_mapViewController correctPosition:targetPoint31 originalCenter31:[OANativeUtilities convertFromPointI:_mainMapTarget31] leftInset:([self.targetMenuView isLandscape] ? kInfoViewLanscapeWidth : 0.0) bottomInset:([self.targetMenuView isLandscape] ? 0.0 : height) centerBBox:(_targetMode == EOATargetBBOX) animated:animated];
}

- (void) showTargetPointMenu:(BOOL)saveMapState showFullMenu:(BOOL)showFullMenu
{
    [self showTargetPointMenu:saveMapState showFullMenu:showFullMenu onComplete:nil];
}

- (void)hideMultiMenuIfNeeded {
    if (self.targetMultiMenuView.superview)
        [self.targetMultiMenuView hide:YES duration:.2 onComplete:^{
            [_hudViewController.quickActionController updateViewVisibility];
        }];
}

- (void) showTargetPointMenu:(BOOL)saveMapState showFullMenu:(BOOL)showFullMenu onComplete:(void (^)(void))onComplete
{
    [self hideMultiMenuIfNeeded];

    if (_activeTargetActive)
    {
        _activeTargetActive = NO;
        BOOL activeTargetChildPushed = _activeTargetChildPushed;
        _activeTargetChildPushed = NO;
        
        [self hideTargetPointMenu:.1 onComplete:^{
            [self showTargetPointMenu:saveMapState showFullMenu:showFullMenu onComplete:onComplete];
            _activeTargetChildPushed = activeTargetChildPushed;
            
        } hideActiveTarget:YES mapGestureAction:NO];
        
        return;
    }
    
    if (_dashboard)
        [self closeDashboard];
    
    if (saveMapState)
        [self saveMapStateNoRestore];
    
    _mapStateSaved = saveMapState;
    
    OATargetMenuViewController *controller = [OATargetMenuViewController createMenuController:_targetMenuView.targetPoint activeTargetType:_activeTargetType activeViewControllerState:_activeViewControllerState headerOnly:NO];
    BOOL prepared = NO;
    switch (_targetMenuView.targetPoint.type)
    {
        case OATargetFavorite:
        case OATargetDestination:
        case OATargetAddress:
        case OATargetHistoryItem:
        case OATargetPOI:
        case OATargetMapDownload:
        case OATargetOsmEdit:
        case OATargetOsmNote:
        case OATargetOsmOnlineNote:
        case OATargetTransportStop:
        case OATargetTransportRoute:
        case OATargetTurn:
        case OATargetMyLocation:
        {
            if (controller)
                [self.targetMenuView doInit:showFullMenu];
            
            break;
        }
        case OATargetParking:
        {
            if (controller)
            {
                [self.targetMenuView doInit:showFullMenu];
                ((OAParkingViewController *)controller).parkingDelegate = self;
            }
            break;
        }
        case OATargetWiki:
        {
            if (controller)
            {
                [self.targetMenuView doInit:showFullMenu];
                ((OAWikiMenuViewController *)controller).menuDelegate = self;
            }
            break;
        }
        case OATargetWpt:
        {
            [self.targetMenuView doInit:showFullMenu];
            
            OAGPXWptViewController *wptViewController = (OAGPXWptViewController *) controller;
            
            wptViewController.mapViewController = self.mapViewController;
            wptViewController.wptDelegate = self;
            
            break;
        }
        case OATargetRouteStart:
        case OATargetRouteFinish:
        case OATargetRouteIntermediate:
        case OATargetRouteStartSelection:
        case OATargetRouteFinishSelection:
        case OATargetRouteIntermediateSelection:
        case OATargetHomeSelection:
        case OATargetWorkSelection:
        case OATargetImpassableRoad:
        case OATargetImpassableRoadSelection:
        case OATargetRouteDetails:
        case OATargetRouteDetailsGraph:
        case OATargetChangePosition:
        case OATargetTransportRouteDetails:
        case OATargetNewMovableWpt:
        {
            if (controller)
                [self.targetMenuView doInit:NO];

            break;
        }
        case OATargetMapillaryImage:
        {
            break;
        }
        case OATargetDownloadMapSource:
        {
            [self.targetMenuView doInit:showFullMenu showFullScreen:NO];
            [self.mapViewController disableRotationAnd3DView:YES];
            [self.mapViewController resetViewAngle];
            break;
        }
        default:
        {
            [self.targetMenuView prepare];
            prepared = YES;
        }
    }
    if (controller && !prepared)
    {
        [self.targetMenuView setCustomViewController:controller needFullMenu:NO];
        [self.targetMenuView prepareNoInit];
    }
    
    CGRect frame = self.targetMenuView.frame;
    frame.origin.y = DeviceScreenHeight + 10.0;
    self.targetMenuView.frame = frame;
    
    [self.targetMenuView.layer removeAllAnimations];
    if ([self.view.subviews containsObject:self.targetMenuView])
        [self.targetMenuView removeFromSuperview];

    if (_targetMenuView.targetPoint.minimized)
    {
        _targetMenuView.targetPoint.minimized = NO;
        if (onComplete)
            onComplete();
        
        return;
    }
    
    [self.view addSubview:self.targetMenuView];
    OAMapRendererView *renderView = (OAMapRendererView*)_mapViewController.view;
    Point31 targetPoint31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_targetLatitude, _targetLongitude))];
    BOOL landscape = ([self.targetMenuView isLandscape] || OAUtilities.isIPad) && !OAUtilities.isWindowed;
    if (_targetMenuView.targetPoint.type != OATargetRouteDetailsGraph && _targetMenuView.targetPoint.type != OATargetRouteDetails && _targetMenuView.targetPoint.type != OATargetImpassableRoadSelection)
    {
        [_mapViewController correctPosition:targetPoint31 originalCenter31:[OANativeUtilities convertFromPointI:_mapStateSaved ? _mainMapTarget31 : renderView.target31] leftInset:landscape ? self.targetMenuView.frame.size.width + 20.0 : 0 bottomInset:landscape ? 0.0 : [self.targetMenuView getHeaderViewHeight] centerBBox:(_targetMode == EOATargetBBOX) animated:YES];
    }
    
    if (onComplete)
        onComplete();
    
    self.sidePanelController.recognizesPanGesture = NO;
    [_hudViewController.quickActionController updateViewVisibility];
    [self.targetMenuView show:YES onComplete:^{
        self.sidePanelController.recognizesPanGesture = NO;
    }];
}

- (void) showMultiPointMenu:(NSArray<OATargetPoint *> *)points onComplete:(void (^)(void))onComplete
{
    if (_dashboard)
        [self closeDashboard];
    
    if (self.targetMenuView.superview)
        [self hideTargetPointMenu];
    
    CGRect frame = self.targetMultiMenuView.frame;
    frame.origin.y = DeviceScreenHeight + 10.0;
    self.targetMultiMenuView.frame = frame;
    
    [self.targetMultiMenuView.layer removeAllAnimations];
    if ([self.view.subviews containsObject:self.targetMultiMenuView])
        [self.targetMultiMenuView removeFromSuperview];
    
    [self.targetMultiMenuView setTargetPoints:points];
    
    [self.view addSubview:self.targetMultiMenuView];
    
    if (onComplete)
        onComplete();
    
    self.sidePanelController.recognizesPanGesture = NO;
    [self.targetMultiMenuView show:YES onComplete:^{
        [_hudViewController.quickActionController updateViewVisibility];
        self.sidePanelController.recognizesPanGesture = NO;
    }];
}

- (void) targetHideMenuByMapGesture
{
    [self hideTargetPointMenu:.2 onComplete:nil hideActiveTarget:NO mapGestureAction:YES];
}

- (void) targetSetTopControlsVisible:(BOOL)visible
{
    [self setTopControlsVisible:visible];
}

- (void) targetSetBottomControlsVisible:(BOOL)visible menuHeight:(CGFloat)menuHeight animated:(BOOL)animated
{
    [self setBottomControlsVisible:visible menuHeight:menuHeight animated:animated];
}

- (void) targetStatusBarChanged
{
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void) targetSetMapRulerPosition:(CGFloat)bottom left:(CGFloat)left
{
    [self.hudViewController updateRulerPosition:bottom left:left];
}

- (void) targetResetRulerPosition
{
    [self.hudViewController resetToDefaultRulerLayout];
}

- (void) targetOpenAvoidRoad
{
    [[OAAvoidSpecificRoads instance] addImpassableRoad:[[CLLocation alloc] initWithLatitude:_targetLatitude longitude:_targetLongitude] skipWritingSettings:NO appModeKey:nil];
    self.targetMenuView.skipOpenRouteSettings = YES;
    [self openTargetViewWithImpassableRoadSelection];
    if (self.targetMenuView.customController.delegate)
        [self.targetMenuView.customController.delegate requestFullMode];
}

- (void) hideTargetPointMenu
{
    [self hideTargetPointMenu:.2 onComplete:nil];
}

- (void) hideTargetPointMenu:(CGFloat)animationDuration
{
    [self hideTargetPointMenu:animationDuration onComplete:nil];
}

- (void) hideTargetPointMenu:(CGFloat)animationDuration onComplete:(void (^)(void))onComplete
{
    [self hideTargetPointMenu:animationDuration onComplete:onComplete hideActiveTarget:NO mapGestureAction:NO];
}

- (void) hideTargetPointMenu:(CGFloat)animationDuration onComplete:(void (^)(void))onComplete hideActiveTarget:(BOOL)hideActiveTarget mapGestureAction:(BOOL)mapGestureAction
{
    if (self.targetMultiMenuView.superview)
    {
        [self.targetMultiMenuView hide:YES duration:animationDuration onComplete:^{
            [_hudViewController.quickActionController updateViewVisibility];
        }];
        return;
    }
    
    if (mapGestureAction && !self.targetMenuView.superview)
    {
        return;
    }
        
    if (![self.targetMenuView preHide])
        return;
    
    if (!hideActiveTarget)
    {
        _mapStateSaved = NO;
    }
    
    [self destroyShadowButton];
    
    if (_activeTargetType != OATargetNone && !_activeTargetActive && !_activeTargetChildPushed && !hideActiveTarget && animationDuration > .1)
        animationDuration = .1;
    
    if (_targetMenuView.needsManualContextMode)
        [self restoreFromContextMenuMode];
    
    [self.targetMenuView hide:YES duration:animationDuration onComplete:^{
        
        if (_activeTargetType != OATargetNone)
        {
            if (_activeTargetActive || _activeTargetChildPushed)
            {
                [self resetActiveTargetMenu];
                _activeTargetChildPushed = NO;
            }
            else if (!hideActiveTarget)
            {
                [self restoreActiveTargetMenu];
            }
        }
        
        if (onComplete)
            onComplete();
        
        [_hudViewController.quickActionController updateViewVisibility];
        
    }];
    
    [self showTopControls];
    _customStatusBarStyleNeeded = NO;
    [self setNeedsStatusBarAppearanceUpdate];

    self.sidePanelController.recognizesPanGesture = NO; //YES;
    [self.mapViewController disableRotationAnd3DView:NO];
}

- (void) hideTargetPointMenuAndPopup:(CGFloat)animationDuration onComplete:(void (^)(void))onComplete
{
    if (self.targetMultiMenuView.superview)
    {
        [self.targetMultiMenuView hide:YES duration:animationDuration onComplete:onComplete];
        return;
    }

    if (![self.targetMenuView preHide])
        return;

    if (_mapStateSaved)
        [self restoreMapAfterReuseAnimated];
    
    _mapStateSaved = NO;
    
    [self destroyShadowButton];
    
    if (_targetMenuView.needsManualContextMode)
        [self restoreFromContextMenuMode];
    
    if ((_activeTargetType == OATargetNone || _activeTargetActive)
            && self.targetMenuView.targetPoint.type == OATargetFavorite
            && ![OAFavoriteListViewController popToParent])
        [self.navigationController popViewControllerAnimated:YES];

    [self.targetMenuView hide:YES duration:animationDuration onComplete:^{
        
        if (_activeTargetType != OATargetNone)
        {
            if (_activeTargetActive)
                [self resetActiveTargetMenu];
            else
                [self restoreActiveTargetMenu];

            _activeTargetChildPushed = NO;
        }
        if (onComplete)
            onComplete();
        
        [_hudViewController.quickActionController updateViewVisibility];
    }];
    
    [self showTopControls];
    _customStatusBarStyleNeeded = NO;
    [self setNeedsStatusBarAppearanceUpdate];
    
    [self.mapViewController disableRotationAnd3DView:NO];
    self.sidePanelController.recognizesPanGesture = NO; //YES;
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (self.targetMenuView.superview)
        [self.targetMenuView prepareForRotation:toInterfaceOrientation];
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [self.targetMenuView.customController viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.targetMultiMenuView transitionToSize];
    } completion:nil];
}

- (OATargetPoint *) getCurrentTargetPoint
{
    if (_targetMenuView.superview)
        return _targetMenuView.targetPoint;
    else
        return nil;
}

- (void) openTargetViewWithFavorite:(OAFavoriteItem *)item pushed:(BOOL)pushed saveState:(BOOL)saveState
{
    OATargetPoint *targetPoint = [_mapViewController.mapLayers.favoritesLayer getTargetPointCpp:item.favorite.get()];
    if (targetPoint)
    {
        _targetMenuView.isAddressFound = YES;
        _formattedTargetName = targetPoint.title;
        _targetMode = EOATargetPoint;
        _targetLatitude = targetPoint.location.latitude;
        _targetLongitude = targetPoint.location.longitude;
        _targetZoom = 0.0;
        
        targetPoint.toolbarNeeded = pushed;
        
        [_mapViewController showContextPinMarker:targetPoint.location.latitude longitude:targetPoint.location.longitude animated:NO];
        [_targetMenuView setTargetPoint:targetPoint];
        
        [self showTargetPointMenu:saveState showFullMenu:NO onComplete:^{
            [self goToTargetPointDefault];
        }];
    }
}

- (void) openTargetViewWithFavorite:(OAFavoriteItem *)item pushed:(BOOL)pushed
{
    return [self openTargetViewWithFavorite:item pushed:pushed saveState:YES];
}

- (void) openTargetViewWithAddress:(OAAddress *)address name:(NSString *)name typeName:(NSString *)typeName pushed:(BOOL)pushed
{
    return [self openTargetViewWithAddress:address name:name typeName:typeName pushed:pushed saveState:YES];
}

- (void) openTargetViewWithAddress:(OAAddress *)address name:(NSString *)name typeName:(NSString *)typeName pushed:(BOOL)pushed saveState:(BOOL)saveState
{
    double lat = address.latitude;
    double lon = address.longitude;
    
    [_mapViewController showContextPinMarker:lat longitude:lon animated:NO];
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    NSString *lang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    if (!lang)
        lang = @"";
    BOOL transliterate = [OAAppSettings sharedManager].settingMapLanguageTranslit.get;
    
    NSString *caption = name.length == 0 ? [address getName:lang transliterate:transliterate] : name;
    NSString *description = typeName.length == 0 ?  [address getAddressTypeName] : typeName;
    UIImage *icon = [address icon];
    
    targetPoint.type = OATargetAddress;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = description;
    _targetMode = EOATargetPoint;
    _targetLatitude = lat;
    _targetLongitude = lon;
    _targetZoom = 16.0;
    
    targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
    targetPoint.title = caption;
    targetPoint.titleAddress = description;
    targetPoint.icon = icon;
    targetPoint.toolbarNeeded = pushed;
    targetPoint.targetObj = address;
    
    [_targetMenuView setTargetPoint:targetPoint];
    
    [self showTargetPointMenu:saveState showFullMenu:NO onComplete:^{
        [self goToTargetPointDefault];
    }];
}

- (void) openTargetViewWithHistoryItem:(OAHistoryItem *)item pushed:(BOOL)pushed
{
    [self openTargetViewWithHistoryItem:item pushed:pushed showFullMenu:NO];
}

- (void) openTargetViewWithHistoryItem:(OAHistoryItem *)item pushed:(BOOL)pushed showFullMenu:(BOOL)showFullMenu
{
    double lat = item.latitude;
    double lon = item.longitude;
    
    [_mapViewController showContextPinMarker:lat longitude:lon animated:NO];
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    NSString *caption = item.name;
    UIImage *icon = [item icon];
    
    targetPoint.type = OATargetHistoryItem;

    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = [self findRoadNameByLat:lat lon:lon];
    _targetMode = EOATargetPoint;
    _targetLatitude = lat;
    _targetLongitude = lon;
    _targetZoom = 0.0;
    
    targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
    targetPoint.title = caption;
    targetPoint.titleAddress = _formattedTargetName;
    targetPoint.icon = icon;
    targetPoint.toolbarNeeded = pushed;
    targetPoint.targetObj = item;
    
    [_targetMenuView setTargetPoint:targetPoint];
    
    [self showTargetPointMenu:NO showFullMenu:showFullMenu onComplete:^{
        [self goToTargetPointDefault];
    }];
}

- (void) openTargetViewWithWpt:(OAGpxWptItem *)item pushed:(BOOL)pushed
{
    [self openTargetViewWithWpt:item pushed:pushed showFullMenu:YES];
}

- (void) openTargetViewWithWpt:(OAGpxWptItem *)item pushed:(BOOL)pushed showFullMenu:(BOOL)showFullMenu
{
    return [self openTargetViewWithWpt:item pushed:pushed showFullMenu:showFullMenu saveState:YES];
}

- (void) openTargetViewWithWpt:(OAGpxWptItem *)item pushed:(BOOL)pushed showFullMenu:(BOOL)showFullMenu saveState:(BOOL)saveState
{
    double lat = item.point.position.latitude;
    double lon = item.point.position.longitude;
    
    [_mapViewController showContextPinMarker:lat longitude:lon animated:NO];
    
    if ([_mapViewController findWpt:item.point.position])
    {
        item.point = _mapViewController.foundWpt;
        item.groups = _mapViewController.foundWptGroups;
    }
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    NSString *caption = item.point.name;
    
    OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:item.color];
    UIImage *icon = [UIImage imageNamed:favCol.iconName];
    
    targetPoint.type = OATargetWpt;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = caption;
    _targetMode = EOATargetPoint;
    _targetLatitude = lat;
    _targetLongitude = lon;
    _targetZoom = 0.0;
    
    targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
    targetPoint.title = _formattedTargetName;
    targetPoint.icon = icon;
    targetPoint.toolbarNeeded = pushed;
    targetPoint.targetObj = item;
    
    [_targetMenuView setTargetPoint:targetPoint];
    
    if (pushed && _activeTargetActive && [self hasGpxActiveTargetType])
        _activeTargetChildPushed = YES;

    [self showTargetPointMenu:saveState showFullMenu:showFullMenu onComplete:^{
        [self goToTargetPointDefault];
    }];
}

- (void)openTargetViewWithGPX:(OAGPX *)item
{
    [self openTargetViewWithGPX:item
                   trackHudMode:EOATrackMenuHudMode
                          state:[_activeViewControllerState isKindOfClass:OATrackMenuViewControllerState.class]
                    ? _activeViewControllerState : [OATrackMenuViewControllerState withPinLocation:item.bounds.center]];
}

- (void)openTargetViewWithGPX:(OAGPX *)item
                 trackHudMode:(EOATrackHudMode)trackHudMode
                        state:(OATrackMenuViewControllerState *)state;
{
    if (_scrollableHudViewController)
    {
        [_scrollableHudViewController hide:YES duration:0.2 onComplete:^{
            state.pinLocation = item.bounds.center;
            [self doShowGpxItem:item state:state trackHudMode:trackHudMode];
        }];
        return;
    }
    [self doShowGpxItem:item state:state trackHudMode:trackHudMode];
}

- (void)doShowGpxItem:(OAGPX *)item
                state:(OATrackMenuViewControllerState *)state
         trackHudMode:(EOATrackHudMode)trackHudMode
{
    BOOL showCurrentTrack = NO;
    if (item == nil)
    {
        item = [[OASavingTrackHelper sharedInstance] getCurrentGPX];
        item.gpxTitle = OALocalizedString(@"track_recording_name");
        showCurrentTrack = YES;
    }

    [self hideMultiMenuIfNeeded];

    if (_dashboard)
        [self closeDashboard];

    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    if (!state || !CLLocationCoordinate2DIsValid(state.pinLocation))
    {
        if (CLLocationCoordinate2DIsValid(item.bounds.center))
        {
            targetPoint.location = item.bounds.center;
        }
        else
        {
            OAMapRendererView *renderView = _mapViewController.mapView;
            OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(renderView.target31);
            targetPoint.location = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
        }
    }
    else
    {
        targetPoint.location = state.pinLocation;
    }
    BOOL pinAnimation = _targetLatitude != targetPoint.location.latitude
            && _targetLongitude != targetPoint.location.longitude;

    _targetLatitude = targetPoint.location.latitude;
    _targetLongitude = targetPoint.location.longitude;

    targetPoint.type = OATargetGPX;
    targetPoint.title = _formattedTargetName;
    targetPoint.icon = [UIImage imageNamed:@"icon_info"];
    targetPoint.toolbarNeeded = NO;
    if (!showCurrentTrack)
        targetPoint.targetObj = item;

    _activeTargetType = targetPoint.type;
    _activeTargetObj = targetPoint.targetObj;
    _activeViewControllerState = state;

    _formattedTargetName = [item getNiceTitle];
    _targetMenuView.isAddressFound = YES;
    _targetMenuView.activeTargetType = _activeTargetType;
    [_targetMenuView setTargetPoint:targetPoint];

    OABaseTrackMenuHudViewController *trackMenuHudViewController;

    switch (trackHudMode)
    {
        case EOATrackAppearanceHudMode:
        {
            trackMenuHudViewController = [[OATrackMenuAppearanceHudViewController alloc] initWithGpx:targetPoint.targetObj
                                                                                               state:state];
            break;
        }
        default:
        {
            trackMenuHudViewController = [[OATrackMenuHudViewController alloc] initWithGpx:targetPoint.targetObj
                                                                                     state:state];
            [_mapViewController showContextPinMarker:targetPoint.location.latitude
                                           longitude:targetPoint.location.longitude
                                            animated:pinAnimation];
            break;
        }
    }

    [self showScrollableHudViewController:trackMenuHudViewController];
    _activeTargetActive = YES;
    [self enterContextMenuMode];
}

- (void) openTargetViewWithImpassableRoad:(unsigned long long)roadId pushed:(BOOL)pushed
{
    [self closeDashboard];
    [self closeRouteInfo];

    OAAvoidSpecificRoads *avoidRoads = [OAAvoidSpecificRoads instance];
    NSArray<OAAvoidRoadInfo *> *roads = [avoidRoads getImpassableRoads];
    for (OAAvoidRoadInfo *r in roads)
    {
        if (r.roadId == roadId)
        {
            CLLocation *location = [avoidRoads getLocation:r.roadId];
            if (location)
            {
                double lat = location.coordinate.latitude;
                double lon = location.coordinate.longitude;
                
                [_mapViewController showContextPinMarker:lat longitude:lon animated:NO];
                
                OATargetPoint *targetPoint = [_mapViewController.mapLayers.impassableRoadsLayer getTargetPoint:r];
                if (targetPoint)
                {
                    targetPoint.toolbarNeeded = pushed;
                    
                    _targetMenuView.isAddressFound = YES;
                    _formattedTargetName = targetPoint.title;
                    
                    _targetMode = EOATargetPoint;
                    _targetLatitude = targetPoint.location.latitude;
                    _targetLongitude =  targetPoint.location.longitude;
                    _targetZoom = 0.0;
                    
                    [_targetMenuView setTargetPoint:targetPoint];
                    
                    [self showTargetPointMenu:YES showFullMenu:NO onComplete:^{
                        [self goToTargetPointDefault];
                    }];
                }
            }
            break;
        }
    }
}

- (void) openTargetViewWithImpassableRoadSelection
{
    [_mapViewController hideContextPinMarker];
    [self closeDashboard];
    [self closeRouteInfoWithTopControlsVisibility:NO bottomsControlHeight:nil onComplete:nil];
    
    [UIApplication.sharedApplication.keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    targetPoint.type = OATargetImpassableRoadSelection;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = OALocalizedString(@"impassable_road_desc");
    
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(renderView.target31);
    targetPoint.location = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
    _targetLatitude = latLon.latitude;
    _targetLongitude = latLon.longitude;
    
    targetPoint.title = _formattedTargetName;
    targetPoint.toolbarNeeded = NO;
    
    _activeTargetType = targetPoint.type;
    _activeTargetObj = targetPoint.targetObj;
    _targetMenuView.activeTargetType = _activeTargetType;
    
    [_targetMenuView setTargetPoint:targetPoint];
    
    [self enterContextMenuMode];
    [self showTargetPointMenu:NO showFullMenu:NO onComplete:^{
        _activeTargetActive = YES;
    }];
}

- (void) openTargetViewWithTransportRouteDetails:(NSInteger)routeIndex showFullScreen:(BOOL)showFullScreeen
{
    [_mapViewController hideContextPinMarker];
    [self closeDashboard];
    [self closeRouteInfo];
    [UIApplication.sharedApplication.keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    targetPoint.type = OATargetTransportRouteDetails;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = @"";
    
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(renderView.target31);
    targetPoint.location = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
    _targetLatitude = latLon.latitude;
    _targetLongitude = latLon.longitude;
    
    targetPoint.title = _formattedTargetName;
    targetPoint.toolbarNeeded = NO;
    targetPoint.targetObj = @(routeIndex);
    
    _activeTargetType = targetPoint.type;
    _activeTargetObj = targetPoint.targetObj;
    _targetMenuView.activeTargetType = _activeTargetType;
    
    [_targetMenuView setTargetPoint:targetPoint];
    
    [self enterContextMenuMode];
    [self showTargetPointMenu:NO showFullMenu:NO onComplete:^{
        if (showFullScreeen)
            [_targetMenuView requestFullScreenMode];
        _activeTargetActive = YES;
    }];
}

- (void) openTargetViewWithMovableTarget:(OATargetPoint *)targetPoint
{
    [_mapViewController hideContextPinMarker];
    [self closeDashboard];
    [self closeRouteInfo];
    
    OATargetPoint *target = [[OATargetPoint alloc] init];
    
    target.type = OATargetChangePosition;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = nil;

    target.title = _formattedTargetName;
    target.toolbarNeeded = NO;
    target.centerMap = YES;
    target.location = targetPoint.location;
    
    target.targetObj = targetPoint;
    
    _activeTargetType = target.type;
    _activeTargetObj = target.targetObj;
    _targetMenuView.activeTargetType = _activeTargetType;

    [_targetMenuView setTargetPoint:target];
    [self applyTargetPoint:target];

    [self enterContextMenuMode];
    [self showTargetPointMenu:NO showFullMenu:NO onComplete:^{
        _activeTargetActive = YES;
    }];
}

- (void)openTargetViewWithNewGpxWptMovableTarget:(OAGPX *)gpx
                                menuControlState:(OATargetMenuViewControllerState *)menuControlState
{
    [_mapViewController hideContextPinMarker];
    [self closeDashboard];
    [self closeRouteInfo];

    OATargetPoint *target = [[OATargetPoint alloc] init];

    target.type = OATargetNewMovableWpt;
    target.toolbarNeeded = NO;
    target.centerMap = YES;
    target.targetObj = gpx;

    _activeTargetType = target.type;
    _activeTargetObj = target.targetObj;
    _activeViewControllerState = menuControlState;

    [_targetMenuView setTargetPoint:target];
    [self applyTargetPoint:target];

    [self enterContextMenuMode];
    [self showTargetPointMenu:NO showFullMenu:NO onComplete:^{
        _activeTargetActive = YES;
    }];
}

- (void) openTargetViewWithRouteDetailsGraph:(OAGPXDocument *)gpx
                                    analysis:(OAGPXTrackAnalysis *)analysis
                            menuControlState:(OATargetMenuViewControllerState *)menuControlState
{
    [_mapViewController hideContextPinMarker];
    [self closeDashboard];
    [self closeRouteInfo];

    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    targetPoint.type = OATargetRouteDetailsGraph;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = nil;

    targetPoint.title = _formattedTargetName;
    targetPoint.toolbarNeeded = NO;
    
    if (gpx && analysis)
        targetPoint.targetObj = @{@"gpx" : gpx, @"analysis" : analysis};
    else
        targetPoint.targetObj = nil;
    
    _activeTargetType = targetPoint.type;
    _activeTargetObj = targetPoint.targetObj;
    _activeViewControllerState = menuControlState;
    _targetMenuView.activeTargetType = _activeTargetType;

    [_targetMenuView setTargetPoint:targetPoint];
    [self applyTargetPoint:targetPoint];

    [self enterContextMenuMode];
    [self showTargetPointMenu:NO showFullMenu:NO onComplete:^{
        _activeTargetActive = YES;
    }];
}

- (void) openTargetViewWithRouteDetails:(OAGPXDocument *)gpx analysis:(OAGPXTrackAnalysis *)analysis
{
    [_mapViewController hideContextPinMarker];
    [self closeDashboard];
    [self closeRouteInfo];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    targetPoint.type = OATargetRouteDetails;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = nil;
    
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(renderView.target31);
    targetPoint.location = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
    _targetLatitude = latLon.latitude;
    _targetLongitude = latLon.longitude;
    
    targetPoint.title = _formattedTargetName;
    targetPoint.toolbarNeeded = NO;
    if (gpx && analysis)
        targetPoint.targetObj = @{@"gpx" : gpx, @"analysis" : analysis};
    else
        targetPoint.targetObj = nil;
    
    _activeTargetType = targetPoint.type;
    _activeTargetObj = targetPoint.targetObj;
    _targetMenuView.activeTargetType = _activeTargetType;
    
    [_targetMenuView setTargetPoint:targetPoint];

    [self enterContextMenuMode];
    [self showTargetPointMenu:NO showFullMenu:NO onComplete:^{
        _activeTargetActive = YES;
    }];
}

- (void) openTargetViewWithRouteTargetPoint:(OARTargetPoint *)routeTargetPoint pushed:(BOOL)pushed
{
    double lat = routeTargetPoint.point.coordinate.latitude;
    double lon = routeTargetPoint.point.coordinate.longitude;
    
    [_mapViewController showContextPinMarker:lat longitude:lon animated:NO];
    
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    UIImage *icon;
    if (routeTargetPoint.start)
    {
        targetPoint.type = OATargetRouteStart;
        [UIImage imageNamed:@"list_startpoint"];
    }
    else if (!routeTargetPoint.intermediate)
    {
        targetPoint.type = OATargetRouteFinish;
        [UIImage imageNamed:@"list_destination"];
    }
    else
    {
        targetPoint.type = OATargetRouteIntermediate;
        [UIImage imageNamed:@"list_intermediate"];
    }
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = [routeTargetPoint getPointDescription].name;
    _targetMode = EOATargetPoint;
    _targetLatitude = lat;
    _targetLongitude = lon;
    _targetZoom = 0.0;
    
    targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
    targetPoint.title = _formattedTargetName;
    targetPoint.icon = icon;
    targetPoint.toolbarNeeded = pushed;
    
    [_targetMenuView setTargetPoint:targetPoint];
    
    [self showTargetPointMenu:YES showFullMenu:NO onComplete:^{
            [self goToTargetPointDefault];
    }];
}

- (void) openTargetViewWithRouteTargetSelection:(OATargetPointType)type
{
    [_mapViewController hideContextPinMarker];
    [self closeRouteInfoForSelectPoint:nil];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    targetPoint.type = type;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = OALocalizedString(@"shared_string_select_on_map");
    
    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(renderView.target31);
    targetPoint.location = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
    _targetLatitude = latLon.latitude;
    _targetLongitude = latLon.longitude;
    
    targetPoint.title = _formattedTargetName;
    targetPoint.icon = [UIImage imageNamed:@"ic_custom_location_marker"];
    targetPoint.toolbarNeeded = NO;
    
    _activeTargetType = targetPoint.type;
    _activeTargetObj = targetPoint.targetObj;
    _targetMenuView.activeTargetType = _activeTargetType;
    
    [_targetMenuView setTargetPoint:targetPoint];
    
    [self enterContextMenuMode];
    [self showTargetPointMenu:YES showFullMenu:NO onComplete:^{
        _activeTargetActive = YES;
    }];
}

- (void) openTargetViewWithDestination:(OADestination *)destination
{
    [self destinationViewMoveTo:destination];
}

- (void) openTargetViewWithDownloadMapSource:(BOOL)pushed
{
    [_mapViewController hideContextPinMarker];

    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];

    targetPoint.type = OATargetDownloadMapSource;

    OsmAnd::LatLon latLon = OsmAnd::Utilities::convert31ToLatLon(renderView.target31);
    targetPoint.location = CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude);
    _targetLatitude = latLon.latitude;
    _targetLongitude = latLon.longitude;

    targetPoint.toolbarNeeded = YES;
    
    _activeTargetType = targetPoint.type;
    _activeTargetObj = targetPoint.targetObj;
    _targetMenuView.activeTargetType = _activeTargetType;
    [_targetMenuView setTargetPoint:targetPoint];
    [self showTargetPointMenu:YES showFullMenu:YES onComplete:^{
        [self enterContextMenuMode];
        _activeTargetActive = YES;
    }];
}

- (void) displayGpxOnMap:(OAGPX *)item
{
    if (item.bounds.topLeft.latitude == DBL_MAX)
        return;

    BOOL landscape = [self.scrollableHudViewController isLandscape];
    CGSize screenBBox = CGSizeMake(
            landscape ? DeviceScreenWidth - [self.scrollableHudViewController getLandscapeViewWidth] : DeviceScreenWidth,
            landscape ? DeviceScreenHeight : DeviceScreenHeight - [self.scrollableHudViewController getViewHeight]);

    [self displayAreaOnMap:item.bounds
                      zoom:0.
                screenBBox:screenBBox
               bottomInset:0.
                 leftInset:0.
                  topInset:0.
                  animated:NO];
}

- (BOOL)goToMyLocationIfInArea:(CLLocationCoordinate2D)topLeft
                   bottomRight:(CLLocationCoordinate2D)bottomRight
{
    BOOL res = NO;
    
    CLLocation *myLoc = _app.locationServices.lastKnownLocation;
    if (myLoc && topLeft.latitude != DBL_MAX)
    {
        CLLocationCoordinate2D my = myLoc.coordinate;

        OsmAnd::PointI myI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(my.latitude, my.longitude));
        OsmAnd::PointI topLeftI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(topLeft.latitude, topLeft.longitude));
        OsmAnd::PointI bottomRightI = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bottomRight.latitude, bottomRight.longitude));
        
        if (topLeftI.x < myI.x &&
            topLeftI.y < myI.y &&
            bottomRightI.x > myI.x &&
            bottomRightI.y > myI.y)
        {
            OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
            
            _targetZoom = kDefaultFavoriteZoom;
            _targetMode = EOATargetPoint;
            
            _targetLatitude = my.latitude;
            _targetLongitude = my.longitude;
            
            Point31 targetPoint31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(my.latitude, my.longitude))];
            [_mapViewController goToPosition:targetPoint31
                                     andZoom:(_targetMode == EOATargetBBOX ? _targetZoom : kDefaultFavoriteZoomOnShow)
                                    animated:NO];
            
            renderView.azimuth = 0.0;
            renderView.elevationAngle = 90.0;
            
            OsmAnd::LatLon latLon(my.latitude, my.longitude);
            _mainMapTarget31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
            _mainMapZoom = _targetZoom;
            
            res = YES;
        }
    }
    
    return res;
}

- (void)displayAreaOnMap:(CLLocationCoordinate2D)topLeft
             bottomRight:(CLLocationCoordinate2D)bottomRight
                    zoom:(float)zoom
             bottomInset:(float)bottomInset
               leftInset:(float)leftInset
                animated:(BOOL)animated
{
    OAToolbarViewController *toolbar = [self getTopToolbar];
    CGFloat topInset = 0.0;
    if (toolbar && [toolbar.navBarView superview])
        topInset = toolbar.navBarView.frame.size.height;
    CGSize screenBBox = CGSizeMake(DeviceScreenWidth - leftInset, DeviceScreenHeight - topInset - bottomInset);
    [self displayAreaOnMap:topLeft
               bottomRight:bottomRight
                      zoom:zoom
                screenBBox:screenBBox
               bottomInset:bottomInset
                 leftInset:leftInset
                  topInset:topInset
                  animated:animated];
}

- (void)displayAreaOnMap:(CLLocationCoordinate2D)topLeft
             bottomRight:(CLLocationCoordinate2D)bottomRight
                    zoom:(float)zoom
              screenBBox:(CGSize)screenBBox
             bottomInset:(float)bottomInset
               leftInset:(float)leftInset
                topInset:(float)topInset
                animated:(BOOL)animated
{
    OAGpxBounds bounds;
    bounds.topLeft = topLeft;
    bounds.bottomRight = bottomRight;
    bounds.center.latitude = bottomRight.latitude / 2.0 + topLeft.latitude / 2.0;
    bounds.center.longitude = bottomRight.longitude / 2.0 + topLeft.longitude / 2.0;
    [self displayAreaOnMap:bounds
                      zoom:zoom
                screenBBox:screenBBox
               bottomInset:bottomInset
                 leftInset:leftInset
                  topInset:topInset
                  animated:animated];
}

- (void)displayAreaOnMap:(OAGpxBounds)bounds
                    zoom:(float)zoom
              screenBBox:(CGSize)screenBBox
             bottomInset:(float)bottomInset
               leftInset:(float)leftInset
                topInset:(float)topInset
                animated:(BOOL)animated
{
    if (bounds.topLeft.latitude == DBL_MAX)
        return;
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
	
    _targetZoom = (zoom <= 0 ? [self getZoomForBounds:bounds mapSize:screenBBox] : zoom);
    _targetMode = (_targetZoom > 0.0 ? EOATargetBBOX : EOATargetPoint);
    
    _targetLatitude = bounds.bottomRight.latitude;
    _targetLongitude = bounds.topLeft.longitude;
    
    Point31 targetPoint31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bounds.center.latitude, bounds.center.longitude))];
    [_mapViewController goToPosition:targetPoint31
                             andZoom:(_targetMode == EOATargetBBOX ? _targetZoom : kDefaultFavoriteZoomOnShow)
                            animated:NO];
    
    renderView.azimuth = 0.0;
    renderView.elevationAngle = 90.0;
    
    OsmAnd::LatLon latLon(bounds.center.latitude, bounds.center.longitude);
    _mainMapTarget31 = OsmAnd::Utilities::convertLatLonTo31(latLon);
    _mainMapZoom = _targetZoom;
    
    targetPoint31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_targetLatitude, _targetLongitude))];
    if (bottomInset > 0)
    {
        [_mapViewController correctPosition:targetPoint31
                           originalCenter31:[OANativeUtilities convertFromPointI:_mainMapTarget31]
                                  leftInset:leftInset
                                bottomInset:bottomInset
                                 centerBBox:(_targetMode == EOATargetBBOX)
                                   animated:animated];
    }
    else if (topInset > 0)
    {
        [_mapViewController correctPosition:targetPoint31
                           originalCenter31:[OANativeUtilities convertFromPointI:_mainMapTarget31]
                                  leftInset:leftInset
                                bottomInset:-topInset
                                 centerBBox:(_targetMode == EOATargetBBOX)
                                   animated:animated];
    }
    else
    {
        [_mapViewController correctPosition:targetPoint31
                           originalCenter31:[OANativeUtilities convertFromPointI:_mainMapTarget31]
                                  leftInset:leftInset > 0 ? leftInset : 0
                                bottomInset:0
                                 centerBBox:(_targetMode == EOATargetBBOX)
                                   animated:animated];
    }
}

- (BOOL) isTopToolbarActive
{
    OAToolbarViewController *toolbar = [self getTopToolbar];
    return toolbar || [_targetMenuView isToolbarVisible];
}

- (OAToolbarViewController *) getTopToolbar
{
    BOOL followingMode = [_routingHelper isFollowingMode];
    for (OAToolbarViewController *toolbar in _toolbars)
    {
        BOOL isDestinationToolBar = [toolbar isKindOfClass:[OADestinationViewController class]];
        if (toolbar && (toolbar.showOnTop || ((!followingMode && !self.hudViewController.downloadMapWidget.isVisible) || !isDestinationToolBar)))
            return toolbar;
    }
    return nil;
}

- (void) updateToolbar
{
    OAToolbarViewController *toolbar = [self getTopToolbar];
    if (self.hudViewController)
    {
        if (toolbar)
        {
            [self.hudViewController setToolbar:toolbar];
            [toolbar updateFrame:NO];
        }
        else
        {
            [self.hudViewController removeToolbar];
        }
    }
}

- (void) showCards
{
    [OAAnalyticsHelper logEvent:@"destinations_open"];

    _destinationViewController.showOnTop = YES;
    [self showToolbar:_destinationViewController];
    [self openDestinationCardsView];
}

- (void) showToolbar:(OAToolbarViewController *)toolbarController
{
    if (![_toolbars containsObject:toolbarController])
    {
        [_toolbars addObject:toolbarController];
        toolbarController.delegate = self;
    }
    
    [_toolbars sortUsingComparator:^NSComparisonResult(OAToolbarViewController * _Nonnull t1, OAToolbarViewController * _Nonnull t2) {
        int t1p = [t1 getPriority];
        if (t1.showOnTop)
            t1p -= 1000;
        int t2p = [t2 getPriority];
        if (t2.showOnTop)
            t2p -= 1000;
        return [OAUtilities compareInt:t1p y:t2p];
    }];

    [self updateToolbar];
}

- (void) hideToolbar:(OAToolbarViewController *)toolbarController
{
    [_toolbars removeObject:toolbarController];
    [self updateToolbar];
}

- (void)showPoiToolbar:(OAPOIUIFilter *)filter latitude:(double)latitude longitude:(double)longitude
{
    BOOL searchNearMapCenter = NO;
    OsmAnd::PointI myLocation = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(latitude, longitude));
    OAMapRendererView* mapView = _mapViewController.mapView;
    double distanceFromMyLocation = OsmAnd::Utilities::distance31(myLocation, mapView.target31);

    if (!_searchViewController)
        _searchViewController = [[OAQuickSearchViewController alloc] init];

    _searchViewController.myLocation = myLocation;
    _searchViewController.distanceFromMyLocation = distanceFromMyLocation;
    _searchViewController.searchNearMapCenter = searchNearMapCenter;

    [_searchViewController setupBarActionView:BarActionShowOnMap title:filter.name];
    [_searchViewController showToolbar:filter];
}

#pragma mark - OAToolbarViewControllerProtocol

- (CGFloat) toolbarTopPosition
{
    return OAUtilities.getStatusBarHeight;
}

- (void) toolbarLayoutDidChange:(OAToolbarViewController *)toolbarController animated:(BOOL)animated
{
    if (self.hudViewController)
        [self.hudViewController updateToolbarLayout:animated];

    if ([toolbarController isKindOfClass:[OADestinationViewController class]])
    {
        BOOL isCoordinatesVisible = [self.hudViewController.topCoordinatesWidget isVisible];
        
        CGFloat coordinateWidgetHeight = self.hudViewController.topCoordinatesWidget.frame.size.height;
        CGFloat markersLandscapeWidth = DeviceScreenWidth / 2;
        
        CGFloat coordinateWidgetTopOffset;
        CGFloat markersHeaderLeftOffset;
        CGFloat markersHeaderWidth;
        
        if (isCoordinatesVisible)
        {
            coordinateWidgetTopOffset = [OAUtilities isLandscape] ? 0 : coordinateWidgetHeight;
            CGFloat horisontalLeftOffset = [toolbarController.view isDirectionRTL] ? OAUtilities.getLeftMargin : DeviceScreenWidth / 2;
            markersHeaderLeftOffset = [OAUtilities isLandscape] ? horisontalLeftOffset : 0;
            markersHeaderWidth = [OAUtilities isLandscape] ? (DeviceScreenWidth / 2 - OAUtilities.getLeftMargin) : DeviceScreenWidth;
        }
        else
        {
            coordinateWidgetTopOffset = [OAUtilities isLandscape] ? 0 : 0;
            markersHeaderLeftOffset = [OAUtilities isLandscape] ? ((DeviceScreenWidth - markersLandscapeWidth) / 2) : 0;
            markersHeaderWidth = [OAUtilities isLandscape] ? markersLandscapeWidth : DeviceScreenWidth;
        }
        
        _destinationViewController.view.frame = CGRectMake( markersHeaderLeftOffset - OAUtilities.getLeftMargin, coordinateWidgetTopOffset + self.hudViewController.statusBarView.frame.size.height, markersHeaderWidth, 50);
        _destinationViewController.titleLabel.frame = CGRectMake( 0, 0, markersHeaderWidth, 44);
        
        OADestinationCardsViewController *cardsController = [OADestinationCardsViewController sharedInstance];
        
        CGFloat bottomMargin = [OAUtilities getBottomMargin];
        cardsController.toolBarHeight.constant = 48 + bottomMargin;
        cardsController.leftTableViewPadding.constant = 8 + OAUtilities.getLeftMargin;
        cardsController.rightTableViewPadding.constant = 8 + OAUtilities.getLeftMargin;
        cardsController.leftToolbarPadding.constant = OAUtilities.getLeftMargin;
        cardsController.rightToolbarPadding.constant = OAUtilities.getLeftMargin;
        CGFloat y = _destinationViewController.view.frame.origin.y + [_destinationViewController getHeight];
        CGFloat h = DeviceScreenHeight - y;
        CGFloat w = DeviceScreenWidth;
        
        CGFloat toolbarHeight = cardsController.toolBarHeight.constant;
        CGFloat cardsTableHeight = h - toolbarHeight;
        
        if (cardsController.view.superview && !cardsController.isHiding && [OADestinationsHelper instance].sortedDestinations.count > 0)
        {
            cardsController.view.frame = CGRectMake(0.0 - OAUtilities.getLeftMargin, y, w, h);
            [UIView animateWithDuration:(animated ? .25 : 0.0) animations:^{
                cardsController.cardsView.frame = CGRectMake(0.0, 0.0, w, cardsTableHeight);
                _shadeView.frame = CGRectMake(0.0 - OAUtilities.getLeftMargin, 0, DeviceScreenWidth, DeviceScreenHeight);
                _shadeView.alpha = 1.0;
                [cardsController.tableView reloadData];
            }];
        }
    }
}

- (void) toolbarHide:(OAToolbarViewController *)toolbarController;
{
    [self hideToolbar:toolbarController];
}

- (void) recreateControls
{
    if (self.hudViewController)
        [self.hudViewController recreateControls];
}

- (void) refreshMap
{
    [self refreshMap:NO];
}

- (void) refreshMap:(BOOL)redrawMap
{
    if (self.hudViewController)
        [self.hudViewController updateInfo];
    
    [self updateToolbar];
    
    if (redrawMap)
        [_mapViewController.mapView invalidateFrame];
}

#pragma mark - OAParkingDelegate

- (void) addParking:(OAParkingViewController *)sender
{
    OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPlugin getEnabledPlugin:OAParkingPositionPlugin.class];
    if (plugin)
    {
        [plugin addOrRemoveParkingEvent:sender.addToCalActive];
        [plugin setParkingTime:sender.timeLimitActive ? ([sender.date timeIntervalSince1970] * 1000) : -1];
        [plugin setParkingStartTime:[NSDate date].timeIntervalSince1970];
        [plugin setParkingPosition:sender.coord.latitude longitude:sender.coord.longitude limited:sender.timeLimitActive];
        
        if (sender.timeLimitActive && sender.addToCalActive)
            [OAFavoritesHelper addParkingReminderToCalendar];
        else if (!sender.addToCalActive)
            [OAFavoritesHelper removeParkingReminderFromCalendar];
        
        [OAFavoritesHelper setParkingPoint:sender.coord.latitude lon:sender.coord.longitude address:nil pickupDate:sender.timeLimitActive ? sender.date : nil addToCalendar:sender.addToCalActive];
        
        [_mapViewController hideContextPinMarker];
        [self hideTargetPointMenu];
    }
}

- (void) cancelParking:(OAParkingViewController *)sender
{
    [self hideTargetPointMenu];
    
}

#pragma mark - OAGPXWptViewControllerDelegate

- (void) changedWptItem
{
    [self.targetMenuView applyTargetObjectChanges];
}

#pragma mark - OAWikiMenuDelegate

- (void)openWiki:(OAWikiMenuViewController *)sender
{
    id obj = self.targetMenuView.targetPoint.targetObj;
    if ([obj isKindOfClass:OAPOI.class])
    {
        OAWikiWebViewController *wikiWeb = [[OAWikiWebViewController alloc] initWithPoi:(OAPOI *) obj];
        [self.navigationController pushViewController:wikiWeb animated:YES];
    }
}

#pragma mark - OADestinationViewControllerProtocol

- (void)destinationsAdded
{
    if ([_settings.distanceIndication get] == TOP_BAR_DISPLAY && [_settings.distanceIndicationVisibility get])
        [self showToolbar:_destinationViewController];
}

- (void) hideDestinations
{
    [self hideToolbar:_destinationViewController];
}

- (void) openDestinationCardsView
{
    OADestinationCardsViewController *cardsController = [OADestinationCardsViewController sharedInstance];
    
    if (!cardsController.view.superview)
    {
        [self hideTargetPointMenu];
        CGFloat y = _destinationViewController.view.frame.origin.y + [_destinationViewController getHeight];
        CGFloat h = DeviceScreenHeight - y;
        CGFloat w = DeviceScreenWidth;
        CGFloat toolbarHeight = cardsController.toolBarHeight.constant;
        CGFloat cardsTableHeight = h - toolbarHeight;
    
        cardsController.view.frame = CGRectMake(0.0 - OAUtilities.getLeftMargin, 0.0, w, DeviceScreenHeight);
        cardsController.cardsView.frame = CGRectMake(0.0, y - h, w, h - toolbarHeight);
        cardsController.bottomView.frame = CGRectMake(0.0, DeviceScreenHeight + 1, DeviceScreenWidth, toolbarHeight);
        [cardsController.cardsView setHidden:YES];
        [cardsController.bottomView setHidden:YES];
        
        [self.hudViewController addChildViewController:cardsController];
        
        [self createShade];
        
        [self.hudViewController.view insertSubview:_shadeView belowSubview:_destinationViewController.view];
        
        [self.hudViewController.view insertSubview:cardsController.view belowSubview:_destinationViewController.view];
        
        if (_destinationViewController)
            [self.destinationViewController updateCloseButton];
        
        cardsController.view.frame = CGRectMake(0.0 - OAUtilities.getLeftMargin, y, w, h);
        
        [UIView animateWithDuration:.25 animations:^{
            cardsController.cardsView.frame = CGRectMake(0.0, 0.0, w, cardsTableHeight);
            cardsController.bottomView.frame = CGRectMake(0.0, DeviceScreenHeight - toolbarHeight, DeviceScreenWidth, toolbarHeight);
            _shadeView.alpha = 1.0;
        }];
        [cardsController.cardsView setHidden:NO];
        [cardsController.bottomView setHidden:NO];
    }
}

- (void) hideDestinationCardsView
{
    [self hideDestinationCardsViewAnimated:YES];
}

- (void) hideDestinationCardsViewAnimated:(BOOL)animated
{
    OADestinationCardsViewController *cardsController = [OADestinationCardsViewController sharedInstance];
    BOOL wasOnTop = _destinationViewController.showOnTop;
    _destinationViewController.showOnTop = NO;
    
    if (cardsController.view.superview)
    {
        CGFloat y = _destinationViewController.view.frame.origin.y + [_destinationViewController getHeight];
        CGFloat h = DeviceScreenHeight - y;
        CGFloat w = DeviceScreenWidth;
        CGFloat cardsTableHeight = h - cardsController.toolBarHeight.constant;
    
        [cardsController doViewWillDisappear];

        if ([OADestinationsHelper instance].sortedDestinations.count == 0 || !([_settings.distanceIndicationVisibility get]) || ([_settings.distanceIndication get] == WIDGET_DISPLAY))
        {
            [self hideToolbar:_destinationViewController];
        }
        else
        {
            [self.destinationViewController updateCloseButton];
            if (wasOnTop)
                [self updateToolbar];
        }
        
        if (animated)
        {
            [UIView animateWithDuration:.25 animations:^{
                cardsController.cardsView.frame = CGRectMake(0.0, y - h, w, cardsTableHeight);
                cardsController.bottomView.frame = CGRectMake(0.0, DeviceScreenHeight, w, cardsController.toolBarHeight.constant);
                _shadeView.alpha = 0.0;
                
            } completion:^(BOOL finished) {
                
                [self removeShade];
                
                [cardsController.view removeFromSuperview];
                [cardsController removeFromParentViewController];
            }];
        }
        else
        {
            [self removeShade];
            [cardsController.view removeFromSuperview];
            [cardsController removeFromParentViewController];
        }
    }
}

- (void) openHideDestinationCardsView
{
    if (![OADestinationCardsViewController sharedInstance].view.superview)
        [self openDestinationCardsView];
    else
        [self hideDestinationCardsView];
}

- (void) destinationViewMoveTo:(OADestination *)destination
{
    [_mapViewController showContextPinMarker:destination.latitude longitude:destination.longitude animated:YES];

    OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
    
    NSString *caption = destination.desc;
    UIImage *icon = [UIImage imageNamed:destination.markerResourceName];
    
    targetPoint.type = OATargetDestination;
    
    targetPoint.targetObj = destination;
    
    _targetDestination = destination;
    
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = caption;
    _targetMode = EOATargetPoint;
    _targetLatitude = destination.latitude;
    _targetLongitude = destination.longitude;
    _targetZoom = 0.0;
    
    targetPoint.location = CLLocationCoordinate2DMake(destination.latitude, destination.longitude);
    targetPoint.title = _formattedTargetName;
    targetPoint.icon = icon;
    targetPoint.titleAddress = [self findRoadNameByLat:destination.latitude lon:destination.longitude];
    
    [_targetMenuView setTargetPoint:targetPoint];
    [self enterContextMenuMode];
    
    [self showTargetPointMenu:YES showFullMenu:NO onComplete:^{
        [self targetGoToPoint];
    }];
}

// Navigation

- (void) displayCalculatedRouteOnMap:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight
{
    [self displayCalculatedRouteOnMap:topLeft bottomRight:bottomRight animated:YES];
}

- (void) displayCalculatedRouteOnMap:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight animated:(BOOL)animated
{
    BOOL landscape = [self.targetMenuView isLandscape];
    [self displayAreaOnMap:topLeft bottomRight:bottomRight zoom:0 bottomInset:[_routeInfoView superview] && !landscape ? _routeInfoView.frame.size.height + 20.0 : 0 leftInset:[_routeInfoView superview] && landscape ? _routeInfoView.frame.size.width + 20.0 : 0 animated:NO];
}

- (void) onNavigationClick:(BOOL)hasTargets
{
    OATargetPointsHelper *targets = [OATargetPointsHelper sharedInstance];
    if (![_routingHelper isFollowingMode] && ![_routingHelper isRoutePlanningMode])
    {
        OARTargetPoint *start = [targets getPointToStart];
        if (start)
        {
            [_mapActions enterRoutePlanningMode:[[CLLocation alloc] initWithLatitude:[start getLatitude] longitude:[start getLongitude]] fromName:[start getPointDescription]];
        }
        else
        {
            [_mapActions enterRoutePlanningMode:nil fromName:nil];
        }
        [self updateRouteButton];
    }
    else
    {
        [self showRouteInfo];
    }
}

- (void) switchToRouteFollowingLayout
{
    [_routingHelper setRoutePlanningMode:NO];
    [_mapViewTrackingUtilities switchToRoutePlanningMode];
    [self refreshMap];
}

- (BOOL) switchToRoutePlanningLayout
{
    if (![_routingHelper isRoutePlanningMode] && [_routingHelper isFollowingMode])
    {
        [_routingHelper setRoutePlanningMode:YES];
        [_mapViewTrackingUtilities switchToRoutePlanningMode];
        [self refreshMap];
        return YES;
    }
    return NO;
}


- (void) startNavigation
{
    if ([_routingHelper isFollowingMode])
    {
        [self switchToRouteFollowingLayout];
        if (_settings.applicationMode.get != [_routingHelper getAppMode])
            [_settings setApplicationModePref:[_routingHelper getAppMode]];

        if (_settings.simulateRouting && ![_app.locationServices.locationSimulation isRouteAnimating])
            [_app.locationServices.locationSimulation startStopRouteAnimation];
    }
    else
    {
        if (![[OATargetPointsHelper sharedInstance] checkPointToNavigateShort])
        {
            [self showRouteInfo];
        }
        else
        {
            //app.logEvent(mapActivity, "start_navigation");
            [_settings setApplicationModePref:[_routingHelper getAppMode] markAsLastUsed:NO];
            [_mapViewTrackingUtilities backToLocationImpl:17 forceZoom:YES];
            [_settings.followTheRoute set:YES];
            [[[OsmAndApp instance] followTheRouteObservable] notifyEvent];
            [_routingHelper setFollowingMode:true];
            [_routingHelper setRoutePlanningMode:false];
            [_mapViewTrackingUtilities switchToRoutePlanningMode];
            [_routingHelper notifyIfRouteIsCalculated];
            [_routingHelper setCurrentLocation:_app.locationServices.lastKnownLocation returnUpdatedLocation:false];
            
            [self updateRouteButton];
            [self updateToolbar];
            
            if (_settings.simulateRouting && ![_app.locationServices.locationSimulation isRouteAnimating])
                [_app.locationServices.locationSimulation startStopRouteAnimation];
        }
    }
}

- (void) stopNavigation
{
    [self closeRouteInfo];
    if ([_routingHelper isFollowingMode])
        [_mapActions stopNavigationActionConfirm];
    else
        [_mapActions stopNavigationWithoutConfirm];

    if (_settings.simulateRouting && [_app.locationServices.locationSimulation isRouteAnimating])
        [_app.locationServices.locationSimulation startStopRouteAnimation];
}

- (void) updateRouteButton
{
    dispatch_async(dispatch_get_main_queue(), ^{
        bool routePlanningMode = false;
        if ([_routingHelper isRoutePlanningMode])
        {
            routePlanningMode = true;
        }
        else if (([_routingHelper isRouteCalculated] || [_routingHelper isRouteBeingCalculated]) && ![_routingHelper isFollowingMode])
        {
            routePlanningMode = true;
        }
        
        [self.hudViewController updateRouteButton:routePlanningMode followingMode:[_routingHelper isFollowingMode]];
    });
}

- (void) updateColors
{
    [self updateRouteButton];
}

#pragma mark - OARouteCalculationProgressCallback

- (void) updateProgress:(int)progress
{
    //NSLog(@"Route calculation in progress: %d", progress);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.hudViewController onRoutingProgressChanged:progress];
    });
}

- (void) finish
{
    NSLog(@"Route calculation finished");
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.hudViewController onRoutingProgressFinished];
    });
}

- (void) requestPrivateAccessRouting
{
    
}

- (void) start
{
    
}

#pragma mark - OARouteInformationListener

- (void) newRouteIsCalculated:(BOOL)newRoute
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateRouteButton];
    });
}

- (void) routeWasUpdated
{
}

- (void) routeWasCancelled
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateRouteButton];
    });
}

- (void) routeWasFinished
{
}

#pragma mark - CarPlay related actions

- (void) onCarPlayConnected
{
    if (_carPlayActiveController && _carPlayActiveController.presentingViewController == self)
        return;
    _carPlayActiveController = [[OACarPlayActiveViewController alloc] init];
    _carPlayActiveController.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:_carPlayActiveController animated:YES completion:nil];
}

- (void) onCarPlayDisconnected:(void (^ __nullable)(void))onComplete
{
    [_carPlayActiveController dismissViewControllerAnimated:YES completion:^{
        _carPlayActiveController = nil;
        if (onComplete)
            onComplete();
    }];
}

#pragma mark - OAGpxWptEditingHandlerDelegate

- (void)saveGpxWpt:(OAGpxWptItem *)gpxWpt gpxFileName:(NSString *)gpxFileName
{
    [_mapViewController addNewWpt:gpxWpt.point gpxFileName:gpxFileName];

    gpxWpt.groups = _mapViewController.foundWptGroups;

    UIColor* color = gpxWpt.color;
    OAFavoriteColor *favCol = [OADefaultFavorite nearestFavColor:color];

    self.targetMenuView.targetPoint.type = OATargetWpt;
    self.targetMenuView.targetPoint.icon = [UIImage imageNamed:favCol.iconName];
    self.targetMenuView.targetPoint.targetObj = gpxWpt;

    [self.targetMenuView updateTargetPointType:OATargetWpt];
    [self.targetMenuView applyTargetObjectChanges];

    if (!gpxFileName && ![OAAppSettings sharedManager].mapSettingShowRecordingTrack)
    {
        [[OAAppSettings sharedManager].mapSettingShowRecordingTrack set:YES];
        [[_app updateRecTrackOnMapObservable] notifyEvent];
    }
}

- (void)updateGpxWpt:(OAGpxWptItem *)gpxWptItem docPath:(NSString *)docPath updateMap:(BOOL)updateMap
{
    [_mapViewController updateWpts:@[gpxWptItem] docPath:docPath updateMap:updateMap];
    [self.targetMenuView applyTargetObjectChanges];
}

- (void)deleteGpxWpt:(OAGpxWptItem *)gpxWptItem docPath:(NSString *)docPath
{
    [_mapViewController deleteWpts:@[gpxWptItem] docPath:docPath];
}

- (void)saveItemToStorage:(OAGpxWptItem *)gpxWptItem
{
    if (gpxWptItem.point.wpt != nullptr)
    {
        [OAGPXDocument fillWpt:gpxWptItem.point.wpt usingWpt:gpxWptItem.point];
        [_mapViewController saveFoundWpt];
    }
}

@end
