//
//  OABrowseMapAppModeHudViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OABrowseMapAppModeHudViewController.h"
#import "OAAppSettings.h"
#import "OAMapRulerView.h"
#import "InfoWidgetsView.h"
#import "OAIAPHelper.h"
#import "OAMapStyleSettings.h"

#import <JASidePanelController.h>
#import <UIViewController+JASidePanel.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OAMapViewController.h"
#if defined(OSMAND_IOS_DEV)
#   import "OADebugHudViewController.h"
#endif // defined(OSMAND_IOS_DEV)
#import "OARootViewController.h"
#import "OAOverlayUnderlayView.h"

#import "OADestinationViewController.h"
#import "OADestination.h"
#import "OADestinationCell.h"
#import "OANativeUtilities.h"
#import "OAUtilities.h"
#import "OADestinationsHelper.h"

#import "OADownloadProgressView.h"
#import "OADownloadTask.h"

#include <OsmAndCore/Utilities.h>

#define _(name) OAMapModeHudViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

@interface OABrowseMapAppModeHudViewController ()

@property (weak, nonatomic) IBOutlet UIView *statusBarView;

@property (weak, nonatomic) IBOutlet UIView *compassBox;
@property (weak, nonatomic) IBOutlet UIButton *compassButton;
@property (weak, nonatomic) IBOutlet UIImageView *compassImage;

@property (weak, nonatomic) IBOutlet UIButton *mapSettingsButton;
@property (weak, nonatomic) IBOutlet UIButton *searchButton;

@property (weak, nonatomic) IBOutlet UIButton *mapModeButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomInButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomOutButton;
@property (weak, nonatomic) IBOutlet UIView *zoomButtonsView;

@property (weak, nonatomic) IBOutlet UIButton *driveModeButton;
@property (weak, nonatomic) IBOutlet UIButton *debugButton;
@property (weak, nonatomic) IBOutlet UITextField *searchQueryTextfield;
@property (weak, nonatomic) IBOutlet UIButton *optionsMenuButton;
@property (weak, nonatomic) IBOutlet UIButton *actionsMenuButton;

@property (strong, nonatomic) IBOutlet OAMapRulerView *rulerLabel;

@property OADownloadProgressView* downloadView;

@end

@implementation OABrowseMapAppModeHudViewController
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _mapModeObserver;
    OAAutoObserverProxy* _mapAzimuthObserver;
    OAAutoObserverProxy* _mapZoomObserver;
    OAAutoObserverProxy* _mapLocationObserver;
    OAAutoObserverProxy* _appearanceObserver;

    OAMapViewController* _mapViewController;
    UIPanGestureRecognizer* _grMove;
    
    OAAutoObserverProxy* _dayNightModeObserver;

    BOOL _driveModeActive;
    
    OAAutoObserverProxy* _downloadTaskProgressObserver;
    OAAutoObserverProxy* _downloadTaskCompletedObserver;
    OAAutoObserverProxy* _locationServicesUpdateFirstTimeObserver;
    OAAutoObserverProxy* _lastMapSourceChangeObserver;
    
    OAOverlayUnderlayView* _overlayUnderlayView;
    
#if defined(OSMAND_IOS_DEV)
    OADebugHudViewController* _debugHudViewController;
#endif // defined(OSMAND_IOS_DEV)
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)dealloc
{
    [self deinit];
}

- (void)commonInit
{
    _app = [OsmAndApp instance];

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
                                                             withHandler:@selector(updateMapSettingsButton)
                                                              andObserve:_app.data.lastMapSourceChangeObservable];

}

- (void)deinit
{

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	    
#if defined(OSMAND_IOS_DEV)
    UILongPressGestureRecognizer* debugLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(onDebugButtonLongClicked:)];
    [_debugButton addGestureRecognizer:debugLongPress];
