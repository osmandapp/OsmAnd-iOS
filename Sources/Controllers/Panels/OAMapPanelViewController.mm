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
#import "OAAutoObserverProxy.h"
#import "OALog.h"
#import "OAIAPHelper.h"
#import "OAProducts.h"
#import "OAGPXDatabase.h"
#import <UIViewController+JASidePanel.h>
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
#import "OAFloatingButtonsHudViewController.h"
#import "OARouteSettingsViewController.h"
#import "OARouteAvoidSettingsViewController.h"
#import "OARoutePreferencesParameters.h"
#import "OATransportRoutingHelper.h"
#import "OAMainSettingsViewController.h"
#import "OABaseScrollableHudViewController.h"
#import "OAParkingPositionPlugin.h"
#import "OAFavoritesHelper.h"
#import "OADownloadMapWidget.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OADestination.h"
#import "OAMapSettingsViewController.h"
#import "OAQuickSearchViewController.h"
#import "OAPOI.h"
#import "OAPOIType.h"
#import "OADefaultFavorite.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OASavingTrackHelper.h"
#import "OAParkingViewController.h"
#import "OAFavoriteViewController.h"
#import "OAPOIViewController.h"
#import "OAWikiMenuViewController.h"
#import "OAWikiWebViewController.h"
#import "OAGPXWptViewController.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAUtilities.h"
#import "OAFavoriteListViewController.h"
#import "OADestinationsHelper.h"
#import "OAHistoryItem.h"
#import "OAGPXEditWptViewController.h"
#import "OAPOI.h"
#import "OATransportStop.h"
#import "OAPOILocationType.h"
#import "OAAnalyticsHelper.h"
#import "OATargetMultiView.h"
#import "OAReverseGeocoder.h"
#import "OAAddress.h"
#import "OABuilding.h"
#import "OAStreet.h"
#import "OAStreetIntersection.h"
#import "OACity.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAMapLayers.h"
#import "OACarPlayActiveViewController.h"
#import "OASearchUICore.h"
#import "OASearchPhrase.h"
#import "OAQuickSearchHelper.h"
#import "OAEditPointViewController.h"
#import "OARoutePlanningHudViewController.h"
#import "OAPOIUIFilter.h"
#import "OATrackMenuAppearanceHudViewController.h"
#import "OARouteLineAppearanceHudViewController.h"
#import "OAOpenAddTrackViewController.h"
#import "OASearchToolbarViewController.h"
#import "OAWeatherLayerSettingsViewController.h"
#import "OAMapInfoController.h"
#import "OAMapViewController.h"
#import "OAGPXAppearanceCollection.h"
#import "OAMapSettingsTerrainParametersViewController.h"
#import "OADiscountToolbarViewController.h"
#import "OAGPXMutableDocument.h"
#import "OAPluginsHelper.h"
#import "OAApplicationMode.h"
#import "OARouteKey.h"
#import "OANetworkRouteSelectionTask.h"
#import <MBProgressHUD.h>
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/NetworkRouteContext.h>
#include <OsmAndCore/CachingRoadLocator.h>
#include <OsmAndCore/Data/Road.h>

#define _(name) OAMapPanelViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

#define kMaxRoadDistanceInMeters 1000
#define kMaxZoom 22.0f

static int MAX_ZOOM_OUT_STEPS = 2;

typedef enum
{
    EOATargetPoint = 0,
    EOATargetBBOX,
    
} EOATargetMode;

@interface OAMapPanelViewController () <OAParkingDelegate, OAWikiMenuDelegate, OAGPXWptViewControllerDelegate, OAToolbarViewControllerProtocol, OARouteCalculationProgressCallback, OATransportRouteCalculationProgressCallback, OARouteInformationListener, OAGpxWptEditingHandlerDelegate, OAOpenAddTrackDelegate>

@property (nonatomic) OAMapHudViewController *hudViewController;
@property (nonatomic) OAMapillaryImageViewController *mapillaryController;

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
    OADestinationsHelper *_destinationsHelper;

    OAAutoObserverProxy* _addonsSwitchObserver;
    OAAutoObserverProxy* _destinationRemoveObserver;
    OAAutoObserverProxy* _mapillaryChangeObserver;
    OAAutoObserverProxy *_weatherSettingsChangeObserver;
    OAAutoObserverProxy *_wikipediaChangeObserver;

    BOOL _mapNeedsRestore;
    OAMapMode _mainMapMode;
    OsmAnd::PointI _mainMapTarget31;
    float _mainMapZoom;
    float _mainMapAzimuth;
    float _mainMapElevationAngle;
    
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
    
    BOOL _reopenSettings;
    OAApplicationMode *_targetAppMode;
    
    OACarPlayActiveViewController *_carPlayActiveController;

    BOOL _isNewContextMenuStillEnabled;

    MBProgressHUD *_gpxProgress;
    OANetworkRouteSelectionTask *_gpxNetworkTask;
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
    _destinationsHelper = [OADestinationsHelper instance];
    _mapWidgetRegistry = [OAMapWidgetRegistry sharedInstance];
    _weatherToolbarStateChangeObservable = [[OAObservable alloc] init];

    _addonsSwitchObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                      withHandler:@selector(onAddonsSwitch:withKey:andValue:)
                                                       andObserve:_app.addonsSwitchObservable];

    _destinationRemoveObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                           withHandler:@selector(onDestinationRemove:withKey:)
                                                            andObserve:_app.data.destinationRemoveObservable];
    
    _mapillaryChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onMapillaryChanged)
                                                          andObserve:_app.data.mapillaryChangeObservable];

    _weatherSettingsChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onWeatherSettingsChange:withKey:andValue:)
                                                                andObserve:_app.data.weatherSettingsChangeObservable];

    _wikipediaChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                         withHandler:@selector(onWikipediaChange:withKey:andValue:)
                                                          andObserve:_app.data.wikipediaChangeObservable];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMapGestureAction:) name:kNotificationMapGestureAction object:nil];

    [_routingHelper addListener:self];
    [_routingHelper addCalculationProgressCallback:self];
    [OATransportRoutingHelper.sharedInstance addCalculationProgressCallback:self];
    
    _toolbars = [NSMutableArray array];
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
    if (([self contextMenuMode] && ![self.targetMenuView needsManualContextMode])
        || (_scrollableHudViewController && [_scrollableHudViewController getNavbarHeight] > 0))
    {
        [self.hudViewController updateControlsLayout:YES];
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
        _shadeView.frame = CGRectMake(0., 0., DeviceScreenWidth, DeviceScreenHeight);
}
 
@synthesize mapViewController = _mapViewController;

