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
#import "Localization.h"
#import "OAMapRendererView.h"
#import "OAMapViewController.h"
#import "OATransportDetailsTableViewController.h"

#import <OsmAndCore/Utilities.h>

#define kPageControlMargin 4.0

@interface OATrsansportRouteDetailsViewController () <UIPageViewControllerDataSource, UIPageViewControllerDelegate>

@end

@implementation OATrsansportRouteDetailsViewController
{
    OsmAndAppInstance _app;
    
    UIPageViewController *_pageController;
    NSArray<OATransportDetailsTableViewController *> *_tableViews;
    NSInteger _currentRoute;
}

- (BOOL)hasControlButtons
{
    return NO;
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _currentRoute = 0;
    
    _pageControlContainer.layer.cornerRadius = 6.;
    _pageControl.currentPage = 0/*route index*/;
    _pageControl.numberOfPages = 5;
    CGRect pageControlFrame = _pageControl.frame;
    pageControlFrame.size = [_pageControl sizeForNumberOfPages:5];
    _pageControl.frame = pageControlFrame;
    
    CGRect pageControlContainerFrame = _pageControlContainer.frame;
    pageControlContainerFrame.size.width = _pageControl.frame.size.width + kPageControlMargin * 2;
    _pageControlContainer.frame = pageControlContainerFrame;
    
    _currentRoute = 0;
    
    [self setupPageController];
    
    NSMutableArray<OATransportDetailsTableViewController *> *viewControllers = [NSMutableArray new];
    for (NSInteger i = 0; i < 5; i++)
    {
        OATransportDetailsTableViewController *tableController = [[OATransportDetailsTableViewController alloc] init];
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
    NSInteger prevIndex = _currentRoute == 0 ? 4 : (_currentRoute - 1);
    return _tableViews[prevIndex];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    NSInteger nextIndex = (_currentRoute + 1) % 5;
    return _tableViews[nextIndex];
}

#pragma mark - UIPageViewControllerDelegate

-(void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
    if (!completed)
        return;
    _currentRoute = pageViewController.viewControllers.firstObject.view.tag;
    _pageControl.currentPage = _currentRoute;
}

@end
