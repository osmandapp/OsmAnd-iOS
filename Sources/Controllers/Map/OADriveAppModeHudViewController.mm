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
#import "OAMapRendererView.h"
#if defined(OSMAND_IOS_DEV)
#   import "OADebugHudViewController.h"
#endif // defined(OSMAND_IOS_DEV)
#import "OARootViewController.h"
#import "OAUserInteractionInterceptorView.h"
#import "OAAppearance.h"
#import "OALog.h"
#include "Localization.h"

#include <OsmAndCore.h>
#include <OsmAndCore/CachingRoadLocator.h>
#include <OsmAndCore/Data/Model/Road.h>

#define kMaxRoadDistanceInMeters 15.0

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
    OAAutoObserverProxy* _mapFramePreparedObserver;

    CLLocation* _lastCapturedLocation;
    OAAutoObserverProxy* _locationServicesUpdateObserver;

    CLLocation* _lastQueriedLocation;
    std::shared_ptr<const OsmAnd::Model::Road> _road;
    std::shared_ptr<OsmAnd::CachingRoadLocator> _roadLocator;
    NSObject* _roadLocatorSync;

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
    _mapFramePreparedObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                          withHandler:@selector(onMapFramePrepared)
                                                           andObserve:_mapViewController.framePreparedObservable];

    _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onLocationServicesUpdate)
                                                                 andObserve:_app.locationServices.updateObserver];

    _roadLocator.reset(new OsmAnd::CachingRoadLocator(_app.resourcesManager->obfsCollection));
    _roadLocatorSync = [[NSObject alloc] init];

    _app.resourcesManager->localResourcesChangeObservable.attach((__bridge const void*)self,
                                                                 [self]
                                                                 (const OsmAnd::ResourcesManager* const resourcesManager,
                                                                  const QList< QString >& added,
                                                                  const QList< QString >& removed,
                                                                  const QList< QString >& updated)
                                                                 {
                                                                     [self onLocalResourcesChanged];
                                                                 });
}

- (void)deinit
{
    _app.resourcesManager->localResourcesChangeObservable.detach((__bridge const void*)self);
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
    _debugButton.hidden = YES;
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

- (void)safeUpdateCurrentLocation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateCurrentLocation];
    });
}

- (void)updateCurrentLocation
{
    [self updateCurrentSpeedAndAltitude];
    [self updateCurrentPosition];
}

- (void)updateCurrentSpeedAndAltitude
{
#if defined(OSMAND_IOS_DEV)
    if (_app.debugSettings.useRawSpeedAndAltitudeOnHUD)
    {
        self.currentSpeedLabel.text = [NSString stringWithFormat:@"(R) %.1f km/h", _lastCapturedLocation.speed * 3.6];
        self.currentAltitudeLabel.text = [NSString stringWithFormat:@"(R) %d m", (int)_lastCapturedLocation.altitude];

        return;
    }
#endif // defined(OSMAND_IOS_DEV)

    const auto speed = MAX(_lastCapturedLocation.speed, 0);
    self.currentSpeedLabel.text = [_app.locationFormatter stringFromSpeed:speed];
    self.currentAltitudeLabel.text = [_app.locationFormatter stringFromDistance:_lastCapturedLocation.altitude];
}

- (void)updateCurrentPosition
{
    // If road is unknown, or no query has been performed, or distance between query points is more than X meters,
    // repeat query
    if (!_road ||
        _lastQueriedLocation == nil ||
        [_lastQueriedLocation distanceFromLocation:_lastCapturedLocation] >= kMaxRoadDistanceInMeters)
    {
        [self restartLocationUpdateTimer];

        const OsmAnd::PointI position31(
                                        OsmAnd::Utilities::get31TileNumberX(_lastCapturedLocation.coordinate.longitude),
                                        OsmAnd::Utilities::get31TileNumberY(_lastCapturedLocation.coordinate.latitude));
        _lastQueriedLocation = [_lastCapturedLocation copy];

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @synchronized(_roadLocatorSync)
            {
                // Try to find road in basemap, then in detaled map
                _road = _roadLocator->findNearestRoad(position31,
                                                      kMaxRoadDistanceInMeters,
                                                      OsmAnd::RoutingDataLevel::Basemap);
                if (!_road)
                {
                    _road = _roadLocator->findNearestRoad(position31,
                                                          kMaxRoadDistanceInMeters,
                                                          OsmAnd::RoutingDataLevel::Detailed);
                }
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePositionLabels];
            });
        });
    }
}

- (void)updatePositionLabels
{
    NSString* localizedTitle = nil;
    NSString* nativeTitle = nil;

    std::shared_ptr<const OsmAnd::Model::Road> road;
    @synchronized(_roadLocatorSync)
    {
        road = _road;
    }

    if (road)
    {
        const auto mainLanguage = QString::fromNSString([[NSLocale preferredLanguages] firstObject]);
        const auto localizedName = road->getNameInLanguage(mainLanguage);
        const auto nativeName = road->getNameInNativeLanguage();

        if (!localizedName.isNull())
            localizedTitle = localizedName.toNSString();
        if (!nativeName.isNull())
            nativeTitle = nativeName.toNSString();
    }

    if (localizedTitle == nil && nativeTitle != nil)
    {
        localizedTitle = nativeTitle;
        nativeTitle = nil;
    }

    if (localizedTitle == nil)
    {
        localizedTitle = [_app.locationFormatter stringFromCoordinate:_lastCapturedLocation.coordinate];;
    }

    if (nativeTitle == nil)
    {
        if (_lastCapturedLocation.course >= 0)
        {
            NSString* course = [_app.locationFormatter stringFromBearing:_lastCapturedLocation.course];
            nativeTitle = OALocalizedString(@"Heading %@", course);
        }
        else
            nativeTitle = OALocalizedString(@"No movement");
    }

    self.positionLocalizedTitleLabel.text = localizedTitle;
    self.positionNativeTitleLabel.text = nativeTitle;
}

- (void)restartLocationUpdateTimer
{
    if (_locationUpdateTimer != nil)
        [_locationUpdateTimer invalidate];
    _locationUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                            target:self
                                                          selector:@selector(safeUpdateCurrentLocation)
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
    [self safeUpdateCurrentLocation];
}

- (void)onLocalResourcesChanged
{
    if (![self isViewLoaded])
        return;

    @synchronized(_roadLocatorSync)
    {
        _road.reset();
        _roadLocator->clearCache();
    }
    [self safeUpdateCurrentLocation];
}

- (void)onMapFramePrepared
{
    OAMapRendererView* mapRendererView = (OAMapRendererView*)_mapViewController.mapRendererView;

    _roadLocator->clearCacheNotInTiles(mapRendererView.visibleTiles.toSet(),
                                       mapRendererView.zoomLevel,
                                       true);
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

@end
