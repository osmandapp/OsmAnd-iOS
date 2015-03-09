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

#import <JASidePanelController.h>
#import <UIViewController+JASidePanel.h>

#import "OsmAndApp.h"
#import "OAAutoObserverProxy.h"
#import "OAMapViewController.h"
#if defined(OSMAND_IOS_DEV)
#   import "OADebugHudViewController.h"
#endif // defined(OSMAND_IOS_DEV)
#import "OARootViewController.h"

#import "OADestinationViewController.h"
#import "OADestination.h"
#import "OADestinationCell.h"
#import "OANativeUtilities.h"

#include <OsmAndCore/Data/Road.h>
#include <OsmAndCore/CachingRoadLocator.h>

#define _(name) OAMapModeHudViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

#define kMaxRoadDistanceInMeters 1000

@interface OABrowseMapAppModeHudViewController ()<OADestinationViewControllerProtocol>

@property (weak, nonatomic) IBOutlet UIView *compassBox;
@property (weak, nonatomic) IBOutlet UIButton *compassButton;
@property (weak, nonatomic) IBOutlet UIImageView *compassImage;
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
@property (strong, nonatomic) OATargetPointView* targetMenuView;
@property (strong, nonatomic) UIButton* shadowButton;

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
        
    NSString *_formattedTargetName;
    double _targetLatitude;
    double _targetLongitude;
    
    BOOL _driveModeActive;

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
    
    // Menu guest recognizer
    _grMove = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                      action:@selector(moveGestureDetected:)];
    _grMove.delegate = self;
    
    [_mapViewController.view addGestureRecognizer:_grMove];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTargetPointSet:) name:kNotificationSetTargetPoint object:nil];
    
}

- (void)deinit
{

}

- (void)moveGestureDetected:(UIPanGestureRecognizer*)recognizer
{
    self.sidePanelController.recognizesPanGesture = NO;
}

NSLayoutConstraint* targetBottomConstraint;
- (void)viewDidLoad
{
    [super viewDidLoad];
	    
    if (_app.mapMode == OAMapModeFollow || _app.mapMode == OAMapModePositionTrack)
        _driveModeButton.hidden = NO;
    else
        _driveModeButton.hidden = YES;

    _compassImage.transform = CGAffineTransformMakeRotation(-_mapViewController.mapRendererView.azimuth / 180.0f * M_PI);
    _zoomInButton.enabled = [_mapViewController canZoomIn];
    
    UIImageView *backgroundViewIn = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD_button_bg"]];
    [backgroundViewIn setFrame:CGRectMake(_zoomInButton.frame.origin.x + 8, _zoomInButton.frame.origin.y, _zoomInButton.frame.size.width - 16, _zoomInButton.frame.size.height)];
    [_zoomInButton.superview insertSubview:backgroundViewIn belowSubview:_zoomInButton];
    
    UIImageView *backgroundViewOut = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HUD_button_bg"]];
    [backgroundViewOut setFrame:CGRectMake(_zoomOutButton.frame.origin.x + 8, _zoomOutButton.frame.origin.y, _zoomOutButton.frame.size.width - 16, _zoomOutButton.frame.size.height)];
    [_zoomOutButton.superview insertSubview:backgroundViewOut belowSubview:_zoomOutButton];
    
    _zoomOutButton.enabled = [_mapViewController canZoomOut];
    
    // IOS-218
    self.rulerLabel = [[OAMapRulerView alloc] initWithFrame:CGRectMake(50, DeviceScreenHeight - 40, kMapRulerMinWidth, 25)];
    self.rulerLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.rulerLabel];
    
    // Constraints
    NSLayoutConstraint* constraint = [NSLayoutConstraint constraintWithItem:self.rulerLabel attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant:-15.0f];
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.rulerLabel attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0f constant:50.0f];
    [self.view addConstraint:constraint];
    
    constraint = [NSLayoutConstraint constraintWithItem:self.rulerLabel attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:25];
    [self.view addConstraint:constraint];
    self.rulerLabel.hidden = true;
    
    
    // Setup target point menu
    self.targetMenuView = [[OATargetPointView alloc] initWithFrame:CGRectMake(0, DeviceScreenHeight + 10, DeviceScreenWidth, kOATargetPointViewHeight)];
    self.targetMenuView.translatesAutoresizingMaskIntoConstraints = NO;
    self.targetMenuView.delegate = self;
    [self.view addSubview:self.targetMenuView];
    
    // Constraints
    targetBottomConstraint = [NSLayoutConstraint constraintWithItem:self.targetMenuView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0f constant: self.targetMenuView.frame.size.height + 10];
    [self.view addConstraint:targetBottomConstraint];
    
    NSLayoutConstraint* targetConstraint = [NSLayoutConstraint constraintWithItem:self.targetMenuView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1.0f constant:0.0f];
    [self.view addConstraint:targetConstraint];
    
    targetConstraint = [NSLayoutConstraint constraintWithItem:self.targetMenuView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1.0f constant:0.0f];
    [self.view addConstraint:targetConstraint];
    
    targetConstraint = [NSLayoutConstraint constraintWithItem:self.targetMenuView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0f constant:kOATargetPointViewHeight];
    [self.view addConstraint:targetConstraint];

