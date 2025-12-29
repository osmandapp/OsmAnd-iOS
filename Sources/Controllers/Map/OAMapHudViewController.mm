//
//  OAMapHudViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapHudViewController.h"
#import "OAAppSettings.h"
#import "OADownloadsManager.h"
#import "OAMapRulerView.h"
#import "OAMapInfoController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAColors.h"
#import "OALocationServices.h"
#import "OAMapViewState.h"
#import "OADownloadMapWidget.h"
#import <JASidePanelController.h>
#import <UIViewController+JASidePanel.h>
#import "OsmAndApp.h"
#import "OAObservable.h"
#import "OAAppData.h"
#import "OAAutoObserverProxy.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OAOverlayUnderlayView.h"
#import "OAToolbarViewController.h"
#import "OAFloatingButtonsHudViewController.h"
#import "OADownloadProgressView.h"
#import "OARoutingProgressView.h"
#import "OAMapWidgetRegistry.h"
#import "OAWeatherPlugin.h"
#import "OAWeatherToolbar.h"
#import "Localization.h"
#import "OAProfileGeneralSettingsParametersViewController.h"
#import "OAReverseGeocoder.h"
#import "OAMapRendererViewProtocol.h"
#import "OAApplicationMode.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OAMapStyleSettings.h"
#import "OAWeatherHelper.h"
#import "StartupLogging.h"

#define _(name) OAMapModeHudViewController__##name
#define commonInit _(commonInit)

static const float kButtonWidth = 48.0;
static const float kButtonOffset = 16.0;
static const float kWidgetsOffset = 3.0;
static const float kDistanceMeters = 100.0;
static const float kGridCellWidthPt = 8.0;
static const NSTimeInterval kWidgetsUpdateFrameInterval = 1.0 / 30.0;


@interface OAMapHudViewController () <OAMapInfoControllerProtocol, UIGestureRecognizerDelegate>

@property (nonatomic) OADownloadProgressView *downloadView;
@property (nonatomic) OARoutingProgressView *routingProgressView;

@end

@implementation OAMapHudViewController
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    OAAutoObserverProxy* _mapModeObserver;
    OAAutoObserverProxy* _mapAzimuthObserver;
    OAAutoObserverProxy* _mapZoomObserver;
    OAAutoObserverProxy* _mapLocationObserver;
    OAAutoObserverProxy* _appearanceObserver;

    OAMapPanelViewController *_mapPanelViewController;
    OAMapViewController* _mapViewController;

    UIPanGestureRecognizer* _grMove;
    UILongPressGestureRecognizer *_compassLongPressRecognizer;
    UITapGestureRecognizer *_compassSingleTapRecognizer;
    UITapGestureRecognizer *_compassDoubleTapRecognizer;
    
    OAAutoObserverProxy* _dayNightModeObserver;
    OAAutoObserverProxy* _locationServicesStatusObserver;

    BOOL _driveModeActive;
    
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _locationServicesUpdateFirstTimeObserver;
    OAAutoObserverProxy* _lastMapSourceChangeObserver;
    OAAutoObserverProxy* _applicaionModeObserver;
    OAAutoObserverProxy *_weatherSettingsChangeObserver;
    OAAutoObserverProxy *_weatherSourceChangeObserver;

    OAOverlayUnderlayView* _overlayUnderlayView;
    
    NSLayoutConstraint *_bottomRulerConstraint;
    NSLayoutConstraint *_leftRulerConstraint;
    
    CLLocation *_previousLocation;
    
    NSTimeInterval _lastWidgetsUpdateTime;
    
    BOOL _cachedLocationAvailableState;
    
    CGFloat _lastRulerLeftAbs;
    CGFloat _lastExtraTop;
    CGFloat _lastExtraBottom;
    
    BOOL _isCacheValidForRuler;
    BOOL _isCacheValidForTop;
    BOOL _isCacheValidForBottom;
    BOOL _lastIgnoreAllPanels;
    BOOL _lastIgnoreBottomSidePanels;
    
    MapHudLayout *_lastRulerLayoutRef;
    MapHudLayout *_lastTopLayoutRef;
    MapHudLayout *_lastBottomLayoutRef;
}

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    _mapHudType = EOAMapHudBrowse;
    
    _app = [OsmAndApp instance];
    _settings = [OAAppSettings sharedManager];

    _mapPanelViewController = [OARootViewController instance].mapPanel;
    _mapViewController = _mapPanelViewController.mapViewController;

    _mapModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapModeChanged)
                                                  andObserve:_app.mapModeObservable];
    _mapLocationObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                     withHandler:@selector(onMapChanged:withKey:)
                                                      andObserve:_mapViewController.mapObservable];
    _appearanceObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                     withHandler:@selector(onMapAppearanceChanged:withKey:)
                                                      andObserve:_app.appearanceChangeObservable];
    _mapAzimuthObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                    withHandler:@selector(onMapAzimuthChanged:withKey:andValue:)
                                                     andObserve:_mapViewController.azimuthObservable];
    _mapZoomObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapZoomChanged:withKey:andValue:)
                                                  andObserve:_mapViewController.zoomObservable];
    _dayNightModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                      withHandler:@selector(onDayNightModeChanged)
                                                       andObserve:_app.dayNightModeObservable];
    
    _downloadTaskProgressObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                              withHandler:@selector(onDownloadTaskProgressChanged:withKey:andValue:)
                                                               andObserve:_app.downloadsManager.progressCompletedObservable];
    _downloadTaskCompletedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                               withHandler:@selector(onDownloadTaskFinished:withKey:andValue:)
                                                                andObserve:_app.downloadsManager.completedObservable];
    _locationServicesUpdateFirstTimeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onLocationServicesFirstTimeUpdate)
                                                                 andObserve:_app.locationServices.updateFirstTimeObserver];
    _lastMapSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                             withHandler:@selector(onLastMapSourceChanged)
                                                              andObserve:_app.data.lastMapSourceChangeObservable];

    _applicaionModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onApplicationModeChanged:)
                                                         andObserve:[OsmAndApp instance].applicationModeChangedObservable];

    _weatherSettingsChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onWeatherSettingsChange:withKey:andValue:)
                                                         andObserve:[OsmAndApp instance].data.weatherSettingsChangeObservable];
    
    _weatherSourceChangeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                        withHandler:@selector(onWeatherSourceChanged:withKey:andValue:)
                                                         andObserve:[OsmAndApp instance].data.weatherSourceChangeObservable];
    
    _locationServicesStatusObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                        withHandler:@selector(onLocationServicesStatusChanged)
                                                                         andObserve:_app.locationServices.statusObservable];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProfileSettingSet:) name:kNotificationSetProfileSetting object:nil];
    
    _cachedLocationAvailableState = NO;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    LogStartup(@"viewDidLoad");

    _mapInfoController = [[OAMapInfoController alloc] initWithHudViewController:self];

    _driveModeButton.hidden = NO;
    _driveModeButton.userInteractionEnabled = YES;
    [self updateRouteButton:NO followingMode:NO];

    self.statusBarViewHeightConstraint.constant = [OAUtilities isIPad] || ![OAUtilities isLandscape] ? [OAUtilities getStatusBarHeight] : 0.;
    self.bottomBarViewHeightConstraint.constant = [OAUtilities getBottomMargin];
    
    _topWidgetsView.accessibilityIdentifier = @"widgets_panel_top";
    _leftWidgetsView.accessibilityIdentifier = @"widgets_panel_left";
    _bottomWidgetsView.accessibilityIdentifier = @"widgets_panel_bottom";
    _rightWidgetsView.accessibilityIdentifier = @"widgets_panel_right";

    _mapHudLayout = [[MapHudLayout alloc] initWithContainerView:self.view];
    [_mapHudLayout configureWithLeftWidgetsPanel:_leftWidgetsView rightWidgetsPanel:_rightWidgetsView topBarPanelContainer:_topWidgetsView bottomBarPanelContainer:_bottomWidgetsView];
    [self setupMapHudButtonsPosition];
    
    [_compassImage removeFromSuperview];
    [_compassButton addSubview:_compassImage];
    _compassImage.translatesAutoresizingMaskIntoConstraints = YES;
    _compassImage.frame = CGRectMake(9.0, 9.0, 30.0, 30.0);
    _compassImage.transform = CGAffineTransformMakeRotation(-_mapViewController.mapRendererView.azimuth / 180.0f * M_PI);
    
    OAMapButtonsHelper *mapButtonHelper = [OAMapButtonsHelper sharedInstance];
    [self setupCompassButton];
    [self setupButton:_mapSettingsButton shouldShow:[self shouldShowConfigureMap] appearanceParams:[[mapButtonHelper getConfigureMapButtonState] createAppearanceParams]];
    [self setupButton:_searchButton shouldShow:[self shouldShowSearch] appearanceParams:[[mapButtonHelper getSearchButtonState] createAppearanceParams]];
    [self setupButton:_optionsMenuButton shouldShow:[self shouldShowMenu] appearanceParams:[[mapButtonHelper getMenuButtonState] createAppearanceParams]];
    [self setupButton:_driveModeButton shouldShow:[self shouldShowNavigation] appearanceParams:[[mapButtonHelper getNavigationModeButtonState] createAppearanceParams]];
    [self setupButton:_mapModeButton shouldShow:[self shouldShowMyLocation] appearanceParams:[[mapButtonHelper getMyLocationButtonState] createAppearanceParams]];
    [self setupButton:_zoomInButton shouldShow:[self shouldShowZoomIn] appearanceParams:[[mapButtonHelper getZoomInButtonState] createAppearanceParams]];
    [self setupButton:_zoomOutButton shouldShow:[self shouldShowZoomOut] appearanceParams:[[mapButtonHelper getZoomOutButtonState] createAppearanceParams]];

    [self updateWeatherButtonVisibility];

    _zoomInButton.enabled = [_mapViewController canZoomIn];
    _zoomOutButton.enabled = [_mapViewController canZoomOut];
    
    self.floatingButtonsController = [[OAFloatingButtonsHudViewController alloc] initWithMapHudViewController:self];
    self.floatingButtonsController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addChildViewController:self.floatingButtonsController];

    self.floatingButtonsController.view.frame = self.view.frame;
    [self.view addSubview:self.floatingButtonsController.view];

    self.weatherContoursButton.alpha = 0.;
    self.weatherLayersButton.alpha = 0.;

    // IOS-218
    self.rulerLabel = [[OAMapRulerView alloc] initWithFrame:CGRectMake(0, 0, kMapRulerMinWidth, 25)];
    self.rulerLabel.accessibilityIdentifier = @"map_ruler_view";
    self.rulerLabel.translatesAutoresizingMaskIntoConstraints = YES;
    [_mapHudLayout addWidget:self.rulerLabel];
    self.rulerLabel.hidden = YES;
    self.rulerLabel.userInteractionEnabled = NO;

    [self updateColors];
    [self addAccessibilityLabels];

    _mapInfoController.delegate = self;

    _compassSingleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTapCompass)];
    _compassSingleTapRecognizer.numberOfTapsRequired = 1;
    _compassSingleTapRecognizer.delaysTouchesBegan = YES;

    _compassDoubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTapCompass)];
    _compassDoubleTapRecognizer.numberOfTapsRequired = 2;

    [_compassSingleTapRecognizer requireGestureRecognizerToFail:_compassDoubleTapRecognizer];

    [self.compassButton addGestureRecognizer:_compassSingleTapRecognizer];
    [self.compassButton addGestureRecognizer:_compassDoubleTapRecognizer];

    _compassLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPressCompass)];
    _compassLongPressRecognizer.minimumPressDuration = .5;
    [self.compassButton addGestureRecognizer:_compassLongPressRecognizer];

    _compassSingleTapRecognizer.delegate = self;
    _compassDoubleTapRecognizer.delegate = self;
    _compassLongPressRecognizer.delegate = self;

    [self configureWeatherContoursButton];

    [self.leftWidgetsView addShadow];
    [self.rightWidgetsView addShadow];
    [self.middleWidgetsView addShadow];
}

