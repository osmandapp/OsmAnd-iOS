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
#import "OABrowseMapAppModeHudViewController.h"
#import "OADriveAppModeHudViewController.h"
#import "OAMapViewController.h"
#import "OAAutoObserverProxy.h"
#import "OALog.h"

#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OADestinationViewController.h"
#import "OADestination.h"
#import "OAMapSettingsViewController.h"
#import "OAPOISearchViewController.h"
#import "OAPOIType.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/Road.h>
#include <OsmAndCore/CachingRoadLocator.h>

#define _(name) OAMapPanelViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

#define kMaxRoadDistanceInMeters 1000

@interface OAMapPanelViewController () <OADestinationViewControllerProtocol>

@property (nonatomic) OABrowseMapAppModeHudViewController *browseMapViewController;
@property (nonatomic) OADriveAppModeHudViewController *driveModeViewController;
@property (nonatomic) OADestinationViewController *destinationViewController;

@property (strong, nonatomic) OATargetPointView* targetMenuView;
@property (strong, nonatomic) UIButton* shadowButton;

@property (nonatomic, strong) UIViewController* prevHudViewController;

@end

@implementation OAMapPanelViewController
{
    OsmAndAppInstance _app;

    OAAutoObserverProxy* _appModeObserver;

    BOOL _hudInvalidated;
    
    BOOL _mapNeedsRestore;
    OAMapMode _mainMapMode;
    OsmAnd::PointI _mainMapTarget31;
    float _mainMapZoom;
    float _mainMapAzimuth;
    float _mainMapEvelationAngle;
    
    NSString *_formattedTargetName;
    double _targetLatitude;
    double _targetLongitude;

    OAMapSettingsViewController *_mapSettings;
    OAPOISearchViewController *_searchPOI;
    UILongPressGestureRecognizer *_shadowLongPress;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _app = [OsmAndApp instance];

    _appModeObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onAppModeChanged)
                                                  andObserve:_app.appModeObservable];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onTargetPointSet:) name:kNotificationSetTargetPoint object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onNoSymbolFound:) name:kNotificationNoSymbolFound object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onContextMarkerClicked:) name:kNotificationContextMarkerClicked object:nil];

    _hudInvalidated = NO;
}

- (void)loadView
{
    OALog(@"Creating Map Panel views...");
    
    // Create root view
    UIView* rootView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.view = rootView;
    
    // Instantiate map view controller
    _mapViewController = [[OAMapViewController alloc] init];
    [self addChildViewController:_mapViewController];
    [self.view addSubview:_mapViewController.view];
    _mapViewController.view.frame = self.view.frame;
    _mapViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    // Setup target point menu
    self.targetMenuView = [[OATargetPointView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, kOATargetPointViewHeightPortrait)];
    self.targetMenuView.delegate = self;

    [self updateHUD:NO];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (_hudInvalidated)
    {
        [self updateHUD:animated];
        _hudInvalidated = NO;
    }
    
    if (_mapNeedsRestore) {
        _mapNeedsRestore = NO;
        [self restoreMapAfterReuse];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if ([_mapViewController parentViewController] != self)
        [self doMapRestore];
}

- (void)viewWillLayoutSubviews
{
    if (_destinationViewController)
        [_destinationViewController updateFrame];
    
    if (_shadowButton)
        _shadowButton.frame = [self shadowButtonRect];
}

@synthesize mapViewController = _mapViewController;
@synthesize hudViewController = _hudViewController;

- (void)updateHUD:(BOOL)animated
{
    if (!_destinationViewController) {
        _destinationViewController = [[OADestinationViewController alloc] initWithNibName:@"OADestinationViewController" bundle:nil];
        _destinationViewController.delegate = self;

        for (OADestination *destination in _app.data.destinations)
            [_mapViewController addDestinationPin:destination.markerResourceName color:destination.color latitude:destination.latitude longitude:destination.longitude];

    }
    
    // Inflate new HUD controller and add it
    UIViewController* newHudController = nil;
    if (_app.appMode == OAAppModeBrowseMap)
    {
        if (!self.browseMapViewController) {
            self.browseMapViewController = [[OABrowseMapAppModeHudViewController alloc] initWithNibName:@"BrowseMapAppModeHUD"
                                                                                   bundle:nil];
            _browseMapViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            _browseMapViewController.destinationViewController = self.destinationViewController;
        }
        newHudController = self.browseMapViewController;

        _mapViewController.view.frame = self.view.frame;
    }
    else if (_app.appMode == OAAppModeDrive)
    {
        if (!self.driveModeViewController) {
            self.driveModeViewController = [[OADriveAppModeHudViewController alloc] initWithNibName:@"DriveAppModeHUD"
                                                                               bundle:nil];
            _driveModeViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            _driveModeViewController.destinationViewController = self.destinationViewController;
        }
        newHudController = self.driveModeViewController;
        
        CGRect frame = self.view.frame;
        frame.origin.y = 64.0;
        frame.size.height = DeviceScreenHeight - 64.0;
        _mapViewController.view.frame = frame;

    }
    [self addChildViewController:newHudController];

    // Switch views
    newHudController.view.frame = self.view.frame;
    [self.view addSubview:newHudController.view];
    
    if (animated && _hudViewController != nil)
    {
        _prevHudViewController = _hudViewController;
        [UIView transitionFromView:_hudViewController.view
                            toView:newHudController.view
                          duration:0.6
                           options:UIViewAnimationOptionTransitionFlipFromTop
         
                        completion:^(BOOL finished) {
                            [_prevHudViewController.view removeFromSuperview];
                            _prevHudViewController = nil;
                        }];
    }
    else
    {
        if (_hudViewController != nil)
            [_hudViewController.view removeFromSuperview];
    }

    // Remove previous view controller if such exists
    if (_hudViewController != nil)
        [_hudViewController removeFromParentViewController];
    _hudViewController = newHudController;

    [self.rootViewController setNeedsStatusBarAppearanceUpdate];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (_hudViewController == nil)
        return UIStatusBarStyleDefault;

    return _hudViewController.preferredStatusBarStyle;
}

- (void)onAppModeChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.isViewLoaded || self.view.window == nil)
        {
            _hudInvalidated = YES;
            return;
        }

        [self updateHUD:YES];
    });
}

