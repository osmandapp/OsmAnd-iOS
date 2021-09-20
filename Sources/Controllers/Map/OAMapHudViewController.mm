//
//  OAMapHudViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAMapHudViewController.h"
#import "OAAppSettings.h"
#import "OAMapRulerView.h"
#import "OAIAPHelper.h"
#import "OAMapStyleSettings.h"
#import "OAMapInfoController.h"
#import "Localization.h"
#import "OAMapViewTrackingUtilities.h"
#import "OAColors.h"
#import "OATopCoordinatesWidget.h"
#import "OADownloadMapWidget.h"

#import <JASidePanelController.h>
#import <UIViewController+JASidePanel.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OAOverlayUnderlayView.h"
#import "OAToolbarViewController.h"
#import "OAQuickActionHudViewController.h"
#import "OANativeUtilities.h"
#import "OAUtilities.h"

#import "OADownloadProgressView.h"
#import "OADownloadTask.h"
#import "OARoutingProgressView.h"

#import "OAMapWidgetRegistry.h"

#include <OsmAndCore/Utilities.h>

#define kButtonWidth 50.0
#define kButtonOffset 16.0

#define _(name) OAMapModeHudViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

@interface OAMapHudViewController () <OAMapInfoControllerProtocol>

@property (nonatomic) OADownloadProgressView *downloadView;
@property (nonatomic) OARoutingProgressView *routingProgressView;

@end

@implementation OAMapHudViewController
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _mapModeObserver;
    OAAutoObserverProxy* _mapAzimuthObserver;
    OAAutoObserverProxy* _mapZoomObserver;
    OAAutoObserverProxy* _mapLocationObserver;
    OAAutoObserverProxy* _appearanceObserver;

    OAMapPanelViewController *_mapPanelViewController;
    OAMapViewController* _mapViewController;

    UIPanGestureRecognizer* _grMove;
    
    OAAutoObserverProxy* _dayNightModeObserver;
    OAAutoObserverProxy* _locationServicesStatusObserver;

    BOOL _driveModeActive;
    
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _locationServicesUpdateFirstTimeObserver;
    OAAutoObserverProxy* _lastMapSourceChangeObserver;
    OAAutoObserverProxy* _applicaionModeObserver;
    
    OAOverlayUnderlayView* _overlayUnderlayView;
    
    NSLayoutConstraint *_bottomRulerConstraint;
    NSLayoutConstraint *_leftRulerConstraint;
    
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

    _mapPanelViewController = [OARootViewController instance].mapPanel;
    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;
    
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
                                                         andObserve:[OsmAndApp instance].data.applicationModeChangedObservable];
    
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

    _toolbarTopPosition = [OAUtilities getStatusBarHeight];
    
    _compassImage.transform = CGAffineTransformMakeRotation(-_mapViewController.mapRendererView.azimuth / 180.0f * M_PI);
    _compassBox.alpha = ([self shouldShowCompass] ? 1.0 : 0.0);
    _compassBox.userInteractionEnabled = _compassBox.alpha > 0.0;
    
    _zoomInButton.enabled = [_mapViewController canZoomIn];
    _zoomOutButton.enabled = [_mapViewController canZoomOut];
    
    self.quickActionController = [[OAQuickActionHudViewController alloc] initWithMapHudViewController:self];
    self.quickActionController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addChildViewController:self.quickActionController];
    
    self.quickActionController.view.frame = self.view.frame;
    [self.view addSubview:self.quickActionController.view];
    
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

    _mapInfoController.delegate = self;
}

- (CGFloat) getExtraScreenOffset
{
    return (OAUtilities.isLandscape && OAUtilities.getLeftMargin > 0) ? 0.0 : kButtonOffset;
}