- (void)setupCompassButton
{
    [self setupButtonVisibilityFor:_compassButton shouldShow:[self shouldShowCompass]];
    [self updateCompassButton];
}

- (void)setupButton:(OAHudButton *)button shouldShow:(BOOL)shouldShow appearanceParams:(ButtonAppearanceParams *)appearanceParams
{
    [self setupButtonVisibilityFor:button shouldShow:shouldShow];
    [self updateMapButtonAppearance:button appearanceParams:appearanceParams];
}

- (void)setupButtonVisibilityFor:(OAHudButton *)button shouldShow:(BOOL)shouldShow
{
    button.alpha = shouldShow ? 1.0 : 0.0;
    button.userInteractionEnabled = button.alpha > 0.0;
}

- (void)configureWeatherContoursButton
{
    [_weatherContoursButton configure];
    __weak __typeof(self) weakSelf = self;
    _weatherContoursButton.onTapMenuAction = ^{
        [weakSelf updateStateWeatherContoursButton];
        [weakSelf configureWeatherContoursButton];
    };
}

- (void)updateStateWeatherContoursButton
{
    NSString *contourName = OsmAndApp.instance.data.contourName;
    BOOL isEnabledContourButton = [[OAMapStyleSettings sharedInstance] isAnyWeatherContourLinesEnabled] || contourName.length > 0;
    [_weatherContoursButton setImage:[UIImage templateImageNamed:isEnabledContourButton ? @"ic_custom_contour_lines" : @"ic_custom_contour_lines_disabled"] forState:UIControlStateNormal];
    UIColor *color = [UIColor colorNamed:isEnabledContourButton ? ACColorNameMapButtonBgColorActive : ACColorNameMapButtonBgColorDefault];

    _weatherContoursButton.tintColorDay = color.dark;
    _weatherContoursButton.tintColorNight = color.light;
    [_weatherContoursButton updateColorsForPressedState:NO];
}

- (void)updateStateWeatherLayersButton
{
    BOOL allLayersAreDisabled = OAWeatherHelper.sharedInstance.allLayersAreDisabled;
    [_weatherLayersButton setImage:[UIImage templateImageNamed:allLayersAreDisabled ? @"ic_custom_overlay_map_disabled" : @"ic_custom_overlay_map"] forState:UIControlStateNormal];
    
    UIColor *color = [UIColor colorNamed:allLayersAreDisabled ? ACColorNameMapButtonBgColorDefault : ACColorNameMapButtonBgColorActive];
    
    _weatherLayersButton.tintColorDay = color.dark;
    _weatherLayersButton.tintColorNight = color.light;
    [_weatherLayersButton updateColorsForPressedState:NO];
}

- (CGFloat) getExtraScreenOffset
{
    return kButtonOffset + ([OAUtilities isLandscape] ? [OAUtilities getLeftMargin] : 0.);
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.toolbarViewController)
        [self.toolbarViewController onViewWillAppear:self.mapHudType];
    
    //IOS-222
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUDLastMapModePositionTrack] && !_driveModeActive)
    {
        OAMapMode mapMode = (OAMapMode) [[NSUserDefaults standardUserDefaults] integerForKey:kUDLastMapModePositionTrack];
        [_app setMapMode:mapMode];
    }
    [self updateMapModeButton];
    _driveModeActive = NO;
    
    BOOL hasInitialURL = _app.initialURLMapState != nil;
    if (_settings.settingShowZoomButton || (!hasInitialURL && !self.contextMenuMode))
        [self updateControlsLayout:YES];

    [self updateMapRulerDataWithDelay];

    if (hasInitialURL)
        _app.initialURLMapState = nil;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.toolbarViewController)
        [self.toolbarViewController onViewDidAppear:self.mapHudType];
    
    LogStartup(@"viewDidAppear");
    MarkStartupFinished();
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (self.toolbarViewController)
        [self.toolbarViewController onViewWillDisappear:self.mapHudType];
}

- (void) viewWillLayoutSubviews
{
    if (_overlayUnderlayView)
    {
        if (OAUtilities.isLandscape || OAUtilities.isIPad)
        {
            CGFloat w = (self.view.frame.size.width < 570) ? 200 : 300;
            CGFloat h = [_overlayUnderlayView getHeight:w];
            
            CGFloat x = self.view.frame.size.width / 2. - w / 2.;
            CGFloat y = ([_overlayUnderlayView isTwoSlidersVisible]) ? CGRectGetMaxY(_driveModeButton.frame) - h : CGRectGetMinY(_driveModeButton.frame);
            _overlayUnderlayView.frame = CGRectMake(x, y, w, h);
        }
        else
        {
            CGFloat x1 = _driveModeButton.frame.origin.x;
            CGFloat x2 = MIN(_zoomInButton.frame.origin.x, _zoomOutButton.frame.origin.x) - 8.0;
            CGFloat w = x2 - x1;
            CGFloat h = [_overlayUnderlayView getHeight:w];
            _overlayUnderlayView.frame = CGRectMake(x1, CGRectGetMinY(_driveModeButton.frame) - 16. - h, w, h);
        }
    }
}

-(void) viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        self.statusBarViewHeightConstraint.constant = [OAUtilities isIPad] || ![OAUtilities isLandscape] ? [OAUtilities getStatusBarHeight] : 0.;
        self.bottomBarViewHeightConstraint.constant = [OAUtilities getBottomMargin];
        if (_mapInfoController.weatherToolbarVisible)
            [_mapInfoController updateWeatherToolbarVisible];
        [_mapInfoController viewWillTransition:size];
        [self resetToDefaultRulerLayout];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateControlsLayout:YES];
        [self updateMapRulerData];
    }];
}

- (void)viewSafeAreaInsetsDidChange
{
    [super viewSafeAreaInsetsDidChange];
    self.statusBarViewHeightConstraint.constant = [OAUtilities isIPad] || ![OAUtilities isLandscape] ? [OAUtilities getStatusBarHeight] : 0.;
    self.bottomBarViewHeightConstraint.constant = [OAUtilities getBottomMargin];
    [_mapHudLayout onContainerSizeChanged];
}

-(void) addAccessibilityLabels
{
    self.mapSettingsButton.accessibilityLabel = OALocalizedString(@"configure_map");
    self.searchButton.accessibilityLabel = OALocalizedString(@"shared_string_search");
    self.optionsMenuButton.accessibilityLabel = OALocalizedString(@"shared_string_menu");
    self.driveModeButton.accessibilityLabel = OALocalizedString(@"shared_string_navigation");
    self.mapModeButton.accessibilityLabel = OALocalizedString(@"shared_string_my_location");
    self.zoomInButton.accessibilityLabel = OALocalizedString(@"key_hint_zoom_in");
    self.zoomOutButton.accessibilityLabel = OALocalizedString(@"key_hint_zoom_out");
    self.compassButton.accessibilityLabel = OALocalizedString(@"map_widget_compass");
    self.weatherContoursButton.accessibilityLabel = OALocalizedString(@"shared_string_contours");
    self.weatherLayersButton.accessibilityLabel = OALocalizedString(@"shared_string_layers");
}

- (void) setupMapHudButtonsPosition
{
    [self registerMapButton:_mapSettingsButton stateClass:[MapSettingsButtonState class]];
    [self registerMapButton:_searchButton stateClass:[SearchButtonState class]];
    [self registerMapButton:_compassButton stateClass:[CompassButtonState class]];
    [self registerMapButton:_zoomOutButton stateClass:[ZoomOutButtonState class]];
    [self registerMapButton:_zoomInButton stateClass:[ZoomInButtonState class]];
    [self registerMapButton:_mapModeButton stateClass:[MyLocationButtonState class]];
    [self registerMapButton:_optionsMenuButton stateClass:[OptionsMenuButtonState class]];
    [self registerMapButton:_driveModeButton stateClass:[DriveModeButtonState class]];
}

- (void) registerMapButton:(OAHudButton *)button stateClass:(Class)stateClass
{
    button.useCustomPosition = NO;
    button.buttonState = [[stateClass alloc] init];
    [_mapHudLayout addMapButton:button];
}

- (void) resetToDefaultRulerLayout
{
    BOOL isLandscape = [OAUtilities isLandscape];
    BOOL isIPad = [OAUtilities isIPad];
    OATargetPointType target = _mapPanelViewController.activeTargetType;
    BOOL isTrackMenuVisible = target == OATargetGPX;
    BOOL isPlanRouteVisible = target == OATargetRoutePlanning;
    BOOL isWeatherVisible = _mapInfoController.weatherToolbarVisible;
    BOOL hasHUD = _mapPanelViewController.scrollableHudViewController != nil;
    CGFloat leftOffset = kButtonOffset;
    BOOL shouldApply = NO;
    if (isLandscape)
    {
        if ([_mapPanelViewController isTargetMapRulerNeeds])
        {
            leftOffset += [_mapPanelViewController getTargetContainerWidth];
            shouldApply = YES;
        }
        else if (isPlanRouteVisible)
        {
            leftOffset += kButtonWidth + kButtonOffset;
            if (hasHUD)
            {
                leftOffset += [_mapPanelViewController.scrollableHudViewController getLandscapeViewWidth];
                shouldApply = YES;
            }
        }
        else if (isWeatherVisible)
        {
            leftOffset += self.weatherToolbar.frame.size.width + 70.f;
            shouldApply = YES;
        }
        else if (isTrackMenuVisible)
        {
            if (hasHUD)
            {
                leftOffset += [_mapPanelViewController.scrollableHudViewController getLandscapeViewWidth];
                shouldApply = YES;
            }
        }
    }
    
    if (!isLandscape && isIPad && isTrackMenuVisible && hasHUD && !shouldApply)
    {
        leftOffset += [_mapPanelViewController.scrollableHudViewController getLandscapeViewWidth];
        shouldApply = YES;
    }
    
    CGFloat applied = shouldApply ? leftOffset : 0.0f;
    BOOL layoutChanged = _lastRulerLayoutRef != self.mapHudLayout;
    BOOL needUpdate = !_isCacheValidForRuler || layoutChanged || fabs(_lastRulerLeftAbs - applied) > 0.0f;
    if (self.mapHudLayout && needUpdate)
    {
        _isCacheValidForRuler = YES;
        _lastRulerLayoutRef = self.mapHudLayout;
        _lastRulerLeftAbs = applied;
        [self.mapHudLayout setExternalRulerLeftOffset:applied];
    }
}

