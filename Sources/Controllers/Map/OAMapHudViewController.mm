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

#define _(name) OAMapModeHudViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

static const float kButtonWidth = 50.0;
static const float kButtonOffset = 16.0;
static const float kButtonHeight = 50.0;
static const float kWidgetsOffset = 3.0;
static const float kDistanceMeters = 100.0;


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

    OAOverlayUnderlayView* _overlayUnderlayView;
    
    NSLayoutConstraint *_bottomRulerConstraint;
    NSLayoutConstraint *_leftRulerConstraint;
    
    CLLocation *_previousLocation;
    
    BOOL _cachedLocationAvailableState;
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

- (void) dealloc
{
    [self deinit];
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
    
    _locationServicesStatusObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                        withHandler:@selector(onLocationServicesStatusChanged)
                                                                         andObserve:_app.locationServices.statusObservable];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onProfileSettingSet:) name:kNotificationSetProfileSetting object:nil];
    
    _cachedLocationAvailableState = NO;
}

- (void) deinit
{

}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _mapInfoController = [[OAMapInfoController alloc] initWithHudViewController:self];

    _driveModeButton.hidden = NO;
    _driveModeButton.userInteractionEnabled = YES;
    [self updateRouteButton:NO followingMode:NO];

    self.statusBarViewHeightConstraint.constant = [OAUtilities isIPad] || ![OAUtilities isLandscape] ? [OAUtilities getStatusBarHeight] : 0.;
    self.bottomBarViewHeightConstraint.constant = [OAUtilities getBottomMargin];

    _compassImage.transform = CGAffineTransformMakeRotation(-_mapViewController.mapRendererView.azimuth / 180.0f * M_PI);
    _compassBox.alpha = ([self shouldShowCompass] ? 1.0 : 0.0);
    _compassBox.userInteractionEnabled = _compassBox.alpha > 0.0;

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
    self.rulerLabel = [[OAMapRulerView alloc] initWithFrame:CGRectMake(120, DeviceScreenHeight - 42, kMapRulerMinWidth, 25)];
    self.rulerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.rulerLabel];

    // Constraints
    _bottomRulerConstraint = [NSLayoutConstraint constraintWithItem:self.rulerLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:-17.0f];
    [self.view addConstraint:_bottomRulerConstraint];

    _leftRulerConstraint = [NSLayoutConstraint constraintWithItem:self.rulerLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0f constant:148.0f];
    [self.view addConstraint:_leftRulerConstraint];

    NSLayoutConstraint *constraint = [NSLayoutConstraint constraintWithItem:self.rulerLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:25];
    [self.view addConstraint:constraint];
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
            CGFloat x2 = _zoomButtonsView.frame.origin.x - 8.0;
            
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

- (void) updateRulerPosition:(CGFloat)bottom left:(CGFloat)left
{
    _bottomRulerConstraint.constant = bottom;
    _leftRulerConstraint.constant = left;
    [self.rulerLabel layoutIfNeeded];
}

- (void) resetToDefaultRulerLayout
{
    BOOL isLandscape = [OAUtilities isLandscape];
    BOOL isIPad = [OAUtilities isIPad];

    BOOL isTrackMenuVisible = _mapPanelViewController.activeTargetType == OATargetGPX;
    BOOL isPlanRouteVisible = _mapPanelViewController.activeTargetType == OATargetRoutePlanning;
    BOOL isWeatherVisible = _mapInfoController.weatherToolbarVisible;
    BOOL isBottomWidgetsVisible = _mapInfoController.bottomPanelController && [_mapInfoController.bottomPanelController hasWidgets];

    CGFloat bottomOffset = DeviceScreenHeight - ((isLandscape || isIPad) && isBottomWidgetsVisible ? (_optionsMenuButton.frame.origin.y - kButtonOffset) : [self getBottomHudOffset]);
    CGFloat leftOffset = kButtonOffset;

    if (isPlanRouteVisible && (isLandscape || isIPad))
        bottomOffset = kButtonOffset + [_mapPanelViewController.scrollableHudViewController getToolbarHeight] + OAUtilities.getBottomMargin;

    if ([_mapPanelViewController isTargetMapRulerNeeds])
        leftOffset += isLandscape ? [_mapPanelViewController getTargetContainerWidth] : 0.;
    else if (isPlanRouteVisible)
        leftOffset += kButtonWidth + kButtonOffset + (isLandscape ? [_mapPanelViewController.scrollableHudViewController getLandscapeViewWidth] : 0.);
    else if (isWeatherVisible)
    {
        leftOffset += isLandscape ? self.weatherToolbar.frame.size.width + 70: (kButtonWidth + kButtonOffset) + 50;
        
        bottomOffset = isLandscape ?  OAUtilities.getBottomMargin + 25 : self.weatherToolbar.frame.size.height + 25;
    } else if (!self.contextMenuMode)
        leftOffset += (isLandscape || isIPad) && isBottomWidgetsVisible ? _optionsMenuButton.frame.size.width : (_driveModeButton.frame.origin.x + _driveModeButton.frame.size.width);
    else if (isTrackMenuVisible && isLandscape)
        leftOffset += isLandscape ? [_mapPanelViewController.scrollableHudViewController getLandscapeViewWidth] : 0.;

    [self updateRulerPosition:-bottomOffset left:leftOffset];
}

