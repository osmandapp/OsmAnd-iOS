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
    NSLayoutConstraint *_speedometerHeightConstraint;
    NSLayoutConstraint *_alarmSpeedometerStackViewLeftConstraint;
    NSLayoutConstraint *_alarmSpeedometerStackViewRightConstraint;
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
    
    [self setupAlarmSpeedometerStackView];
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
        [_speedometerView contentAlignmentWithIsRight:YES];
        
        _alarmSpeedometerStackViewRightConstraint.active = YES;
        _alarmSpeedometerStackViewLeftConstraint.active = NO;
    }
    else
    {
        [_speedometerView contentAlignmentWithIsRight:NO];
        
        _alarmSpeedometerStackViewLeftConstraint.active = YES;
        _alarmSpeedometerStackViewRightConstraint.active = NO;
    }
    
    if (_speedometerView && _speedometerView.superview)
    {
        if (_speedometerView.carPlayConfig.isLeftSideDriving != isLeftSideDriving) {
            _speedometerView.carPlayConfig.isLeftSideDriving = isLeftSideDriving;
            [_speedometerView configure];
        }
        [self updateSpeedometerViewStyleTheme];
    }

    [self updateMapCenterPoint];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection])
    {
        if (_speedometerView)
            [self updateSpeedometerViewStyleTheme];
       
        if (self.delegate)
            [self.delegate onUpdateMapTemplateStyle];
    }
}

- (void)updateSpeedometerViewStyleTheme
{
    [_speedometerView configureUserInterfaceStyleWithStyle:self.traitCollection.userInterfaceStyle];
}

- (void)updateMapCenterPoint
{
    if (UIApplication.sharedApplication.isCarPlayDashboardActive)
        return;
    
    UIEdgeInsets insets = self.view.safeAreaInsets;
    CGFloat heightOffset = [self heightOffsetForInsets:insets];

    BOOL isLeftSideDriving = [self isLeftSideDriving];
    
    BOOL isRoutePlanning = [OARoutingHelper sharedInstance].isRoutePlanningMode;
    EOAPositionPlacement placement = (EOAPositionPlacement) [[OAAppSettings sharedManager].positionPlacementOnMap get];
    double y;
    if (placement == EOAPositionPlacementAuto)
        y = ([[OAAppSettings sharedManager].rotateMap get] == ROTATE_MAP_BEARING && !isRoutePlanning ? [self mapCenterBottomYWithInsets:insets] : 1.0 + heightOffset);
    else
        y = (placement == EOAPositionPlacementCenter || isRoutePlanning ? 1.0 + heightOffset : [self mapCenterBottomYWithInsets:insets]);
    
    if (_isInNavigationMode)
    {
        [_mapVc setViewportForCarPlayScaleX:isLeftSideDriving ? 1.5 : 0.5 y:y];
    }
    else
    {
        CGFloat w = MAX(self.view.frame.size.width, 1.0);
        CGFloat widthOffset = MAX(insets.right, insets.left) / w;
        
        [_mapVc setViewportForCarPlayScaleX:isLeftSideDriving ? 1.0 + widthOffset : 1.0 - widthOffset y:y];
    }
}

- (CGFloat)heightOffsetForInsets:(UIEdgeInsets)insets
{
    CGFloat viewHeight = [self viewHeightSafe];
    return (insets.top - insets.bottom) / viewHeight;
}

- (CGFloat)viewHeightSafe
{
    return MAX(self.view.frame.size.height, 1.0);
}

- (CGFloat)mapCenterBottomYWithInsets:(UIEdgeInsets)insets
{
    CGFloat viewHeight = [self viewHeightSafe];
    
    CGFloat bottomMargin = 60.0;
    CGFloat totalBottomOffset = bottomMargin + (insets.bottom / 3.0);
    CGFloat y = 2.0 - (totalBottomOffset / (viewHeight / 2.0));

    CGFloat heightOffset = (insets.top - insets.bottom) / viewHeight;
    y += heightOffset;

    return y;
}

