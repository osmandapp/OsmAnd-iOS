//
//  OASuperViewController.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    // for content size category
    [self addNotification:UIContentSizeCategoryDidChangeNotification selector:@selector(onContentSizeChanged:)];
    // for other
    [self registerNotifications];
    [self registerObservers];

    if (_contentSizeCategory)
    {
        // check if dynamic type size has changed
        UIContentSizeCategory contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
        if (![contentSizeCategory isEqualToString:_contentSizeCategory])
        {
            // needs to update navbar height after returning from next screen
            [self resetNavbarEstimatedHeight];
            [self.view setNeedsDisplay];
        }
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    if (!_isScreenLoaded || [self getNavbarEstimatedHeight] == 0)
    {
        [self updateNavbarEstimatedHeight];
        _isScreenLoaded = YES;
        _contentSizeCategory = [UIApplication sharedApplication].preferredContentSizeCategory;
        [self adjustScrollStartPosition];
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

- (CGFloat)getNavbarEstimatedHeight
{
    return [self isModal] ? [OAUtilities isLandscape] ? defaultNavBarHeight : modalNavBarHeight : defaultNavBarHeight;;
}

- (void)updateNavbarEstimatedHeight
{
}

- (void)resetNavbarEstimatedHeight
{
}

- (void)adjustScrollStartPosition
{
}

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

#pragma mark - Selectors

// after resizing dynamic type for navbar and UI components with adjustsFontForContentSizeCategory = NO
// override with super to work correctly
- (void)onContentSizeChanged:(NSNotification *)notification
{
    // needs to update navbar height
    [self resetNavbarEstimatedHeight];
}

- (IBAction)onLeftNavbarButtonPressed:(UIButton *)sender
{
    [self dismissViewController];
}

#pragma mark - Actions

- (void)dismissViewController
{
    if ([self isModal])
        [self dismissViewControllerAnimated:YES completion:nil];
    else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)showViewController:(UIViewController *)viewController
{
    if ([self isModal])
        [self presentViewController:viewController animated:YES completion:nil];
    else
        [self.navigationController pushViewController:viewController animated:YES];
}

@end
