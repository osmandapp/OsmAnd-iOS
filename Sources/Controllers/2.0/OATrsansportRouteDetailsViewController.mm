//
//  OATrsansportRouteDetailsViewController.m
//  OsmAnd
//
//  Created by Paul on 17/12/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATrsansportRouteDetailsViewController.h"
#import "Localization.h"
#import "OARootViewController.h"
#import "OASizes.h"
#import "OAColors.h"
#import "OANativeUtilities.h"
#import "OsmAndApp.h"
#import "OAMapLayers.h"
#import "Localization.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OATransportDetailsTableViewController.h"
#import "OATransportRoutingHelper.h"

#import <OsmAndCore/Utilities.h>

#define kPageControlMargin 4.0

@interface OATrsansportRouteDetailsViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate, OATransportDetailsControllerDelegate>

@end

@implementation OATrsansportRouteDetailsViewController
{
    OsmAndAppInstance _app;
    OATransportRoutingHelper *_transportHelper;
    
    UIPageViewController *_pageController;
    NSArray<OATransportDetailsTableViewController *> *_tableViews;
    NSInteger _currentRoute;
    NSInteger _numberOfRoutes;
}

- (instancetype) initWithRouteIndex:(NSInteger)routeIndex
{
    self = [super init];
    if (self) {
        _currentRoute = routeIndex;
    }
    return self;
}

- (BOOL)hasControlButtons
{
    return NO;
}

- (BOOL)hideButtons
{
    return YES;
}

- (NSAttributedString *)getAttributedTypeStr
{
    return nil;
}

- (NSAttributedString *) getAdditionalInfoStr
{
    return nil;
}

- (NSString *)getTypeStr
{
    return nil;
}

- (void)refreshRouteLayer
{
    OARouteLayer *routeLayer = OARootViewController.instance.mapPanel.mapViewController.mapLayers.routeMapLayer;
    [OARootViewController.instance.mapPanel.mapViewController runWithRenderSync:^{
        [routeLayer resetLayer];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [routeLayer refreshRoute];
    });
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    _transportHelper = OATransportRoutingHelper.sharedInstance;
    _numberOfRoutes = _transportHelper.getRoutes.size();
    
    _pageControlContainer.layer.cornerRadius = 7.;
    _pageControl.currentPage = _currentRoute;
    _pageControl.numberOfPages = _numberOfRoutes;
    CGRect pageControlFrame = _pageControl.frame;
    pageControlFrame.size = [_pageControl sizeForNumberOfPages:_numberOfRoutes];
    pageControlFrame.origin.y = _pageControlContainer.frame.size.height / 2 - pageControlFrame.size.height / 2;
    _pageControl.frame = pageControlFrame;
    
    CGRect pageControlContainerFrame = _pageControlContainer.frame;
    pageControlContainerFrame.size.width = _pageControl.frame.size.width + kPageControlMargin * 2;
    _pageControlContainer.frame = pageControlContainerFrame;
    
    [self setupPageController];
    
    NSMutableArray<OATransportDetailsTableViewController *> *viewControllers = [NSMutableArray new];
    for (NSInteger i = 0; i < _numberOfRoutes; i++)
    {
        OATransportDetailsTableViewController *tableController = [[OATransportDetailsTableViewController alloc] initWithRouteIndex:i];
        tableController.delegate = self;
        tableController.view.frame = _pageController.view.frame;
        tableController.view.tag = i;
        [viewControllers addObject:tableController];
    }
    _tableViews = [NSArray arrayWithArray:viewControllers];
    
    if (!self.isLandscape)
    {
        [OAUtilities setMaskTo:_pageController.view byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
        [OAUtilities setMaskTo:self.contentView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
    }
    
    [self refreshRouteLayer];
}

- (void)setupPageController
{
    _pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal options:nil];
    _pageController.dataSource = self;
    _pageController.delegate = self;
    CGRect frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
    _pageController.view.frame = frame;
    [self.parentViewController addChildViewController:_pageController];
    [self.contentView addSubview:_pageController.view];
    [_pageController didMoveToParentViewController:self.parentViewController];
}

- (CGFloat) additionalContentOffset
{
    return [self isLandscape] ? 0. : ((OATransportDetailsTableViewController *)_tableViews[_currentRoute]).getMinimizedContentHeight + OAUtilities.getBottomMargin;
}

- (BOOL) needsLayoutOnModeChange
{
    return NO;
}

- (BOOL)supportMapInteraction
{
    return YES;
}

- (BOOL)supportFullScreen
{
    return YES;
}

- (BOOL)supportFullMenu
{
    return YES;
}

- (BOOL) hasTopToolbar
{
    return YES;
}

- (BOOL) shouldShowToolbar
{
    return YES;
}

- (BOOL)hasContent
{
    return YES;
}

- (BOOL)needsAdditionalBottomMargin
{
    return NO;
}

- (BOOL)showTopControls
{
    return NO;
}

- (BOOL)supportsForceClose
{
    return YES;
}

- (void)cancelPressed
{
    [[OARootViewController instance].mapPanel showRouteInfo];
}

- (void)backPressed
{
    [[OARootViewController instance].mapPanel showRouteInfo];
}

- (ETopToolbarType) topToolbarType
{
    return ETopToolbarTypeFloatingFixedButton;
}

- (void) applyLocalization
{
    _navBarTitleView.text = OALocalizedString(@"gpx_route");
}

- (void)onMenuShown
{
    CGRect pageFrame = _pageController.view.frame;
    pageFrame.origin.x = OAUtilities.getLeftMargin;
    pageFrame.size.width = self.contentView.frame.size.width - pageFrame.origin.x;
    _pageController.view.frame = pageFrame;
    
    [_pageController setViewControllers:@[_tableViews[_currentRoute]] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self.delegate contentChanged];
}

- (CGFloat)contentHeight
{
    return _tableViews[_currentRoute].tableView.contentSize.height;
}

- (void)goFullScreen
{
    _pageController.view.layer.mask = nil;
    self.contentView.layer.mask = nil;
    self.additionalAccessoryView.hidden = YES;
}

- (void)restoreFromFullScreen
{
    if (!self.isLandscape)
    {
        [OAUtilities setMaskTo:_pageController.view byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
        [OAUtilities setMaskTo:self.contentView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
    }
    self.additionalAccessoryView.hidden = NO;
}

- (void) goFull
{
    [self restoreFromFullScreen];
}

- (void)goHeaderOnly
{
    [self restoreFromFullScreen];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        if (self.delegate)
            [self.delegate contentChanged];
        
        CGRect pageFrame = _pageController.view.frame;
        pageFrame.origin.x = OAUtilities.getLeftMargin;
        pageFrame.size.width = self.contentView.frame.size.width - pageFrame.origin.x;
        _pageController.view.frame = pageFrame;
        
        if (!self.isLandscape)
        {
            [OAUtilities setMaskTo:_pageController.view byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
            [OAUtilities setMaskTo:self.contentView byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight];
        }
        else
        {
            _pageController.view.layer.mask = nil;
            self.contentView.layer.mask = nil;
        }
    } completion:nil];
}

#pragma mark - UIPageViewControllerDataSource

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSInteger prevIndex = _currentRoute == 0 ? _numberOfRoutes - 1 : (_currentRoute - 1);
    return _numberOfRoutes > 1 ? _tableViews[prevIndex] : nil;
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger nextIndex = (_currentRoute + 1) % _numberOfRoutes;
    return _numberOfRoutes > 1 ? _tableViews[nextIndex] : nil;
}

#pragma mark - UIPageViewControllerDelegate

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (!completed)
        return;
    _currentRoute = pageViewController.viewControllers.firstObject.view.tag;
    _pageControl.currentPage = _currentRoute;
    [_transportHelper setCurrentRoute:_currentRoute];
    [self refreshRouteLayer];
}

