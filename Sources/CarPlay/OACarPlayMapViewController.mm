//
//  OACarPlayMapViewController.m
//  OsmAnd Maps
//
//  Created by Paul on 11.02.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACarPlayMapViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OANativeUtilities.h"
#import "OAMapViewTrackingUtilities.h"

#import <CarPlay/CarPlay.h>

#include <QtMath>

@interface OACarPlayMapViewController ()

@end

@implementation OACarPlayMapViewController
{
    CPWindow *_window;
    OAMapViewController *_mapVc;
}

- (instancetype) initWithCarPlayWindow:(CPWindow *)window mapViewController:(OAMapViewController *)mapVC
{
    self = [super init];
    if (self) {
        _window = window;
        _mapVc = mapVC;
    }
    return self;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self attachMapToWindow];
}

- (void) attachMapToWindow
{
    if (_window && _mapVc)
    {
        [_mapVc.mapView suspendRendering];
        [_mapVc removeFromParentViewController];
        [_mapVc.view removeFromSuperview];
        
        [self addChildViewController:_mapVc];
        [self.view addSubview:_mapVc.view];
        _mapVc.view.frame = self.view.frame;
        _mapVc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [_mapVc.mapView resumeRendering];
    }
}

- (void) detachFromCarPlayWindow
{
    if (_mapVc)
    {
        [_mapVc.mapView suspendRendering];
        
        [_mapVc removeFromParentViewController];
        [_mapVc.view removeFromSuperview];
        
        OAMapPanelViewController *mapPanel = OARootViewController.instance.mapPanel;
        
        [mapPanel addChildViewController:_mapVc];
        [mapPanel.view insertSubview:_mapVc.view atIndex:0];
        _mapVc.view.frame = mapPanel.view.frame;
        _mapVc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_mapVc.mapView resumeRendering];
    }
}

// MARK: OACarPlayDashboardDelegate

- (void) onMapControlPressed:(CPPanDirection)panDirection
{
    // Get movement delta in points (not pixels, that is for retina and non-retina devices value is the same)
    CGPoint translation;
    CGFloat moveStep = 0.5;
    switch (panDirection) {
        case CPPanDirectionUp:
        {
            translation = CGPointMake(0., self.view.center.y * moveStep);
            break;
        }
        case CPPanDirectionDown:
        {
            translation = CGPointMake(0., -self.view.center.y * moveStep);
            break;
        }
        case CPPanDirectionLeft:
        {
            translation = CGPointMake(self.view.center.x * moveStep, 0.);
            break;
        }
        case CPPanDirectionRight:
        {
            translation = CGPointMake(-self.view.center.x * moveStep, 0.);
            break;
        }
        default:
        {
            return;
        }
    }
    
    translation.x *= _mapVc.mapView.contentScaleFactor;
    translation.y *= _mapVc.mapView.contentScaleFactor;
    
    const float angle = qDegreesToRadians(_mapVc.mapView.azimuth);
    const float cosAngle = cosf(angle);
    const float sinAngle = sinf(angle);
    CGPoint translationInMapSpace;
    translationInMapSpace.x = translation.x * cosAngle - translation.y * sinAngle;
    translationInMapSpace.y = translation.x * sinAngle + translation.y * cosAngle;
    
    // Taking into account current zoom, get how many 31-coordinates there are in 1 point
    const uint32_t tileSize31 = (1u << (31 - _mapVc.mapView.zoomLevel));
    const double scale31 = static_cast<double>(tileSize31) / _mapVc.mapView.currentTileSizeOnScreenInPixels;
    
    // Rescale movement to 31 coordinates
    OsmAnd::PointI target31 = _mapVc.mapView.target31;
    target31.x -= static_cast<int32_t>(round(translationInMapSpace.x * scale31));
    target31.y -= static_cast<int32_t>(round(translationInMapSpace.y * scale31));
    
    [_mapVc goToPosition:[OANativeUtilities convertFromPointI:target31] animated:YES];
}

- (void)onZoomInPressed
{
    [_mapVc animatedZoomIn];
}

- (void)onZoomOutPressed
{
    [_mapVc animatedZoomOut];
}

- (void)onCenterMapPressed
{
    [[OAMapViewTrackingUtilities instance] backToLocationImpl];
}

- (void) centerMapOnRoute:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight
{
    UIEdgeInsets safeAreaInsets = self.view.safeAreaInsets;
    CGFloat viewWidth = self.view.frame.size.width;
    CGFloat leftInset = viewWidth * 0.48;
    CGSize screenBBox = CGSizeMake(viewWidth - leftInset, self.view.frame.size.height - safeAreaInsets.top - safeAreaInsets.bottom);
    [[OARootViewController instance].mapPanel displayAreaOnMap:topLeft bottomRight:bottomRight zoom:0. screenBBox:screenBBox bottomInset:safeAreaInsets.bottom leftInset:leftInset topInset:safeAreaInsets.top];
}

@end