- (void)saveMapStateIfNeeded
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

- (void)prepareMapForReuse:(Point31)destinationPoint zoom:(CGFloat)zoom newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated
{
    [self saveMapStateIfNeeded];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    [_mapViewController goToPosition:destinationPoint
                             andZoom:zoom
                            animated:animated];
    
    renderView.azimuth = newAzimuth;
    renderView.elevationAngle = newElevationAngle;
}

- (void)prepareMapForReuse:(UIView *)destinationView mapBounds:(OAGpxBounds)mapBounds newAzimuth:(float)newAzimuth newElevationAngle:(float)newElevationAngle animated:(BOOL)animated
{
    [self saveMapStateIfNeeded];
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    if (mapBounds.topLeft.latitude != DBL_MAX) {
        
        const OsmAnd::LatLon latLon(mapBounds.center.latitude, mapBounds.center.longitude);
        Point31 center = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
        
        float metersPerPixel = [_mapViewController calculateMapRuler];
        
        double distanceH = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.bottomRight.longitude, mapBounds.topLeft.latitude);
        double distanceV = OsmAnd::Utilities::distance(mapBounds.topLeft.longitude, mapBounds.topLeft.latitude, mapBounds.topLeft.longitude, mapBounds.bottomRight.latitude);
        
        CGSize mapSize = destinationView.bounds.size;
        
        CGFloat newZoomH = distanceH / (mapSize.width * metersPerPixel);
        CGFloat newZoomV = distanceV / (mapSize.height * metersPerPixel);
        CGFloat newZoom = log2(MAX(newZoomH, newZoomV));
        
        OAMapRendererView *renderer = (OAMapRendererView*)_mapViewController.view;
        CGFloat zoom = renderer.zoom - newZoom;
        
        [_mapViewController goToPosition:center
                                 andZoom:zoom
                                animated:animated];
    }
    
    
    renderView.azimuth = newAzimuth;
    renderView.elevationAngle = newElevationAngle;
}

- (void)doMapReuse:(UIViewController *)destinationViewController destinationView:(UIView *)destinationView
{
    CGRect newFrame = CGRectMake(0, 0, destinationView.bounds.size.width, destinationView.bounds.size.height);
    if (!CGRectEqualToRect(_mapViewController.view.frame, newFrame))
        _mapViewController.view.frame = newFrame;

    [_mapViewController willMoveToParentViewController:nil];
    
    [destinationViewController addChildViewController:_mapViewController];
    [destinationView addSubview:_mapViewController.view];
    [_mapViewController didMoveToParentViewController:self];
    [destinationView bringSubviewToFront:_mapViewController.view];
    
}

- (void)modifyMapAfterReuse:(Point31)destinationPoint zoom:(CGFloat)zoom azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated
{
    _mapNeedsRestore = NO;
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    renderView.azimuth = azimuth;
    renderView.elevationAngle = elevationAngle;
    [_mapViewController goToPosition:destinationPoint andZoom:zoom animated:YES];
}

- (void)modifyMapAfterReuse:(OAGpxBounds)mapBounds azimuth:(float)azimuth elevationAngle:(float)elevationAngle animated:(BOOL)animated
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
        
        OAMapRendererView *renderer = (OAMapRendererView*)_mapViewController.view;
        CGFloat zoom = renderer.zoom - newZoom;
        
        [_mapViewController goToPosition:center
                                 andZoom:zoom
                                animated:animated];
    }
}

