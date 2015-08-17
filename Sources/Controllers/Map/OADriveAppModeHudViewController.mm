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
#import "OADebugHudViewController.h"
#endif // defined(OSMAND_IOS_DEV)
#import "OARootViewController.h"
#import "OAUserInteractionInterceptorView.h"
#import "OAAppearance.h"
#import "OAUtilities.h"
#import "OALog.h"
#import "Localization.h"
#import "InfoWidgetsView.h"
#import "OAIAPHelper.h"
#import "OADestinationsHelper.h"

#import "OADestinationViewController.h"
#import "OADestination.h"
#import "OADestinationCell.h"
#import "OANativeUtilities.h"

#include <OsmAndCore.h>
#include <OsmAndCore/CachingRoadLocator.h>
#include <OsmAndCore/Data/Road.h>

#define kMaxRoadDistanceInMeters 15.0

@interface OADriveAppModeHudViewController () <OAUserInteractionInterceptorProtocol>

@property (weak, nonatomic) IBOutlet UIView *currentPositionContainer;
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
@property (weak, nonatomic) IBOutlet UIButton *mapModeButton;

@property (weak, nonatomic) IBOutlet UIView *currentSpeedWidget;
@property (weak, nonatomic) IBOutlet UILabel *currentSpeedLabel;
@property (weak, nonatomic) IBOutlet UIView *currentAltitudeWidget;
@property (weak, nonatomic) IBOutlet UILabel *currentAltitudeLabel;

@end

@implementation OADriveAppModeHudViewController
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;

    UIFont *_primaryFont;
    UIFont *_unitsFont;
    
    BOOL _iOS70plus;

    OAMapViewController* _mapViewController;

    OAAutoObserverProxy* _mapModeObserver;
    OAAutoObserverProxy* _mapAzimuthObserver;
    OAAutoObserverProxy* _mapZoomObserver;
    OAAutoObserverProxy* _mapFramePreparedObserver;

    CLLocation* _lastCapturedLocation;
    OAAutoObserverProxy* _locationServicesUpdateObserver;

    CLLocation* _lastQueriedLocation;
    std::shared_ptr<const OsmAnd::Road> _road;
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
    _settings = [OAAppSettings sharedManager];

    _iOS70plus = [OAUtilities iosVersionIsAtLeast:@"7.0"];

    _mapViewController = [OARootViewController instance].mapPanel.mapViewController;

    _roadLocator.reset(new OsmAnd::CachingRoadLocator(_app.resourcesManager->obfsCollection));
    _roadLocatorSync = [[NSObject alloc] init];

}

- (void)deinit
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _compassImage.transform = CGAffineTransformMakeRotation(-_mapViewController.mapRendererView.azimuth / 180.0f * M_PI);
    _compassBox.alpha = (_mapViewController.mapRendererView.azimuth != 0.0 && _currentPositionContainer.alpha == 1.0 ? 1.0 : 0.0);

    _zoomInButton.enabled = [_mapViewController canZoomIn];
    _zoomOutButton.enabled = [_mapViewController canZoomOut];
    
    OAUserInteractionInterceptorView* interceptorView = (OAUserInteractionInterceptorView*)self.view;
    interceptorView.delegate = self;

#if !defined(OSMAND_IOS_DEV)
    _debugButton.hidden = YES;
#else
    UILongPressGestureRecognizer* debugLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                 action:@selector(onDebugButtonLongClicked:)];
    [_debugButton addGestureRecognizer:debugLongPress];