- (void)applyCorrectViewSize
{
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    CGFloat leftMargin = [OAUtilities getLeftMargin];
    
    CGRect frame = self.view.frame;
    frame.origin.x = leftMargin;
    frame.size.height = DeviceScreenHeight - bottomMargin;
    frame.size.width = DeviceScreenWidth - leftMargin * 2;
    self.view.frame = frame;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (self.toolbarViewController)
    {
        [self.toolbarViewController onViewWillAppear:self.mapHudType];
        //[self showToolbar];
    }
    
    //IOS-222
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUDLastMapModePositionTrack] && !_driveModeActive)
    {
        OAMapMode mapMode = (OAMapMode)[[NSUserDefaults standardUserDefaults] integerForKey:kUDLastMapModePositionTrack];
        [_app setMapMode:mapMode];
    }
    [self updateMapModeButton];
    
    if (![self.view.subviews containsObject:self.widgetsView])
    {
        _widgetsView.frame = CGRectMake(0.0, 20.0, DeviceScreenWidth - OAUtilities.getLeftMargin * 2, 10.0);
        
        if (self.toolbarViewController && self.toolbarViewController.view.superview)
            [self.view insertSubview:self.widgetsView belowSubview:self.toolbarViewController.view];
        else
            [self.view addSubview:self.widgetsView];
    }
    [self applyCorrectViewSize];
    _driveModeActive = NO;
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([[OAAppSettings sharedManager] settingShowZoomButton])
    {
        [self.zoomButtonsView setHidden: NO];
        [self showBottomControls:0 animated:NO];
    }
    else
    {
        [self.zoomButtonsView setHidden: YES];
        [self hideBottomControls:0 animated:NO];
    }
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([self.rulerLabel hasNoData])
        {
            [self.rulerLabel setRulerData:[_mapViewController calculateMapRuler]];
        }
    });
    
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
        if (OAUtilities.isLandscape)
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
        [self applyCorrectViewSize];
        [self setupBottomContolMarginsForHeight:0];
        [self updateControlsLayout:[self getHudTopOffset]];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.rulerLabel setRulerData:[_mapViewController calculateMapRuler]];
    }  ];
}

- (void) updateRulerPosition:(CGFloat)bottom left:(CGFloat)left
{
    _bottomRulerConstraint.constant = bottom;
    _leftRulerConstraint.constant = left;
    [self.rulerLabel layoutIfNeeded];
}

- (void) resetToDefaultRulerLayout
{
    CGFloat bottomMargin = OAUtilities.getBottomMargin > 0 ? 0 : kButtonOffset;
    [self updateRulerPosition:-bottomMargin left:_driveModeButton.frame.origin.x + _driveModeButton.frame.size.width + kButtonOffset];
}

- (BOOL) shouldShowCompass
{
    return [self shouldShowCompass:_mapViewController.mapRendererView.azimuth];
}

- (BOOL) shouldShowCompass:(float)azimuth
{
    return (azimuth != 0.0 || [[OAAppSettings sharedManager].rotateMap get] != ROTATE_MAP_NONE || [_mapPanelViewController.mapWidgetRegistry isVisible:@"compass"]) && _mapSettingsButton.alpha == 1.0;
}

- (BOOL) isOverlayUnderlayViewVisible
{
    return _overlayUnderlayView && _overlayUnderlayView.superview != nil;
}

- (void) updateOverlayUnderlayView
{
    BOOL shouldOverlaySliderBeVisible = _app.data.overlayMapSource && [[OAAppSettings sharedManager] getOverlayOpacitySliderVisibility];
    BOOL shouldUnderlaySliderBeVisible = _app.data.underlayMapSource && [[OAAppSettings sharedManager] getUnderlayOpacitySliderVisibility];
    
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
    
    switch (self.mapModeButtonType)
    {
        case EOAMapModeButtonTypeShowMap:
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_mapViewController keepTempGpxTrackVisible];
            });
            [[OARootViewController instance].mapPanel hideContextMenu];
            return;
        }
        default:
            break;
    }

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
    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    
    [_quickActionController updateColors:isNight];

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
    
    [self.rulerLabel updateColors];
    
    [_mapPanelViewController updateColors];
    
    _statusBarView.backgroundColor = [self getStatusBarBackgroundColor];
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
    return _app.locationServices.lastKnownLocation && _app.locationServices.status == OALocationServicesStatusActive && _app.locationServices.available && !_app.locationServices.denied;
}