#endif

    if (_app.mapMode == OAMapModeFollow || _app.mapMode == OAMapModePositionTrack)
        _driveModeButton.hidden = NO;
    else
        _driveModeButton.hidden = YES;

    _compassImage.transform = CGAffineTransformMakeRotation(-_mapViewController.mapRendererView.azimuth / 180.0f * M_PI);
    _zoomInButton.enabled = [_mapViewController canZoomIn];

    _zoomOutButton.enabled = [_mapViewController canZoomOut];
    
    // IOS-218
    self.rulerLabel = [[OAMapRulerView alloc] initWithFrame:CGRectMake(60, DeviceScreenHeight - 42, kMapRulerMinWidth, 25)];
    self.rulerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.rulerLabel];
    
    // Constraints
    NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:self.rulerLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:-17.0f];
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.rulerLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0f constant:60.0f];
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.rulerLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:25];
    [self.view addConstraint:constraint];
    self.rulerLabel.hidden = true;
    
    [self updateMapSettingsButton];

#if !defined(OSMAND_IOS_DEV)
    _debugButton.hidden = YES;
#endif // !defined(OSMAND_IOS_DEV)
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    _destinationViewController.singleLineOnly = NO;
    _destinationViewController.top = 20.0;
    
    if (![self.view.subviews containsObject:_destinationViewController.view] &&
        [OADestinationsHelper instance].sortedDestinations.count > 0)
        [self.view addSubview:_destinationViewController.view];

    //IOS-222
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUDLastMapModePositionTrack] && !_driveModeActive)
    {
        OAMapMode mapMode = (OAMapMode)[[NSUserDefaults standardUserDefaults] integerForKey:kUDLastMapModePositionTrack];
        [_app setMapMode:mapMode];
    }
    [self updateMapModeButton];
    
    if (![self.view.subviews containsObject:self.widgetsView] && [[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_TrackRecording])
    {
        _widgetsView.frame = CGRectMake(DeviceScreenWidth - _widgetsView.bounds.size.width + 4.0, 25.0, _widgetsView.bounds.size.width, _widgetsView.bounds.size.height);
        _widgetsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        [self.view addSubview:self.widgetsView];
    }
    
    _driveModeActive = NO;
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    [self.zoomButtonsView setHidden: ![[OAAppSettings sharedManager] settingShowZoomButton]];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([self.rulerLabel hasNoData])
        {
            [self.rulerLabel setRulerData:[_mapViewController calculateMapRuler]];
            if (!_driveModeButton.hidden)
                self.rulerLabel.hidden = YES;
        }
    });
    
    [_destinationViewController startLocationUpdate];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [_destinationViewController stopLocationUpdate];
}

- (void)viewWillLayoutSubviews
{
    if (_overlayUnderlayView)
    {
        if (_driveModeButton.hidden || UIInterfaceOrientationIsLandscape(self.interfaceOrientation))
        {
            CGFloat x1 =  (_driveModeButton.hidden ? _optionsMenuButton.frame.origin.x + _optionsMenuButton.frame.size.width + 8.0 : _driveModeButton.frame.origin.x + _driveModeButton.frame.size.width + 8.0);
            CGFloat x2 = _mapModeButton.frame.origin.x - 8.0;
            
            CGFloat w = x2 - x1;
            CGFloat h = [_overlayUnderlayView getHeight:w];
            _overlayUnderlayView.frame = CGRectMake(x1, DeviceScreenHeight - h - 15.0, w, h);
        }
        else
        {
            CGFloat x1 = _driveModeButton.frame.origin.x;
            CGFloat x2 = _zoomButtonsView.frame.origin.x - 8.0;
            
            CGFloat w = x2 - x1;
            CGFloat h = [_overlayUnderlayView getHeight:w];
            _overlayUnderlayView.frame = CGRectMake(x1, DeviceScreenHeight - h - 15.0 - _optionsMenuButton.frame.size.height - 8.0, w, h);
        }
    }
}

- (BOOL)isOverlayUnderlayViewVisible
{
    return _overlayUnderlayView && _overlayUnderlayView.superview != nil;
}

