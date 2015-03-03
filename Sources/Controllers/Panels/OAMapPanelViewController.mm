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

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

#define _(name) OAMapPanelViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

@interface OAMapPanelViewController ()

@property (nonatomic) OABrowseMapAppModeHudViewController *browseMapViewController;
@property (nonatomic) OADriveAppModeHudViewController *driveModeViewController;
@property (nonatomic) OADestinationViewController *destinationViewController;

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
    _hudInvalidated = NO;
}

- (void)loadView
{
    OALog(@"Creating Map Panel views...");
    
    // Create root view
    UIView* rootView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    self.view = rootView;
    
    // Instantiate map view controller
    _mapViewController = [[OAMapViewController alloc] init];
    [self addChildViewController:_mapViewController];
    [_mapViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:_mapViewController.view];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"view":_mapViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"view":_mapViewController.view}]];

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

@synthesize mapViewController = _mapViewController;
@synthesize hudViewController = _hudViewController;

- (void)updateHUD:(BOOL)animated
{
    if (!_destinationViewController)
        _destinationViewController = [[OADestinationViewController alloc] initWithNibName:@"OADestinationViewController" bundle:nil];
    
    // Inflate new HUD controller and add it
    UIViewController* newHudController = nil;
    if (_app.appMode == OAAppModeBrowseMap)
    {
        if (!self.browseMapViewController) {
            self.browseMapViewController = [[OABrowseMapAppModeHudViewController alloc] initWithNibName:@"BrowseMapAppModeHUD"
                                                                                   bundle:nil];
            self.browseMapViewController.destinationViewController = self.destinationViewController;
        }
        newHudController = self.browseMapViewController;
    }
    else if (_app.appMode == OAAppModeDrive)
    {
        if (!self.driveModeViewController) {
            self.driveModeViewController = [[OADriveAppModeHudViewController alloc] initWithNibName:@"DriveAppModeHUD"
                                                                               bundle:nil];
            self.driveModeViewController.destinationViewController = self.destinationViewController;
        }
        newHudController = self.driveModeViewController;
    }
    [self addChildViewController:newHudController];

    // Switch views
    [newHudController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:newHudController.view];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"view":newHudController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"view":newHudController.view}]];
    if (animated && _hudViewController != nil)
    {
        [UIView transitionFromView:_hudViewController.view
                            toView:newHudController.view
                          duration:0.6
                           options:UIViewAnimationOptionTransitionFlipFromTop
                        completion:nil];
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
        
        //double distanceH = OsmAnd::Utilities::distance(left, top, right, top);
        //double distanceV = OsmAnd::Utilities::distance(left, top, left, bottom);
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
    
    //UIView * parent = destinationView;
    //UIView * child = _mapViewController.view;
    [_mapViewController.view setTranslatesAutoresizingMaskIntoConstraints:YES];
    /*
    
    [parent addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:@{@"view":_mapViewController.view}]];
    [parent addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                   options:0
                                                                   metrics:nil
                                                                     views:@{@"view":_mapViewController.view}]];
     */
    //[parent layoutIfNeeded];
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
        
        //double distanceH = OsmAnd::Utilities::distance(left, top, right, top);
        //double distanceV = OsmAnd::Utilities::distance(left, top, left, bottom);
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
    
    [_mapViewController.view setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"view":_mapViewController.view}]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[view]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:@{@"view":_mapViewController.view}]];
}


@end