#if !defined(OSMAND_IOS_DEV)
    _debugButton.hidden = YES;
#endif // !defined(OSMAND_IOS_DEV)
}

-(void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    
    _destinationViewController.singleLineOnly = NO;
    _destinationViewController.top = 20.0;
    _destinationViewController.delegate = self;
    
    if (![self.view.subviews containsObject:_destinationViewController.view] &&
        [_destinationViewController allDestinations].count > 0)
        [self.view addSubview:_destinationViewController.view];

    //IOS-222
    if ([[NSUserDefaults standardUserDefaults] objectForKey:kUDLastMapModePositionTrack] && !_driveModeActive) {
        OAMapMode mapMode = (OAMapMode)[[NSUserDefaults standardUserDefaults] integerForKey:kUDLastMapModePositionTrack];
        [_app setMapMode:mapMode];
    }
    _driveModeActive = NO;
}

-(void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:animated];
    
    [self.zoomButtonsView setHidden: ![[OAAppSettings sharedManager] settingShowZoomButton]];
    
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 2.0 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.rulerLabel.hidden)
            [self.rulerLabel setRulerData:[_mapViewController calculateMapRuler]];
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
    if (_destinationViewController)
        [_destinationViewController updateFrame];
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

- (void)onMapModeChanged
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_app.mapMode == OAMapModeFollow || _app.mapMode == OAMapModePositionTrack)
            _driveModeButton.hidden = NO;
        else
            _driveModeButton.hidden = YES;
        
        [_mapModeButton setImage:modeImage forState:UIControlStateNormal];
    });
}

- (IBAction)onOptionsMenuButtonDown:(id)sender {
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
    });
}

- (void)onMapAppearanceChanged:(id)observable withKey:(id)key
{
    [self viewDidAppear:false];
}

- (void)onMapChanged:(id)observable withKey:(id)key
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.rulerLabel setRulerData:[_mapViewController calculateMapRuler]];
    });
}