#endif // !defined(OSMAND_IOS_DEV)
    
    // widgets
    
    _primaryFont = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:21];
    _unitsFont = [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:14];
    
    // drop shadow
    [_currentSpeedWidget.layer setShadowColor:[UIColor blackColor].CGColor];
    [_currentSpeedWidget.layer setShadowOpacity:0.3];
    [_currentSpeedWidget.layer setShadowRadius:2.0];
    [_currentSpeedWidget.layer setShadowOffset:CGSizeMake(0.0, 0.0)];

    [_currentAltitudeWidget.layer setShadowColor:[UIColor blackColor].CGColor];
    [_currentAltitudeWidget.layer setShadowOpacity:0.3];
    [_currentAltitudeWidget.layer setShadowRadius:2.0];
    [_currentAltitudeWidget.layer setShadowOffset:CGSizeMake(0.0, 0.0)];

    CGFloat radius = 3.0;
    UIColor *widgetBackgroundColor = [UIColor whiteColor];
    _currentSpeedWidget.backgroundColor = [widgetBackgroundColor copy];
    _currentSpeedWidget.layer.cornerRadius = radius;
    _currentAltitudeWidget.backgroundColor = [widgetBackgroundColor copy];
    _currentAltitudeWidget.layer.cornerRadius = radius;

    _currentSpeedWidget.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    _currentAltitudeWidget.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

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
    
    _app.resourcesManager->localResourcesChangeObservable.attach((__bridge const void*)self,
                                                                 [self]
                                                                 (const OsmAnd::ResourcesManager* const resourcesManager,
                                                                  const QList< QString >& added,
                                                                  const QList< QString >& removed,
                                                                  const QList< QString >& updated)
                                                                 {
                                                                     [self onLocalResourcesChanged];
                                                                 });
    
    
    
    _lastCapturedLocation = _app.locationServices.lastKnownLocation;

    // Initially, show coordinates while road is not yet determined
    _road.reset();
    [self updatePositionLabels: _lastCapturedLocation];
    [self updateCurrentSpeedAndAltitude];

    [self updateCurrentLocation];
    [self restartLocationUpdateTimer];

    [self updateMapModeButton];
    
    _destinationViewController.singleLineOnly = YES;
    _destinationViewController.top = 64.0;
    
    _locationServicesUpdateObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                                withHandler:@selector(onLocationServicesUpdate)
                                                                 andObserve:_app.locationServices.updateObserver];
    
    [self showDestinations];
    
    CGFloat y = _destinationViewController.view.frame.origin.y + _destinationViewController.view.frame.size.height + 1.0;

    //widgets
    if (![self.view.subviews containsObject:self.widgetsView] && [[OAIAPHelper sharedInstance] productPurchased:kInAppId_Addon_TrackRecording])
    {
        _widgetsView.frame = CGRectMake(DeviceScreenWidth - _widgetsView.bounds.size.width + 4.0, y + 5.0, _widgetsView.bounds.size.width, _widgetsView.bounds.size.height);
        _widgetsView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

        if (_destinationViewController && _destinationViewController.view.superview)
            [self.view insertSubview:self.widgetsView belowSubview:_destinationViewController.view];
        else
            [self.view addSubview:self.widgetsView];
    }
    
    _currentAltitudeWidget.hidden = !_settings.settingShowAltInDriveMode;
    
    [self updateWidgetsLayout:y + 5.0];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self fadeInOptionalControlsWithDelay];

    [_destinationViewController startLocationUpdate];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (!_iOS70plus)
        [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleDefault;

    [_destinationViewController stopLocationUpdate];
}

- (void)viewDidDisappear:(BOOL)animated
{
    _app.resourcesManager->localResourcesChangeObservable.detach((__bridge const void*)self);
    
    [_mapModeObserver detach];
    _mapModeObserver = nil;
    
    [_mapAzimuthObserver detach];
    _mapAzimuthObserver = nil;
    
    [_mapZoomObserver detach];
    _mapZoomObserver = nil;
    
    [_mapFramePreparedObserver detach];
    _mapFramePreparedObserver = nil;
    
    [_locationServicesUpdateObserver detach];
    _locationServicesUpdateObserver = nil;
    
    [super viewDidDisappear:animated];
}

- (void)viewWillLayoutSubviews
{
    //if (_destinationViewController)
    //    [_destinationViewController updateFrame:YES];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (void)updateWidgetsLayout:(CGFloat)y
{
    CGFloat x = DeviceScreenWidth - _currentSpeedWidget.bounds.size.width + 4.0;

    if (_widgetsView && _widgetsView.superview)
    {
        _widgetsView.frame = CGRectMake(x, y, _widgetsView.bounds.size.width, _widgetsView.bounds.size.height);
        y += _widgetsView.bounds.size.height + 2.0;
    }
    
    _currentSpeedWidget.frame = CGRectMake(x, y, _currentSpeedWidget.bounds.size.width, _currentSpeedWidget.bounds.size.height);
    if (_settings.settingShowAltInDriveMode)
    {
        y += _currentSpeedWidget.bounds.size.height + 2.0;
        _currentAltitudeWidget.frame = CGRectMake(x, y, _currentAltitudeWidget.bounds.size.width, _currentAltitudeWidget.bounds.size.height);
    }
}

- (void)onDebugButtonLongClicked:(id)sender
{
    _debugButton.hidden = YES;
}

- (void)fadeInOptionalControlsWithDelay
{
    if (_fadeInTimer != nil)
        [_fadeInTimer invalidate];
    
    if (_app.mapMode != OAMapModeFollow)
        return;
    
    /*
    _fadeInTimer = [NSTimer scheduledTimerWithTimeInterval:3.0
                                                    target:self
                                                  selector:@selector(optionalControlsFadeInAnimation)
                                                  userInfo:nil
                                                   repeats:NO];
     */
}

- (void)optionalControlsFadeInAnimation
{
    if (_app.mapMode != OAMapModeFollow)
        return;

    [UIView animateWithDuration:0.3
                     animations:^{
                         self.zoomButtons.alpha = 0.0;
                         self.mapModeButton.alpha = 0.0;
                     }];
}

- (void)optionalControlsFadeOutAnimation
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         self.zoomButtons.alpha = 1.0;
                         self.mapModeButton.alpha = 1.0;
                     }];
}

