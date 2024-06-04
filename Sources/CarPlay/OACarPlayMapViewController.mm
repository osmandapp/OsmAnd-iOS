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
#import "OsmAnd_Maps-Swift.h"

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
    SpeedometerView *_speedometerView;
    UIStackView *_alarmSpeedometerStackView;
    
    NSLayoutConstraint *_leftHandDrivingAlarmSpeedometerStackViewConstraint;
    NSLayoutConstraint *_rightHandDrivingAlarmSpeedometerStackViewConstraint;
    NSLayoutConstraint *_speedometerHeightConstraint;
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
        [self.delegate onInterfaceControllerAttached];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [self attachMapToWindow];
    
    _alarmSpeedometerStackView = [UIStackView new];
    _alarmSpeedometerStackView.translatesAutoresizingMaskIntoConstraints = NO;
    _alarmSpeedometerStackView.axis = UILayoutConstraintAxisVertical;
    _alarmSpeedometerStackView.distribution = UIStackViewDistributionEqualSpacing;
    _alarmSpeedometerStackView.spacing = 5;
    [_window addSubview:_alarmSpeedometerStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [_alarmSpeedometerStackView.topAnchor constraintEqualToAnchor:_window.mapButtonSafeAreaLayoutGuide.topAnchor constant:8]
    ]];
    
    _leftHandDrivingAlarmSpeedometerStackViewConstraint = [_alarmSpeedometerStackView.leftAnchor constraintEqualToAnchor:_window.mapButtonSafeAreaLayoutGuide.leftAnchor];
    _rightHandDrivingAlarmSpeedometerStackViewConstraint = [_alarmSpeedometerStackView.rightAnchor constraintEqualToAnchor:_window.mapButtonSafeAreaLayoutGuide.rightAnchor];
    
    [self setupSpeedometer];
    [self setupAlarmWidget];
    
    if (self.delegate)
        [self.delegate onMapViewAttached];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    if (self.delegate)
        [self.delegate onInterfaceControllerDetached];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    BOOL isLeftSideDriving = [self isLeftSideDriving];
    if (isLeftSideDriving)
    {
        _alarmSpeedometerStackView.alignment = UIStackViewAlignmentTrailing;
        NSLog(@"isLeftSideDriving YES");
        [_leftHandDrivingAlarmSpeedometerStackViewConstraint setActive:NO];
        [_rightHandDrivingAlarmSpeedometerStackViewConstraint setActive:YES];
    }
    else
    {
        _alarmSpeedometerStackView.alignment = UIStackViewAlignmentLeading;
        NSLog(@"isLeftSideDriving NO");
        [_leftHandDrivingAlarmSpeedometerStackViewConstraint setActive:YES];
        [_rightHandDrivingAlarmSpeedometerStackViewConstraint setActive:NO];
    }
    
    if (_speedometerView && _speedometerView.superview && !_speedometerView.hidden)
    {
        if (_speedometerView.carPlayConfig.isLeftSideDriving != isLeftSideDriving) {
            _speedometerView.carPlayConfig.isLeftSideDriving = isLeftSideDriving;
            [_speedometerView configure];
        }
    }

    [self updateMapCenterPoint];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [_speedometerView configureUserInterfaceStyleWithStyle:self.traitCollection.userInterfaceStyle];
            NSLog(@"traitCollectionDidChange: %ld", (long)self.traitCollection.userInterfaceStyle);
        });
    }
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
    
    [_alarmSpeedometerStackView addArrangedSubview:_alarmWidget];
    
    [NSLayoutConstraint activateConstraints:@[
        [_alarmWidget.heightAnchor constraintEqualToConstant:60.0],
        [_alarmWidget.widthAnchor constraintEqualToConstant:60.0]
    ]];
}

- (void)setupSpeedometer
{
    _speedometerView = [SpeedometerView initView];
    _speedometerView.carPlayConfig = [CarPlayConfig new];
    __weak __typeof(self) weakSelf = self;
    _speedometerView.didChangeIsVisible = ^{
        [weakSelf.view layoutIfNeeded];
    };
    _speedometerView.translatesAutoresizingMaskIntoConstraints = NO;
    _speedometerView.hidden = YES;
    [_window addSubview:_speedometerView];
    [_speedometerView configure];
    [_speedometerView configureUserInterfaceStyleWithStyle:self.traitCollection.userInterfaceStyle];
    
    [_alarmSpeedometerStackView addArrangedSubview:_speedometerView];
    
    _speedometerHeightConstraint = [_speedometerView.heightAnchor constraintEqualToConstant:[_speedometerView getCurrentSpeedViewMaxHeightWidth]];
    _speedometerHeightConstraint.active = YES;
}

- (void)configureSpeedometer {
    [_speedometerView configure];
    _speedometerHeightConstraint.constant = _speedometerView.intrinsicContentSize.height;
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
    return _alarmSpeedometerStackView.frame.origin.x > self.view.frame.size.width / 2.0;
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
        [_speedometerView updateInfo];
    });
}

@end
