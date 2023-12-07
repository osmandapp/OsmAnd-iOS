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

@implementation OASuperViewController
{
    BOOL _isScreenLoaded;
    UIContentSizeCategory _contentSizeCategory;
    NSMutableArray<OAAutoObserverProxy *> *_observers;
}

#pragma mark - Initialization

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];

    for (OAAutoObserverProxy *observer in _observers)
    {
        [observer detach];
    }
}

// use addNotification:selector: method here
// notifications will be automatically added in viewWillAppear: and removed in dealloc
- (void)registerNotifications
{
}

// do not override
- (void)addNotification:(NSNotificationName)name selector:(SEL)selector
{
    [NSNotificationCenter.defaultCenter addObserver:self selector:selector name:name object:nil];
}

// use addObserver: method here
// observers will be automatically added in viewWillAppear: and removed in dealloc
- (void)registerObservers
{
}

// do not override
- (OAAutoObserverProxy *)addObserver:(OAAutoObserverProxy *)observer
{
    [_observers addObject:observer];
    return observer;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self applyLocalization];
    [self addAccessibilityLabels];

    _observers = [NSMutableArray array];

    // for content size category
    [self addNotification:UIContentSizeCategoryDidChangeNotification selector:@selector(onContentSizeChanged:)];
    // for other
    [self registerNotifications];

    [self registerObservers];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    if (!_isScreenLoaded)
    {
        _isScreenLoaded = YES;
        _contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
    }
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

- (void)dismissViewController
{
    if ([self isModal] && self.navigationController.viewControllers.count == 1)
        [self dismissViewControllerAnimated:YES completion:nil];
    else
        [self.navigationController popViewControllerAnimated:YES];
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