- (void)safeUpdateCurrentLocation
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _lastCapturedLocation = _app.locationServices.lastKnownLocation;
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
    [self updateSpeed];
    if (_settings.settingShowAltInDriveMode)
        [self updateAltitude];
}

- (void)updateSpeed
{
    const auto speed = MAX(_lastCapturedLocation.speed, 0);

    NSString *text = [_app getFormattedSpeed:speed drive:YES];

#if defined(OSMAND_IOS_DEV)

    if (_app.debugSettings.useRawSpeedAndAltitudeOnHUD)
        text = [NSString stringWithFormat:@"%.1f km/h", _lastCapturedLocation.speed * 3.6];

#endif // defined(OSMAND_IOS_DEV)
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text];
    
    NSUInteger spaceIndex = 0;
    for (NSUInteger i = text.length - 1; i > 0; i--)
        if ([text characterAtIndex:i] == ' ')
        {
            spaceIndex = i;
            break;
        }
    
    NSRange valueRange = NSMakeRange(0, spaceIndex);
    NSRange unitRange = NSMakeRange(spaceIndex, text.length - spaceIndex);
    
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:valueRange];
    
    [string addAttribute:NSFontAttributeName value:_primaryFont range:valueRange];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:unitRange];
    [string addAttribute:NSFontAttributeName value:_unitsFont range:unitRange];
    
    _currentSpeedLabel.attributedText = string;
}

- (void)updateAltitude
{
    NSString *text = [_app getFormattedAlt:_lastCapturedLocation.altitude];

#if defined(OSMAND_IOS_DEV)
    
    if (_app.debugSettings.useRawSpeedAndAltitudeOnHUD)
        text = [NSString stringWithFormat:@"%d m", (int)_lastCapturedLocation.altitude];
    
#endif // defined(OSMAND_IOS_DEV)
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text];
    
    NSUInteger spaceIndex = 0;
    for (NSUInteger i = text.length - 1; i > 0; i--)
        if ([text characterAtIndex:i] == ' ')
        {
            spaceIndex = i;
            break;
        }
    
    NSRange valueRange = NSMakeRange(0, spaceIndex);
    NSRange unitRange = NSMakeRange(spaceIndex, text.length - spaceIndex);
    
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor blackColor] range:valueRange];
    
    [string addAttribute:NSFontAttributeName value:_primaryFont range:valueRange];
    [string addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:unitRange];
    [string addAttribute:NSFontAttributeName value:_unitsFont range:unitRange];
    
    _currentAltitudeLabel.attributedText = string;
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

        CLLocation* tempLocation = [_lastCapturedLocation copy];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @synchronized(_roadLocatorSync)
            {
                _road = _roadLocator->findNearestRoad(position31,
                                                          kMaxRoadDistanceInMeters,
                                                          OsmAnd::RoutingDataLevel::Detailed);
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [self updatePositionLabels:tempLocation];
            });
        });
    }
}

- (void)updatePositionLabels:(CLLocation *)location
{
    NSString* localizedTitle = nil;
    NSString* nativeTitle = nil;

    std::shared_ptr<const OsmAnd::Road> road;
    @synchronized(_roadLocatorSync)
    {
        road = _road;
    }

    if (road)
    {
        const auto mainLanguage = QString::fromNSString([[NSLocale preferredLanguages] firstObject]);
        const auto localizedName = road->getCaptionInLanguage(mainLanguage);
        const auto nativeName = road->getCaptionInNativeLanguage();

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
        localizedTitle = [_app.locationFormatter stringFromCoordinate:location.coordinate];
    }

    if (nativeTitle == nil)
    {
        if (location.course >= 0)
        {
            NSString* course = [_app.locationFormatter stringFromBearing:location.course];
            nativeTitle = OALocalizedString(@"hud_heading %@", course);
        }
        else
            nativeTitle = OALocalizedString(@"hud_no_movement");
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
        [self updateMapModeButton];
    });
}