- (void) updateHUD:(BOOL)animated
{
    // Inflate new HUD controller
    if (!self.hudViewController)
    {
        self.hudViewController = [[OAMapHudViewController alloc] initWithNibName:@"OAMapHudViewController"
                                                                                             bundle:nil];

        self.hudViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
        [self addChildViewController:self.hudViewController];
        
        [self.view addSubview:self.hudViewController.view];
        [NSLayoutConstraint activateConstraints:@[
            [self.view.topAnchor constraintEqualToAnchor:self.hudViewController.view.topAnchor constant:0.],
            [self.view.leftAnchor constraintEqualToAnchor:self.hudViewController.view.leftAnchor constant:0.],
            [self.view.bottomAnchor constraintEqualToAnchor:self.hudViewController.view.bottomAnchor constant:0.],
            [self.view.rightAnchor constraintEqualToAnchor:self.hudViewController.view.rightAnchor constant:0.],
        ]];

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
    [_hudViewController updateDependentButtonsVisibility];
    [self enterContextMenuMode];
}

- (void) showScrollableHudViewController:(OABaseScrollableHudViewController *)controller
{
    [self.hudViewController hideWeatherToolbarIfNeeded];

    self.sidePanelController.recognizesPanGesture = NO;

    if ([controller isKindOfClass:OARoutePlanningHudViewController.class])
        _activeTargetType = OATargetRoutePlanning;
    else if ([controller isKindOfClass:OARouteLineAppearanceHudViewController.class])
        _activeTargetType = OATargetRouteLineAppearance;
    else if ([controller isKindOfClass:OAWeatherLayerSettingsViewController.class])
        _activeTargetType = OATargetWeatherLayerSettings;
    else if ([controller isKindOfClass:OAMapSettingsTerrainParametersViewController.class])
        _activeTargetType = OATargetTerrainParametersSettings;

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
    [self resetActiveTargetMenu];
    [self restoreFromContextMenuMode];
    [_hudViewController updateDependentButtonsVisibility];
}

- (void)showPlanRouteViewController:(OARoutePlanningHudViewController *)controller
{
    _activeTargetType = OATargetRoutePlanning;
    [self showScrollableHudViewController:controller];
}

- (void)showRouteLineAppearanceViewController:(OABaseScrollableHudViewController *)controller
{
    _activeTargetType = OATargetRouteLineAppearance;
    [self showScrollableHudViewController:controller];
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
    if (_dashboard || !_mapillaryController.view.hidden)
        return UIStatusBarStyleLightContent;
    else if (_targetMenuView != nil && _targetMenuView.customController != nil &&
                                        (_targetMenuView.targetPoint.type == OATargetImpassableRoadSelection ||
                                        _targetMenuView.targetPoint.type == OATargetRouteDetails ||
                                        _targetMenuView.targetPoint.type == OATargetRouteDetailsGraph ||
                                        _targetMenuView.targetPoint.type == OATargetTransportRouteDetails))
        return UIStatusBarStyleDefault;
    else if (_scrollableHudViewController)
        return _scrollableHudViewController.preferredStatusBarStyle;
    else if ([self isRouteInfoVisible] && [_routeInfoView isFullScreen])
        return [[ThemeManager shared] isLightTheme] ? UIStatusBarStyleDarkContent : UIStatusBarStyleLightContent;

    if (_customStatusBarStyleNeeded)
        return _customStatusBarStyle;
    
    if (self.hudViewController.mapInfoController.weatherToolbarVisible) {
        return [[ThemeManager shared] isLightTheme] ? UIStatusBarStyleDarkContent : UIStatusBarStyleLightContent;
    }

    UIStatusBarStyle style = self.hudViewController ? self.hudViewController.preferredStatusBarStyle : UIStatusBarStyleDefault;
    return [self.targetMenuView getStatusBarStyle:[self contextMenuMode] defaultStyle:style];
}

- (BOOL) hasGpxActiveTargetType
{
    return _activeTargetType == OATargetGPX || _activeTargetType == OATargetRouteStartSelection || _activeTargetType == OATargetRouteFinishSelection || _activeTargetType == OATargetRouteIntermediateSelection || _activeTargetType == OATargetImpassableRoadSelection || _activeTargetType == OATargetHomeSelection || _activeTargetType == OATargetWorkSelection || _activeTargetType == OATargetRouteDetails || _activeTargetType == OATargetRouteDetailsGraph;
}

- (void) onMapillaryChanged
{
    if (!_app.data.mapillary)
        [_mapillaryController hideMapillaryView];
}

- (void) onWeatherSettingsChange:(id)observer withKey:(id)key andValue:(id)value
{
    NSString *operation = (NSString *) key;
    if ([operation isEqualToString:kWeatherSettingsChanging])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            _activeTargetType = self.hudViewController.mapInfoController.weatherToolbarVisible ? OATargetWeatherToolbar : OATargetNone;
        });
    }
}

- (void) onWikipediaChange:(id)observer withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_mapViewController updatePoiLayer];
        [self refreshMap];
    });
}

- (void) onAddonsSwitch:(id)observable withKey:(id)key andValue:(id)value
{
    NSString *productIdentifier = key;
    if ([productIdentifier isEqualToString:kInAppId_Addon_Srtm] || [productIdentifier isEqualToString:kInAppId_Addon_Nautical])
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
        _mainMapElevationAngle = renderView.elevationAngle;
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
    _mainMapElevationAngle = renderView.elevationAngle;
}

- (void) prepareMapForReuse:(Point31)destinationPoint zoom:(CGFloat)zoom newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated
{
    [self saveMapStateIfNeeded];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;

    if (isnan(zoom))
        zoom = renderView.zoom;
    if (zoom > kMaxZoom)
        zoom = kMaxZoom;
    
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
        if (zoom > kMaxZoom)
            zoom = kMaxZoom;
        
        [_mapViewController goToPosition:center
                                 andZoom:zoom
                                animated:animated];
    }
    
    
    renderView.azimuth = newAzimuth;
    renderView.elevationAngle = newElevationAngle;
}

- (CGFloat)getZoomForBounds:(OAGpxBounds)mapBounds mapSize:(CGSize)mapSize
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
    if (zoom > kMaxZoom)
        zoom = kMaxZoom;
    
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
        if (zoom > kMaxZoom)
            zoom = kMaxZoom;
        
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
    mapView.elevationAngle = _mainMapElevationAngle;
    
    _mapViewController.minimap = NO;
}

- (void) restoreMapAfterReuseAnimated
{
    _app.mapMode = _mainMapMode;
 
    if (_mainMapMode == OAMapModeFree || _mainMapMode == OAMapModeUnknown)
    {
        OAMapRendererView* mapView = (OAMapRendererView*)_mapViewController.view;
        mapView.azimuth = _mainMapAzimuth;
        mapView.elevationAngle = _mainMapElevationAngle;
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

- (void) openDestinationViewController
{
    OADestinationsListViewController *destinationsListViewController = [[OADestinationsListViewController alloc] init];
    [self.navigationController pushViewController:destinationsListViewController animated:YES];
}

- (void) swapStartAndFinish
{
    [_routeInfoView switchStartAndFinish];
}

- (void) hideContextMenu
{
    [self targetHideMenu:.2 backButtonClicked:NO onComplete:^{
        [_hudViewController updateDependentButtonsVisibility];
    }];
}

- (BOOL) isContextMenuVisible
{
    return (_targetMenuView && _targetMenuView.superview && !_targetMenuView.hidden)
        || self.isTargetMultiMenuViewVisible
        || (_scrollableHudViewController && _scrollableHudViewController.view.superview);
}

- (BOOL) isTargetMultiMenuViewVisible
{
    return _targetMultiMenuView && _targetMultiMenuView.superview;
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
            OAMainSettingsViewController *settingsVC = [[OAMainSettingsViewController alloc] initWithTargetAppMode:_targetAppMode
                                                                                                   targetScreenKey:nil];
            [OARootViewController.instance.navigationController pushViewController:settingsVC animated:NO];
        }
        _targetAppMode = nil;
        _reopenSettings = NO;
        
        _dashboard = nil;

        [self.targetMenuView quickShow];

        self.sidePanelController.recognizesPanGesture = NO; //YES;

        if (_prevScrollableHudViewController)
        {
             [self showScrollableHudViewController:_prevScrollableHudViewController];
            _prevScrollableHudViewController = nil;
        }
    }
}