- (void)updateMapRulerData
{
    CGFloat oldWidth = CGRectGetWidth(self.rulerLabel.frame);
    [self.rulerLabel setRulerData:[_mapViewController calculateMapRuler]];
    CGFloat newWidth = CGRectGetWidth(self.rulerLabel.frame);
    if (fabs(newWidth - oldWidth) >= kGridCellWidthPt)
        [_mapHudLayout updateButtons];
}

- (void)updateMapRulerDataWithDelay
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self updateMapRulerData];
    });
}

- (BOOL) shouldShowCompass
{
    return _mapViewController.mapRendererView && [self shouldShowCompass:_mapViewController.mapRendererView.azimuth];
}

- (BOOL)shouldShowConfigureMap
{
    return [[[[OAMapButtonsHelper sharedInstance] getConfigureMapButtonState] visibilityPref] get];
}

- (BOOL)shouldShowSearch
{
    return [[[[OAMapButtonsHelper sharedInstance] getSearchButtonState] visibilityPref] get];
}

- (BOOL)shouldShowMenu
{
    return [[[[OAMapButtonsHelper sharedInstance] getMenuButtonState] visibilityPref] get];
}

- (BOOL)shouldShowNavigation
{
    return [[[[OAMapButtonsHelper sharedInstance] getNavigationModeButtonState] visibilityPref] get];
}

- (BOOL)shouldShowMyLocation
{
    return [[[[OAMapButtonsHelper sharedInstance] getMyLocationButtonState] visibilityPref] get];
}

- (BOOL)shouldShowZoomIn
{
    return [[[[OAMapButtonsHelper sharedInstance] getZoomInButtonState] visibilityPref] get];
}

- (BOOL)shouldShowZoomOut
{
    return [[[[OAMapButtonsHelper sharedInstance] getZoomOutButtonState] visibilityPref] get];
}

- (BOOL)needsSettingsForWeatherToolbar
{
    return _mapInfoController.weatherToolbarVisible || _weatherToolbar.needsSettingsForToolbar;
}

- (void)changeWeatherToolbarVisible
{
    _mapInfoController.weatherToolbarVisible = !_mapInfoController.weatherToolbarVisible;
    [_app.data.weatherSettingsChangeObservable notifyEventWithKey:kWeatherSettingsChanging
                                                         andValue:@(_mapInfoController.weatherToolbarVisible || _weatherToolbar.needsSettingsForToolbar)];
}

- (void)hideWeatherToolbarIfNeeded
{
    if (_mapInfoController.weatherToolbarVisible)
        [self changeWeatherToolbarVisible];
}

- (void)onWeatherSettingsChange:(id)observer withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *operation = (NSString *) key;
        if ([operation isEqualToString:kWeatherSettingsChanged])
            [_weatherToolbar updateInfo];
    });
}

- (void)onWeatherSourceChanged:(id)observer withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self configureWeatherContoursButton];
    });
}

- (BOOL) shouldShowCompass:(float)azimuth
{
    NSInteger rotateMap = [_settings.rotateMap get];
    CompassVisibility compassVisibility = [[[OAMapButtonsHelper sharedInstance] getCompassButtonState] getVisibility];
    return ((azimuth != 0.0 || rotateMap != ROTATE_MAP_NONE) && compassVisibility == CompassVisibilityVisibleIfMapRotated) || compassVisibility == CompassVisibilityAlwaysVisible;
}

- (BOOL) isOverlayUnderlayViewVisible
{
    return _overlayUnderlayView && _overlayUnderlayView.superview != nil;
}

- (void) updateOverlayUnderlayView
{
    BOOL shouldOverlaySliderBeVisible = _app.data.overlayMapSource && [_settings getOverlayOpacitySliderVisibility];
    BOOL shouldUnderlaySliderBeVisible = _app.data.underlayMapSource && [_settings getUnderlayOpacitySliderVisibility];
    
    if (shouldOverlaySliderBeVisible || shouldUnderlaySliderBeVisible)
    {
        if (!_overlayUnderlayView)
        {
            _overlayUnderlayView = [[OAOverlayUnderlayView alloc] init];
        }
        else
        {
            [_overlayUnderlayView updateView];
            [self.view setNeedsLayout];
        }
        
        if (!_overlayUnderlayView.superview)
        {
            [self.view addSubview:_overlayUnderlayView];
        }
    }
    else
    {
        if (_overlayUnderlayView && _overlayUnderlayView.superview)
        {
            [_overlayUnderlayView removeFromSuperview];
        }
    }
}

- (IBAction) onMapModeButtonClicked:(id)sender
{
    [self updateMapModeButton];

    [[OAMapViewTrackingUtilities instance] backToLocationImpl];
}

- (void) onDayNightModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateColors];
    });
}

- (void) onLocationServicesStatusChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMapModeButtonIfNeeded];
    });
}

- (void) updateColors
{
    [self updateMapSettingsButton];
    [self updateCompassButton];

    [_searchButton setImage:[UIImage imageNamed:@"ic_custom_search"] forState:UIControlStateNormal];
    [_searchButton updateColorsForPressedState:NO];
    
    [_zoomInButton setImage:[UIImage templateImageNamed:@"ic_custom_map_zoom_in"] forState:UIControlStateNormal];
    [_zoomOutButton setImage:[UIImage templateImageNamed:@"ic_custom_map_zoom_out"] forState:UIControlStateNormal];
    [_zoomInButton updateColorsForPressedState:NO];
    [_zoomOutButton updateColorsForPressedState:NO];

    [self updateMapModeButton];

    [_optionsMenuButton setImage:[UIImage templateImageNamed:@"ic_custom_drawer"] forState:UIControlStateNormal];
    [_optionsMenuButton updateColorsForPressedState:NO];
    _optionsMenuButton.layer.cornerRadius = 6;

    [_floatingButtonsController updateColors];
    [self.rulerLabel updateColors];
    [_mapPanelViewController updateColors];
    _statusBarView.backgroundColor = [self getStatusBarBackgroundColor];
    [self updateBottomBarViewBackgroundColor];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void) onMapModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMapModeButton];
    });
}

- (BOOL) isLocationAvailable
{
    return _app.locationServices.lastKnownLocation && _app.locationServices.status == OALocationServicesStatusActive && !_app.locationServices.denied;
}

- (void) updateMapModeButtonIfNeeded
{
    if (_cachedLocationAvailableState != [self isLocationAvailable])
        [self updateMapModeButton];
}

- (void) updateMapModeButton
{
    if ([self isLocationAvailable])
    {
        switch (_app.mapMode)
        {
            case OAMapModeFree: // Free mode
            {
                [_mapModeButton setImage:[UIImage templateImageNamed:@"ic_custom_map_location_position"] forState:UIControlStateNormal];
                _mapModeButton.unpressedColorDay = UIColorFromRGB(color_on_map_icon_background_color_active);
                _mapModeButton.unpressedColorNight = UIColorFromRGB(color_on_map_icon_background_color_active);
                _mapModeButton.tintColorDay = UIColor.whiteColor;
                _mapModeButton.tintColorNight = UIColor.whiteColor;
                _mapModeButton.accessibilityHint = OALocalizedString(@"with_permission_my_position_value");
                _mapModeButton.borderWidthNight = 0;
                break;
            }
                
            case OAMapModePositionTrack: // Trace point
            {
                [_mapModeButton setImage:[UIImage templateImageNamed:@"ic_custom_map_location_position"] forState:UIControlStateNormal];
                _mapModeButton.unpressedColorDay = UIColorFromRGB(color_on_map_icon_background_color_light);
                _mapModeButton.unpressedColorNight = UIColorFromRGB(color_on_map_icon_background_color_dark);
                _mapModeButton.tintColorDay = UIColorFromRGB(color_primary_purple);
                _mapModeButton.tintColorNight = UIColorFromRGB(color_primary_light_blue);
                _mapModeButton.accessibilityHint = nil;
                _mapModeButton.borderWidthNight = 2;
                break;
            }

            default:
                break;
        }
        _cachedLocationAvailableState = YES;
    }
    else
    {
        [_mapModeButton setImage:[UIImage templateImageNamed:@"ic_custom_map_location_free"] forState:UIControlStateNormal];
        _mapModeButton.unpressedColorDay = UIColorFromRGB(color_on_map_icon_background_color_light);
        _mapModeButton.unpressedColorNight = UIColorFromRGB(color_on_map_icon_background_color_dark);
        _mapModeButton.tintColorDay = UIColorFromRGB(color_on_map_icon_tint_color_light);
        _mapModeButton.tintColorNight = UIColorFromRGB(color_on_map_icon_tint_color_dark);
        _mapModeButton.borderWidthNight = 2;
        _mapModeButton.accessibilityHint = OALocalizedString(@"without_permission_my_position_value");
        _mapModeButton.accessibilityValue = OALocalizedString(@"shared_string_location_unknown");
        _cachedLocationAvailableState = NO;
    }
    
    [_mapModeButton updateColorsForPressedState:NO];

    if (_overlayUnderlayView && _overlayUnderlayView.superview)
    {
        [_overlayUnderlayView updateView];
        [self.view setNeedsLayout];
    }
}

- (IBAction) onMapSettingsButtonClick:(id)sender
{
    [_mapPanelViewController mapSettingsButtonClick:sender];
}

- (IBAction) onSearchButtonClick:(id)sender
{
    [_mapPanelViewController searchButtonClick:sender];
}

- (IBAction) onWeatherToolbarButtonClick:(id)sender
{
    [self changeWeatherToolbarVisible];
}

