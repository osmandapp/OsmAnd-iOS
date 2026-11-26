//
//  OASuperViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OABaseNavbarViewController.h"
#import "OAAutoObserverProxy.h"
#import "OASizes.h"
#import "GeneratedAssetSymbols.h"

@implementation OASuperViewController
{
    BOOL _isScreenLoaded;
    UIView *_navbarTopBackgroundView;
    UIContentSizeCategory _contentSizeCategory;
    NSMutableArray<OAAutoObserverProxy *> *_observers;
}

#pragma mark - Initialization

// use addNotification:selector: method here
// notifications will be automatically added in viewDidLoad: and removed in dealloc
- (void)registerNotifications
{
}

// use addObserver: method here
// observers will be automatically added in viewDidLoad: and removed in dealloc
- (void)registerObservers
{
}

// do not override
- (void)addNotification:(NSNotificationName)name selector:(SEL)selector
{
    [NSNotificationCenter.defaultCenter addObserver:self selector:selector name:name object:nil];
}

// do not override
- (OAAutoObserverProxy *)addObserver:(OAAutoObserverProxy *)observer
{
    [_observers addObject:observer];
    return observer;
}

- (void)registerNotificationsAndObservers
{
    // for content size category
    [self addNotification:UIContentSizeCategoryDidChangeNotification selector:@selector(onContentSizeChanged:)];
    // for other
    [self registerNotifications];

    [self registerObservers];
}

- (void)unregisterNotificationsAndObservers
{
    [NSNotificationCenter.defaultCenter removeObserver:self];

    for (OAAutoObserverProxy *observer in _observers)
        [observer detach];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self applyLocalization];
    [self addAccessibilityLabels];

    _observers = [NSMutableArray array];

    [self registerNotificationsAndObservers];
}

- (void) dealloc
{
    [self unregisterNotificationsAndObservers];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self updateNavbarTopBackground];

    if (!_isScreenLoaded)
    {
        _isScreenLoaded = YES;
        _contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
    }
}

- (void)updateNavbarTopBackground
{
    UINavigationBar *navbar = self.navigationController.navigationBar;
    UIView *container = self.navigationController.view;
    CGRect navbarFrame = [navbar convertRect:navbar.bounds toView:container];
    UIEdgeInsets safeInsets = container.window.safeAreaInsets;
    CGFloat topInset = safeInsets.top;
    CGFloat gap = MAX(0., CGRectGetMinY(navbarFrame) - topInset);
    UIColor *backgroundColor = navbar.scrollEdgeAppearance.backgroundColor ?: navbar.standardAppearance.backgroundColor;
    UIColor *orangeColor = [UIColor colorNamed:ACColorNameNavBarBgColorPrimary];
    BOOL fillGap = safeInsets.left + safeInsets.right > 0. && topInset == 0. && gap > 0.
        && [[backgroundColor resolvedColorWithTraitCollection:self.traitCollection] isEqual:[orangeColor resolvedColorWithTraitCollection:self.traitCollection]] && !navbar.hidden
        && self.navigationController.topViewController == self;
    if (fillGap)
    {
        if (!_navbarTopBackgroundView)
        {
            _navbarTopBackgroundView = [[UIView alloc] init];
            _navbarTopBackgroundView.userInteractionEnabled = NO;
        }
        if (_navbarTopBackgroundView.superview != container)
            [container addSubview:_navbarTopBackgroundView];
        _navbarTopBackgroundView.backgroundColor = backgroundColor;
        _navbarTopBackgroundView.frame = CGRectMake(0., topInset, container.bounds.size.width, gap);
    }
    else
    {
        [_navbarTopBackgroundView removeFromSuperview];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self updateNavbarTopBackground];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_navbarTopBackgroundView removeFromSuperview];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - Base setup UI

- (void)applyLocalization
{
    // override point
}

- (void)addAccessibilityLabels
{
    // override point
}

- (BOOL)isModal
{
    if ([self presentingViewController])
        return YES;
    if ([[[self navigationController] presentingViewController] presentedViewController] == [self navigationController])
        return YES;
    if ([[[self tabBarController] presentingViewController] isKindOfClass:[UITabBarController class]])
        return YES;

   return NO;
}

- (BOOL)isScreenLoaded
{
    return _isScreenLoaded;
}

- (CGFloat)getNavbarHeight
{
    return [OAUtilities getTopMargin] + ([self isModal] && ![OAUtilities isLandscape] ? modalNavBarHeight : defaultNavBarHeight);
}

#pragma mark - IBAction

- (IBAction)onLeftNavbarButtonPressed:(UIButton *)sender
{
    [self onLeftNavbarButtonPressed];
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    [self dismissViewController];
}

// after resizing dynamic type for navbar and UI components with adjustsFontForContentSizeCategory = NO
- (void)onContentSizeChanged:(NSNotification *)notification
{
}

#pragma mark - Actions

- (void)dismissViewControllerWithAnimated:(BOOL)flag completion:(void (^ __nullable)(void))completion
{
    if ([self isModal] && self.navigationController.viewControllers.count == 1)
        [self dismissViewControllerAnimated:flag completion:completion];
    else
        [self.navigationController popViewControllerAnimated:flag];
}

- (void)dismissViewController
{
    [self dismissViewControllerWithAnimated:YES completion:nil];
}

- (void)showViewController:(UIViewController *)viewController
{
    if ([self isModal])
        [self showModalViewController:viewController];
    else
        [self.navigationController pushViewController:viewController animated:YES];
}

- (void)showModalViewController:(UIViewController *)viewController
{
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    if (self.navigationController)
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    else
        [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)showMediumSheetViewController:(UIViewController *)viewController isLargeAvailable:(BOOL)isLargeAvailable
{
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    navigationController.modalPresentationStyle = UIModalPresentationPageSheet;
    UISheetPresentationController *sheet = navigationController.sheetPresentationController;
    if (sheet)
    {
        sheet.detents = isLargeAvailable
            ? @[UISheetPresentationControllerDetent.mediumDetent, UISheetPresentationControllerDetent.largeDetent]
            : @[UISheetPresentationControllerDetent.mediumDetent];
        sheet.prefersGrabberVisible = isLargeAvailable;
        sheet.preferredCornerRadius = 20;
    }
    if (self.navigationController)
        [self.navigationController presentViewController:navigationController animated:YES completion:nil];
    else
        [self presentViewController:navigationController animated:YES completion:nil];
}

@end
