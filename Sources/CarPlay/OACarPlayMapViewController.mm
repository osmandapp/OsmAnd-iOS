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
#import "OANativeUtilities.h"
#import "OAMapViewTrackingUtilities.h"
#import "OACarPlayDashboardInterfaceController.h"
#import "OAAlarmWidget.h"

#define kViewportXNonShifted 1.0

@interface OACarPlayMapViewController ()

@end

@implementation OACarPlayMapViewController
{
    CPWindow *_window;
    OAMapViewController *_mapVc;

    CGFloat _cachedViewportX;
    CGFloat _cachedViewportY;

    BOOL _isInNavigationMode;
    
    OAAlarmWidget *_alarmWidget;
    
    NSLayoutConstraint *leftHandDrivingAlarmWidgetConstraint;
    NSLayoutConstraint *rightHandDrivingAlarmWidgetConstraint;
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.delegate)
        [self.delegate onIntefaceControllerAttached];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self attachMapToWindow];
    [self setupAlarmWidget];
    if (self.delegate)
        [self.delegate onMapViewAttached];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (self.delegate)
        [self.delegate onIntefaceControllerDetached];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    BOOL isLeftSideDriving = [self isLeftSideDriving];
    if (isLeftSideDriving)
    {
        [rightHandDrivingAlarmWidgetConstraint setActive:NO];
        [leftHandDrivingAlarmWidgetConstraint setActive:YES];
    }
    else
    {
        [leftHandDrivingAlarmWidgetConstraint setActive:NO];
        [rightHandDrivingAlarmWidgetConstraint setActive:YES];
    }

    [self updateMapCenterPoint];
}

- (void)updateMapCenterPoint
{
    if (_mapVc.isCarPlayDashboardActive)
        return;

    UIEdgeInsets insets = _window.safeAreaInsets;

    CGFloat w = self.view.frame.size.width;
    CGFloat h = self.view.frame.size.height;

    CGFloat widthOffset = MAX(insets.right, insets.left) / w;
    CGFloat heightOffset = insets.top / h;

    BOOL isLeftSideDriving = [self isLeftSideDriving];
    if (_isInNavigationMode)
        [_mapVc setViewportForCarPlayScaleX:isLeftSideDriving ? 1.5 : 0.5 y:kViewportBottomScale];
    else
        [_mapVc setViewportForCarPlayScaleX:isLeftSideDriving ? 1.0 + widthOffset : 1.0 - widthOffset y:1.0 + heightOffset];
}

- (void)setupAlarmWidget
{
    _alarmWidget = [[OAAlarmWidget alloc] initForCarPlay];
    _alarmWidget.translatesAutoresizingMaskIntoConstraints = NO;
    [_window addSubview:_alarmWidget];
    
    [NSLayoutConstraint activateConstraints:@[
        [_alarmWidget.topAnchor constraintEqualToAnchor:_window.mapButtonSafeAreaLayoutGuide.topAnchor constant:4.0],
        [_alarmWidget.heightAnchor constraintEqualToConstant:60.0],
        [_alarmWidget.widthAnchor constraintEqualToConstant:60.0]
    ]];
    // In Right-Hand drive mode, the widget automatically has an X offset of -22 pixels. We add an additional constraint with the desired offset.
    leftHandDrivingAlarmWidgetConstraint = [_alarmWidget.trailingAnchor constraintEqualToAnchor:_window.mapButtonSafeAreaLayoutGuide.trailingAnchor constant:8];
    rightHandDrivingAlarmWidgetConstraint = [_alarmWidget.trailingAnchor constraintEqualToAnchor:_window.mapButtonSafeAreaLayoutGuide.trailingAnchor constant:22];
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

        _mapVc.isCarPlayActive = YES;
    }
}

- (void) detachFromCarPlayWindow
{
    if (_mapVc)
    {
        [_mapVc.mapView suspendRendering];
        [_mapVc removeFromParentViewController];
        [_mapVc.view removeFromSuperview];

        _mapVc.isCarPlayActive = NO;
        OAMapPanelViewController *mapPanel = OARootViewController.instance.mapPanel;

        [mapPanel addChildViewController:_mapVc];
        [mapPanel.view insertSubview:_mapVc.view atIndex:0];
        _mapVc.view.frame = mapPanel.view.frame;
        _mapVc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [_mapVc.mapView resumeRendering];

        [_mapVc setViewportScaleX:kViewportScale];
        [[OAMapViewTrackingUtilities instance] updateSettings];
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
    const double scale31 = static_cast<double>(tileSize31) / _mapVc.mapView.tileSizeOnScreenInPixels;
    
    // Rescale movement to 31 coordinates
    OsmAnd::PointI target31 = _mapVc.mapView.target31;
    target31.x -= static_cast<int32_t>(round(translationInMapSpace.x * scale31));
    target31.y -= static_cast<int32_t>(round(translationInMapSpace.y * scale31));
    
    [_mapVc goToPosition:[OANativeUtilities convertFromPointI:target31] animated:YES];
}

- (void)onZoomInPressed
{
    [_mapVc zoomIn];
}

- (void)onZoomOutPressed
{
    [_mapVc zoomOut];
}

- (void)onCenterMapPressed
{
    [[OAMapViewTrackingUtilities instance] backToLocationImpl];
}

- (void)on3DMapPressed
{
    [[OAMapViewTrackingUtilities instance] switchMap3dMode];
}

- (void)centerMapOnRoute:(CLLocationCoordinate2D)topLeft bottomRight:(CLLocationCoordinate2D)bottomRight
{
    CGSize screenBBox = self.view.frame.size;
    [[OARootViewController instance].mapPanel displayAreaOnMap:topLeft
                                                   bottomRight:bottomRight
                                                          zoom:0.
                                                    screenBBox:screenBBox
                                                   bottomInset:0.
                                                     leftInset:0.
                                                      topInset:0.
                                                      animated:YES];
}

- (BOOL)isLeftSideDriving
{
    return _alarmWidget.frame.origin.x > self.view.frame.size.width / 2.0;
}

- (void)enterNavigationMode
{
    _cachedViewportX = _mapVc.mapView.viewportXScale;
    _isInNavigationMode = YES;
    [self.view layoutIfNeeded];
}

- (void)exitNavigationMode
{
    [_mapVc setViewportForCarPlayScaleX:_cachedViewportX];
    _isInNavigationMode = NO;
}

- (void)onLocationChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_alarmWidget updateInfo];
    });
}

@end