- (IBAction)onWeatherLayersButtonClick:(id)sender
{
    auto weatherLayerSettingsViewController = [WeatherLayerSettingsViewController new];
    __weak __typeof(self) weakSelf = self;
    weatherLayerSettingsViewController.onChangeSwitchLayerAction = ^{
        [weakSelf updateStateWeatherLayersButton];
    };

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:weatherLayerSettingsViewController];
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;

    UISheetPresentationController *sheet = navigationController.sheetPresentationController;
    if (sheet)
    {
        sheet.detents = @[UISheetPresentationControllerDetent.mediumDetent];
        sheet.preferredCornerRadius = 20;
        sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = YES;
    }

    [OARootViewController.instance.navigationController presentViewController:navigationController animated:YES completion:nil];
}

- (IBAction) onOptionsMenuButtonDown:(id)sender
{
    self.sidePanelController.recognizesPanGesture = YES;
}

- (IBAction) onOptionsMenuButtonClicked:(id)sender
{
    self.sidePanelController.recognizesPanGesture = YES;
    [self.sidePanelController showLeftPanelAnimated:YES];
}

- (void) onMapAzimuthChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.toolbarViewController)
            [self.toolbarViewController onMapAzimuthChanged:observable withKey:key andValue:value];
        
        CGFloat angle = -[value floatValue] / 180.0f * M_PI;
        _compassImage.transform = CGAffineTransformMakeRotation(angle);
        [_floatingButtonsController rotateMapOrientationButtonIfExistsWith:angle];
        
        BOOL showCompass = [self shouldShowCompass:[value floatValue]];
        [self updateCompassVisibility:showCompass];
        [self updateMapModeButtonIfNeeded];
    });
}

- (IBAction) onZoomInButtonClicked:(id)sender
{
    [_mapViewController zoomInAndAdjustTiltAngle];
}

- (IBAction) onZoomOutButtonClicked:(id)sender
{
    [_mapViewController zoomOutAndAdjustTiltAngle];
    [_mapViewController calculateMapRuler];
}

- (void) onMapZoomChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _zoomInButton.enabled = [_mapViewController canZoomIn];
        _zoomOutButton.enabled = [_mapViewController canZoomOut];
        
        [self updateMapRulerData];
    });
}

- (void) onMapAppearanceChanged:(id)observable withKey:(id)key
{
    [self viewDidAppear:false];
}

- (void) onMapChanged:(id)observable withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.toolbarViewController)
            [self.toolbarViewController onMapChanged:observable withKey:key];
        
        [self updateMapRulerData];
        [self updateMapModeButtonIfNeeded];
    });
}

- (void)handleLongPressCompass
{
    OAProfileGeneralSettingsParametersViewController *settingsViewController = [[OAProfileGeneralSettingsParametersViewController alloc] initMapOrientationFromMap];
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:settingsViewController];
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    UISheetPresentationController *sheet = navigationController.sheetPresentationController;
    if (sheet)
    {
        sheet.detents = @[UISheetPresentationControllerDetent.mediumDetent];
        sheet.preferredCornerRadius = 20;
    }
    
    [self.navigationController presentViewController:navigationController animated:YES completion:nil];
}

- (void)handleSingleTapCompass
{
    [[OAAppSettings sharedManager].mapManuallyRotatingAngle set:0];
    [[OAMapViewTrackingUtilities instance] animatedAlignAzimuthToNorth];
}

- (void)handleDoubleTapCompass
{
    [[OAMapViewTrackingUtilities instance] switchRotateMapMode];
}

- (void) onLocationServicesFirstTimeUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMapModeButton];
    });
}

- (IBAction) onDriveModeButtonClicked:(id)sender
{
    [[OARootViewController instance].mapPanel onNavigationClick:NO];
}

- (void)updateDependentButtons
{
    [self updateDependentButtonsVisibility];
    [_floatingButtonsController updateMap3dModeButtonAppearance];
    [_mapHudLayout updateButtons];
}

- (void)updateDependentButtonsVisibility
{
    [_floatingButtonsController updateViewVisibility];
}

- (void) onApplicationModeChanged:(OAApplicationMode *)prevMode
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateColors];
        [self recreateAllControls];
        if (@available(iOS 16.0, *)) {
            [self setNeedsUpdateOfSupportedInterfaceOrientations];
        }
    });
}

- (void) onProfileSettingSet:(NSNotification *)notification
{
    OACommonPreference *obj = notification.object;
    if (obj)
    {
        OAMapButtonsHelper *mapButtonsHelper = [OAMapButtonsHelper sharedInstance];
        CompassButtonState *compassButtonState = [mapButtonsHelper getCompassButtonState];
        Map3DButtonState *map3DButtonState = [mapButtonsHelper getMap3DButtonState];
        MapSettingsButtonState *configureMapButtonState = [mapButtonsHelper getConfigureMapButtonState];
        SearchButtonState *searchButtonState = [mapButtonsHelper getSearchButtonState];
        OptionsMenuButtonState *menuButtonState = [mapButtonsHelper getMenuButtonState];
        DriveModeButtonState *navigationButtonState = [mapButtonsHelper getNavigationModeButtonState];
        MyLocationButtonState *myLocationButtonState = [mapButtonsHelper getMyLocationButtonState];
        ZoomInButtonState *zoomInButtonState = [mapButtonsHelper getZoomInButtonState];
        ZoomOutButtonState *zoomOutButtonState = [mapButtonsHelper getZoomOutButtonState];

        BOOL isQuickAction = NO;
        for (QuickActionButtonState *buttonState in [mapButtonsHelper getButtonsStates])
        {
            if (obj == buttonState.statePref || obj == buttonState.quickActionsPref)
            {
                isQuickAction = YES;
                break;
            }
        }

        if (obj == _settings.rotateMap || obj == compassButtonState.visibilityPref || obj == [compassButtonState storedCornerRadiusPref] || obj == [compassButtonState storedOpacityPref] || obj == [compassButtonState storedSizePref] || obj == [compassButtonState storedIconPref])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateCompassButton];
                [_mapHudLayout updateButtons];
            });
        }
        else if (obj == _settings.transparentMapTheme
                 || obj == _settings.profileIconColor
                 || obj == _settings.profileCustomIconColor)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateColors];
            });
        }
        else if (obj == map3DButtonState.visibilityPref || obj == [map3DButtonState storedCornerRadiusPref] || obj == [map3DButtonState storedOpacityPref] || obj == [map3DButtonState storedSizePref] || obj == [map3DButtonState storedIconPref] || isQuickAction)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateDependentButtons];
            });
        }
        else if (obj == configureMapButtonState.visibilityPref || obj == [configureMapButtonState storedCornerRadiusPref] || obj == [configureMapButtonState storedOpacityPref] || obj == [configureMapButtonState storedSizePref] || obj == [configureMapButtonState storedIconPref])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateMapButton:_mapSettingsButton showButton:[self shouldShowConfigureMap] appearanceParams:[[mapButtonsHelper getConfigureMapButtonState] createAppearanceParams]];
            });
        }
        else if (obj == searchButtonState.visibilityPref || obj == [searchButtonState storedCornerRadiusPref] || obj == [searchButtonState storedOpacityPref] || obj == [searchButtonState storedSizePref] || obj == [searchButtonState storedIconPref])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateMapButton:_searchButton showButton:[self shouldShowSearch] appearanceParams:[[mapButtonsHelper getSearchButtonState] createAppearanceParams]];
            });
        }
        else if (obj == menuButtonState.visibilityPref || obj == [menuButtonState storedCornerRadiusPref] || obj == [menuButtonState storedOpacityPref] || obj == [menuButtonState storedSizePref] || obj == [menuButtonState storedIconPref])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateMapButton:_optionsMenuButton showButton:[self shouldShowMenu] appearanceParams:[[mapButtonsHelper getMenuButtonState] createAppearanceParams]];
            });
        }
        else if (obj == navigationButtonState.visibilityPref || obj == [navigationButtonState storedCornerRadiusPref] || obj == [navigationButtonState storedOpacityPref] || obj == [navigationButtonState storedSizePref] || obj == [navigationButtonState storedIconPref])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateMapButton:_driveModeButton showButton:[self shouldShowNavigation] appearanceParams:[[mapButtonsHelper getNavigationModeButtonState] createAppearanceParams]];
            });
        }
        else if (obj == myLocationButtonState.visibilityPref || obj == [myLocationButtonState storedCornerRadiusPref] || obj == [myLocationButtonState storedOpacityPref] || obj == [myLocationButtonState storedSizePref] || obj == [myLocationButtonState storedIconPref])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateMapButton:_mapModeButton showButton:[self shouldShowMyLocation] appearanceParams:[[mapButtonsHelper getMyLocationButtonState] createAppearanceParams]];
            });
        }
        else if (obj == zoomInButtonState.visibilityPref || obj == [zoomInButtonState storedCornerRadiusPref] || obj == [zoomInButtonState storedOpacityPref] || obj == [zoomInButtonState storedSizePref] || obj == [zoomInButtonState storedIconPref])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateMapButton:_zoomInButton showButton:[self shouldShowZoomIn] appearanceParams:[[mapButtonsHelper getZoomInButtonState] createAppearanceParams]];
            });
        }
        else if (obj == zoomOutButtonState.visibilityPref || obj == [zoomOutButtonState storedCornerRadiusPref] || obj == [zoomOutButtonState storedOpacityPref] || obj == [zoomOutButtonState storedSizePref] || obj == [zoomOutButtonState storedIconPref])
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateMapButton:_zoomOutButton showButton:[self shouldShowZoomOut] appearanceParams:[[mapButtonsHelper getZoomOutButtonState] createAppearanceParams]];
            });
        }
    }
}

- (void)updateMapButton:(OAHudButton *)button showButton:(BOOL)showButton appearanceParams:(ButtonAppearanceParams *)appearanceParams
{
    [self updateMapButtonVisibility:button showButton:showButton];
    [self updateMapButtonAppearance:button appearanceParams:appearanceParams];
    [_mapHudLayout updateButtons];
}

- (void)updateMapButtonVisibility:(UIButton *)button showButton:(BOOL)showButton
{
    BOOL needShow = button.alpha == 0.0 && showButton;
    BOOL needHide = button.alpha == 1.0 && !showButton;
    if (needShow)
    {
        button.hidden = NO;
        [UIView animateWithDuration:.25 animations:^{
            button.alpha = 1.0;
        } completion:^(BOOL finished) {
            button.userInteractionEnabled = button.alpha > 0.0;
        }];
    }
    else if (needHide)
    {
        button.userInteractionEnabled = NO;
        [UIView animateWithDuration:.25 animations:^{
            button.alpha = 0.0;
        } completion:^(BOOL finished) {
            button.hidden = YES;
        }];
    }
}

- (void)updateMapButtonAppearance:(OAHudButton *)button appearanceParams:(ButtonAppearanceParams *)appearanceParams
{
    [button setCustomAppearanceParams:appearanceParams];
}