- (void) updateMapModeButtonIfNeeded
{
    if (_cachedLocationAvailableState != [self isLocationAvailable])
        [self updateMapModeButton];
}

- (void) updateMapModeButton
{
    if (self.contextMenuMode)
    {
        switch (self.mapModeButtonType)
        {
            case EOAMapModeButtonTypeShowMap:
                [_mapModeButton setImage:[UIImage templateImageNamed:@"ic_custom_show_on_map"] forState:UIControlStateNormal];
                break;
                
            default:
                break;
        }
        return;
    }
    
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
                _mapModeButton.borderWidthNight = 2;
                break;
            }
                
            case OAMapModeFollow: // Compass - 3D mode
            {
                [_mapModeButton setImage:[UIImage templateImageNamed:@"ic_custom_map_location_follow"] forState:UIControlStateNormal];
                _mapModeButton.unpressedColorDay = UIColorFromRGB(color_on_map_icon_background_color_light);
                _mapModeButton.unpressedColorNight = UIColorFromRGB(color_on_map_icon_background_color_dark);
                _mapModeButton.tintColorDay = UIColorFromRGB(color_primary_purple);
                _mapModeButton.tintColorNight = UIColorFromRGB(color_primary_light_blue);
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

- (IBAction) onCompassButtonClicked:(id)sender
{
    [[OAMapViewTrackingUtilities instance] switchRotateMapMode];
}

- (IBAction) onZoomInButtonClicked:(id)sender
{
    [_mapViewController animatedZoomIn];
}

- (IBAction) onZoomOutButtonClicked:(id)sender
{
    [_mapViewController animatedZoomOut];
    [_mapViewController calculateMapRuler];
}

- (void) onMapZoomChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _zoomInButton.enabled = [_mapViewController canZoomIn];
        _zoomOutButton.enabled = [_mapViewController canZoomOut];
        
        [self.rulerLabel setRulerData:[_mapViewController calculateMapRuler]];
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
        
        [self.rulerLabel setRulerData:[_mapViewController calculateMapRuler]];
        [self updateMapModeButtonIfNeeded];
    });
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

- (void) onApplicationModeChanged:(OAApplicationMode *)prevMode
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateColors];
        [_quickActionController updateViewVisibility];
        [_mapPanelViewController refreshToolbar];
    });
}

- (void) onProfileSettingSet:(NSNotification *)notification
{
    OACommonPreference *obj = notification.object;
    OACommonInteger *rotateMap = [OAAppSettings sharedManager].rotateMap;
    OACommonBoolean *transparentMapTheme = [OAAppSettings sharedManager].transparentMapTheme;
    if (obj)
    {
        if (obj == rotateMap)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateCompassButton];
            });
        }
        else if (obj = transparentMapTheme)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self updateColors];
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