- (void)updateOverlayUnderlayView:(BOOL)show
{
    if (!show)
    {
        if (_overlayUnderlayView && _overlayUnderlayView.superview)
            [_overlayUnderlayView removeFromSuperview];
        
        return;
    }
    
    if (!_overlayUnderlayView)
    {
        _overlayUnderlayView = [[OAOverlayUnderlayView alloc] init];
    }
    else
    {
        [_overlayUnderlayView updateView];
        [self.view setNeedsLayout];
    }
 
    if (_overlayUnderlayView.viewLayout != OAViewLayoutNone && !_overlayUnderlayView.superview)
        [self.view addSubview:_overlayUnderlayView];
    else if (_overlayUnderlayView.viewLayout == OAViewLayoutNone && _overlayUnderlayView.superview)
        [_overlayUnderlayView removeFromSuperview];

}

- (IBAction)onMapModeButtonClicked:(id)sender
{
    OAMapMode newMode = _app.mapMode;
    switch (_app.mapMode)
    {
        case OAMapModeFree:
            if (_app.prevMapMode == OAMapModeFollow)
                newMode = OAMapModeFollow;
            else
                newMode = OAMapModePositionTrack;
            break;
            
        case OAMapModePositionTrack:
            // Perform switch to follow-mode only in case location services have compass
            if (_app.locationServices.compassPresent)
                newMode = OAMapModeFollow;
            break;
            
        case OAMapModeFollow:
            newMode = OAMapModePositionTrack;
            break;

        default:
            return;
    }
    
    // If user have denied location services for the application, show notification about that and
    // don't change the mode
    if (_app.locationServices.denied && (newMode == OAMapModePositionTrack || newMode == OAMapModeFollow))
    {
        [OALocationServices showDeniedAlert];
        return;
    }

    _app.mapMode = newMode;
}

-(void)onDayNightModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rulerLabel updateColors];
    });
}

- (void)onMapModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMapModeButton];
    });
}

- (void)updateMapModeButton
{
    UIImage* modeImage = nil;
    switch (_app.mapMode)
    {
        case OAMapModeFree: // Free mode
            modeImage = [UIImage imageNamed:@"free_map_mode_button.png"];
            break;
            
        case OAMapModePositionTrack: // Trace point
            modeImage = [UIImage imageNamed:@"position_track_map_mode_button.png"];
            break;
            
        case OAMapModeFollow: // Compass - 3D mode
            modeImage = [UIImage imageNamed:@"follow_map_mode_button.png"];
            break;

        default:
            break;
    }
    
    if (_app.mapMode == OAMapModeFollow || _app.mapMode == OAMapModePositionTrack)
        _driveModeButton.hidden = NO;
    else
        _driveModeButton.hidden = YES;
    
    self.rulerLabel.hidden = !_driveModeButton.hidden;

    UIImage *backgroundImage;
    
    if (_app.locationServices.lastKnownLocation)
    {
        if (_app.mapMode == OAMapModeFree)
        {
            backgroundImage = [UIImage imageNamed:@"bt_round_big_blue"];
            modeImage = [OAUtilities tintImageWithColor:modeImage color:[UIColor whiteColor]];
        }
        else
        {
            backgroundImage = [UIImage imageNamed:@"bt_round_big"];
            modeImage = [OAUtilities tintImageWithColor:modeImage color:UIColorFromRGB(0x5B7EF8)];
        }
    }
    else
    {
        backgroundImage = [UIImage imageNamed:@"bt_round_big"];
    }

    [_mapModeButton setBackgroundImage:backgroundImage forState:UIControlStateNormal];
    [_mapModeButton setImage:modeImage forState:UIControlStateNormal];

    if (_overlayUnderlayView && _overlayUnderlayView.superview)
    {
        [_overlayUnderlayView updateView];
        [self.view setNeedsLayout];
    }
}

- (IBAction)onMapSettingsButtonClick:(id)sender
{
    [((OAMapPanelViewController *)self.parentViewController) mapSettingsButtonClick:sender];
}

- (IBAction)onSearchButtonClick:(id)sender
{
    [((OAMapPanelViewController *)self.parentViewController) searchButtonClick:sender];
}