- (void)onLocationServicesUpdate
{
    if (![self isViewLoaded])
        return;

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

    const auto& tiles = mapRendererView.visibleTiles;
    
    QSet<OsmAnd::TileId> result;
    result.reserve(tiles.size());
    for (int i = 0; i < tiles.size(); ++i)
        result.insert(tiles.at(i));
    
    _roadLocator->clearCacheNotInTiles(result,
                                       mapRendererView.zoomLevel,
                                       true);
}

- (void)updateMapModeButton
{
    if (self.contextMenuMode)
    {
        [_mapModeButton setBackgroundImage:[UIImage imageNamed:@"bt_round_big"] forState:UIControlStateNormal];
        [_mapModeButton setImage:[UIImage imageNamed:@"ic_dialog_map"] forState:UIControlStateNormal];
        return;
    }
    
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
    
    _mapModeButton.hidden = (_app.mapMode != OAMapModeFree);
    
}

- (IBAction)onOptionsMenuButtonClicked:(id)sender
{
    [self.sidePanelController showLeftPanelAnimated:YES];
}

- (void)onMapAzimuthChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _compassImage.transform = CGAffineTransformMakeRotation(-[value floatValue] / 180.0f * M_PI);

        if ((_compassBox.alpha == 0.0 && [value floatValue] != 0.0 && _currentPositionContainer.alpha == 1.0) ||
            (_compassBox.alpha == 1.0 && [value floatValue] == 0.0))
        {
            [UIView animateWithDuration:.25 animations:^{
                _compassBox.alpha = ([value floatValue] != 0.0 && _currentPositionContainer.alpha == 1.0 ? 1.0 : 0.0);
            }];
        }
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
    _app.appMode = OAAppModeBrowseMap;
    //[[OARootViewController instance] closeMenuAndPanelsAnimated:YES];

    //[self.sidePanelController showRightPanelAnimated:YES];
}