- (void) showCompass
{
    [UIView animateWithDuration:.25 animations:^{
        _compassBox.alpha = 1.0;
    } completion:^(BOOL finished) {
        _compassBox.userInteractionEnabled = _compassBox.alpha > 0.0;
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
    OACommonInteger *rotateMap = [OAAppSettings sharedManager].rotateMap;
    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    BOOL showCompass = [self shouldShowCompass];
    if ([rotateMap get] == ROTATE_MAP_NONE)
    {
        _compassImage.image = [UIImage imageNamed:isNight ? @"ic_custom_direction_north_night" : @"ic_custom_direction_north_day"];
        [self updateCompassVisibility:showCompass];
    }
    else if ([rotateMap get] == ROTATE_MAP_BEARING)
    {
        _compassImage.image = [UIImage imageNamed:isNight ? @"ic_custom_direction_bearing_night" : @"ic_custom_direction_bearing_day"];
        [self updateCompassVisibility:YES];
    }
    else
    {
        _compassImage.image = [UIImage imageNamed:isNight ? @"ic_custom_direction_compass_night" : @"ic_custom_direction_compass_day"];
        [self updateCompassVisibility:YES];
    }
    [_compassButton updateColorsForPressedState:NO];
}

- (UIStatusBarStyle) preferredStatusBarStyle
{
    if (_toolbarViewController && _toolbarViewController.view.alpha > 0.5)
    {
        return [_toolbarViewController getPreferredStatusBarStyle];
    }
    else
    {
        BOOL isNight = [OAAppSettings sharedManager].nightMode;
        if (_topCoordinatesWidget.isVisible && !_downloadMapWidget.isVisible)
            return UIStatusBarStyleLightContent;
        return isNight ? UIStatusBarStyleLightContent : UIStatusBarStyleDefault;
    }
}

- (void) setToolbar:(OAToolbarViewController *)toolbarController
{
    if (_toolbarViewController.view.superview)
        [_toolbarViewController.view removeFromSuperview];
    
    _toolbarViewController = toolbarController;
    if ([self topControlsVisible])
    {
        _toolbarViewController.view.alpha = 1.0;
        _toolbarViewController.view.userInteractionEnabled = YES;
    }
    
    if (![self.view.subviews containsObject:_toolbarViewController.view])
    {
        [self.view addSubview:_toolbarViewController.view];
        [self.view insertSubview:_topCoordinatesWidget aboveSubview:_toolbarViewController.view];
        [self.view insertSubview:self.statusBarView aboveSubview:_topCoordinatesWidget];
        
        if (self.widgetsView && self.widgetsView.superview)
        {
            UIView *shadeView = _mapPanelViewController.shadeView;
            [self.view insertSubview:self.widgetsView belowSubview:shadeView && shadeView.superview ? shadeView : _toolbarViewController.view];
        }
    }
}

- (void) removeToolbar
{
    if (_toolbarViewController)
        [_toolbarViewController.view removeFromSuperview];

    _toolbarViewController = nil;
    [self updateToolbarLayout:YES];
}

- (void) setCoordinatesWidget:(OATopCoordinatesWidget *)widget
{
    if (_topCoordinatesWidget.superview)
        [_topCoordinatesWidget removeFromSuperview];

    _topCoordinatesWidget = widget;
    [_topCoordinatesWidget updateInfo];

    if (![self.view.subviews containsObject:_topCoordinatesWidget])
    {
        [self.view addSubview:_topCoordinatesWidget];
        [self.view insertSubview:_topCoordinatesWidget aboveSubview:_toolbarViewController.view];
        [self.view insertSubview:self.statusBarView aboveSubview:_topCoordinatesWidget];
    }
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

- (void) updateControlsLayout:(CGFloat)y
{
    [self updateControlsLayout:y statusBarColor:[self getStatusBarBackgroundColor]];
}

- (void) updateControlsLayout:(CGFloat)y statusBarColor:(UIColor *)statusBarColor
{
    [self updateButtonsLayoutY:y];
    
    if (_widgetsView)
    {
        CGFloat widgetsOffset = _downloadMapWidget.isVisible ? _downloadMapWidget.shadowOffset : 2.0;
        _widgetsView.frame = CGRectMake(widgetsOffset, y + 2.0, DeviceScreenWidth - OAUtilities.getLeftMargin * 2 - widgetsOffset * 2, 10.0);
    }
    if (_downloadView)
        _downloadView.frame = [self getDownloadViewFrame];
    if (_routingProgressView)
        _routingProgressView.frame = [self getRoutingProgressViewFrame];
    
    _statusBarView.backgroundColor = statusBarColor;
    CGRect statusBarFrame = _statusBarView.frame;
    statusBarFrame.origin.y = 0.0;
    statusBarFrame.size.height = [OAUtilities getStatusBarHeight];
    _statusBarView.frame = statusBarFrame;
    [self setNeedsStatusBarAppearanceUpdate];
}

- (void) updateButtonsLayoutY:(CGFloat)y
{
    CGFloat x = [self getExtraScreenOffset];
    CGSize size = _compassBox.frame.size;
    CGFloat msX = [self getExtraScreenOffset];
    CGSize msSize = _mapSettingsButton.frame.size;
    CGFloat sX = [self getExtraScreenOffset] + kButtonWidth + kButtonOffset;
    CGSize sSize = _searchButton.frame.size;
    
    CGFloat buttonsY = y + [_mapInfoController getLeftBottomY] + kButtonOffset;
    
    if (!CGRectEqualToRect(_mapSettingsButton.frame, CGRectMake(x, buttonsY, size.width, size.height)))
    {
        _compassBox.frame = CGRectMake(x, buttonsY + kButtonOffset + kButtonWidth, size.width, size.height);
        _mapSettingsButton.frame = CGRectMake(msX, buttonsY, msSize.width, msSize.height);
        _searchButton.frame = CGRectMake(sX, buttonsY, sSize.width, sSize.height);
    }
}

- (CGFloat) getHudMinTopOffset
{
    return [OAUtilities getStatusBarHeight];
}

- (CGFloat) getHudTopOffset
{
    CGFloat offset = [self getHudMinTopOffset];
    BOOL isLandscape = [OAUtilities isLandscapeIpadAware];
    BOOL isMarkersWidgetVisible = _toolbarViewController.view.alpha != 0;
    CGFloat markersWidgetHeaderHeight = _toolbarViewController.view.frame.size.height;
    BOOL isCoordinatesVisible = [_topCoordinatesWidget isVisible] && _topCoordinatesWidget.alpha != 0;
    CGFloat coordinateWidgetHeight = _topCoordinatesWidget.frame.size.height;
    BOOL isMapDownloadVisible = [_downloadMapWidget isVisible] && _downloadMapWidget.alpha != 0;
    CGFloat downloadWidgetHeight = _downloadMapWidget.frame.size.height + _downloadMapWidget.shadowOffset;
    
    if (isLandscape)
    {
        if (isCoordinatesVisible && isMarkersWidgetVisible && !isMapDownloadVisible)
            offset += coordinateWidgetHeight;
    }
    else
    {
        if (isMapDownloadVisible)
        {
            offset += downloadWidgetHeight;
        }
        else
        {
            if (isMarkersWidgetVisible)
                offset += markersWidgetHeaderHeight;
            if (isCoordinatesVisible)
                offset += coordinateWidgetHeight;
        }
    }
    return offset;
}

- (void) updateToolbarLayout:(BOOL)animated;
{
    CGFloat y = [self getHudTopOffset];
    if (animated)
    {
        [UIView animateWithDuration:.2 animations:^{
            [self updateControlsLayout:y];
        }];
    }
    else
    {
        [self updateControlsLayout:y];
    }
}

- (void) updateButtonsLayout:(BOOL)animated
{
    CGFloat y = [self getHudTopOffset];
    if (animated)
    {
        [UIView animateWithDuration:.2 animations:^{
            [self updateButtonsLayoutY:y];
        }];
    }
    else
    {
        [self updateButtonsLayoutY:y];
    }
}

- (void) updateContextMenuToolbarLayout:(CGFloat)toolbarHeight animated:(BOOL)animated
{
    CGFloat y = toolbarHeight + 1.0;
    
    if (animated)
    {
        [UIView animateWithDuration:.2 animations:^{
            [self updateControlsLayout:y];
        }];
    }
    else
    {
        [self updateControlsLayout:y];
    }
}

- (UIColor *) getStatusBarBackgroundColor
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    BOOL isNight = settings.nightMode;
    BOOL transparent = [settings.transparentMapTheme get];
    UIColor *statusBarColor;
    if (self.contextMenuMode && !_toolbarViewController)
        statusBarColor = isNight ? UIColor.clearColor : [UIColor colorWithWhite:1.0 alpha:0.5];
    else if (_downloadMapWidget.isVisible)
        statusBarColor = isNight ? UIColorFromRGB(nav_bar_night) : UIColorFromRGB(color_bottom_sheet_background);
    else if ([_topCoordinatesWidget isVisible])
        return UIColorFromRGB(nav_bar_night);
    else if (_toolbarViewController)
        statusBarColor = [_toolbarViewController getStatusBarColor];
    else
        statusBarColor = isNight ? (transparent ? UIColor.clearColor : UIColor.blackColor) : [UIColor colorWithWhite:1.0 alpha:(transparent ? 0.5 : 1.0)];
    
    return statusBarColor;
}

- (CGRect) getDownloadViewFrame
{
    CGFloat y = [self getHudTopOffset];
    CGFloat leftMargin = self.searchButton.frame.origin.x + kButtonWidth + kButtonOffset;
    CGFloat rightMargin = _rightWidgetsView ? _rightWidgetsView.bounds.size.width + 2 * kButtonOffset : kButtonOffset;
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

#pragma mark - debug

- (void) onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    
    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
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
        [UIView animateWithDuration:.3 animations:^{
            download.alpha = 0.0;
        } completion:^(BOOL finished) {
            [download removeFromSuperview];
        }];
    });
}