- (void) updateCompassVisibility:(BOOL)showCompass
{
    BOOL needShow = _compassButton.alpha == 0.0 && showCompass;
    BOOL needHide = _compassButton.alpha == 1.0 && !showCompass;
    if (needShow)
        [self showCompass];
    else if (needHide)
        [self hideCompass];
}

- (void)updateCompassSize
{
    CGFloat size = [[[OAMapButtonsHelper sharedInstance] getCompassButtonState] createAppearanceParams].size;
    _compassImage.center = CGPointMake(size / 2, size / 2);
    _compassButton.frame = CGRectMake(_compassButton.frame.origin.x, _compassButton.frame.origin.y, size, size);
}

- (void)updateCompassCornerRadius
{
    CompassButtonState *buttonState = [[OAMapButtonsHelper sharedInstance] getCompassButtonState];
    ButtonAppearanceParams *params = [buttonState createAppearanceParams];
    NSInteger circleRadius = params.size / 2;
    NSInteger cornerRadius = params.cornerRadius;
    _compassButton.layer.cornerRadius = cornerRadius > circleRadius ? circleRadius : cornerRadius;
}

- (void)updateCompassOpacity
{
    _compassButton.backgroundColor = [_compassButton.backgroundColor colorWithAlphaComponent:[[[OAMapButtonsHelper sharedInstance] getCompassButtonState] createAppearanceParams].opacity];
}

- (void)updateCompassShadow
{
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:_compassButton.bounds
                                                          cornerRadius:_compassButton.layer.cornerRadius];
    _compassButton.layer.shadowPath = shadowPath.CGPath;
}

- (void) updateWeatherButtonVisibility
{
    if (!self.weatherToolbar.hidden && (_weatherContoursButton.alpha < 1. || _weatherLayersButton.alpha < 1.))
        [self showWeatherButton];
    else if (self.weatherToolbar.hidden &&(_weatherContoursButton.alpha > 0 || _weatherLayersButton.alpha > 0))
        [self hideWeatherButton];
}

- (void) showCompass
{
    _compassButton.hidden = NO;
    [UIView animateWithDuration:.25 animations:^{
        _compassButton.alpha = 1.0;
    } completion:^(BOOL finished) {
        _compassButton.userInteractionEnabled = _compassButton.alpha > 0.0;
    }];
}

- (void) showWeatherButton
{
    [self updateStateWeatherContoursButton];
    [self updateStateWeatherLayersButton];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideWeatherButtonImpl) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showWeatherButtonImpl) object:nil];
    [self performSelector:@selector(showWeatherButtonImpl) withObject:NULL afterDelay:0.];
}

- (void)showWeatherButtonImpl
{
    [UIView animateWithDuration:.25 animations:^{
        _weatherContoursButton.alpha = 1.0;
        _weatherLayersButton.alpha = 1.0;
    } completion:^(BOOL finished) {
        _weatherContoursButton.userInteractionEnabled = _weatherContoursButton.alpha > 0.0;
        _weatherLayersButton.userInteractionEnabled = _weatherLayersButton.alpha > 0.0;
    }];
}

- (void) hideCompass
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideCompassImpl) object:nil];
    [self performSelector:@selector(hideCompassImpl) withObject:NULL afterDelay:5.0];
}

- (void) hideCompassImpl
{
    _compassButton.userInteractionEnabled = NO;
    [UIView animateWithDuration:.25 animations:^{
        _compassButton.alpha = 0.0;
    } completion:^(BOOL finished) {
        _compassButton.hidden = YES;
    }];
}

- (void) updateCompassButton
{
    OACommonInteger *rotateMap = _settings.rotateMap;
    BOOL showCompass = [self shouldShowCompass];
    NSString *iconName = [[[OAMapButtonsHelper sharedInstance] getCompassButtonState] createAppearanceParams].iconName;
    if (iconName && iconName.length > 0)
    {
        UIImage *iconImage = [UIImage imageNamed:iconName];
        if (!iconImage)
            iconImage = [OAUtilities getMxIcon:iconName];
        _compassImage.image = iconImage;
    }
    else
    {
        _compassImage.image = [UIImage imageNamed:[CompassModeWrapper iconNameForValue:[rotateMap get] isLightMode:!_settings.nightMode]];
    }
    
    if ([rotateMap get] == ROTATE_MAP_NONE)
        _compassButton.accessibilityValue = OALocalizedString(@"rotate_map_north_opt");
    else if ([rotateMap get] == ROTATE_MAP_BEARING)
        _compassButton.accessibilityValue = OALocalizedString(@"rotate_map_bearing_opt");
    else if ([rotateMap get] == ROTATE_MAP_MANUAL)
        _compassButton.accessibilityValue = OALocalizedString(@"rotate_map_manual_opt");
    else
        _compassButton.accessibilityValue = OALocalizedString(@"rotate_map_compass_opt");
    
    [self updateCompassVisibility:showCompass];
    [self updateCompassSize];
    [self updateCompassCornerRadius];
    [self updateCompassOpacity];
    [self updateCompassShadow];
    [_compassButton updateColorsForPressedState:NO];
}

- (void)hideWeatherButton
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showWeatherButtonImpl) object:nil];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideWeatherButtonImpl) object:nil];
    [self performSelector:@selector(hideWeatherButtonImpl) withObject:NULL afterDelay:0.];
}

- (void)hideWeatherButtonImpl
{
    [UIView animateWithDuration:.25 animations:^{
        _weatherContoursButton.alpha = 0.0;
        _weatherLayersButton.alpha = 0.0;
    } completion:^(BOOL finished) {
        _weatherContoursButton.userInteractionEnabled = _weatherContoursButton.alpha > 0.0;
        _weatherLayersButton.userInteractionEnabled = _weatherLayersButton.alpha > 0.0;
    }];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    if (_toolbarViewController && _toolbarViewController.view.alpha > 0.5)
        return [_toolbarViewController getPreferredStatusBarStyle];
    else
        return _settings.nightMode ? UIStatusBarStyleLightContent : UIStatusBarStyleDarkContent;
}

- (void) setToolbar:(OAToolbarViewController *)toolbarController
{
    if (_toolbarViewController.view.superview)
        [_toolbarViewController.view removeFromSuperview];

    _toolbarViewController = toolbarController;
    _toolbarViewController.view.alpha = 1.;
    _toolbarViewController.view.userInteractionEnabled = YES;

    if (![self.view.subviews containsObject:_toolbarViewController.view])
        [self.view insertSubview:_toolbarViewController.view belowSubview:self.statusBarView];
}

- (void) removeToolbar
{
    if (_toolbarViewController)
        [_toolbarViewController.view removeFromSuperview];

    _toolbarViewController = nil;
    [self updateControlsLayout:YES];
}

- (void) setDownloadMapWidget:(OADownloadMapWidget *)widget
{
    if (_downloadMapWidget.superview)
    {
        [self.mapHudLayout removeWidget:_downloadMapWidget];
        [_downloadMapWidget removeFromSuperview];
    }

    _downloadMapWidget = widget;
    if (![self.view.subviews containsObject:_downloadMapWidget])
    {
        [self.view addSubview:_downloadMapWidget];
        [self.view insertSubview:_downloadMapWidget aboveSubview:_toolbarViewController.view];
        [self.mapHudLayout addWidget:_downloadMapWidget];
    }
}

- (void)setWeatherToolbarMapWidget:(OAWeatherToolbar *)widget navBar:(WeatherNavigationBarView *)navBar
{
    if (_weatherToolbar.superview)
        [_weatherToolbar removeFromSuperview];
    
    if (navBar.superview)
        [navBar removeFromSuperview];
    

    _weatherToolbar = widget;

    if (![_mapPanelViewController.view.subviews containsObject:_weatherToolbar])
        [_mapPanelViewController.view addSubview:_weatherToolbar];
    if (![_mapPanelViewController.view.subviews containsObject:navBar])
        [_mapPanelViewController.view addSubview:navBar];
}

- (void) updateControlsLayout:(BOOL)animated
{
    BOOL isToolbarVisible = _toolbarViewController && _toolbarViewController.view.superview;
    if (isToolbarVisible)
    {
        BOOL isAllowToolbarsVisible = (isToolbarVisible && ([_mapPanelViewController isTopToolbarSearchVisible] || [_mapPanelViewController isTopToolbarDiscountVisible]));
        if (isAllowToolbarsVisible)
            self.topWidgetsViewYConstraint.constant = _toolbarViewController.view.frame.size.height;
        else
            self.topWidgetsViewYConstraint.constant = 0.;
    }
    else
    {
        self.topWidgetsViewYConstraint.constant = 0.;
    }

    [self updateTopControlsVisibility:animated];
    [self updateBottomControlsVisibility:animated];
    [_floatingButtonsController updateViewVisibility];

    if (_downloadView)
        _downloadView.frame = [self getDownloadViewFrame];
    if (_routingProgressView)
        _routingProgressView.frame = [self getRoutingProgressViewFrame];

    _statusBarView.backgroundColor = [self getStatusBarBackgroundColor];
    [self updateBottomBarViewBackgroundColor];
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)updateBottomBarViewBackgroundColor
{
    if ([OAUtilities isLandscape] || [OAUtilities isIPad])
        _bottomBarView.backgroundColor = [UIColor clearColor];
    else
        _bottomBarView.backgroundColor = [UIColor colorNamed:ACColorNameWidgetBgColor].currentMapThemeColor;
}