- (IBAction)onMapModeButtonClicked:(id)sender
{
    if (self.contextMenuMode)
    {
        [[OARootViewController instance].mapPanel hideContextMenu];
        return;
    }

    if (_app.mapMode != OAMapModeFollow)
    {
        _app.mapMode = OAMapModeFollow;
        [self fadeInOptionalControlsWithDelay];
    }
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

- (void)showDestinations
{
    if (![self.view.subviews containsObject:_destinationViewController.view] &&
        [OADestinationsHelper instance].sortedDestinations.count > 0)
    {
        [self.view addSubview:_destinationViewController.view];
        [self.view insertSubview:self.currentPositionContainer aboveSubview:_destinationViewController.view];
        
        if (self.widgetsView && self.widgetsView.superview)
            [self.view insertSubview:self.widgetsView belowSubview:_destinationViewController.view];
    }
}

- (void)updateDestinationViewLayout:(BOOL)animated
{
    CGFloat x = _compassBox.frame.origin.x;
    CGSize size = _compassBox.frame.size;
    CGFloat y = _destinationViewController.view.frame.origin.y + _destinationViewController.view.frame.size.height + 1.0;
    
    if (animated)
    {
        [UIView animateWithDuration:.2 animations:^{
            if (!CGRectEqualToRect(_compassBox.frame, CGRectMake(x, y, size.width, size.height)))
                _compassBox.frame = CGRectMake(x, y, size.width, size.height);
            
            [self updateWidgetsLayout:y + 5.0];
        }];
    }
    else
    {
        if (!CGRectEqualToRect(_compassBox.frame, CGRectMake(x, y, size.width, size.height)))
            _compassBox.frame = CGRectMake(x, y, size.width, size.height);
        
        [self updateWidgetsLayout:y + 5.0];
    }
    
}

- (void)showTopControls
{
    if (_currentPositionContainer.alpha == 0.0)
    {
        [UIView animateWithDuration:.3 animations:^{
            
            _currentPositionContainer.alpha = 1.0;
            
            _compassBox.alpha = (_mapViewController.mapRendererView.azimuth != 0.0 && _currentPositionContainer.alpha == 1.0 ? 1.0 : 0.0);
            _widgetsView.alpha = 1.0;
            _currentSpeedWidget.alpha = 1.0;
            _currentAltitudeWidget.alpha = 1.0;
            _destinationViewController.view.alpha = 1.0;
            
        }];
    }
}

- (void)hideTopControls
{
    if (_currentPositionContainer.alpha == 1.0)
    {
        [UIView animateWithDuration:.3 animations:^{
            
            _currentPositionContainer.alpha = 0.0;
            
            _compassBox.alpha = 0.0;
            _widgetsView.alpha = 0.0;
            _currentSpeedWidget.alpha = 0.0;
            _currentAltitudeWidget.alpha = 0.0;
            _destinationViewController.view.alpha = 0.0;
            
        }];
    }
}

- (void)showBottomControls:(CGFloat)menuHeight
{
    if (_optionsMenuButton.alpha == 0.0 || _mapModeButton.frame.origin.y != DeviceScreenHeight - 69.0 - menuHeight)
    {
        [UIView animateWithDuration:.3 animations:^{
            
            _optionsMenuButton.alpha = (self.contextMenuMode ? 0.0 : 1.0);
            _zoomButtons.alpha = 1.0;
            _mapModeButton.alpha = 1.0;
            _actionsMenuButton.alpha = (self.contextMenuMode ? 0.0 : 1.0);

            _optionsMenuButton.frame = CGRectMake(0.0, DeviceScreenHeight - 63.0 - menuHeight, _optionsMenuButton.bounds.size.width, _optionsMenuButton.bounds.size.height);
            _actionsMenuButton.frame = CGRectMake(57.0, DeviceScreenHeight - 63.0 - menuHeight, _actionsMenuButton.bounds.size.width, _actionsMenuButton.bounds.size.height);
            _mapModeButton.frame = CGRectMake(DeviceScreenWidth - 128.0, DeviceScreenHeight - 69.0 - menuHeight, _mapModeButton.bounds.size.width, _mapModeButton.bounds.size.height);
            _zoomButtons.frame = CGRectMake(DeviceScreenWidth - 68.0, DeviceScreenHeight - 129.0 - menuHeight, _zoomButtons.bounds.size.width, _zoomButtons.bounds.size.height);
        }];
    }
}

- (void)hideBottomControls:(CGFloat)menuHeight
{
    if (_optionsMenuButton.alpha == 1.0 || _mapModeButton.frame.origin.y != DeviceScreenHeight - 69.0 - menuHeight)
    {
        [UIView animateWithDuration:.3 animations:^{
            
            _optionsMenuButton.alpha = 0.0;
            _zoomButtons.alpha = 0.0;
            _mapModeButton.alpha = 0.0;
            _actionsMenuButton.alpha = 0.0;
            
            _optionsMenuButton.frame = CGRectMake(0.0, DeviceScreenHeight - 63.0 - menuHeight, _optionsMenuButton.bounds.size.width, _optionsMenuButton.bounds.size.height);
            _actionsMenuButton.frame = CGRectMake(57.0, DeviceScreenHeight - 63.0 - menuHeight, _actionsMenuButton.bounds.size.width, _actionsMenuButton.bounds.size.height);
            _mapModeButton.frame = CGRectMake(DeviceScreenWidth - 128.0, DeviceScreenHeight - 69.0 - menuHeight, _mapModeButton.bounds.size.width, _mapModeButton.bounds.size.height);
            _zoomButtons.frame = CGRectMake(DeviceScreenWidth - 68.0, DeviceScreenHeight - 129.0 - menuHeight, _zoomButtons.bounds.size.width, _zoomButtons.bounds.size.height);
        }];
    }
}

- (void)enterContextMenuMode
{
    if (!self.contextMenuMode)
    {
        self.contextMenuMode = YES;
        [self updateMapModeButton];
        
        [UIView animateWithDuration:.3 animations:^{
            _optionsMenuButton.alpha = 0.0;
            _actionsMenuButton.alpha = 0.0;
        }];
    }
}

- (void)restoreFromContextMenuMode
{
    if (self.contextMenuMode)
    {
        self.contextMenuMode = NO;
        [self updateMapModeButton];
        
        [UIView animateWithDuration:.3 animations:^{
            _optionsMenuButton.alpha = 1.0;
            _actionsMenuButton.alpha = 1.0;
        }];
    }
}


@end