- (BOOL) topControlsVisible
{
    return _statusBarView.alpha > 0;
}

- (void) setTopControlsAlpha:(CGFloat)alpha
{
    CGFloat alphaEx = self.contextMenuMode ? 0.0 : alpha;

    _statusBarView.alpha = alpha;
    _mapSettingsButton.alpha = alpha;
    _compassBox.alpha = [_mapPanelViewController.mapWidgetRegistry isVisible:@"compass"] ? alpha : 0.0;
    _searchButton.alpha = alpha;
    
    _downloadView.alpha = alphaEx;
    _widgetsView.alpha = alphaEx;
    if (self.toolbarViewController)
        self.toolbarViewController.view.alpha = alphaEx;
    if (self.topCoordinatesWidget)
        self.topCoordinatesWidget.alpha = alphaEx;
    if (self.downloadMapWidget)
        self.downloadMapWidget.alpha = alphaEx;
}

- (void) showTopControls
{
    CGFloat alphaEx = self.contextMenuMode ? 0.0 : 1.0;

    [UIView animateWithDuration:.3 animations:^{
        
        _statusBarView.alpha = 1.0;
        _mapSettingsButton.alpha = 1.0;
        _compassBox.alpha = ([self shouldShowCompass] ? 1.0 : 0.0);
        _searchButton.alpha = 1.0;
        
        _downloadView.alpha = alphaEx;
        _widgetsView.alpha = alphaEx;
        if (self.toolbarViewController)
            self.toolbarViewController.view.alpha = alphaEx;
        if (self.topCoordinatesWidget)
            self.topCoordinatesWidget.alpha = alphaEx;
        if (self.downloadMapWidget)
            self.downloadMapWidget.alpha = alphaEx;

        [self updateControlsLayout:[self getHudTopOffset]];

    } completion:^(BOOL finished) {
        
        _statusBarView.userInteractionEnabled = YES;
        _mapSettingsButton.userInteractionEnabled = YES;
        _compassBox.userInteractionEnabled = _compassBox.alpha > 0.0;
        _searchButton.userInteractionEnabled = YES;
        _downloadView.userInteractionEnabled = alphaEx > 0.0;
        _widgetsView.userInteractionEnabled = alphaEx > 0.0;
        if (self.toolbarViewController)
            self.toolbarViewController.view.userInteractionEnabled = alphaEx > 0.0;
        if (self.topCoordinatesWidget)
            self.topCoordinatesWidget.userInteractionEnabled = alphaEx > 0.0;
        if (self.downloadMapWidget)
            self.downloadMapWidget.userInteractionEnabled = alphaEx > 0.0;
        
    }];
}