- (void) closeRouteInfo
{
    [self closeRouteInfo:YES onComplete:nil];
}

- (void) closeRouteInfo:(BOOL)topControlsVisibility onComplete:(void (^)(void))onComplete
{
    [self closeRouteInfoWithTopControlsVisibility:topControlsVisibility bottomsControlHeight:@0 onComplete:onComplete];
}

- (void) closeRouteInfoWithTopControlsVisibility:(BOOL)topControlsVisibility bottomsControlHeight:(NSNumber *)bottomsControlHeight onComplete:(void (^)(void))onComplete
{
    if (self.routeInfoView.superview)
    {
        [self.routeInfoView hide:YES duration:.2 onComplete:^{
            [_hudViewController updateControlsLayout:YES];
            [_hudViewController updateDependentButtonsVisibility];
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
        [self.routeInfoView hide:YES duration:.2 onComplete:^{
            [_hudViewController updateControlsLayout:YES];
            [_hudViewController updateDependentButtonsVisibility];
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

- (BOOL)isDashboardVisible
{
    return _dashboard != nil;
}

- (void)closeDashboardLastScreen
{
    if (_dashboard)
    {
        NSObject *lastMapSettingsCtrl = [self.childViewControllers lastObject];
        if (lastMapSettingsCtrl && [lastMapSettingsCtrl isKindOfClass:OADashboardViewController.class])
            [((OADashboardViewController *) lastMapSettingsCtrl) onLeftNavbarButtonPressed];
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

    if (_scrollableHudViewController)
    {
        _prevScrollableHudViewController = _scrollableHudViewController;
        [self hideScrollableHudViewController];
    }

    [self.hudViewController hideWeatherToolbarIfNeeded];

    _dashboard = [[OAMapSettingsViewController alloc] init];
    [_dashboard show:self parentViewController:nil animated:YES];
    
    [self createShadowButton:@selector(closeDashboard) withLongPressEvent:nil topView:_dashboard.view];
    
    [self targetHideContextPinMarker];
    [self hideContextMenu];

    self.sidePanelController.recognizesPanGesture = NO;
}


- (void) showMapStylesScreen
{
    [self showMapSettingsScreen:EMapSettingsScreenMapType logEvent:@"configure_map_styles_open"];
}

- (void) showWeatherLayersScreen
{
    [self showMapSettingsScreen:EMapSettingsScreenMain logEvent:nil];
    OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenWeather];
    [mapSettingsViewController show:_dashboard.parentViewController parentViewController:_dashboard animated:YES];
}

- (void) showTerrainScreen
{
    [self showMapSettingsScreen:EMapSettingsScreenMain logEvent:nil];
    OAMapSettingsViewController *mapSettingsViewController = [[OAMapSettingsViewController alloc] initWithSettingsScreen:EMapSettingsScreenTerrain];
    [mapSettingsViewController show:_dashboard.parentViewController parentViewController:_dashboard animated:YES];
}

- (void)showMapSettingsScreen:(EMapSettingsScreen)screen logEvent:(nullable NSString *)event
{
    if (event)
        [OAAnalyticsHelper logEvent:event];
    
    _targetAppMode = nil;
    _reopenSettings = _targetAppMode != nil;
    
    [self removeGestureRecognizers];
    
    _dashboard = [[OAMapSettingsViewController alloc] initWithSettingsScreen:screen];
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
    
//    _targetAppMode = targetMode;
//    _reopenSettings = _targetAppMode != nil;
//
//    [self removeGestureRecognizers];
    
    OAConfigureScreenViewController *vc = [[OAConfigureScreenViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
    
//    _dashboard = [[OAConfigureMenuViewController alloc] init];
//    [_dashboard show:self parentViewController:nil animated:YES];
//
//    [self createShadowButton:@selector(closeDashboard) withLongPressEvent:nil topView:_dashboard.view];
    
//    [self.targetMenuView quickHide];
    
//    self.sidePanelController.recognizesPanGesture = NO;
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

- (void) showTravelGuides
{
    if ([OAIAPHelper isPaidVersion])
        [self.navigationController pushViewController:[OATravelExploreViewController new] animated:YES];
    else
        [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.WIKIVOYAGE navController:[OARootViewController instance].navigationController];
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
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:routePrefs];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void) showRouteInfo
{
    [self showRouteInfo:YES];
}

- (void) showRouteInfo:(BOOL)fullMenu
{
    [OAAnalyticsHelper logEvent:@"route_info_open"];

    [self removeGestureRecognizers];

    [self.hudViewController hideWeatherToolbarIfNeeded];

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
    [_hudViewController updateDependentButtonsVisibility];
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

- (void) updateRouteInfoData
{
    if ([self isRouteInfoVisible])
        [self.routeInfoView update];
}

- (void) updateTargetDescriptionLabel
{
    [self.targetMenuView updateDescriptionLabel];
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
    [[OARootViewController instance].keyCommandUpdateObserver handleObservedEventFrom:nil withKey:kCommandSearchScreenOpen];

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
    _searchViewController.fromNavigation = [self isRouteInfoVisible];
    __weak OAMapPanelViewController *selfWeak = self;
    _searchViewController.onCloseCallback = ^{
        [selfWeak clearSearchViewController];
    };

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
    navController.edgesForExtendedLayout = UIRectEdgeNone;

    if (_scrollableHudViewController && [_scrollableHudViewController isKindOfClass:OARoutePlanningHudViewController.class])
        _isNewContextMenuStillEnabled = YES;

    [self presentViewController:navController animated:YES completion:nil];
}

- (void)clearSearchViewController
{
    _searchViewController = nil;
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
    if (_activeTargetType == OATargetGPX && _scrollableHudViewController)
        [_scrollableHudViewController forceHide];

    if (self.isNewContextMenuDisabled)
        return;

    [self.hudViewController hideWeatherToolbarIfNeeded];

    NSMutableArray<OATargetPoint *> *validPoints = [NSMutableArray array];
        
    if (_activeTargetType == OATargetRouteIntermediateSelection && targetPoints.count > 1)
    {
        [validPoints addObjectsFromArray:targetPoints];
    }
    else
    {
        for (OATargetPoint *targetPoint in targetPoints)
        {
            if ([self processTargetPoint:targetPoint])
                [validPoints addObject:targetPoint];
        }
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
    || (_activeTargetType == OATargetRoutePlanning && !_isNewContextMenuStillEnabled)
    || _activeTargetType == OATargetGPX
    || _activeTargetType == OATargetRouteLineAppearance
    || _activeTargetType == OATargetWeatherLayerSettings
    || _activeTargetType == OATargetWeatherToolbar
    || _activeTargetType == OATargetTerrainParametersSettings;
}

- (void)showContextMenu:(OATargetPoint *)targetPoint saveState:(BOOL)saveState preferredZoom:(float)preferredZoom
{
    if (_activeTargetType == OATargetGPX)
        [self hideScrollableHudViewController];

    if (self.isNewContextMenuDisabled)
        return;

    _isNewContextMenuStillEnabled = NO;
    
    if (targetPoint.type == OATargetMapillaryImage)
    {
        [self.hudViewController hideWeatherToolbarIfNeeded];

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
            [self goToTargetPointWithZoom:preferredZoom];
        
        if (_targetMenuView.needsManualContextMode)
            [self enterContextMenuMode];
    }];
}

- (void) setupNetworkGpxProgress
{
    _gpxProgress = [[MBProgressHUD alloc] initWithView:self.view];
    _gpxProgress.minShowTime = .3;
    _gpxProgress.removeFromSuperViewOnHide = YES;
    _gpxProgress.labelText = OALocalizedString(@"shared_string_loading");
    _gpxProgress.labelFont = [UIFont scaledSystemFontOfSize:22. weight:UIFontWeightSemibold];
    _gpxProgress.detailsLabelText = OALocalizedString(@"shared_string_cancel");
    _gpxProgress.detailsLabelFont = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    _gpxProgress.detailsLabelColor = UIColor.blackColor;
    _gpxProgress.labelColor = UIColor.blackColor;
    [[UIActivityIndicatorView appearanceWhenContainedInInstancesOfClasses:@[[MBProgressHUD class]]] setColor:UIColor.blackColor];
    _gpxProgress.color = UIColor.whiteColor;
    [self.view addSubview:_gpxProgress];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onCancelNetworkGPX)];
    [_gpxProgress addGestureRecognizer:tap];
}

- (void)hideProgress
{
    [_gpxProgress hide:YES];
    _gpxProgress = nil;
    [[UIActivityIndicatorView appearanceWhenContainedInInstancesOfClasses:@[[MBProgressHUD class]]] setColor:UIColor.whiteColor];
}

- (void) onCancelNetworkGPX
{
    [_gpxNetworkTask setCancelled:YES];
    _gpxNetworkTask = nil;
    [self hideProgress];
}

- (void) showContextMenu:(OATargetPoint *)targetPoint
{
    if (targetPoint.type == OATargetGPX)
    {
        [self openTargetViewWithGPX:targetPoint.targetObj
                              items:nil
                           routeKey:nil
                       trackHudMode:EOATrackMenuHudMode
                              state:[OATrackMenuViewControllerState withPinLocation:targetPoint.location
                                                                      openedFromMap:[targetPoint.values[@"opened_from_map"] boolValue]]];
    }
    else if (targetPoint.type == OATargetNetworkGPX)
    {
        [self setupNetworkGpxProgress];
        [_gpxProgress show:YES];
        __weak OAMapPanelViewController *weakSelf = self;
        _gpxNetworkTask = [[OANetworkRouteSelectionTask alloc] initWithRouteKey:targetPoint.targetObj area:targetPoint.values[@"area"]];
        [_gpxNetworkTask execute:^(OAGPXDocument *gpxFile) {
            [weakSelf hideProgress];
            if (!gpxFile)
                return;
            OAGPXDatabase *db = [OAGPXDatabase sharedDb];
            OARouteKey *key = (OARouteKey *)targetPoint.targetObj;
            NSString *name = key.routeKey.getRouteName().toNSString();
            name = name.length == 0 ? OALocalizedString(@"layer_route") : name;
            NSString *folderPath = [_app.gpxPath stringByAppendingPathComponent:@"Temp"];
            NSFileManager *manager = NSFileManager.defaultManager;
            if (![manager fileExistsAtPath:folderPath])
                [manager createDirectoryAtPath:folderPath withIntermediateDirectories:NO attributes:nil error:nil];
            NSString *path = [[folderPath stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"gpx"];
            gpxFile.path = path;
            gpxFile.metadata.name = targetPoint.title;
            [gpxFile saveTo:path];
            [weakSelf.mapViewController showTempGpxTrackFromDocument:gpxFile];
            OAGPX *gpx = [db buildGpxItem:[path stringByReplacingOccurrencesOfString:_app.gpxPath withString:@""] title:name desc:gpxFile.metadata.desc bounds:gpxFile.bounds document:gpxFile fetchNearestCity:NO];
            OATrackMenuViewControllerState *state = [OATrackMenuViewControllerState withPinLocation:targetPoint.location
                                                                                      openedFromMap:YES];
            state.trackIcon = targetPoint.icon;
            [weakSelf openTargetViewWithGPX:gpx
                                      items:nil
                               routeKey:targetPoint.targetObj
                           trackHudMode:EOATrackMenuHudMode
                                  state:state];
        }];
    }
    else
    {
        [self showContextMenu:targetPoint saveState:YES preferredZoom:PREFERRED_FAVORITE_ZOOM];
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
        case OATargetGPX:
        {
            if (isNone)
            {
                [self.scrollableHudViewController forceHide];
                return NO;
            }
            else if (!isWaypoint)
            {
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

- (void) moveMapToLat:(double)lat lon:(double)lon zoom:(int)zoom withTitle:(NSString *)title
{
    UIViewController *top = self.rootViewController.navigationController.topViewController;
    if (![top isKindOfClass:[JASidePanelController class]])
        [self.rootViewController.navigationController popToRootViewControllerAnimated:NO];

    if (self.rootViewController.state != JASidePanelCenterVisible)
        [self.rootViewController showCenterPanelAnimated:NO];

    [self closeDashboard];

    Point31 pos31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon))];
    OATargetPoint *targetPoint = [self.mapViewController.mapLayers.contextMenuLayer getUnknownTargetPoint:lat longitude:lon];
    if (title.length > 0)
        targetPoint.title = title;

    [self showContextMenu:targetPoint];
    [self.mapViewController goToPosition:pos31 andZoom:zoom animated:NO];
}

- (void) goToTargetPointDefault
{
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    renderView.azimuth = 0.0;
    renderView.elevationAngle = 90.0;
    renderView.zoom = kDefaultFavoriteZoomOnShow;
    
    _mainMapAzimuth = 0.0;
    _mainMapElevationAngle = 90.0;
    _mainMapZoom = kDefaultFavoriteZoomOnShow;
    
    [self targetGoToPoint];
}

- (CGSize)getScreenBBox
{
    BOOL landscape = [self.scrollableHudViewController isLandscape];
    return CGSizeMake(landscape ? DeviceScreenWidth - [self.scrollableHudViewController getLandscapeViewWidth] : DeviceScreenWidth,
                      landscape ? DeviceScreenHeight : DeviceScreenHeight - [self.scrollableHudViewController getViewHeight]);
}

- (void)goToTargetPointWithZoom:(float)zoom
{
    OAMapRendererView *renderView = (OAMapRendererView*)_mapViewController.view;
    renderView.azimuth = 0.0;
    renderView.elevationAngle = 90.0;
    
    CLLocationCoordinate2D topLeft = _targetMenuView.targetPoint.location;
    CLLocationCoordinate2D bottomRight = [_mapViewController getMapLocation].coordinate;
        
    OAGpxBounds bounds;
    bounds.topLeft = topLeft; // search point
    bounds.bottomRight = bottomRight; // map center
    bounds.center.latitude = bottomRight.latitude / 2.0 + topLeft.latitude / 2.0;
    bounds.center.longitude = bottomRight.longitude / 2.0 + topLeft.longitude / 2.0;
    
    float currentZoom = MIN([self getZoomForBounds:bounds mapSize:[self getScreenBBox]], zoom);
    if (currentZoom != zoom && currentZoom < zoom - MAX_ZOOM_OUT_STEPS)
    {
        currentZoom = zoom;
    }
        
    renderView.zoom = currentZoom;
    
    _mainMapAzimuth = 0.0;
    _mainMapElevationAngle = 90.0;
    _mainMapZoom = currentZoom;
    
    [self targetGoToPoint];
}

- (void) goToTargetPointMapillary
{
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    renderView.azimuth = 0.0;
    renderView.elevationAngle = 90.0;
    renderView.zoom = kDefaultMapillaryZoomOnShow;
    
    _mainMapAzimuth = 0.0;
    _mainMapElevationAngle = 90.0;
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

- (void) targetUpdateControlsLayout:(BOOL)customStatusBarStyleNeeded
               customStatusBarStyle:(UIStatusBarStyle)customStatusBarStyle
{
    [_hudViewController updateControlsLayout:YES];
    _customStatusBarStyle = customStatusBarStyle;
    _customStatusBarStyleNeeded = customStatusBarStyleNeeded;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL) isTopControlsVisible
{
    return _hudViewController.mapSettingsButton.alpha > 0;
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
    [self.hudViewController enterContextMenuMode];
}

- (void) restoreFromContextMenuMode
{
    [self.hudViewController restoreFromContextMenuMode];
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
    
    _shadeView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., DeviceScreenWidth, DeviceScreenHeight)];
    _shadeView.backgroundColor = UIColorFromRGBA(0x00000060);
    _shadeView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _shadeView.alpha = 0.;
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
         [_hudViewController.floatingButtonsController hideActionsSheetAnimated:nil];
 }

- (void) updateTargetPointPosition:(CGFloat)height animated:(BOOL)animated
{
    if ((![self.targetMenuView isLandscape] && self.targetMenuView.showFullScreen) || (self.targetMenuView.targetPoint.type == OATargetImpassableRoadSelection && !_routingHelper.isRouteCalculated) || self.targetMenuView.targetPoint.type == OATargetRouteDetailsGraph || self.targetMenuView.targetPoint.type == OATargetChangePosition)
        return;
    
    Point31 targetPoint31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(_targetLatitude, _targetLongitude))];
    [_mapViewController correctPosition:targetPoint31 originalCenter31:[OANativeUtilities convertFromPointI:_mainMapTarget31] leftInset:([self.targetMenuView isLandscape] ? self.targetMenuView.frame.size.width + 20.0 : 0.0) bottomInset:([self.targetMenuView isLandscape] ? 0.0 : height) centerBBox:(_targetMode == EOATargetBBOX) animated:animated];
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
    [_mapViewController zoomIn];
}

- (void) targetZoomOut
{
    [_mapViewController zoomOut];
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

- (OAPOI *) getTargetPointPoi
{
    OAPOI *poi = nil;
    if ([self.targetMenuView.targetPoint.targetObj isKindOfClass:OAPOI.class])
    {
        poi = self.targetMenuView.targetPoint.targetObj;
    }
    else if ([self.targetMenuView.targetPoint.targetObj isKindOfClass:OATransportStop.class])
    {
        OATransportStop *transportStop = self.targetMenuView.targetPoint.targetObj;
        poi = transportStop.poi;
    }
    else if ([self.targetMenuView.targetPoint.targetObj isKindOfClass:OAGpxWptItem.class])
    {
        OAGpxWptItem *wptItem = self.targetMenuView.targetPoint.targetObj;
        poi = [wptItem.point getAmenity];
    }
    return poi;
}

- (void) targetPointAddFavorite
{
    [self targetHideContextPinMarker];
    [self targetHideMenu:.3 backButtonClicked:YES onComplete:nil];
    
    OAPOI *poi = [self getTargetPointPoi];
    OAEditPointViewController *controller =
            [[OAEditPointViewController alloc] initWithLocation:self.targetMenuView.targetPoint.location
                                                          title:self.targetMenuView.targetPoint.title
                                                        address:self.targetMenuView.targetPoint.titleAddress
                                                    customParam:nil
                                                      pointType:EOAEditPointTypeFavorite
                                                targetMenuState:nil
                                                            poi:poi];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}

- (void) targetPointEditFavorite:(OAFavoriteItem *)item
{
    [self targetHideContextPinMarker];
    [self targetHideMenu:.3 backButtonClicked:YES onComplete:nil];
    OAEditPointViewController *controller = [[OAEditPointViewController alloc] initWithFavorite:item];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}

- (void) targetPointShare
{
}

- (void) addMapMarker:(double)lat lon:(double)lon description:(NSString *)descr
{
    OADestination *destination = [[OADestination alloc] initWithDesc:descr latitude:lat longitude:lon];
    [_mapViewController hideContextPinMarker];
    [_destinationsHelper addDestinationWithNewColor:destination];
    [_destinationsHelper moveDestinationOnTop:destination wasSelected:NO];
}

- (void) targetPointDirection
{
    if (_targetDestination)
    {
        if (self.targetMenuView.targetPoint.type != OATargetDestination && self.targetMenuView.targetPoint.type != OATargetParking)
            return;
        
        if (self.targetMenuView.targetPoint.type == OATargetParking)
        {
            OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPluginsHelper getPlugin:OAParkingPositionPlugin.class];
            if (plugin)
                [plugin clearParkingPosition];
            [self targetHideContextPinMarker];
        }
        else
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_destinationsHelper addHistoryItem:_targetDestination];
                [_destinationsHelper removeDestination:_targetDestination];
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

        UIColor *color = [_destinationsHelper addDestinationWithNewColor:destination];
        if (color)
        {
            [_mapViewController hideContextPinMarker];
            [_destinationsHelper moveDestinationOnTop:destination wasSelected:NO];
        }
        else
        {
            [self showDistinationAlert];
        }
    }
    
    [self hideTargetPointMenu];
}

- (void)showDistinationAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"cannot_add_destination") message:OALocalizedString(@"cannot_add_marker_desc") preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
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
        NSString *path = gpx.absolutePath;
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
                NSString *path = gpx.absolutePath;
                [self targetPointAddWaypoint:path];
            }
            else
            {
                [self targetPointAddWaypoint:nil];
            }
            return;
        }
        OAOpenAddTrackViewController *saveTrackViewController = [[OAOpenAddTrackViewController alloc] initWithScreenType:EOASelectTrack showCurrent:YES];
        saveTrackViewController.delegate = self;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:saveTrackViewController];
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
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
    
    OAPOI *poi = [self getTargetPointPoi];
    OAEditPointViewController *controller = [[OAEditPointViewController alloc] initWithLocation:location
                                                                                          title:title
                                                                                        address:self.targetMenuView.targetPoint.titleAddress
                                                                                    customParam:gpxFileName
                                                                                      pointType:EOAEditPointTypeWaypoint
                                                                                targetMenuState:_activeViewControllerState
                                                                            poi:poi];
    controller.gpxWptDelegate = self;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
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
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
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
    [self showScrollableHudViewController:[[OARoutePlanningHudViewController alloc] initWithInitialPoint:[[CLLocation alloc]
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

- (void) targetViewOnAppear:(CGFloat)height animated:(BOOL)animated
{
    [self updateTargetPointPosition:height animated:animated];
}

- (void) targetViewHeightChanged:(CGFloat)height animated:(BOOL)animated
{
    [self updateTargetPointPosition:height animated:animated];
}

- (void) showTargetPointMenu:(BOOL)saveMapState showFullMenu:(BOOL)showFullMenu
{
    [self showTargetPointMenu:saveMapState showFullMenu:showFullMenu onComplete:^{
        if (_targetMenuView.needsManualContextMode)
            [self enterContextMenuMode];
    }];
}

- (void)hideMultiMenuIfNeeded {
    if (self.targetMultiMenuView.superview)
        [self.targetMultiMenuView hide:YES duration:.2 onComplete:^{
            [_hudViewController updateDependentButtonsVisibility];
        }];
}

- (void) showTargetPointMenu:(BOOL)saveMapState showFullMenu:(BOOL)showFullMenu onComplete:(void (^)(void))onComplete
{
    [self.hudViewController hideWeatherToolbarIfNeeded];
    [self hideMultiMenuIfNeeded];

    if (_scrollableHudViewController)
    {
        _prevScrollableHudViewController = _scrollableHudViewController;
        [self hideScrollableHudViewController];
    }

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
    
    if (onComplete)
        onComplete();
    
    self.sidePanelController.recognizesPanGesture = NO;
    [_hudViewController updateDependentButtonsVisibility];
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
    
    [self.targetMultiMenuView setActiveTargetType:_activeTargetType];
    [self.targetMultiMenuView setTargetPoints:points];
    
    [self.view addSubview:self.targetMultiMenuView];
    
    if (onComplete)
        onComplete();
    
    self.sidePanelController.recognizesPanGesture = NO;
    [self.targetMultiMenuView show:YES onComplete:^{
        [_hudViewController updateDependentButtonsVisibility];
        self.sidePanelController.recognizesPanGesture = NO;
    }];
}

- (void) targetHideMenuByMapGesture
{
    [self hideTargetPointMenu:.2 onComplete:nil hideActiveTarget:NO mapGestureAction:YES];
}

- (void) targetStatusBarChanged
{
    [self setNeedsStatusBarAppearanceUpdate];
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
            [_hudViewController updateDependentButtonsVisibility];
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

        if (_prevScrollableHudViewController)
        {
            [self showScrollableHudViewController:_prevScrollableHudViewController];
            _prevScrollableHudViewController = nil;
        }
        else
        {
            [_hudViewController updateDependentButtonsVisibility];
        }
    }];
    
    [_hudViewController updateControlsLayout:YES];
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
            && self.targetMenuView.targetPoint.type == OATargetFavorite)
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

        [_hudViewController updateDependentButtonsVisibility];
    }];
    
    [_hudViewController updateControlsLayout:YES];
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
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
    }];
}