- (IBAction)onOptionsMenuButtonDown:(id)sender
{
    self.sidePanelController.recognizesPanGesture = YES;
}


- (IBAction)onOptionsMenuButtonClicked:(id)sender
{
    self.sidePanelController.recognizesPanGesture = YES;
    [self.sidePanelController showLeftPanelAnimated:YES];
}

- (void)onMapAzimuthChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([OAAppSettings sharedManager].settingMapArrows == MAP_ARROWS_MAP_CENTER)
            [_destinationViewController updateDestinationsUsingMapCenter];
        _compassImage.transform = CGAffineTransformMakeRotation(-[value floatValue] / 180.0f * M_PI);
    });
}

- (IBAction)onCompassButtonClicked:(id)sender
{
    [_mapViewController animatedAlignAzimuthToNorth];
}

- (IBAction)onZoomInButtonClicked:(id)sender
{
    [_mapViewController animatedZoomIn];
}

- (IBAction)onZoomOutButtonClicked:(id)sender
{
    [_mapViewController animatedZoomOut];
    [_mapViewController calculateMapRuler];
}

- (void)onMapZoomChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _zoomInButton.enabled = [_mapViewController canZoomIn];
        _zoomOutButton.enabled = [_mapViewController canZoomOut];
        
        [self.rulerLabel setRulerData:[_mapViewController calculateMapRuler]];
        if (!_driveModeButton.hidden)
            self.rulerLabel.hidden = YES;
    });
}

- (void)onMapAppearanceChanged:(id)observable withKey:(id)key
{
    [self viewDidAppear:false];
}

- (void)onMapChanged:(id)observable withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if ([OAAppSettings sharedManager].settingMapArrows == MAP_ARROWS_MAP_CENTER)
            [_destinationViewController updateDestinationsUsingMapCenter];
        else
            [_destinationViewController doLocationUpdate];
        
        [self.rulerLabel setRulerData:[_mapViewController calculateMapRuler]];
        if (!_driveModeButton.hidden)
            self.rulerLabel.hidden = YES;
    });
}

- (void)onLocationServicesFirstTimeUpdate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateMapModeButton];
    });
}

- (IBAction)onDriveModeButtonClicked:(id)sender
{
    _driveModeActive = YES;
    _app.appMode = OAAppModeDrive;
}