- (void) hideTopControls
{
    [UIView animateWithDuration:.3 animations:^{
        
        _statusBarView.alpha = 0.0;
        _compassBox.alpha = 0.0;
        _mapSettingsButton.alpha = 0.0;
        _searchButton.alpha = 0.0;
        _downloadView.alpha = 0.0;
        _widgetsView.alpha = 0.0;
        if (self.toolbarViewController)
            self.toolbarViewController.view.alpha = 0.0;
        if (self.topCoordinatesWidget)
            self.topCoordinatesWidget.alpha = 0.0;
        if (self.downloadMapWidget)
            self.downloadMapWidget.alpha = 0.0;
        
    } completion:^(BOOL finished) {
        
        _statusBarView.userInteractionEnabled = NO;
        _compassBox.userInteractionEnabled = NO;
        _mapSettingsButton.userInteractionEnabled = NO;
        _searchButton.userInteractionEnabled = NO;
        _downloadView.userInteractionEnabled = NO;
        _widgetsView.userInteractionEnabled = NO;
        if (self.toolbarViewController)
            self.toolbarViewController.view.userInteractionEnabled = NO;
        if (self.topCoordinatesWidget)
            self.topCoordinatesWidget.userInteractionEnabled = NO;
        if (self.downloadMapWidget)
            self.downloadMapWidget.userInteractionEnabled = NO;
        
    }];
}