- (void) updateTopButtonsLayoutY
{
    BOOL isPhoneLandscape = [OAUtilities isLandscape] && ![OAUtilities isIPad];
    BOOL contextMenuMode = self.contextMenuMode;
    BOOL isTargetMode = _mapPanelViewController.activeTargetType == OATargetChangePosition;
    CGFloat baseMin = self.statusBarViewHeightConstraint.constant;
    CGFloat ctxToolbarH = 0.0;
    if (_mapPanelViewController.scrollableHudViewController)
        ctxToolbarH = [_mapPanelViewController.scrollableHudViewController getNavbarHeight];
    else if ([_mapPanelViewController isTopToolbarActive])
        ctxToolbarH = [_mapPanelViewController getTargetToolbarHeight];
    
    BOOL isToolbarVisible = !_mapInfoController.weatherToolbarVisible && _toolbarViewController && _toolbarViewController.view.superview;
    BOOL isAllowToolbarsVisible = isToolbarVisible && ([_mapPanelViewController isTopToolbarSearchVisible] || [_mapPanelViewController isTopToolbarDiscountVisible]);
    CGFloat classicToolbarH = 0.0;
    if (isAllowToolbarsVisible)
        classicToolbarH = _toolbarViewController.view.frame.size.height;
    
    BOOL isBannerVisible = self.downloadMapWidget && [self.downloadMapWidget isVisible] && self.downloadMapWidget.alpha > 0.0;
    CGFloat bannerH = 0.0;
    if (isBannerVisible)
        bannerH = self.downloadMapWidget.frame.size.height + self.downloadMapWidget.shadowOffset;
    
    BOOL ignoreTopSidePanels = !isPhoneLandscape && (contextMenuMode || isTargetMode || isAllowToolbarsVisible || (ctxToolbarH > baseMin));
    CGFloat extraTop = 0.0;
    if (!isPhoneLandscape)
    {
        if (contextMenuMode || isTargetMode)
        {
            if (ctxToolbarH > baseMin)
                extraTop += ctxToolbarH - baseMin;
            if (isBannerVisible)
                extraTop += bannerH;
        }
        else if (isAllowToolbarsVisible)
        {
            extraTop += isBannerVisible ? bannerH : classicToolbarH;
        }
        else if (ctxToolbarH > baseMin)
        {
            extraTop += (ctxToolbarH - baseMin);
        }
    }
    
    if (self.mapHudLayout)
    {
        BOOL layoutChanged = _lastTopLayoutRef != self.mapHudLayout;
        BOOL needUpdate = !_isCacheValidForTop || layoutChanged || (ignoreTopSidePanels != _lastIgnoreAllPanels) || (extraTop != _lastExtraTop);
        if (needUpdate)
        {
            _isCacheValidForTop = YES;
            _lastTopLayoutRef = self.mapHudLayout;
            _lastIgnoreAllPanels = ignoreTopSidePanels;
            _lastExtraTop = extraTop;
            [self.mapHudLayout setExternalTopOverlay:extraTop ignorePanels:ignoreTopSidePanels];
        }
    }
}

- (BOOL)hasTopWidget
{
    return [_mapInfoController.topPanelController hasWidgets];
}

- (BOOL)hasBottomWidget
{
    return [_mapInfoController.bottomPanelController hasWidgets];
}

- (BOOL)hasLeftWidget
{
    return [_mapInfoController.leftPanelController hasWidgets];
}
- (BOOL)hasRightWidget
{
    return [_mapInfoController.rightPanelController hasWidgets];
}

- (void) updateBottomButtonsLayout
{
    BOOL isIpad = [OAUtilities isIPad];
    BOOL isLandscape = [OAUtilities isLandscape];
    BOOL contextMenu = self.contextMenuMode;
    OATargetPointType target = _mapPanelViewController.activeTargetType;
    BOOL isPlanRoute = target == OATargetRoutePlanning;
    BOOL hasScrollableHudVisible = _mapPanelViewController.scrollableHudViewController && _mapPanelViewController.scrollableHudViewController.view.superview;
    CGFloat viewHeight = 0.0;
    CGFloat toolbarHeight = 0.0;
    if (hasScrollableHudVisible)
    {
        viewHeight = [_mapPanelViewController.scrollableHudViewController getViewHeight];
        toolbarHeight = [_mapPanelViewController.scrollableHudViewController getToolbarHeight];
    }
    
    BOOL weatherVisible = _mapInfoController.weatherToolbarVisible;
    CGFloat bottomInset = self.view.safeAreaInsets.bottom;
    CGFloat extraBottom = 0.0;
    BOOL contextAffectsBottom = contextMenu && (!isLandscape || isPlanRoute);
    if (contextAffectsBottom && (!isIpad || isPlanRoute))
    {
        if (hasScrollableHudVisible)
        {
            if (isPlanRoute && isLandscape)
                extraBottom += toolbarHeight;
            else
                extraBottom += MAX(0.f, viewHeight - bottomInset);
        }
        else
        {
            CGFloat targetH = [_mapPanelViewController getTargetMenuHeight];
            extraBottom += MAX(0.f, targetH - bottomInset);
        }
    }
    else if (!contextAffectsBottom && weatherVisible && !isLandscape)
    {
        extraBottom += MAX(0.f, self.weatherToolbar.frame.size.height - bottomInset);
    }
    
    BOOL ignoreBottomSidePanels = contextMenu || weatherVisible;
    BOOL layoutChanged = _lastBottomLayoutRef != self.mapHudLayout;
    BOOL needUpdate = !_isCacheValidForBottom || layoutChanged || (ignoreBottomSidePanels != _lastIgnoreBottomSidePanels) || (fabs(_lastExtraBottom - extraBottom) > 0.0);
    if (self.mapHudLayout && needUpdate)
    {
        _isCacheValidForBottom = YES;
        _lastBottomLayoutRef = self.mapHudLayout;
        _lastIgnoreBottomSidePanels = ignoreBottomSidePanels;
        _lastExtraBottom = extraBottom;
        [self.mapHudLayout setExternalBottomOverlay:extraBottom ignorePanels:ignoreBottomSidePanels];
        [self resetToDefaultRulerLayout];
    }
}

- (CGFloat) getHudMinTopOffset
{
    return self.statusBarViewHeightConstraint.constant;
}

- (CGFloat) getHudTopOffset
{
    CGFloat contextMenuToolbarHeight = _mapPanelViewController.scrollableHudViewController
            ? [_mapPanelViewController.scrollableHudViewController getNavbarHeight]
            : [_mapPanelViewController isTopToolbarActive] ? [_mapPanelViewController getTargetToolbarHeight] : 0.;
    CGFloat offset = [OAUtilities isLandscape] && ![OAUtilities isIPad] ? 0. : contextMenuToolbarHeight > 0 ? contextMenuToolbarHeight : [self getHudMinTopOffset];
    BOOL isToolbarAllowed = !_mapInfoController.weatherToolbarVisible;
    BOOL isToolbarVisible = isToolbarAllowed && _toolbarViewController && _toolbarViewController.view.superview;
    BOOL isTargetToHideVisible = _mapPanelViewController.activeTargetType == OATargetChangePosition;
    BOOL isTopWidgetsVisible = _mapInfoController.topPanelController && [_mapInfoController.topPanelController hasWidgets] && !isTargetToHideVisible;
    BOOL isLeftWidgetsVisible = _mapInfoController.leftPanelController && [_mapInfoController.leftPanelController hasWidgets];
    BOOL isMapDownloadVisible = [_downloadMapWidget isVisible] && _downloadMapWidget.alpha != 0;
    if (isMapDownloadVisible)
    {
        offset += _downloadMapWidget.frame.size.height + _downloadMapWidget.shadowOffset;
    }
    else if (!self.contextMenuMode)
    {
        if (isTopWidgetsVisible && contextMenuToolbarHeight == 0. && ![OAUtilities isLandscapeIpadAware])
            offset += self.topWidgetsViewHeightConstraint.constant;
        if (isToolbarVisible)
            offset += _toolbarViewController.view.frame.size.height;
        else if (isLeftWidgetsVisible)
            offset += self.leftWidgetsViewHeightConstraint.constant;
    }
    return offset;
}

- (CGFloat) getHudMinBottomOffset
{
    return self.bottomBarViewHeightConstraint.constant;
}

- (CGFloat) getHudBottomOffset
{
    CGFloat offset = [self getHudMinBottomOffset];
    BOOL isBottomWidgetsVisible = _mapInfoController.bottomPanelController && [_mapInfoController.bottomPanelController hasWidgets];
    CGFloat bottomWidgetsHeight = self.bottomWidgetsViewHeightConstraint.constant;
    
    if (isBottomWidgetsVisible)
        offset += bottomWidgetsHeight;

    return offset;
}

- (UIColor *) getStatusBarBackgroundColor
{
    BOOL isNight = _settings.nightMode;
    BOOL transparent = [_settings.transparentMapTheme get];
    UIColor *statusBarColor;
    if ([_mapPanelViewController isDashboardVisible])
        statusBarColor = UIColor.clearColor;
    else if (self.contextMenuMode)
        statusBarColor = isNight ? UIColor.clearColor : [UIColor colorWithWhite:1.0 alpha:0.5];
    else if (_downloadMapWidget.isVisible)
        statusBarColor = isNight ? UIColorFromRGB(nav_bar_night) : UIColorFromRGB(color_primary_table_background);
    else if (_toolbarViewController)
        statusBarColor = [_toolbarViewController getStatusBarColor];
    else if (_mapInfoController.topPanelController && [_mapInfoController.topPanelController hasWidgets])
        statusBarColor = isNight ? UIColorFromRGB(nav_bar_night) : UIColor.whiteColor;
    if (!statusBarColor)
        statusBarColor = isNight ? (transparent ? UIColor.clearColor : UIColor.blackColor) : [UIColor colorWithWhite:1.0 alpha:(transparent ? 0.5 : 1.0)];
    return statusBarColor;
}

- (CGRect) getDownloadViewFrame
{
    CGFloat y = [self getHudTopOffset];
    CGFloat leftMargin = _mapInfoController.leftPanelController && [_mapInfoController.leftPanelController hasWidgets] ? _mapInfoController.leftPanelController.view.bounds.size.width + kButtonOffset : self.searchButton.frame.origin.x + kButtonWidth + kButtonOffset;
    CGFloat rightMargin = _mapInfoController.rightPanelController && [_mapInfoController.rightPanelController hasWidgets] ? _mapInfoController.rightPanelController.view.bounds.size.width + kButtonOffset : kButtonOffset;
    return CGRectMake(leftMargin, y + 12.0, self.view.bounds.size.width - leftMargin - rightMargin, 28.0);
}

- (CGRect) getRoutingProgressViewFrame
{
    CGFloat y;
    if (_downloadView)
        y = _downloadView.frame.origin.y + _downloadView.frame.size.height;
    else
        y = [self getHudTopOffset];
    
    return CGRectMake(self.view.bounds.size.width / 2.0 - 50.0, y + 12.0, 100.0, 20.0);
}

- (void) updateCurrentLocationAddress
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        if (UIAccessibilityIsVoiceOverRunning())
        {
            CLLocation *currentLocation = _app.locationServices.lastKnownLocation;
            if (currentLocation)
            {
                if (!_previousLocation || [currentLocation distanceFromLocation:_previousLocation] > kDistanceMeters)
                {
                    NSString *positionAddress;
                    _previousLocation = currentLocation;
                    positionAddress = [[OAReverseGeocoder instance] lookupAddressAtLat:currentLocation.coordinate.latitude lon:currentLocation.coordinate.longitude];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        _mapModeButton.accessibilityValue = positionAddress.length > 0 ? positionAddress : OALocalizedString(@"shared_string_location_unknown");
                    });
                }
            }
        }
    });
}

#pragma mark - debug