- (void)setupAlarmSpeedometerStackView
{
    _alarmSpeedometerStackView = [UIStackView new];
    _alarmSpeedometerStackView.translatesAutoresizingMaskIntoConstraints = NO;
    _alarmSpeedometerStackView.axis = UILayoutConstraintAxisVertical;
    _alarmSpeedometerStackView.distribution = UIStackViewDistributionEqualSpacing;
    _alarmSpeedometerStackView.spacing = 5;
    _alarmSpeedometerStackView.alignment = UIStackViewAlignmentFill;
    [_window addSubview:_alarmSpeedometerStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [_alarmSpeedometerStackView.topAnchor constraintEqualToAnchor:_window.mapButtonSafeAreaLayoutGuide.topAnchor constant:8],
    ]];
    CGFloat outsideShadowOffset = 1.0;
    _alarmSpeedometerStackViewLeftConstraint = [_alarmSpeedometerStackView.leftAnchor constraintEqualToAnchor:_window.mapButtonSafeAreaLayoutGuide.leftAnchor constant:outsideShadowOffset];
    _alarmSpeedometerStackViewLeftConstraint.active = YES;
    
    _alarmSpeedometerStackViewRightConstraint = [_alarmSpeedometerStackView.rightAnchor constraintEqualToAnchor:_window.mapButtonSafeAreaLayoutGuide.rightAnchor constant:-outsideShadowOffset];
    _alarmSpeedometerStackViewRightConstraint.active = YES;
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
    [_speedometerView configure];
    
    [_alarmSpeedometerStackView addArrangedSubview:_speedometerView];
        
    _speedometerHeightConstraint = [_speedometerView.heightAnchor constraintEqualToConstant:[_speedometerView getCurrentSpeedViewMaxHeightWidth] + 2];
    _speedometerHeightConstraint.active = YES;
}

- (void)configureSpeedometer {
    [_speedometerView configure];
    [UIView animateWithDuration:0 delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
        _speedometerHeightConstraint.constant = _speedometerView.intrinsicContentSize.height;
    } completion:^(BOOL finished) {
        [self updateSpeedometerViewStyleTheme];
    }];
}

- (void) attachMapToWindow
{
    if (_window && _mapVc)
    {
        [_mapVc.mapView suspendRendering];
        [_mapVc removeFromParentViewController];
        [_mapVc.view removeFromSuperview];
        
        [_mapVc.mapView setTopOffsetOfViewSize:0 bottomOffset:0];
        [self addChildViewController:_mapVc];
        [self.view addSubview:_mapVc.view];
        _mapVc.view.frame = self.view.frame;
        _mapVc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        [_mapVc.mapView setMSAAEnabled:[[OAAppSettings sharedManager].enableMsaaForСarPlay get]];
        [_mapVc.mapView resumeRendering];
        [_mapVc.mapView limitFrameRefreshRate];
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
        if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateBackground)
            [_mapVc.mapView resumeRendering];
        [mapPanel.hudViewController.mapInfoController updateLayout];
        OAAppSettings * settings = [OAAppSettings sharedManager];
        if (![settings.batterySavingMode get])
            [_mapVc.mapView restoreFrameRefreshRate];

        [_mapVc setViewportScaleX:kViewportScale];
        [_mapVc.mapView setMSAAEnabled:NO];
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
                                                    screenBBox:screenBBox
                                                   bottomInset:0.
                                                     leftInset:0.
                                                      topInset:0.
                                          changeElevationAngle:YES];
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
    if (_isInNavigationMode)
    {
        if (_cachedViewportX != 0)
            [_mapVc setViewportForCarPlayScaleX:_cachedViewportX];
        
        _isInNavigationMode = NO;
    }
}

- (void)onLocationChanged
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [_alarmWidget updateInfo];
        [_speedometerView updateInfo];
    });
}

@end
