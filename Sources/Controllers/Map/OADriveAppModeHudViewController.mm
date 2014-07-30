//
//  OADriveAppModeHudViewController.mm
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADriveAppModeHudViewController.h"

#import <JASidePanelController.h>
#import <UIViewController+JASidePanel.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OAMapViewController.h"
#if defined(OSMAND_IOS_DEV)
#   import "OADebugHudViewController.h"
#endif // defined(OSMAND_IOS_DEV)
#import "OARootViewController.h"
#import "OAUserInteractionInterceptorView.h"
#import "OALog.h"
#include "Localization.h"

#import "OAAppearance.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Data/Model/Road.h>

@interface OADriveAppModeHudViewController () <OAUserInteractionInterceptorProtocol>

@property (weak, nonatomic) IBOutlet UIView *compassBox;
@property (weak, nonatomic) IBOutlet UIButton *compassButton;
@property (weak, nonatomic) IBOutlet UIImageView *compassImage;
@property (weak, nonatomic) IBOutlet UIView *zoomButtons;
@property (weak, nonatomic) IBOutlet UIButton *zoomInButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomOutButton;
@property (weak, nonatomic) IBOutlet UIButton *debugButton;
@property (weak, nonatomic) IBOutlet UIButton *optionsMenuButton;
@property (weak, nonatomic) IBOutlet UIButton *actionsMenuButton;
@property (weak, nonatomic) IBOutlet UILabel *positionLocalizedTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *positionNativeTitleLabel;
@property (weak, nonatomic) IBOutlet UIButton *resumeFollowingButton;
@property (weak, nonatomic) IBOutlet UIImageView *leftWidgetsContainerBackground;
@property (weak, nonatomic) IBOutlet UILabel *currentSpeedLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentAltitudeLabel;

@end

@implementation OADriveAppModeHudViewController
{
    OsmAndAppInstance _app;

    BOOL _iOS70plus;

    OAMapViewController* _mapViewController;

    OAAutoObserverProxy* _mapModeObserver;
    OAAutoObserverProxy* _mapAzimuthObserver;
    OAAutoObserverProxy* _mapZoomObserver;

    CLLocation* _lastCapturedLocation;
    OAAutoObserverProxy* _locationServicesUpdateObserver;

    CLLocation* _lastQueriedLocation;
    std::shared_ptr<const OsmAnd::Model::Road> _road;

    NSTimer* _fadeInTimer;

    NSTimer* _locationUpdateTimer;

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

    _iOS70plus = ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending);

    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;

    _mapModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapModeChanged)
                                                  andObserve:_app.mapModeObservable];
    _mapAzimuthObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                    withHandler:@selector(onMapAzimuthChanged:withKey:andValue:)
                                                     andObserve:_mapViewController.azimuthObservable];
    _mapZoomObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapZoomChanged:withKey:andValue:)
                                                  andObserve:_mapViewController.zoomObservable];

    _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onLocationServicesUpdate)
                                                                 andObserve:_app.locationServices.updateObserver];
}

- (void)deinit
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _compassImage.transform = CGAffineTransformMakeRotation(-_mapViewController.mapRendererView.azimuth / 180.0f * M_PI);
    _zoomInButton.enabled = [_mapViewController canZoomIn];
    _zoomOutButton.enabled = [_mapViewController canZoomOut];

    OAUserInteractionInterceptorView* interceptorView = (OAUserInteractionInterceptorView*)self.view;
    interceptorView.delegate = self;

    self.leftWidgetsContainerBackground.image = [_app.appearance hudViewBackgroundForStyle:OAHudViewStyleTopLeadingSideDock];

#if !defined(OSMAND_IOS_DEV)
    [_debugButton hideAndDisableInput];
#endif // !defined(OSMAND_IOS_DEV)
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    _lastCapturedLocation = _app.locationServices.lastKnownLocation;

    // Initially, show coordinates while road is not yet determined
    _road.reset();
    [self updatePositionLabels];
    [self updateCurrentSpeedAndAltitude];

    [self updateCurrentLocation];
    [self restartLocationUpdateTimer];

    [self showOrHideResumeFollowingButtonAnimated:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    if (!_iOS70plus)
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleBlackTranslucent;

    [self fadeInOptionalControlsWithDelay];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (!_iOS70plus)
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)fadeInOptionalControlsWithDelay
{
    if (_fadeInTimer != nil)
        [_fadeInTimer invalidate];
    _fadeInTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                    target:self
                                                  selector:@selector(optionalControlsFadeInAnimation)
                                                  userInfo:nil
                                                   repeats:NO];
}

- (void)optionalControlsFadeInAnimation
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.zoomButtons.alpha = 0.0f;
                     }];
}

- (void)hideOptionalControls
{
    self.zoomButtons.hidden = YES;
}