- (void)updateMapRulerData
{
    [self.rulerLabel setRulerData:[_mapViewController calculateMapRuler]];
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

- (BOOL) shouldShowCompass:(float)azimuth
{
    NSInteger rotateMap = [_settings.rotateMap get];
    CompassVisibility compassVisibility = [[[OAMapButtonsHelper sharedInstance] getCompassButtonState] getVisibility];
    return (((azimuth != 0.0 || rotateMap != ROTATE_MAP_NONE) && compassVisibility == CompassVisibilityVisibleIfMapRotated) || compassVisibility == CompassVisibilityAlwaysVisible) && _mapSettingsButton.alpha == 1.0;
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
        
        _compassImage.transform = CGAffineTransformMakeRotation(-[value floatValue] / 180.0f * M_PI);
        
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

- (void) updateDependentButtonsVisibility
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
        OACommonInteger *compassButtonState = [mapButtonsHelper getCompassButtonState].visibilityPref;
        OACommonInteger *map3DButtonState = [mapButtonsHelper getMap3DButtonState].visibilityPref;

        BOOL isQuickAction = NO;
        for (QuickActionButtonState *buttonState in [mapButtonsHelper getButtonsStates])
        {
            if (obj == buttonState.statePref || obj == buttonState.quickActionsPref)
            {
                isQuickAction = YES;
                break;
            }
        }

        if (obj == _settings.rotateMap || obj == compassButtonState)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateCompassButton];
            });
        }
        else if (obj == _settings.transparentMapTheme)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateColors];
            });
        }
        else if (obj == map3DButtonState || isQuickAction)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateDependentButtonsVisibility];
            });
        }
    }
}