- (void) addOffsetToView:(UIView *)view x:(CGFloat)x y:(CGFloat)y
{
    view.frame = CGRectMake(view.frame.origin.x + x, view.frame.origin.y + y, view.frame.size.width, view.frame.size.height);
}

- (void) setupBottomContolMarginsForHeight:(CGFloat)menuHeight
{
    CGFloat bottomMargin = [OAUtilities getBottomMargin] > 0 ? [OAUtilities getBottomMargin] : kButtonOffset;
    CGFloat topSpace = DeviceScreenHeight - bottomMargin;
    if (menuHeight > 0)
        topSpace -= menuHeight + kButtonOffset;
    
    _optionsMenuButton.frame = CGRectMake([self getExtraScreenOffset], topSpace - _optionsMenuButton.bounds.size.height, _optionsMenuButton.bounds.size.width, _optionsMenuButton.bounds.size.height);
    _driveModeButton.frame = CGRectMake([self getExtraScreenOffset] + kButtonWidth + kButtonOffset, topSpace - _driveModeButton.bounds.size.height, _driveModeButton.bounds.size.width, _driveModeButton.bounds.size.height);
    _mapModeButton.frame = CGRectMake(self.view.bounds.size.width - 2 * kButtonWidth - kButtonOffset - [self getExtraScreenOffset], topSpace - _mapModeButton.bounds.size.height, _mapModeButton.bounds.size.width, _mapModeButton.bounds.size.height);
    _zoomButtonsView.frame = CGRectMake(self.view.bounds.size.width - kButtonWidth - [self getExtraScreenOffset], topSpace - _zoomButtonsView.bounds.size.height, _zoomButtonsView.bounds.size.width, _zoomButtonsView.bounds.size.height);
    
    [self resetToDefaultRulerLayout];
}