- (void) onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    
    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil || _app.isInBackgroundOnDevice)
            return;
        
        if (!_downloadView)
        {
            self.downloadView = [[OADownloadProgressView alloc] initWithFrame:[self getDownloadViewFrame]];
            _downloadView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

            _downloadView.layer.cornerRadius = 5.0;
            [_downloadView.layer setShadowColor:[UIColor blackColor].CGColor];
            [_downloadView.layer setShadowOpacity:0.3];
            [_downloadView.layer setShadowRadius:2.0];
            [_downloadView.layer setShadowOffset:CGSizeMake(0.0, 0.0)];
            
            _downloadView.startStopButtonView.hidden = YES;
            CGRect frame = _downloadView.progressBarView.frame;
            frame.origin.y = 20.0;
            frame.size.width = _downloadView.frame.size.width - 16.0;
            _downloadView.progressBarView.frame = frame;

            frame = _downloadView.titleView.frame;
            frame.origin.y = 3.0;
            frame.size.width = _downloadView.frame.size.width - 16.0;
            _downloadView.titleView.frame = frame;
            
            [self.view insertSubview:self.downloadView aboveSubview:self.searchButton];
        }
        
        if (![_downloadView.titleView.text isEqualToString:task.title])
            [_downloadView setTitle: task.title];
        
        [self.downloadView setProgress:[value floatValue]];
        
    });
}

- (void) onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    
    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded)
            return;
        
        OADownloadProgressView *download = self.downloadView;
        self.downloadView  = nil;
        if (_app.isInBackgroundOnDevice)
        {
            [download removeFromSuperview];
        }
        else
        {
            [UIView animateWithDuration:.3 animations:^{
                download.alpha = 0.0;
            } completion:^(BOOL finished) {
                [download removeFromSuperview];
            }];
        }
    });
}

- (void) updateTopControlsVisibility:(BOOL)animated
{
    BOOL isDashboardVisible = [_mapPanelViewController isDashboardVisible];
    BOOL isRouteInfoVisible = [_mapPanelViewController isRouteInfoVisible];
    BOOL isWeatherToolbarVisible = _mapInfoController.weatherToolbarVisible;
    BOOL isScrollableHudVisible = _mapPanelViewController.scrollableHudViewController != nil || _mapPanelViewController.prevScrollableHudViewController != nil;
    BOOL isTopPanelVisible = _mapInfoController.topPanelController && [_mapInfoController.topPanelController hasWidgets];
    BOOL isLeftPanelVisible = [self hasLeftWidget];
    BOOL isRightPanelVisible = [self hasRightWidget];
    BOOL isTargetToHideVisible = _mapPanelViewController.activeTargetType == OATargetGPX
        || _mapPanelViewController.activeTargetType == OATargetWeatherLayerSettings
        || _mapPanelViewController.activeTargetType == OATargetRouteLineAppearance
        || _mapPanelViewController.activeTargetType == OATargetTerrainParametersSettings
        || _mapPanelViewController.activeTargetType == OATargetMapModeParametersSettings
        || _mapPanelViewController.activeTargetType == OATargetRouteDetails
        || _mapPanelViewController.activeTargetType == OATargetRouteDetailsGraph
        || _mapPanelViewController.activeTargetType == OATargetProfileAppearanceIconSizeSettings;
    BOOL isInContextMenuVisible = self.contextMenuMode && !isTargetToHideVisible;
    BOOL isTargetBackButtonVisible = [_mapPanelViewController isTargetBackButtonVisible];
    BOOL isToolbarAllowed = !self.contextMenuMode && !isDashboardVisible && !isWeatherToolbarVisible;
    BOOL isToolbarVisible = isToolbarAllowed && _toolbarViewController && _toolbarViewController.view.superview;
    BOOL isAllowToolbarsVisible = (isToolbarVisible && ([_mapPanelViewController isTopToolbarSearchVisible] || [_mapPanelViewController isTopToolbarDiscountVisible]));
    BOOL isButtonsVisible = isToolbarVisible ? isAllowToolbarsVisible
        : (isInContextMenuVisible || (!isWeatherToolbarVisible && !isDashboardVisible && !isRouteInfoVisible && !isTargetToHideVisible));
    BOOL isPanelAllowed = isButtonsVisible && !self.contextMenuMode && !isScrollableHudVisible && _mapPanelViewController.activeTargetType != OATargetChangePosition;

    void (^mainBlock)(void) = ^{
        _statusBarView.alpha = isTopPanelVisible || isToolbarVisible ? 1. : 0.;
        _mapSettingsButton.alpha = [self shouldShowConfigureMap] && isButtonsVisible && !isTargetBackButtonVisible ? 1. : 0.;
        _compassButton.alpha = [self shouldShowCompass] && isButtonsVisible ? 1. : 0.;
        _searchButton.alpha = [self shouldShowSearch] && isButtonsVisible && !isTargetBackButtonVisible ? 1. : 0.;
        _downloadView.alpha = isButtonsVisible ? 1. : 0.;
        
        if (_toolbarViewController && _toolbarViewController.view.superview)
            _toolbarViewController.view.alpha = isToolbarAllowed ? 1. : 0.;
        if (self.mapInfoController.topPanelController)
        {
            self.mapInfoController.topPanelController.view.alpha = !isTopPanelVisible || !isPanelAllowed || isToolbarVisible ? 0. : 1.;
            [self.middleWidgetsView showShadow:self.mapInfoController.topPanelController.view.alpha == 1.];
        }
        if (self.mapInfoController.leftPanelController)
        {
            self.mapInfoController.leftPanelController.view.alpha = isWeatherToolbarVisible || !isLeftPanelVisible || !isPanelAllowed || isToolbarVisible ? 0. : 1.;
            [self.leftWidgetsView showShadow:self.mapInfoController.leftPanelController.view.alpha == 1.];
        }
        if (self.mapInfoController.rightPanelController)
        {
            self.mapInfoController.rightPanelController.view.alpha = isWeatherToolbarVisible ? 1. : !isRightPanelVisible || !isPanelAllowed || isToolbarVisible ? 0. : 1.;
            [self.rightWidgetsView showShadow:self.mapInfoController.rightPanelController.view.alpha == 1.];
        }
        if (self.downloadMapWidget)
            self.downloadMapWidget.alpha = isButtonsVisible ? 1. : 0.;
        
        [self updateTopButtonsLayoutY];

    };

    void (^completionBlock)(BOOL) = ^(BOOL finished) {

        _statusBarView.userInteractionEnabled = _statusBarView.alpha > 0.;
        _mapSettingsButton.userInteractionEnabled = _mapSettingsButton.alpha > 0.;
        _compassButton.userInteractionEnabled = _compassButton.alpha > 0.;
        _searchButton.userInteractionEnabled = _searchButton.alpha > 0.;
        _downloadView.userInteractionEnabled = _downloadView.alpha > 0.;

        if (self.mapInfoController.topPanelController)
            self.mapInfoController.topPanelController.view.userInteractionEnabled = self.mapInfoController.topPanelController.view.alpha > 0.;
        if (self.mapInfoController.leftPanelController)
            self.mapInfoController.leftPanelController.view.userInteractionEnabled = self.mapInfoController.leftPanelController.view.alpha > 0.;
        if (self.mapInfoController.rightPanelController)
            self.mapInfoController.rightPanelController.view.userInteractionEnabled = self.mapInfoController.rightPanelController.view.alpha > 0.;
        if (self.downloadMapWidget)
            self.downloadMapWidget.userInteractionEnabled = self.downloadMapWidget.alpha > 0.;

    };

    if (animated)
    {
        [UIView animateWithDuration:.3 animations:mainBlock completion:completionBlock];
    }
    else
    {
        mainBlock();
        completionBlock(YES);
    }
}

- (void) updateBottomControlsVisibility:(BOOL)animated
{
    BOOL isDashboardVisible = [_mapPanelViewController isDashboardVisible];
    BOOL isRouteInfoVisible = [_mapPanelViewController isRouteInfoVisible];
    BOOL isWeatherToolbarVisible = _mapInfoController.weatherToolbarVisible;
    BOOL isScrollableHudVisible = _mapPanelViewController.scrollableHudViewController != nil || _mapPanelViewController.prevScrollableHudViewController != nil;
    BOOL isScrollableHudAllowed = _mapPanelViewController.activeTargetType == OATargetMapModeParametersSettings;
    BOOL isTargetMultiMenuViewVisible = [_mapPanelViewController isTargetMultiMenuViewVisible];
    BOOL isBottomPanelVisible = _mapInfoController.bottomPanelController && [_mapInfoController.bottomPanelController hasWidgets];
    BOOL isAllHidden = _mapPanelViewController.activeTargetType == OATargetRouteLineAppearance || _mapPanelViewController.activeTargetType == OATargetProfileAppearanceIconSizeSettings;
    BOOL isTargetToHideVisible = _mapPanelViewController.activeTargetType == OATargetChangePosition
        || _mapPanelViewController.activeTargetType == OATargetRouteLineAppearance;
    BOOL isToolbarAllowed = !self.contextMenuMode && !isDashboardVisible & !isTargetMultiMenuViewVisible && !isWeatherToolbarVisible;
    BOOL isToolbarVisible = isToolbarAllowed && _toolbarViewController && _toolbarViewController.view.superview;
    BOOL isAllowToolbarsVisible = isToolbarVisible;
    BOOL visible = isToolbarVisible ? isAllowToolbarsVisible
        : !self.contextMenuMode && !isWeatherToolbarVisible && !isScrollableHudVisible && !isDashboardVisible && !isRouteInfoVisible && !isTargetMultiMenuViewVisible && !isTargetToHideVisible;
    BOOL isZoomMapModeVisible = (!isDashboardVisible || isScrollableHudAllowed) && !isRouteInfoVisible && !isTargetMultiMenuViewVisible;

    void (^mainBlock)(void) = ^{

        _bottomBarView.alpha = visible && isBottomPanelVisible ? 1.0 : 0.0;
        BOOL optionsMenuButtonVisible = visible;
        _optionsMenuButton.alpha = [self shouldShowMenu] && optionsMenuButtonVisible ? 1. : 0.;
        BOOL zoomButtonsVisible = isToolbarVisible ? isAllowToolbarsVisible : (isZoomMapModeVisible && !isAllHidden);
        _zoomInButton.alpha = [self shouldShowZoomIn] && zoomButtonsVisible ? 1. : 0.;
        _zoomOutButton.alpha = [self shouldShowZoomOut] && zoomButtonsVisible ? 1. : 0.;
        BOOL mapModeButtonVisible = isToolbarVisible ? isAllowToolbarsVisible : (isZoomMapModeVisible && !isAllHidden);
        _mapModeButton.alpha = [self shouldShowMyLocation] && mapModeButtonVisible ? 1. : 0.;
        BOOL driveModeButtonVisible = visible;
        _driveModeButton.alpha = [self shouldShowNavigation] && driveModeButtonVisible ? 1. : 0.;
        _rulerLabel.alpha = (self.contextMenuMode && !isScrollableHudVisible) || isAllHidden || (isDashboardVisible && !isScrollableHudAllowed) ? 0. : 1.;

        if (self.mapInfoController.bottomPanelController)
            self.mapInfoController.bottomPanelController.view.alpha = visible && isBottomPanelVisible && (!isToolbarVisible || isAllowToolbarsVisible) ? 1. : 0.;
        [self updateBottomContolMarginsForHeight];
    };

    void (^completionBlock)(BOOL) = ^(BOOL finished) {

        _bottomBarView.userInteractionEnabled = _bottomBarView.alpha > 0.;
        _optionsMenuButton.userInteractionEnabled = _optionsMenuButton.alpha > 0.;
        _zoomInButton.userInteractionEnabled = _zoomInButton.alpha > 0.;
        _zoomOutButton.userInteractionEnabled = _zoomOutButton.alpha > 0.;
        _mapModeButton.userInteractionEnabled = _mapModeButton.alpha > 0.;
        _driveModeButton.userInteractionEnabled = _driveModeButton.alpha > 0.;

        if (self.mapInfoController.bottomPanelController)
            self.mapInfoController.bottomPanelController.view.userInteractionEnabled = self.mapInfoController.bottomPanelController.view.alpha > 0.;

    };

    if (animated)
    {
        [UIView animateWithDuration:.3 animations:mainBlock completion:completionBlock];
    }
    else
    {
        mainBlock();
        completionBlock(YES);
    }
}