- (void)optionalControlsFadeOutAnimation
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.zoomButtons.alpha = 1.0f;
                     }];
}

- (void)showOptionalControls
{
    self.zoomButtons.hidden = NO;
}

- (void)updateCurrentLocation
{
    [self updateCurrentSpeedAndAltitude];
    [self updateCurrentPosition];
}

- (void)updateCurrentSpeedAndAltitude
{
    const auto speed = MAX(_lastCapturedLocation.speed, 0);
    self.currentSpeedLabel.text = [_app.locationFormatter stringFromSpeed:speed];
    self.currentAltitudeLabel.text = [_app.locationFormatter stringFromDistance:_lastCapturedLocation.altitude];
}

- (void)updateCurrentPosition
{
    // If road is unknown, or no query has been performed, or distance between query points is more than 15 meters,
    // repeat query
    if (!_road || _lastQueriedLocation == nil || [_lastQueriedLocation distanceFromLocation:_lastCapturedLocation] >= 15)
    {
        [self restartLocationUpdateTimer];

        //TODO: perform query and run:
        [self updatePositionLabels];
    }
}

- (void)updatePositionLabels
{
    if (_road)
    {
        //TODO: fill road details
    }
    else
    {
        self.positionLocalizedTitleLabel.text = [_app.locationFormatter stringFromCoordinate:_lastCapturedLocation.coordinate];
        if (_lastCapturedLocation.course >= 0)
        {
            NSString* course = [_app.locationFormatter stringFromBearing:_lastCapturedLocation.course];
            self.positionNativeTitleLabel.text = OALocalizedString(@"Heading %@", course);
        }
        else
            self.positionNativeTitleLabel.text = OALocalizedString(@"No movement");
    }
}

- (void)restartLocationUpdateTimer
{
    if (_locationUpdateTimer != nil)
        [_locationUpdateTimer invalidate];
    _locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                            target:self
                                                          selector:@selector(updateCurrentLocation)
                                                          userInfo:nil
                                                           repeats:YES];
}

- (void)showOrHideResumeFollowingButtonAnimated:(BOOL)animated
{
    BOOL shouldShowButton = (_app.mapMode != OAMapModeFollow);

    if (!animated)
        self.resumeFollowingButton.alpha = shouldShowButton ? 1.0f : 0.0f;
    else
    {
        [UIView animateWithDuration:0.3 animations:^{
            self.resumeFollowingButton.alpha = shouldShowButton ? 1.0f : 0.0f;
        }];
    }
}

- (BOOL)shouldInterceptInteration:(CGPoint)point withEvent:(UIEvent *)event inView:(UIView*)view
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_fadeInTimer)
        {
            [_fadeInTimer invalidate];
            _fadeInTimer = nil;
        }

        [self optionalControlsFadeOutAnimation];
        [self fadeInOptionalControlsWithDelay];
    });

    return NO;
}

- (void)onMapModeChanged
{
    if (![self isViewLoaded])
        return;

    dispatch_async(dispatch_get_main_queue(), ^{
        [self showOrHideResumeFollowingButtonAnimated:YES];
    });
}

- (void)onLocationServicesUpdate
{
    if (![self isViewLoaded])
        return;

    _lastCapturedLocation = _app.locationServices.lastKnownLocation;
    [self updateCurrentLocation];
}

- (IBAction)onOptionsMenuButtonClicked:(id)sender
{
    [self.sidePanelController showLeftPanelAnimated:YES];
}

- (void)onMapAzimuthChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
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
}

- (void)onMapZoomChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _zoomInButton.enabled = [_mapViewController canZoomIn];
        _zoomOutButton.enabled = [_mapViewController canZoomOut];
    });
}

- (IBAction)onActionsMenuButtonClicked:(id)sender
{
    [self.sidePanelController showRightPanelAnimated:YES];
}

- (IBAction)onResumeFollowingButtonClicked:(id)sender
{
    _app.mapMode = OAMapModeFollow;
}

- (IBAction)onDebugButtonClicked:(id)sender
{
#if defined(OSMAND_IOS_DEV)
    if (_debugHudViewController == nil)
    {
        _debugHudViewController = [[OADebugHudViewController alloc] initWithNibName:@"DebugHUD" bundle:nil];
        [self addChildViewController:_debugHudViewController];
        _debugHudViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _debugHudViewController.view.frame = self.view.frame;
        [self.view addSubview:_debugHudViewController.view];
        [self.view bringSubviewToFront:_debugHudViewController.view];
    }
    else
    {
        [_debugHudViewController.view removeFromSuperview];
        [_debugHudViewController removeFromParentViewController];
        _debugHudViewController = nil;
    }
#endif // defined(OSMAND_IOS_DEV)
}

@end