- (OATargetPoint *) getCurrentTargetPoint
{
    if (_targetMenuView.superview)
        return _targetMenuView.targetPoint;
    else
        return nil;
}

- (void)openTargetViewWithFavorite:(OAFavoriteItem *)item
                             pushed:(BOOL)pushed
                          saveState:(BOOL)saveState
                      preferredZoom:(float)preferredZoom
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
        [self enterContextMenuMode];
        
        [self showTargetPointMenu:saveState showFullMenu:NO onComplete:^{
            [self goToTargetPointWithZoom:preferredZoom];
        }];
    }
}

- (void)openTargetViewWithFavorite:(OAFavoriteItem *)item pushed:(BOOL)pushed
{
    return [self openTargetViewWithFavorite:item pushed:pushed saveState:YES preferredZoom:PREFERRED_FAVORITE_ZOOM];
}

- (void)openTargetViewWithFavorite:(OAFavoriteItem *)item pushed:(BOOL)pushed saveState:(BOOL)saveState
{
    return [self openTargetViewWithFavorite:item pushed:pushed saveState:saveState preferredZoom:PREFERRED_FAVORITE_ZOOM];
}

- (void)openTargetViewWithAddress:(OAAddress *)address name:(NSString *)name typeName:(NSString *)typeName pushed:(BOOL)pushed preferredZoom:(float)preferredZoom
{
    return [self openTargetViewWithAddress:address name:name typeName:typeName pushed:pushed saveState:YES preferredZoom:preferredZoom];
}