- (void) updateCompassVisibility:(BOOL)showCompass
{
    BOOL needShow = _compassBox.alpha == 0.0 && showCompass && _mapSettingsButton.alpha == 1.0;
    BOOL needHide = _compassBox.alpha == 1.0 && !showCompass;
    if (needShow)
        [self showCompass];
    else if (needHide)
        [self hideCompass];
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
    [UIView animateWithDuration:.25 animations:^{
        _compassBox.alpha = 1.0;
    } completion:^(BOOL finished) {
        _compassBox.userInteractionEnabled = _compassBox.alpha > 0.0;
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
    [UIView animateWithDuration:.25 animations:^{
        _compassBox.alpha = 0.0;
    } completion:^(BOOL finished) {
        _compassBox.userInteractionEnabled = _compassBox.alpha > 0.0;
    }];
}

- (void) updateCompassButton
{
    OACommonInteger *rotateMap = _settings.rotateMap;
    BOOL isNight = _settings.nightMode;
    BOOL showCompass = [self shouldShowCompass];
    if ([rotateMap get] == ROTATE_MAP_NONE)
    {
        _compassImage.image = [UIImage imageNamed:isNight ? @"ic_custom_direction_north_night" : @"ic_custom_direction_north_day"];
        _compassButton.accessibilityValue = OALocalizedString(@"rotate_map_north_opt");
    }
    else if ([rotateMap get] == ROTATE_MAP_BEARING)
    {
        _compassImage.image = [UIImage imageNamed:isNight ? @"ic_custom_direction_bearing_night" : @"ic_custom_direction_bearing_day"];
        _compassButton.accessibilityValue = OALocalizedString(@"rotate_map_bearing_opt");
    }
    else if ([rotateMap get] == ROTATE_MAP_MANUAL)
    {
        _compassImage.image = [UIImage imageNamed:isNight ? @"ic_custom_direction_manual_night" : @"ic_custom_direction_manual_day"];
        _compassButton.accessibilityValue = OALocalizedString(@"rotate_map_manual_opt");
    }
    else
    {
        _compassImage.image = [UIImage imageNamed:isNight ? @"ic_custom_direction_compass_night" : @"ic_custom_direction_compass_day"];
        _compassButton.accessibilityValue = OALocalizedString(@"rotate_map_compass_opt");
    }
    [self updateCompassVisibility:showCompass];
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
        [_downloadMapWidget removeFromSuperview];

    _downloadMapWidget = widget;

    if (![self.view.subviews containsObject:_downloadMapWidget])
    {
        [self.view addSubview:_downloadMapWidget];
        [self.view insertSubview:_downloadMapWidget aboveSubview:_toolbarViewController.view];
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
    CGFloat y = [self getHudTopOffset];
    CGFloat x = [self getExtraScreenOffset];
    CGRect frame = _compassBox.frame;
    CGFloat msX = [self getExtraScreenOffset];
    CGRect msFrame = _mapSettingsButton.frame;
    CGFloat sX = [self getExtraScreenOffset] + kButtonWidth + kButtonOffset;
    CGRect sFrame = _searchButton.frame;
    CGFloat buttonsY = y + kButtonOffset;
    if (!CGRectEqualToRect(_mapSettingsButton.frame, CGRectMake(x, buttonsY, frame.size.width, frame.size.height)))
    {
        _compassBox.frame = CGRectMake(x, buttonsY + kButtonOffset + kButtonWidth, frame.size.width, frame.size.height);
        _mapSettingsButton.frame = CGRectMake(msX, buttonsY, msFrame.size.width, msFrame.size.height);
        _searchButton.frame = CGRectMake(sX, buttonsY, sFrame.size.width, sFrame.size.height);
    }
}

- (BOOL)hasTopWidget {
    return [_mapInfoController.topPanelController hasWidgets];
}

- (BOOL)isRightPanelVisible
{
    return _mapInfoController.rightPanelController && [_mapInfoController.rightPanelController hasWidgets];
}

- (BOOL)isLeftPanelVisible
{
    return _mapInfoController.leftPanelController && [_mapInfoController.leftPanelController hasWidgets];
}

- (void) updateBottomButtonsLayout
{
    CGFloat x = [self getExtraScreenOffset];
    CGFloat origButtonsY = DeviceScreenHeight - [self getHudMinBottomOffset] - kButtonOffset - kButtonHeight;
    CGFloat buttonsY = DeviceScreenHeight - [self getHudBottomOffset] - kButtonOffset - kButtonHeight;
    CGRect frame = _optionsMenuButton.frame;
    BOOL hasWidgets = _mapInfoController.bottomPanelController && [_mapInfoController.bottomPanelController hasWidgets];
    if ((hasWidgets && !CGRectEqualToRect(_optionsMenuButton.frame, CGRectMake(x, buttonsY, frame.size.width, frame.size.height)))
     || (!hasWidgets && !CGRectEqualToRect(_optionsMenuButton.frame, CGRectMake(x, origButtonsY, frame.size.width, frame.size.height))))
        [self updateBottomContolMarginsForHeight];
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
    else
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
        
        if (![_downloadView.titleView.text isEqualToString:task.name])
            [_downloadView setTitle: task.name];
        
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
    BOOL isLeftPanelVisible = [self isLeftPanelVisible];
    BOOL isRightPanelVisible = [self isRightPanelVisible];
    BOOL isTargetToHideVisible = _mapPanelViewController.activeTargetType == OATargetGPX
        || _mapPanelViewController.activeTargetType == OATargetWeatherLayerSettings
        || _mapPanelViewController.activeTargetType == OATargetRouteLineAppearance
        || _mapPanelViewController.activeTargetType == OATargetTerrainParametersSettings
        || _mapPanelViewController.activeTargetType == OATargetMapModeParametersSettings
        || _mapPanelViewController.activeTargetType == OATargetRouteDetails
        || _mapPanelViewController.activeTargetType == OATargetRouteDetailsGraph;
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
        _mapSettingsButton.alpha = isButtonsVisible && !isTargetBackButtonVisible ? 1. : 0.;
        _compassBox.alpha = ([self shouldShowCompass] && isButtonsVisible ? 1. : 0.);
        _searchButton.alpha = isButtonsVisible && !isTargetBackButtonVisible ? 1. : 0.;
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
        _compassBox.userInteractionEnabled = _compassBox.alpha > 0.;
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
    BOOL isTargetMultiMenuViewVisible = [_mapPanelViewController isTargetMultiMenuViewVisible];
    BOOL isBottomPanelVisible = _mapInfoController.bottomPanelController && [_mapInfoController.bottomPanelController hasWidgets];
    BOOL isAllHidden = _mapPanelViewController.activeTargetType == OATargetRouteLineAppearance;
    BOOL isTargetToHideVisible = _mapPanelViewController.activeTargetType == OATargetChangePosition
        || _mapPanelViewController.activeTargetType == OATargetRouteLineAppearance;
    BOOL isToolbarAllowed = !self.contextMenuMode && !isDashboardVisible & !isTargetMultiMenuViewVisible && !isWeatherToolbarVisible;
    BOOL isToolbarVisible = isToolbarAllowed && _toolbarViewController && _toolbarViewController.view.superview;
    BOOL isAllowToolbarsVisible = isToolbarVisible;
    BOOL visible = isToolbarVisible ? isAllowToolbarsVisible
        : !self.contextMenuMode && !isWeatherToolbarVisible && !isScrollableHudVisible && !isDashboardVisible && !isRouteInfoVisible && !isTargetMultiMenuViewVisible && !isTargetToHideVisible;
    BOOL isZoomMapModeVisible = !isDashboardVisible && !isRouteInfoVisible && !isTargetMultiMenuViewVisible;

    void (^mainBlock)(void) = ^{

        _bottomBarView.alpha = visible && isBottomPanelVisible ? 1.0 : 0.0;
        BOOL optionsMenuButtonVisible = visible;
        _optionsMenuButton.alpha = optionsMenuButtonVisible ? 1. : 0.;
        BOOL zoomButtonsVisible = isToolbarVisible ? isAllowToolbarsVisible : (isZoomMapModeVisible && !isAllHidden);
        _zoomButtonsView.alpha = zoomButtonsVisible ? 1. : 0.;
        BOOL mapModeButtonVisible = isToolbarVisible ? isAllowToolbarsVisible : (isZoomMapModeVisible && !isAllHidden);
        _mapModeButton.alpha = mapModeButtonVisible ? 1. : 0.;
        BOOL driveModeButtonVisible = visible;
        _driveModeButton.alpha = driveModeButtonVisible ? 1. : 0.;
        _rulerLabel.alpha = (self.contextMenuMode && !isScrollableHudVisible) || isAllHidden || isDashboardVisible ? 0. : 1.;

        if (self.mapInfoController.bottomPanelController)
            self.mapInfoController.bottomPanelController.view.alpha = visible && isBottomPanelVisible && (!isToolbarVisible || isAllowToolbarsVisible) ? 1. : 0.;
        [self updateBottomContolMarginsForHeight];

        CGFloat offsetValue = 50;
        if (!optionsMenuButtonVisible)
            [self addOffsetToView:_optionsMenuButton x:-offsetValue y:0.];
        if (!driveModeButtonVisible)
            [self addOffsetToView:_driveModeButton x:-offsetValue y:0.];
        if (!mapModeButtonVisible)
            [self addOffsetToView:_mapModeButton x:offsetValue y:0.];
        if (!zoomButtonsVisible)
            [self addOffsetToView:_zoomButtonsView x:offsetValue y:0.];

    };

    void (^completionBlock)(BOOL) = ^(BOOL finished) {

        _bottomBarView.userInteractionEnabled = _bottomBarView.alpha > 0.;
        _optionsMenuButton.userInteractionEnabled = _optionsMenuButton.alpha > 0.;
        _zoomButtonsView.userInteractionEnabled = _zoomButtonsView.alpha > 0.;
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

    if ([OAUtilities isLandscape]) {
        _weatherLayersButton.frame = CGRectMake(CGRectGetMaxX(_weatherToolbar.frame) + 20, bottomOffset - _weatherLayersButton.bounds.size.height, _weatherLayersButton.bounds.size.width, _weatherLayersButton.bounds.size.height);
        
        _weatherContoursButton.frame = CGRectMake(CGRectGetMaxX(_weatherToolbar.frame) + 20, CGRectGetMinY(_weatherLayersButton.frame) - 70, _weatherContoursButton.bounds.size.width, _weatherContoursButton.bounds.size.height);
    } else {
        _weatherLayersButton.frame = CGRectMake([self getExtraScreenOffset], bottomOffset - _weatherLayersButton.bounds.size.height - (_mapInfoController.weatherToolbarVisible ? 0. : (kButtonOffset + _optionsMenuButton.bounds.size.height)), _weatherLayersButton.bounds.size.width, _weatherLayersButton.bounds.size.height);
        
        _weatherContoursButton.frame = CGRectMake([self getExtraScreenOffset], bottomOffset - _weatherLayersButton.bounds.size.height - 70 - (_mapInfoController.weatherToolbarVisible ? 0. : (kButtonOffset + _optionsMenuButton.bounds.size.height)), _weatherContoursButton.bounds.size.width, _weatherContoursButton.bounds.size.height);
    }

    _optionsMenuButton.frame = CGRectMake([self getExtraScreenOffset], bottomOffset - _optionsMenuButton.bounds.size.height, _optionsMenuButton.bounds.size.width, _optionsMenuButton.bounds.size.height);
    _driveModeButton.frame = CGRectMake([self getExtraScreenOffset] + kButtonWidth + kButtonOffset, bottomOffset - _driveModeButton.bounds.size.height, _driveModeButton.bounds.size.width, _driveModeButton.bounds.size.height);
    _mapModeButton.frame = CGRectMake(self.view.bounds.size.width - 2 * kButtonWidth - kButtonOffset - [self getExtraScreenOffset], bottomOffset - _mapModeButton.bounds.size.height, _mapModeButton.bounds.size.width, _mapModeButton.bounds.size.height);
    _zoomButtonsView.frame = CGRectMake(self.view.bounds.size.width - kButtonWidth - [self getExtraScreenOffset], bottomOffset - _zoomButtonsView.bounds.size.height, _zoomButtonsView.bounds.size.width, _zoomButtonsView.bounds.size.height);
    
    [self resetToDefaultRulerLayout];
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

- (void) addOffsetToView:(UIView *)view x:(CGFloat)x y:(CGFloat)y
{
    view.frame = CGRectMake(view.frame.origin.x + x, view.frame.origin.y + y, view.frame.size.width, view.frame.size.height);
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
        [_driveModeButton setImage:[UIImage templateImageNamed:@"ic_custom_navigation_arrow"] forState:UIControlStateNormal];
        _driveModeButton.tintColorDay = UIColorFromRGB(color_primary_purple);
        _driveModeButton.tintColorNight = UIColorFromRGB(color_primary_light_blue);
        _driveModeButton.accessibilityValue = OALocalizedString(@"simulate_in_progress");
    }
    else if (routePlanningMode)
    {
        [_driveModeButton setImage:[UIImage templateImageNamed:@"ic_custom_navigation"] forState:UIControlStateNormal];
        _driveModeButton.tintColorDay = UIColorFromRGB(color_primary_purple);
        _driveModeButton.tintColorNight = UIColorFromRGB(color_primary_light_blue);
        _driveModeButton.accessibilityValue = OALocalizedString(@"simulate_in_progress");
    }
    else
    {
        [_driveModeButton setImage:[UIImage templateImageNamed:@"ic_custom_navigation"] forState:UIControlStateNormal];
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

- (void) widgetsLayoutDidChange:(BOOL)animated
{
    [self updateControlsLayout:animated];
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