- (void)restoreMapAfterReuse
{
    _app.mapMode = _mainMapMode;
    
    OAMapRendererView* mapView = (OAMapRendererView*)_mapViewController.view;
    mapView.target31 = _mainMapTarget31;
    mapView.zoom = _mainMapZoom;
    mapView.azimuth = _mainMapAzimuth;
    mapView.elevationAngle = _mainMapEvelationAngle;
}

- (void)doMapRestore
{
    [_mapViewController hideTempGpxTrack];
    
    _mapViewController.view.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    
    [_mapViewController willMoveToParentViewController:nil];
    
    [self addChildViewController:_mapViewController];
    [self.view addSubview:_mapViewController.view];
    [_mapViewController didMoveToParentViewController:self];
    [self.view sendSubviewToBack:_mapViewController.view];
    
}

-(void)closeMapSettings
{
    OAMapSettingsViewController* lastMapSettingsCtrl = [self.childViewControllers lastObject];
    if (lastMapSettingsCtrl)
        [lastMapSettingsCtrl hidePopup:YES];
    
    _mapSettings = nil;
    
    [self destroyShadowButton];
}

-(CGRect)shadowButtonRect
{
    CGRect frame;
    if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
        if (_mapSettings)
            frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height - kMapSettingsPopupHeight);
        else
            frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height - kOATargetPointViewHeightPortrait);
    } else {
        if (_mapSettings)
            frame = CGRectMake(kMapSettingsPopupWidth, 0.0, self.view.bounds.size.width - kMapSettingsPopupWidth, self.view.bounds.size.height);
        else
            frame = CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height - kOATargetPointViewHeightLandscape);
    }
    return frame;
}

- (void)removeGestureRecognizers
{
    while (self.view.gestureRecognizers.count > 0)
        [self.view removeGestureRecognizer:self.view.gestureRecognizers[0]];
}

- (void)mapSettingsButtonClick:(id)sender
{
    [self removeGestureRecognizers];
    
    _mapSettings = [[OAMapSettingsViewController alloc] initPopup];
    [_mapSettings showPopupAnimated:self parentViewController:nil];
    
    [self createShadowButton:@selector(closeMapSettings) withLongPressEvent:nil];
}

- (void)searchButtonClick:(id)sender
{
    [self removeGestureRecognizers];

    if (!_searchPOI)
        _searchPOI = [[OAPOISearchViewController alloc] init];
    [self.navigationController presentViewController:_searchPOI animated:YES completion:nil];
}

-(void)onNoSymbolFound:(NSNotification *)notification
{
    //[self hideTargetPointMenu];
}

-(void)onContextMarkerClicked:(NSNotification *)notification
{
    if (!self.targetMenuView.superview)
    {
        [self showTargetPointMenu];
    }
}

-(void)onTargetPointSet:(NSNotification *)notification
{
    NSDictionary *params = [notification userInfo];
    OAPOIType *poiType = [params objectForKey:@"poiType"];
    NSString *caption = [params objectForKey:@"caption"];
    NSString *buildingNumber = [params objectForKey:@"buildingNumber"];
    UIImage *icon = [params objectForKey:@"icon"];
    double lat = [[params objectForKey:@"lat"] floatValue];
    double lon = [[params objectForKey:@"lon"] floatValue];
    CGPoint touchPoint = CGPointMake([[params objectForKey:@"touchPoint.x"] floatValue], [[params objectForKey:@"touchPoint.y"] floatValue]);
    
    NSString* addressString;
    self.targetMenuView.isAddressFound = NO;
    if (caption.length == 0 && !poiType)
    {
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
        
        if (!nativeTitle || [nativeTitle isEqualToString:@""])
        {
            if (buildingNumber.length > 0)
                addressString = buildingNumber;
            else
                addressString = @"Address is not known yet";
            
            self.targetMenuView.isAddressFound = YES;
        }
        else
        {
            if (buildingNumber.length > 0)
                addressString = [NSString stringWithFormat:@"%@, %@", nativeTitle, buildingNumber];
            else
                addressString = nativeTitle;
            self.targetMenuView.isAddressFound = YES;
        }
    }
    else if (caption.length > 0)
    {
        self.targetMenuView.isAddressFound = YES;
        addressString = caption;
    }
    
    if (self.targetMenuView.isAddressFound)
        _formattedTargetName = addressString;
    else if (poiType)
        _formattedTargetName = poiType.nameLocalized;
    else if (buildingNumber.length > 0)
        _formattedTargetName = buildingNumber;
    else
        _formattedTargetName = [[[OsmAndApp instance] locationFormatterDigits] stringFromCoordinate:CLLocationCoordinate2DMake(lat, lon)];
    
    _targetLatitude = lat;
    _targetLongitude = lon;
    
    OAMapRendererView* renderView = (OAMapRendererView*)_mapViewController.view;
    
    [self.targetMenuView setPointLat:lat Lon:lon Zoom:renderView.zoom andTouchPoint:touchPoint];
    [self.targetMenuView setAddress:_formattedTargetName];
    [self.targetMenuView.imageView setImage:icon];
    
    [self showTargetPointMenu];
}