- (IBAction)onActionsMenuButtonClicked:(id)sender
{
    [self.sidePanelController showRightPanelAnimated:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if ([OADestinationsHelper instance].sortedDestinations.count == 0)
        return UIStatusBarStyleDefault;
    else
        return UIStatusBarStyleLightContent;
}

-(void)updateDestinationViewLayout:(BOOL)animated
{
    CGFloat x = _compassBox.frame.origin.x;
    CGSize size = _compassBox.frame.size;
    CGFloat msX = _mapSettingsButton.frame.origin.x;
    CGSize msSize = _mapSettingsButton.frame.size;
    CGFloat sX = _searchButton.frame.origin.x;
    CGSize sSize = _searchButton.frame.size;
    
    CGFloat y = _destinationViewController.view.frame.origin.y + _destinationViewController.view.frame.size.height + 1.0;
    
    if (animated)
    {
        [UIView animateWithDuration:.2 animations:^{
            
            if (!CGRectEqualToRect(_compassBox.frame, CGRectMake(x, y, size.width, size.height)))
            {
                _compassBox.frame = CGRectMake(x, y + 7.0, size.width, size.height);
                _mapSettingsButton.frame = CGRectMake(msX, y + 7.0, msSize.width, msSize.height);
                _searchButton.frame = CGRectMake(sX, y + 7.0, sSize.width, sSize.height);
            }
            
            if (_widgetsView)
                _widgetsView.frame = CGRectMake(DeviceScreenWidth - _widgetsView.bounds.size.width + 4.0, y + 10.0, _widgetsView.bounds.size.width, _widgetsView.bounds.size.height);
            if (_downloadView)
                _downloadView.frame = [self getDownloadViewFrame];
            
            if ([OADestinationsHelper instance].sortedDestinations.count == 0)
                _statusBarView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
            else
                _statusBarView.backgroundColor = UIColorFromRGB(0x021e33);
            [self setNeedsStatusBarAppearanceUpdate];
        }];
    }
    else
    {
        if (!CGRectEqualToRect(_compassBox.frame, CGRectMake(x, y, size.width, size.height)))
        {
            _compassBox.frame = CGRectMake(x, y + 7.0, size.width, size.height);
            _mapSettingsButton.frame = CGRectMake(msX, y + 7.0, msSize.width, msSize.height);
            _searchButton.frame = CGRectMake(sX, y + 7.0, sSize.width, sSize.height);
        }
        
        if (_widgetsView)
            _widgetsView.frame = CGRectMake(DeviceScreenWidth - _widgetsView.bounds.size.width + 4.0, y + 10.0, _widgetsView.bounds.size.width, _widgetsView.bounds.size.height);
        if (_downloadView)
            _downloadView.frame = [self getDownloadViewFrame];

        if ([OADestinationsHelper instance].sortedDestinations.count == 0)
            _statusBarView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        else
            _statusBarView.backgroundColor = UIColorFromRGB(0x021e33);
        [self setNeedsStatusBarAppearanceUpdate];
    }

}

- (CGRect)getDownloadViewFrame
{
    CGFloat y = _destinationViewController.view.frame.origin.y + _destinationViewController.view.frame.size.height + 1.0;
    return CGRectMake(146.0, y + 12.0, DeviceScreenWidth - 156.0 - (_widgetsView ? _widgetsView.bounds.size.width - 4.0 : 0), 28.0);
}

#pragma mark - debug

- (void)onDebugButtonLongClicked:(id)sender
{
    _debugButton.hidden = YES;
}

- (IBAction)onDebugButtonClicked:(id)sender
{
#if defined(OSMAND_IOS_DEV)
    
    if (_debugHudViewController == nil)
    {
        _debugHudViewController = [OADebugHudViewController attachTo:self];
    }
    else
    {
        [_debugHudViewController.view removeFromSuperview];
        [_debugHudViewController removeFromParentViewController];
        _debugHudViewController = nil;
    }
#endif // defined(OSMAND_IOS_DEV)
}

- (void)onDownloadTaskProgressChanged:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
{
    id<OADownloadTask> task = key;
    
    // Skip all downloads that are not resources
    if (![task.key hasPrefix:@"resource:"])
        return;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
            return;
        
        if (!_downloadView) {
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
            
            [self.view addSubview:self.downloadView];
        }
        
        if (![_downloadView.titleView.text isEqualToString:task.name])
            [_downloadView setTitle: task.name];
        
        [self.downloadView setProgress:[value floatValue]];
        
    });
}

- (void)onDownloadTaskFinished:(id<OAObservableProtocol>)observer withKey:(id)key andValue:(id)value
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
        [UIView animateWithDuration:.4 animations:^{
            download.alpha = 0.0;
        } completion:^(BOOL finished) {
            [download removeFromSuperview];
        }];
    });
}

- (void)showTopControls
{
    if (_compassBox.alpha == 0.0)
    {
        [UIView animateWithDuration:.3 animations:^{
           
            _statusBarView.alpha = 1.0;
            
            _compassBox.alpha = 1.0;
            _mapSettingsButton.alpha = 1.0;
            _searchButton.alpha = 1.0;
            
            _downloadView.alpha = 1.0;
            _widgetsView.alpha = 1.0;
            _destinationViewController.view.alpha = 1.0;
            
        }];
    }
}

- (void)hideTopControls
{
    if (_compassBox.alpha == 1.0)
    {
        [UIView animateWithDuration:.3 animations:^{
            
            _statusBarView.alpha = 0.0;

            _compassBox.alpha = 0.0;
            _mapSettingsButton.alpha = 0.0;
            _searchButton.alpha = 0.0;
            
            _downloadView.alpha = 0.0;
            _widgetsView.alpha = 0.0;
            _destinationViewController.view.alpha = 0.0;
            
        }];
    }
}