- (void) showBottomControls:(CGFloat)menuHeight animated:(BOOL)animated
{
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    if (_mapModeButton.alpha == 0.0 || _mapModeButton.frame.origin.y != DeviceScreenHeight - 69.0 - menuHeight - bottomMargin)
    {
         void (^mainBlock)(void) = ^{
            _optionsMenuButton.alpha = (self.contextMenuMode ? 0.0 : 1.0);
            _zoomButtonsView.alpha = 1.0;
            _mapModeButton.alpha = 1.0;
            _driveModeButton.alpha = (self.contextMenuMode ? 0.0 : 1.0);
             [self setupBottomContolMarginsForHeight:menuHeight];
        };
        
        void (^completionBlock)(BOOL) = ^(BOOL finished){
            _optionsMenuButton.userInteractionEnabled = _optionsMenuButton.alpha > 0.0;
            _zoomButtonsView.userInteractionEnabled = YES;
            _mapModeButton.userInteractionEnabled = YES;
            _driveModeButton.userInteractionEnabled = _driveModeButton.alpha > 0.0;
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
}

- (void) hideBottomControls:(CGFloat)menuHeight animated:(BOOL)animated
{
    CGFloat bottomMargin = [OAUtilities getBottomMargin];
    if (_mapModeButton.alpha == 1.0 || _mapModeButton.frame.origin.y != DeviceScreenHeight - 69.0 - menuHeight - bottomMargin)
    {
        void (^mainBlock)(void) = ^{
            _optionsMenuButton.alpha = 0.0;
            _zoomButtonsView.alpha = 0.0;
            _mapModeButton.alpha = 0.0;
            _driveModeButton.alpha = 0.0;
            
            [self setupBottomContolMarginsForHeight:menuHeight];
            
            CGFloat offsetValue = DeviceScreenWidth;
            [self addOffsetToView:_optionsMenuButton x:-offsetValue y:0];
            [self addOffsetToView:_driveModeButton x:-offsetValue y:0];
            [self addOffsetToView:_mapModeButton x:offsetValue y:0];
            [self addOffsetToView:_zoomButtonsView x:offsetValue y:0];
        };
        
        void (^completionBlock)(BOOL) = ^(BOOL finished){
            _optionsMenuButton.userInteractionEnabled = NO;
            _zoomButtonsView.userInteractionEnabled = NO;
            _mapModeButton.userInteractionEnabled = NO;
            _driveModeButton.userInteractionEnabled = NO;
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
    OAApplicationMode *mode = [OAAppSettings sharedManager].applicationMode.get;
    [_mapSettingsButton setImage:mode.getIcon forState:UIControlStateNormal];
    _mapSettingsButton.tintColorDay = UIColorFromRGB(mode.getIconColor);
    _mapSettingsButton.tintColorNight = UIColorFromRGB(mode.getIconColor);
    [_mapSettingsButton updateColorsForPressedState:NO];
}

- (void) enterContextMenuMode
{
    if (!self.contextMenuMode)
    {
        self.contextMenuMode = YES;
        
        [UIView animateWithDuration:.3 animations:^{
            _optionsMenuButton.alpha = 0.0;
            _driveModeButton.alpha = 0.0;
        } completion:^(BOOL finished) {
            _optionsMenuButton.userInteractionEnabled = NO;
            _driveModeButton.userInteractionEnabled = NO;
        }];
    }
    [self updateMapModeButton];
}

- (void) restoreFromContextMenuMode
{
    if (self.contextMenuMode)
    {
        self.contextMenuMode = NO;
        self.mapModeButtonType = EOAMapModeButtonRegular;
        [self updateMapModeButton];
        [self showTopControls];
        
        [UIView animateWithDuration:.3 animations:^{
            _optionsMenuButton.alpha = 1.0;
            _driveModeButton.alpha = 1.0;
        } completion:^(BOOL finished) {
            _optionsMenuButton.userInteractionEnabled = YES;
            _driveModeButton.userInteractionEnabled = YES;
        }];
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
    }
    else if (routePlanningMode)
    {
        [_driveModeButton setImage:[UIImage templateImageNamed:@"ic_custom_navigation"] forState:UIControlStateNormal];
        _driveModeButton.tintColorDay = UIColorFromRGB(color_primary_purple);
        _driveModeButton.tintColorNight = UIColorFromRGB(color_primary_light_blue);
    }
    else
    {
        [_driveModeButton setImage:[UIImage templateImageNamed:@"ic_custom_navigation"] forState:UIControlStateNormal];
        _driveModeButton.tintColorDay = UIColorFromRGB(color_on_map_icon_tint_color_light);
        _driveModeButton.tintColorNight = UIColorFromRGB(color_on_map_icon_tint_color_dark);
    }

    [_driveModeButton updateColorsForPressedState:NO];
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

- (void) leftWidgetsLayoutDidChange:(UIView *)leftWidgetsView animated:(BOOL)animated
{
    [self updateButtonsLayout:animated];
}

@end