-(void)onTargetPointSet:(NSNotification *)notification {
    NSDictionary *params = [notification userInfo];
    NSString *caption = [params objectForKey:@"caption"];
    UIImage *icon = [params objectForKey:@"icon"];
    double lat = [[params objectForKey:@"lat"] floatValue];
    double lon = [[params objectForKey:@"lon"] floatValue];
    CGPoint touchPoint = CGPointMake([[params objectForKey:@"touchPoint.x"] floatValue], [[params objectForKey:@"touchPoint.y"] floatValue]);
    
    NSString* addressString;
    if (caption.length == 0) {
        std::shared_ptr<OsmAnd::CachingRoadLocator> _roadLocator;
        _roadLocator.reset(new OsmAnd::CachingRoadLocator(_app.resourcesManager->obfsCollection));
        
        std::shared_ptr<const OsmAnd::Road> road;
        
        const OsmAnd::PointI position31(
                                        OsmAnd::Utilities::get31TileNumberX(lon),
                                        OsmAnd::Utilities::get31TileNumberY(lat));
        
        road = _roadLocator->findNearestRoad(position31,
                                             kMaxRoadDistanceInMeters,
                                             OsmAnd::RoutingDataLevel::Detailed);
        
        NSString* localizedTitle;
        NSString* nativeTitle;
        if (road) {
            const auto mainLanguage = QString::fromNSString([[NSLocale preferredLanguages] firstObject]);
            const auto localizedName = road->getCaptionInLanguage(mainLanguage);
            const auto nativeName = road->getCaptionInNativeLanguage();
            if (!localizedName.isNull())
                localizedTitle = localizedName.toNSString();
            if (!nativeName.isNull())
                nativeTitle = nativeName.toNSString();
        }
        
        addressString = nativeTitle;
        if (!addressString || [addressString isEqualToString:@""]) {
            addressString = @"Address is not known yet";
            self.targetMenuView.isAddressFound = NO;
        } else {
            self.targetMenuView.isAddressFound = YES;
        }
    } else {
        self.targetMenuView.isAddressFound = YES;
        addressString = caption;
    }
    
    if (self.targetMenuView.isAddressFound) {
        _formattedTargetName = addressString;
    } else {
        _formattedTargetName = [[[OsmAndApp instance] locationFormatterDigits] stringFromCoordinate:CLLocationCoordinate2DMake(lat, lon)];
    }
    _targetLatitude = lat;
    _targetLongitude = lon;
    
    [self.targetMenuView setPointLat:lat Lon:lon andTouchPoint:touchPoint];
    [self.targetMenuView setAddress:addressString];
    
    [self.targetMenuView.imageView setImage:icon];
    
    [self.targetMenuView setNavigationController:self.navigationController];
    [self.targetMenuView setMapViewInstance:_mapViewController.view];

    [targetBottomConstraint setConstant:0];
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        if (_shadowButton && [self.view.subviews containsObject:_shadowButton]) {
            [_shadowButton removeFromSuperview];
            self.shadowButton = nil;
        }
        
        self.shadowButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - kOATargetPointViewHeight)];
        _shadowButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_shadowButton setBackgroundColor:[UIColor colorWithWhite:0.3 alpha:0]];
        [_shadowButton addTarget:self action:@selector(hideTargetPointMenu) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:self.shadowButton];
    }];
    
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
    return UIStatusBarStyleLightContent;

    /*
    if ([OAAppSettings sharedManager].settingAppMode == 0) {
        return UIStatusBarStyleDefault;
    } else {
        return UIStatusBarStyleLightContent;
    }
     */
}

#pragma mark - OATargetPointViewDelegate

-(void)targetPointAddFavorite {
    [self hideTargetPointMenu];
}


-(void)targetPointShare {

}


-(void)targetPointDirection {
    
    OADestination *destination = [[OADestination alloc] initWithDesc:_formattedTargetName latitude:_targetLatitude longitude:_targetLongitude];
    if (![self.view.subviews containsObject:_destinationViewController.view])
        [self.view addSubview:_destinationViewController.view];
    UIColor *color = [_destinationViewController addDestination:destination];
    
    if (color)
        [_mapViewController addDestinationPin:color latitude:_targetLatitude longitude:_targetLongitude];
    
    [self hideTargetPointMenu];
}

-(void)hideTargetPointMenu {
    [_mapViewController hideContextPinMarker];
    [_shadowButton removeFromSuperview];
    self.shadowButton = nil;
    [targetBottomConstraint setConstant:kOATargetPointViewHeight + 10];
    [UIView animateWithDuration:0.5 animations:^{
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - OADestinationViewControllerProtocol

- (void)destinationRemoved:(OADestination *)destination
{
    [_mapViewController removeDestinationPin:destination.color];
}

-(void)destinationViewLayoutDidChange
{
    CGFloat x = _compassBox.frame.origin.x;
    CGSize size = _compassBox.frame.size;
    CGFloat y = _destinationViewController.view.frame.origin.y + _destinationViewController.view.frame.size.height + 1.0;
    
    if (!CGRectEqualToRect(_compassBox.frame, CGRectMake(x, y, size.width, size.height)))
        [UIView animateWithDuration:.2 animations:^{
            _compassBox.frame = CGRectMake(x, y, size.width, size.height);
        }];

}

- (void)destinationViewMoveToLatitude:(double)lat lon:(double)lon
{
    OsmAnd::LatLon latLon(lat, lon);
    Point31 point = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
    [_mapViewController goToPosition:point animated:YES];
}

#pragma mark - debug


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