- (void)showBottomControls:(CGFloat)menuHeight
{
    if (_optionsMenuButton.alpha == 0.0 || _mapModeButton.frame.origin.y != DeviceScreenHeight - 63.0 - menuHeight)
    {
        [UIView animateWithDuration:.3 animations:^{
            
            _optionsMenuButton.alpha = 1.0;
            _zoomButtonsView.alpha = 1.0;
            _mapModeButton.alpha = 1.0;
            _driveModeButton.alpha = 1.0;
            
            _optionsMenuButton.frame = CGRectMake(0.0, DeviceScreenHeight - 63.0 - menuHeight, _optionsMenuButton.bounds.size.width, _optionsMenuButton.bounds.size.height);
            _driveModeButton.frame = CGRectMake(57.0, DeviceScreenHeight - 63.0 - menuHeight, _driveModeButton.bounds.size.width, _driveModeButton.bounds.size.height);
            _mapModeButton.frame = CGRectMake(DeviceScreenWidth - 128.0, DeviceScreenHeight - 63.0 - menuHeight, _mapModeButton.bounds.size.width, _mapModeButton.bounds.size.height);
            _zoomButtonsView.frame = CGRectMake(DeviceScreenWidth - 63.0, DeviceScreenHeight - 123.0 - menuHeight, _zoomButtonsView.bounds.size.width, _zoomButtonsView.bounds.size.height);            
        }];
    }
}

- (void)hideBottomControls:(CGFloat)menuHeight
{
    if (_optionsMenuButton.alpha == 1.0 || _mapModeButton.frame.origin.y != DeviceScreenHeight - 63.0 - menuHeight)
    {
        [UIView animateWithDuration:.3 animations:^{
            
            _optionsMenuButton.alpha = 0.0;
            _zoomButtonsView.alpha = 0.0;
            _mapModeButton.alpha = 0.0;
            _driveModeButton.alpha = 0.0;
            
            _optionsMenuButton.frame = CGRectMake(0.0, DeviceScreenHeight - 63.0 - menuHeight, _optionsMenuButton.bounds.size.width, _optionsMenuButton.bounds.size.height);
            _driveModeButton.frame = CGRectMake(57.0, DeviceScreenHeight - 63.0 - menuHeight, _driveModeButton.bounds.size.width, _driveModeButton.bounds.size.height);
            _mapModeButton.frame = CGRectMake(DeviceScreenWidth - 128.0, DeviceScreenHeight - 63.0 - menuHeight, _mapModeButton.bounds.size.width, _mapModeButton.bounds.size.height);
            _zoomButtonsView.frame = CGRectMake(DeviceScreenWidth - 63.0, DeviceScreenHeight - 123.0 - menuHeight, _zoomButtonsView.bounds.size.width, _zoomButtonsView.bounds.size.height);
        }];
    }
}

- (void)updateMapSettingsButton
{
    dispatch_async(dispatch_get_main_queue(), ^{
        OAMapVariantType variantType = [OAMapStyleSettings getVariantType:_app.data.lastMapSource.variant];
        switch (variantType)
        {
            case OAMapVariantCar:
                [_mapSettingsButton setImage:[UIImage imageNamed:@"ic_mode_car"] forState:UIControlStateNormal];
                break;
            case OAMapVariantPedestrian:
                [_mapSettingsButton setImage:[UIImage imageNamed:@"ic_mode_pedestrian"] forState:UIControlStateNormal];
                break;
            case OAMapVariantBicycle:
                [_mapSettingsButton setImage:[UIImage imageNamed:@"ic_mode_bike"] forState:UIControlStateNormal];
                break;
                
            default:
                [_mapSettingsButton setImage:[UIImage imageNamed:@"ic_mode_browsing"] forState:UIControlStateNormal];
                break;
        }
    });
}

@end