#pragma mark - OATransportDetailsControllerDelegate

- (void)onContentHeightChanged
{
    [self.delegate contentHeightChanged:[self contentHeight]];
}

- (void) onDetailsRequested
{
    [self.delegate requestFullScreenMode];
}

- (void) onStartPressed
{
    [[OARootViewController instance].mapPanel targetHide];
}

- (void) showSegmentOnMap:(NSArray<CLLocation *> *)locations
{
    if (!locations || locations.count == 0)
    {
        return;
    }
    else if (locations.count == 1)
    {
        CLLocationCoordinate2D point = locations.firstObject.coordinate;
        [[OARootViewController instance].mapPanel displayCalculatedRouteOnMap:point bottomRight:point];
    }
    else
    {
        double left = DBL_MAX;
        double top = DBL_MAX;
        double right = DBL_MAX;
        double bottom = DBL_MAX;
        
        for (CLLocation* loc : locations)
        {
            if (left == DBL_MAX)
            {
                left = loc.coordinate.longitude;
                right = loc.coordinate.longitude;
                top = loc.coordinate.latitude;
                bottom = loc.coordinate.latitude;
            }
            else
            {
                left = MIN(left, loc.coordinate.longitude);
                right = MAX(right, loc.coordinate.longitude);
                top = MAX(top, loc.coordinate.latitude);
                bottom = MIN(bottom, loc.coordinate.latitude);
            }
        }
        OABBox result;
        result.bottom = bottom;
        result.top = top;
        result.left = left;
        result.right = right;
        
        [[OARootViewController instance].mapPanel displayCalculatedRouteOnMap:CLLocationCoordinate2DMake(result.top, result.left) bottomRight:CLLocationCoordinate2DMake(result.bottom, result.right)];
    }
    [self.delegate requestHeaderOnlyMode];
}

@end