- (void) updateBottomContolMarginsForHeight
{
    CGFloat bottomOffset = [self getBottomHudOffset];
    if ([OAUtilities isLandscape])
    {
        _weatherLayersButton.frame = CGRectMake(CGRectGetMaxX(_weatherToolbar.frame) + 20, bottomOffset - _weatherLayersButton.bounds.size.height, _weatherLayersButton.bounds.size.width, _weatherLayersButton.bounds.size.height);
        
        _weatherContoursButton.frame = CGRectMake(CGRectGetMaxX(_weatherToolbar.frame) + 20, CGRectGetMinY(_weatherLayersButton.frame) - 64, _weatherContoursButton.bounds.size.width, _weatherContoursButton.bounds.size.height);
    }
    else
    {
        _weatherLayersButton.frame = CGRectMake([self getExtraScreenOffset], bottomOffset - _weatherLayersButton.bounds.size.height - (_mapInfoController.weatherToolbarVisible ? 0. : (kButtonOffset + _optionsMenuButton.bounds.size.height)), _weatherLayersButton.bounds.size.width, _weatherLayersButton.bounds.size.height);
        
        _weatherContoursButton.frame = CGRectMake([self getExtraScreenOffset], bottomOffset - _weatherLayersButton.bounds.size.height - 64 - (_mapInfoController.weatherToolbarVisible ? 0. : (kButtonOffset + _optionsMenuButton.bounds.size.height)), _weatherContoursButton.bounds.size.width, _weatherContoursButton.bounds.size.height);
    }
    
    [self updateBottomButtonsLayout];
}

- (CGFloat) getBottomHudOffset
{
    BOOL isLandscape = [OAUtilities isLandscape];
    BOOL isScrollableHudVisible = _mapPanelViewController.scrollableHudViewController && _mapPanelViewController.scrollableHudViewController.view.superview;
    CGFloat bottomOffset = DeviceScreenHeight - kButtonOffset;
    BOOL isIPad = [OAUtilities isIPad];
    BOOL isPlanRoute = _mapPanelViewController.activeTargetType == OATargetRoutePlanning;
    BOOL isIPadAllowed = isPlanRoute;
    if (self.contextMenuMode && (!isLandscape || isIPadAllowed))
    {
        CGFloat contextMenuHeight = 0.;
        if (!isIPad || isIPadAllowed)
        {
            if (_mapPanelViewController.scrollableHudViewController && _mapPanelViewController.scrollableHudViewController.view.superview)
            {
                if (isPlanRoute && isLandscape)
                    contextMenuHeight = [_mapPanelViewController.scrollableHudViewController getToolbarHeight] + [OAUtilities getBottomMargin];
                else
                    contextMenuHeight = [_mapPanelViewController.scrollableHudViewController getViewHeight];
            }
            else
            {
                contextMenuHeight = [_mapPanelViewController getTargetMenuHeight];
            }
        }
        bottomOffset -= contextMenuHeight;
    }
    else
    {
        if (_mapInfoController.weatherToolbarVisible && !isLandscape)
            bottomOffset -= self.weatherToolbar.frame.size.height;
        else if (self.contextMenuMode ? !isScrollableHudVisible : (_mapInfoController.bottomPanelController && [_mapInfoController.bottomPanelController hasWidgets]))
            bottomOffset -= self.contextMenuMode || isLandscape || [OAUtilities isIPad] ? [self getHudMinBottomOffset] : [self getHudBottomOffset];
        else
            bottomOffset -= [self getHudMinBottomOffset];
    }
    return bottomOffset;
}

- (void) onLastMapSourceChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![self isViewLoaded])
            return;
        
        [self updateMapSettingsButton];
        [self updateMapModeButton];
        [self updateCompassButton];
    });
}

- (void) updateMapSettingsButton
{
    OAApplicationMode *mode = [_settings.applicationMode get];
    [_mapSettingsButton setImage:mode.getIcon forState:UIControlStateNormal];
    _mapSettingsButton.tintColorDay = [mode getProfileColor];
    _mapSettingsButton.tintColorNight = [mode getProfileColor];
    [_mapSettingsButton updateColorsForPressedState:NO];
    [self updateMapSettingsButtonAccessibilityValue];
}

- (void) updateMapSettingsButtonAccessibilityValue
{
    NSString *stringKey = [_settings.applicationMode get].stringKey;
    
    if ([stringKey isEqualToString:@"default"])
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"app_mode_default");
    else if ([stringKey isEqualToString:@"car"])
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"app_mode_car");
    else if ([stringKey isEqualToString:@"bicycle"])
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"app_mode_bicycle");
    else if ([stringKey isEqualToString:@"pedestrian"])
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"app_mode_pedestrian");
    else if ([stringKey isEqualToString:@"public_transport"])
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"poi_filter_public_transport");
    else if ([stringKey isEqualToString:@"aircraft"])
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"app_mode_aircraft");
    else if ([stringKey isEqualToString:@"truck"])
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"app_mode_truck");
    else if ([stringKey isEqualToString:@"motorcycle"])
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"app_mode_motorcycle");
    else if ([stringKey isEqualToString:@"moped"])
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"app_mode_moped");
    else if ([stringKey isEqualToString:@"boat"])
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"app_mode_boat");
    else if ([stringKey isEqualToString:@"ski"])
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"app_mode_skiing");
    else if ([stringKey isEqualToString:@"horse"])
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"horseback_riding");
    else if ([stringKey isEqualToString:@"train"])
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"app_mode_train");
    else
        _mapSettingsButton.accessibilityValue = OALocalizedString(@"profile_type_user_string");
}

- (void) enterContextMenuMode
{
    if (!self.contextMenuMode)
        self.contextMenuMode = YES;
    [self updateMapModeButton];
}

- (void) restoreFromContextMenuMode
{
    if (self.contextMenuMode)
    {
        self.contextMenuMode = NO;
        [self updateMapModeButton];
        [self updateControlsLayout:YES];
    }
}

- (void) onRoutingProgressChanged:(int)progress
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (!self.isViewLoaded || self.view.window == nil)
            return;
        
        if (!_routingProgressView)
        {
            _routingProgressView = [[OARoutingProgressView alloc] initWithFrame:[self getRoutingProgressViewFrame]];
            [self.view insertSubview:_routingProgressView aboveSubview:self.searchButton];
        }
        
        [_routingProgressView setProgress:(double)progress / 100.0];
    });
}

- (void) onRoutingProgressFinished
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded)
            return;
        
        OARoutingProgressView *progress = _routingProgressView;
        _routingProgressView  = nil;
        [UIView animateWithDuration:.3 animations:^{
            progress.alpha = 0.0;
        } completion:^(BOOL finished) {
            [progress removeFromSuperview];
        }];
    });
}

- (void) updateRouteButton:(BOOL)routePlanningMode followingMode:(BOOL)followingMode
{
    if (followingMode)
    {
        [_driveModeButton setImage:[[UIImage templateImageNamed:@"ic_custom_navigation_arrow"] imageFlippedForRightToLeftLayoutDirection] forState:UIControlStateNormal];
        _driveModeButton.tintColorDay = UIColorFromRGB(color_primary_purple);
        _driveModeButton.tintColorNight = UIColorFromRGB(color_primary_light_blue);
        _driveModeButton.accessibilityValue = OALocalizedString(@"simulate_in_progress");
    }
    else if (routePlanningMode)
    {
        [_driveModeButton setImage:[[UIImage templateImageNamed:@"ic_custom_navigation"] imageFlippedForRightToLeftLayoutDirection] forState:UIControlStateNormal];
        _driveModeButton.tintColorDay = UIColorFromRGB(color_primary_purple);
        _driveModeButton.tintColorNight = UIColorFromRGB(color_primary_light_blue);
        _driveModeButton.accessibilityValue = OALocalizedString(@"simulate_in_progress");
    }
    else
    {
        [_driveModeButton setImage:[[UIImage templateImageNamed:@"ic_custom_navigation"] imageFlippedForRightToLeftLayoutDirection] forState:UIControlStateNormal];
        _driveModeButton.tintColorDay = UIColorFromRGB(color_on_map_icon_tint_color_light);
        _driveModeButton.tintColorNight = UIColorFromRGB(color_on_map_icon_tint_color_dark);
        _driveModeButton.accessibilityValue = nil;
    }

    [_driveModeButton updateColorsForPressedState:NO];
}

- (void) recreateAllControls
{
    [_mapInfoController recreateAllControls];
}

- (void) recreateControls
{
    [_mapInfoController recreateControls];
}

- (void) updateInfo
{
    [_mapInfoController updateInfo];
}

#pragma mark - OAMapInfoControllerProtocol

- (void)widgetsLayoutDidChange:(BOOL)animated
{
    NSTimeInterval now = CACurrentMediaTime();
    NSTimeInterval elapsed = now - _lastWidgetsUpdateTime;
    if (elapsed >= kWidgetsUpdateFrameInterval)
    {
        [self coalescedWidgetsUpdate:@(animated)];
    }
    else
    {
        NSTimeInterval delay = kWidgetsUpdateFrameInterval - elapsed;
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(coalescedWidgetsUpdate:) object:nil];
        [self performSelector:@selector(coalescedWidgetsUpdate:) withObject:@(animated) afterDelay:delay];
    }
}

- (void)coalescedWidgetsUpdate:(NSNumber *)animatedNumber
{
    _lastWidgetsUpdateTime = CACurrentMediaTime();
    [self updateControlsLayout:animatedNumber.boolValue];
    [_mapHudLayout updateButtons];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