- (void)openTargetViewWithAddress:(OAAddress *)address
                             name:(NSString *)name
                         typeName:(NSString *)typeName
                           pushed:(BOOL)pushed
                        saveState:(BOOL)saveState
                    preferredZoom:(float)preferredZoom
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
    _targetZoom = 17.0;
    
    targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
    targetPoint.title = caption;
    targetPoint.titleAddress = description;
    targetPoint.icon = icon;
    targetPoint.toolbarNeeded = pushed;
    targetPoint.targetObj = address;
    
    [_targetMenuView setTargetPoint:targetPoint];
    
    [self showTargetPointMenu:saveState showFullMenu:NO onComplete:^{
        [self goToTargetPointWithZoom:preferredZoom];
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
        [self goToTargetPointWithZoom:item.preferredZoom];

        if (_targetMenuView.needsManualContextMode)
            [self enterContextMenuMode];
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
    targetPoint.type = OATargetWpt;
    _targetMenuView.isAddressFound = YES;
    _formattedTargetName = caption;
    _targetMode = EOATargetPoint;
    _targetLatitude = lat;
    _targetLongitude = lon;
    _targetZoom = 0.0;
    
    targetPoint.location = CLLocationCoordinate2DMake(lat, lon);
    targetPoint.title = _formattedTargetName;
    targetPoint.toolbarNeeded = pushed;
    targetPoint.targetObj = item;
    
    [_targetMenuView setTargetPoint:targetPoint];
    
    if (pushed && _activeTargetActive && [self hasGpxActiveTargetType])
        _activeTargetChildPushed = YES;

    [self showTargetPointMenu:saveState showFullMenu:showFullMenu onComplete:^{
        [self goToTargetPointDefault];
    }];
}

- (void)openRecordingTrackTargetView
{
    [self openTargetViewWithGPX:nil];
}

- (void)openTargetViewWithGPX:(OAGPX *)item
{
    [self openTargetViewWithGPX:item
                   trackHudMode:EOATrackMenuHudMode
                          state:[_activeViewControllerState isKindOfClass:OATrackMenuViewControllerState.class]
                                  ? _activeViewControllerState
                                  : [OATrackMenuViewControllerState withPinLocation:item.bounds.center
                                                                      openedFromMap:NO]];
}

- (void)openTargetViewWithGPXFromTracksList:(OAGPX *)item
                       navControllerHistory:(NSArray<UIViewController *> *)navControllerHistory
                              fromTrackMenu:(BOOL)fromTrackMenu
                                selectedTab:(EOATrackMenuHudTab)selectedTab
{
    OATrackMenuViewControllerState *state = [OATrackMenuViewControllerState withPinLocation:item.bounds.center openedFromMap:NO];
    state.openedFromTracksList = YES;
    state.openedFromTrackMenu = fromTrackMenu;
    state.navControllerHistory = navControllerHistory;
    state.lastSelectedTab = selectedTab;
    [self openTargetViewWithGPX:item trackHudMode:EOATrackMenuHudMode state:state];
}

- (void)openTargetViewWithGPX:(OAGPX *)item selectedTab:(EOATrackMenuHudTab)selectedTab selectedStatisticsTab:(EOATrackMenuHudSegmentsStatisticsTab)selectedStatisticsTab openedFromMap:(BOOL)openedFromMap
{
    OATrackMenuViewControllerState *state = [OATrackMenuViewControllerState withPinLocation:item.bounds.center openedFromMap:openedFromMap];
    state.lastSelectedTab = selectedTab;
    state.selectedStatisticsTab = selectedStatisticsTab;
    [self openTargetViewWithGPX:item
                   trackHudMode:EOATrackMenuHudMode
                          state:state];
}

- (void)openTargetViewWithGPX:(OAGPX *)item
                 trackHudMode:(EOATrackHudMode)trackHudMode
                        state:(OATrackMenuViewControllerState *)state;
{
    [self openTargetViewWithGPX:item items:nil routeKey:nil trackHudMode:trackHudMode state:state];
}

- (void)openTargetViewWithGPX:(OAGPX *)item
                        items:(NSArray<OAGPX *> *)items
                 trackHudMode:(EOATrackHudMode)trackHudMode
                        state:(OATrackMenuViewControllerState *)state;
{
    [self openTargetViewWithGPX:item items:items routeKey:nil trackHudMode:trackHudMode state:state];
}

- (void)openTargetViewWithGPX:(OAGPX *)item
                        items:(NSArray<OAGPX *> *)items
                     routeKey:(OARouteKey *)routeKey
                 trackHudMode:(EOATrackHudMode)trackHudMode
                        state:(OATrackMenuViewControllerState *)state;
{
    if (_scrollableHudViewController)
    {
        [_scrollableHudViewController hide:YES duration:0.2 onComplete:^{
            state.pinLocation = item.bounds.center;
            if (!state.openedFromTrackMenu)
                state.navControllerHistory = nil;
            [self doShowGpxItem:item items:items routeKey:routeKey state:state trackHudMode:trackHudMode];
        }];
        return;
    }
    [self doShowGpxItem:item items:items routeKey:routeKey state:state trackHudMode:trackHudMode];
}

- (void)doShowGpxItem:(OAGPX *)item
                items:(NSArray<OAGPX *> *)items
             routeKey:(OARouteKey *)routeKey
                state:(OATrackMenuViewControllerState *)state
         trackHudMode:(EOATrackHudMode)trackHudMode
{
    BOOL showCurrentTrack = item == nil || !item.gpxFileName || item.gpxFileName.length == 0 || [item.gpxTitle isEqualToString:OALocalizedString(@"shared_string_currently_recording_track")];
    if (showCurrentTrack)
    {
        if (item == nil)
            item = [[OASavingTrackHelper sharedInstance] getCurrentGPX];
        if (!item.gpxTitle || item.gpxTitle.length == 0)
            item.gpxTitle = OALocalizedString(@"shared_string_currently_recording_track");
    }

    [self hideMultiMenuIfNeeded];
    [self hideTargetPointMenu];

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
    targetPoint.icon = state.trackIcon;
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
            if (items)
            {
                trackMenuHudViewController = [[OATrackMenuAppearanceHudViewController alloc] initWithGpx:item tracks:items state:state];
            }
            else
            {
                trackMenuHudViewController = [[OATrackMenuAppearanceHudViewController alloc] initWithGpx:item state:state];
            }
            break;
        }
        default:
        {
            trackMenuHudViewController = [[OATrackMenuHudViewController alloc] initWithGpx:item
                                                                                  routeKey:routeKey
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
    
    [UIApplication.sharedApplication.mainWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
    
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
    [UIApplication.sharedApplication.mainWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
    
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

- (void) openTargetViewFromTracksListWithRouteDetailsGraph:(NSString *)gpxFilepath
                                            isCurrentTrack:(BOOL)isCurrentTrack
                                                     state:(OATrackMenuViewControllerState *)state;
{
    OAGPXDocument *doc = isCurrentTrack ? [OASavingTrackHelper.sharedInstance currentTrack] : [[OAGPXDocument alloc] initWithGpxFile:gpxFilepath];
    if (doc)
    {
        OAGPXTrackAnalysis *analysis = !isCurrentTrack && [doc getGeneralTrack] && [doc getGeneralSegment]
            ? [OAGPXTrackAnalysis segment:0 seg:doc.generalSegment]
            : [doc getAnalysis:0];
        state.scrollToSectionIndex = -1;
        state.routeStatistics = @[@(GPXDataSetTypeAltitude), @(GPXDataSetTypeSpeed)];
        [self openTargetViewWithRouteDetailsGraph:doc analysis:analysis menuControlState:state];
    }
}

- (void) openTargetViewWithRouteDetailsGraph:(OAGPXDocument *)gpx
                                    analysis:(OAGPXTrackAnalysis *)analysis
                            menuControlState:(OATargetMenuViewControllerState *)menuControlState
{
    [self openTargetViewWithRouteDetailsGraph:gpx analysis:analysis menuControlState:menuControlState isRoute:YES];
}

- (void) openTargetViewWithRouteDetailsGraph:(OAGPXDocument *)gpx
                                    analysis:(OAGPXTrackAnalysis *)analysis
                            menuControlState:(OATargetMenuViewControllerState *)menuControlState
                                     isRoute:(BOOL)isRoute
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
        targetPoint.targetObj = @{@"gpx" : gpx, @"analysis" : analysis, @"route" : @(isRoute)};
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

    [self displayAreaOnMap:item.bounds
                      zoom:0.
                screenBBox:[self getScreenBBox]
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
    [self displayAreaOnMap:topLeft
               bottomRight:bottomRight
                      zoom:zoom
                   maxZoom:kMaxZoom
                screenBBox:screenBBox
               bottomInset:bottomInset
                 leftInset:leftInset
                  topInset:topInset
                  animated:animated];
}

- (void)displayAreaOnMap:(CLLocationCoordinate2D)topLeft
             bottomRight:(CLLocationCoordinate2D)bottomRight
                    zoom:(float)zoom
                 maxZoom:(float)maxZoom
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

    if (maxZoom > 0 && zoom <= 0)
        zoom = MIN([self getZoomForBounds:bounds mapSize:screenBBox], maxZoom);

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

- (BOOL)isTopToolbarSearchVisible
{
    OAToolbarViewController *toolbar = [self getTopToolbar];
    return toolbar && [toolbar isKindOfClass:OASearchToolbarViewController.class];
}

- (BOOL)isTopToolbarDiscountVisible
{
    return [[self getTopToolbar] isKindOfClass:OADiscountToolbarViewController.class];
}

- (BOOL) isTargetMapRulerNeeds
{
    return _targetMenuView && _targetMenuView.customController && [_targetMenuView.customController needsMapRuler];
}

- (BOOL) isTargetBackButtonVisible
{
    return _targetMenuView && _targetMenuView.customController && _targetMenuView.customController.buttonBack.alpha > .4;
}

- (CGFloat) getTargetToolbarHeight
{
    return _targetMenuView ? [_targetMenuView toolbarHeight] : 0.;
}

- (CGFloat) getTargetMenuHeight
{
    return [self isTargetMultiMenuViewVisible] ? _targetMultiMenuView.frame.size.height
        : _targetMenuView ? [_targetMenuView getVisibleHeight] : 0.;
}

- (CGFloat) getTargetContainerWidth
{
    return _targetMenuView && [_targetMenuView.customController getMiddleView] ? [_targetMenuView.customController getMiddleView].frame.size.width : 0.;
}

- (OAToolbarViewController *) getTopToolbar
{
    BOOL followingMode = [_routingHelper isFollowingMode];
    for (OAToolbarViewController *toolbar in _toolbars)
    {
        if (toolbar && (toolbar.showOnTop || ((!followingMode
        	&& !self.hudViewController.downloadMapWidget.isVisible))))
        {
            return toolbar;
        }
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

- (void) showDestinations
{
    [OAAnalyticsHelper logEvent:@"destinations_open"];

    [self openDestinationViewController];
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
    {
        _searchViewController = [[OAQuickSearchViewController alloc] init];
        __weak OAMapPanelViewController *selfWeak = self;
        _searchViewController.onCloseCallback = ^{
            [selfWeak clearSearchViewController];
        };
    }

    _searchViewController.myLocation = myLocation;
    _searchViewController.distanceFromMyLocation = distanceFromMyLocation;
    _searchViewController.searchNearMapCenter = searchNearMapCenter;

    [_searchViewController setupBarActionView:BarActionShowOnMap title:filter.name];
    [_searchViewController showToolbar:filter];
}

#pragma mark - OAToolbarViewControllerProtocol

- (CGFloat) toolbarTopPosition
{
    return self.hudViewController ? self.hudViewController.statusBarViewHeightConstraint.constant : [OAUtilities getStatusBarHeight];
}

- (void) toolbarLayoutDidChange:(OAToolbarViewController *)toolbarController animated:(BOOL)animated
{
    if (self.hudViewController)
        [self.hudViewController updateControlsLayout:animated];
}

- (void) toolbarHide:(OAToolbarViewController *)toolbarController;
{
    [self hideToolbar:toolbarController];
}

- (BOOL)hasTopWidget
{
    if (self.hudViewController)
    {
        return [self.hudViewController hasTopWidget];
    }
    return false;
}

- (void) recreateAllControls
{
    if (self.hudViewController)
        [self.hudViewController recreateAllControls];
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
    OAParkingPositionPlugin *plugin = (OAParkingPositionPlugin *)[OAPluginsHelper getEnabledPlugin:OAParkingPositionPlugin.class];
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

- (void) buildRoute:(CLLocation *)start end:(CLLocation *)end appMode:(OAApplicationMode *)appMode
{
   if (appMode)
       [[OARoutingHelper sharedInstance] setAppMode:appMode];

   [[OATargetPointsHelper sharedInstance] navigateToPoint:end updateRoute:YES intermediate:-1];
   [self.mapActions enterRoutePlanningModeGivenGpx:nil
                                           appMode:appMode
                                              path:nil
                                              from:start
                                          fromName:nil
                    useIntermediatePointsByDefault:NO
                                        showDialog:YES];
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

        if (_settings.simulateNavigation && ![_app.locationServices.locationSimulation isRouteAnimating])
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

            if (!_settings.simulateNavigation)
            {
                [_routingHelper setCurrentLocation:_app.locationServices.lastKnownLocation returnUpdatedLocation:false];
            }
            else if ([_routingHelper isRouteCalculated] && ![_routingHelper isRouteBeingCalculated])
            {
                OALocationSimulation *sim = _app.locationServices.locationSimulation;
                if (!sim.isRouteAnimating)
                    [_app.locationServices.locationSimulation startStopRouteAnimation];
            }
            
            [self recreateControls];
            [self updateRouteButton];
            [self updateToolbar];
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

    if (_settings.simulateNavigation && [_app.locationServices.locationSimulation isRouteAnimating])
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

- (void) startProgress
{
}

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
    if (![_settings.forcePrivateAccessRoutingAsked get:[_routingHelper getAppMode]])
    {
        OACommonBoolean *allowPrivate = [_settings getCustomRoutingBooleanProperty:@"allow_private" defaultValue:NO];
        NSArray<OAApplicationMode *> * modes = OAApplicationMode.allPossibleValues;
        for (OAApplicationMode *mode in modes)
        {
            if (![allowPrivate get:mode])
            {
                [_settings.forcePrivateAccessRoutingAsked set:YES mode:mode];
            }
        }
        if (![allowPrivate get:[_routingHelper getAppMode]])
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"private_access_routing_req") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_no") style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_yes") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                for (OAApplicationMode *mode in modes)
                {
                    if (![allowPrivate get:mode])
                    {
                        [allowPrivate set:YES mode:mode];
                    }
                }
                [_routingHelper recalculateRouteDueToSettingsChange];
                
            }]];
            [OARootViewController.instance presentViewController:alert animated:YES completion:nil];
        }
    }
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
    if (_carPlayActiveController)
        return;
    _carPlayActiveController = [[OACarPlayActiveViewController alloc] init];
    _carPlayActiveController.messageText = OALocalizedString(@"carplay_active_message");
    [self addChildViewController:_carPlayActiveController];
    [self.view insertSubview:_carPlayActiveController.view atIndex:0];
}

- (void) onCarPlayDisconnected:(void (^ __nullable)(void))onComplete
{
    [_carPlayActiveController.view removeFromSuperview];
    [_carPlayActiveController removeFromParentViewController];
    _carPlayActiveController = nil;
    if (onComplete)
        onComplete();
    if (_routingHelper.isFollowingMode)
        [self startNavigation];
}

- (void)detachFromCarPlayWindow
{
    if (_mapViewController)
    {
        [_mapViewController.mapView suspendRendering];
        
        [_mapViewController removeFromParentViewController];
        [_mapViewController.view removeFromSuperview];
        
        OAMapPanelViewController *mapPanel = OARootViewController.instance.mapPanel;
        
        [mapPanel addChildViewController:_mapViewController];
        [mapPanel.view insertSubview:_mapViewController.view atIndex:0];
        _mapViewController.view.frame = mapPanel.view.frame;
        _mapViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_mapViewController.mapView resumeRendering];
    }
}

#pragma mark - OAGpxWptEditingHandlerDelegate

- (void)saveGpxWpt:(OAGpxWptItem *)gpxWpt gpxFileName:(NSString *)gpxFileName
{
    [_mapViewController addNewWpt:gpxWpt.point gpxFileName:gpxFileName];

    gpxWpt.groups = _mapViewController.foundWptGroups;

    self.targetMenuView.targetPoint.type = OATargetWpt;
    self.targetMenuView.targetPoint.targetObj = gpxWpt;

    [self.targetMenuView updateTargetPointType:OATargetWpt];
    [self.targetMenuView applyTargetObjectChanges];

    if (!gpxFileName || gpxFileName.length == 0)
    {
        if (![[OAAppSettings sharedManager].mapSettingShowRecordingTrack get])
            [[OAAppSettings sharedManager].mapSettingShowRecordingTrack set:YES];
        [_mapViewController.mapLayers.gpxRecMapLayer refreshGpxWaypoints];
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

#pragma mark - OAOpenAddTrackDelegate

- (void)onFileSelected:(NSString *)gpxFileName
{
    NSString *fullPath = nil;
    if (gpxFileName && gpxFileName.length > 0)
        fullPath = [OsmAndApp.instance.gpxPath stringByAppendingPathComponent:gpxFileName];
    [self targetPointAddWaypoint:fullPath];
}

@end