-(void)createShadowButton:(SEL)action withLongPressEvent:(SEL)withLongPressEvent
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
    [self.view addSubview:self.shadowButton];
}

-(void)destroyShadowButton
{
    [_shadowButton removeFromSuperview];
    if (_shadowLongPress) {
        [_shadowButton removeGestureRecognizer:_shadowLongPress];
        _shadowLongPress = nil;
    }
    self.shadowButton = nil;
}

- (void)shadowTargetPointLongPress:(UILongPressGestureRecognizer*)gesture
{
    if ( gesture.state == UIGestureRecognizerStateEnded )
        [_mapViewController simulateContextMenuPress:gesture];
}

#pragma mark - OATargetPointViewDelegate

-(void)targetPointAddFavorite
{
    [self hideTargetPointMenu];
}

-(void)targetPointShare
{
}

-(void)targetPointDirection
{
    OADestination *destination = [[OADestination alloc] initWithDesc:_formattedTargetName latitude:_targetLatitude longitude:_targetLongitude];
    if (![_hudViewController.view.subviews containsObject:_destinationViewController.view])
        [_hudViewController.view addSubview:_destinationViewController.view];
    UIColor *color = [_destinationViewController addDestination:destination];
    
    if (color)
        [_mapViewController addDestinationPin:destination.markerResourceName color:destination.color latitude:_targetLatitude longitude:_targetLongitude];
    
    [self hideTargetPointMenu];
}

-(void)targetHide
{
    [_mapViewController hideContextPinMarker];
    [self hideTargetPointMenu];
}

-(void)targetGoToPoint
{
    OsmAnd::LatLon latLon(_targetLatitude, _targetLongitude);
    Point31 point = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
    [_mapViewController goToPosition:point animated:YES];
}

-(void)showTargetPointMenu
{
    [self.targetMenuView setNavigationController:self.navigationController];
    [self.targetMenuView setMapViewInstance:_mapViewController.view];
    
    [self.targetMenuView doLayoutSubviews];
    CGRect frame = self.targetMenuView.frame;
    frame.origin.y = DeviceScreenHeight + 10.0;
    self.targetMenuView.frame = frame;
    
    if ([self.view.subviews containsObject:self.targetMenuView])
        [self.targetMenuView removeFromSuperview];
    [self.view addSubview:self.targetMenuView];
    
    [UIView animateWithDuration:0.3 animations:^{
        
        CGRect frame = self.targetMenuView.frame;
        frame.origin.y = DeviceScreenHeight - self.targetMenuView.bounds.size.height;
        self.targetMenuView.frame = frame;
        
    } completion:^(BOOL finished) {
        
        [self createShadowButton:@selector(hideTargetPointMenu) withLongPressEvent:@selector(shadowTargetPointLongPress:)];
        
    }];
}

-(void)hideTargetPointMenu
{
    [self destroyShadowButton];
    
    if (self.targetMenuView.superview)
    {
        CGRect frame = self.targetMenuView.frame;
        frame.origin.y = DeviceScreenHeight + 10.0;
        
        [UIView animateWithDuration:0.5 animations:^{
            self.targetMenuView.frame = frame;
            
        } completion:^(BOOL finished) {
            [self.targetMenuView removeFromSuperview];
        }];
    }
}

#pragma mark - OADestinationViewControllerProtocol

- (void)destinationRemoved:(OADestination *)destination
{
    [_mapViewController removeDestinationPin:destination.color];
}

-(void)destinationViewLayoutDidChange
{
    if ([_hudViewController isKindOfClass:[OABrowseMapAppModeHudViewController class]]) {
        OABrowseMapAppModeHudViewController *browserMap = (OABrowseMapAppModeHudViewController *)_hudViewController;
        [browserMap updateDestinationViewLayout];
        
    } else if ([_hudViewController isKindOfClass:[OADriveAppModeHudViewController class]]) {
        OADriveAppModeHudViewController *drive = (OADriveAppModeHudViewController *)_hudViewController;
        [drive updateDestinationViewLayout];
        
    }
}

- (void)destinationViewMoveToLatitude:(double)lat lon:(double)lon
{
    OsmAnd::LatLon latLon(lat, lon);
    Point31 point = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(latLon)];
    [_mapViewController goToPosition:point animated:YES];
}

@end
