//
//  OARootViewController.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/20/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OARootViewController.h"

#import <QuartzCore/QuartzCore.h>

#import <JASidePanelController.h>
#import <UIAlertView+Blocks.h>

#import "OAAppDelegate.h"
#import "OAMenuOriginViewControllerProtocol.h"
#import "OAMenuViewControllerProtocol.h"
#import "OAFavoriteImportViewController.h"
#import "OANavigationController.h"
#import "OAOptionsPanelBlackViewController.h"

#include "Localization.h"

#define _(name) OARootViewController__##name
#define commonInit _(commonInit)
#define deinit _(deinit)

@interface OARootViewController () <UIPopoverControllerDelegate>
@end

@implementation OARootViewController
{
    CALayer* __weak _customCenterBorderLayer;

    UIViewController* __weak _lastMenuOriginViewController;
    UIPopoverController* _lastMenuPopoverController;
    UIViewController* __weak _lastMenuViewController;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {  
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    // Create panels:
    
    [self setLeftPanel:[[OAOptionsPanelBlackViewController alloc] initWithNibName:@"OptionsPanel" bundle:nil]];

    [self setCenterPanel:[[OAMapPanelViewController alloc] init]];

    [self setRightPanel:[[OAActionsPanelViewController alloc] init]];
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // 80% of smallest device width in portait mode (320 points)
    self.leftFixedWidth = 256;
    self.rightFixedWidth = 256;
    self.shouldResizeLeftPanel = NO;
    self.shouldResizeRightPanel = YES;
    
    // Initially disallow pan gesture to exclude interference with map
    // (it should be enabled after side panel is shown until it's not hidden)
    self.recognizesPanGesture = NO;
    self.panningLimitedToTopViewController = NO;
    
    // Allow rotation, without respect to current active panel
    self.shouldDelegateAutorotateToVisiblePanel = NO;
    
    self.navigationController.navigationBarHidden = YES;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:YES
                                             animated:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:YES
                                             animated:animated];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (self.isMenuOpened)
        return _lastMenuViewController.preferredStatusBarStyle;

    if (self.state == JASidePanelLeftVisible)
        return self.leftPanel.preferredStatusBarStyle;
    else if (self.state == JASidePanelRightVisible)
        return self.rightPanel.preferredStatusBarStyle;

    return self.centerPanel.preferredStatusBarStyle;
}

- (void)styleContainer:(UIView *)container animate:(BOOL)animate duration:(NSTimeInterval)duration
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7.0)
    {
        // For iOS 7.0+ disable casting shadow. Instead use border for left and right panels
        container.clipsToBounds = NO;

        if (container == self.centerPanelContainer)
        {
            if (_customCenterBorderLayer == nil)
            {
                CALayer* borderLayer = [CALayer layer];
                borderLayer.borderColor = [UIColor darkGrayColor].CGColor;
                borderLayer.borderWidth = 1.0f;
                [container.layer addSublayer:borderLayer];
                _customCenterBorderLayer = borderLayer;
            }

            // Update frame
            _customCenterBorderLayer.frame = CGRectMake(-1.0f,
                                                        -1.0f,
                                                        CGRectGetWidth(container.frame) + 2.0f,
                                                        CGRectGetHeight(container.frame) + 2.0f);
        }
    }
    else
    {
        // For previous version keep default behavior
        [super styleContainer:container animate:animate duration:duration];
    }

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)stylePanel:(UIView *)panel
{
    [super stylePanel:panel];
    
    // Setting corner radius on EGL layer will drop (or better to say, cap) framerate to 40 fps
    panel.layer.cornerRadius = 0.0f;
}


- (OAMapPanelViewController*)mapPanel
{
    return (OAMapPanelViewController*)self.centerPanel;
}

- (OAActionsPanelViewController*)actionsPanel
{
    return (OAActionsPanelViewController*)self.rightPanel;
}

- (void)openMenu:(UIViewController*)menuViewController
        fromRect:(CGRect)originRect
          inView:(UIView*)originView
        ofParent:(UIViewController*)parentViewController
        animated:(BOOL)animated
{
    // Save reference to origin
    if ([menuViewController conformsToProtocol:@protocol(OAMenuViewControllerProtocol)])
        ((id<OAMenuViewControllerProtocol>)menuViewController).menuOriginViewController = parentViewController;
    _lastMenuOriginViewController = parentViewController;
    _lastMenuViewController = menuViewController;

    // Open menu actually
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        // For iPhone and iPod, push menu to navigation controller
        [self.navigationController pushViewController:menuViewController
                                             animated:animated];
    }
    else //if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        // For iPad, open menu in a popover with it's own navigation controller
        UINavigationController* popoverNavigationController = [[OANavigationController alloc] initWithRootViewController:menuViewController];
        _lastMenuPopoverController = [[UIPopoverController alloc] initWithContentViewController:popoverNavigationController];
        _lastMenuPopoverController.delegate = self;

        [_lastMenuPopoverController presentPopoverFromRect:originRect
                                                    inView:originView
                                  permittedArrowDirections:UIPopoverArrowDirectionAny
                                                  animated:animated];
    }

    [self setNeedsStatusBarAppearanceUpdate];
}

- (void)closeMenuAnimated:(BOOL)animated
{
    if (!self.isMenuOpened)
        return;

    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
    {
        if ([self.navigationController.viewControllers containsObject:_lastMenuOriginViewController])
        {
            [self.navigationController popToViewController:_lastMenuOriginViewController
                                                  animated:animated];
        }
        else
        {
            NSArray* viewControllers = self.navigationController.viewControllers;
            NSUInteger menuIndex = [viewControllers indexOfObject:_lastMenuViewController];
            if (menuIndex == 0)
                [self.navigationController popToRootViewControllerAnimated:animated];
            else
            {
                [self.navigationController popToViewController:[viewControllers objectAtIndex:menuIndex-1]
                                                      animated:animated];
            }
        }

        if ([_lastMenuOriginViewController conformsToProtocol:@protocol(OAMenuOriginViewControllerProtocol)])
        {
            id<OAMenuOriginViewControllerProtocol> origin = (id<OAMenuOriginViewControllerProtocol>)_lastMenuOriginViewController;
            [origin notifyMenuClosed];
        }
    }
    else //if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
    {
        if (_lastMenuPopoverController != nil)
            [_lastMenuPopoverController dismissPopoverAnimated:animated];
        [self popoverControllerDidDismissPopover:_lastMenuPopoverController];
    }

    _lastMenuOriginViewController = nil;
    _lastMenuViewController = nil;

    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)isMenuOpened
{
    if (_lastMenuViewController == nil)
        return NO;

    // For iPhone/iPod devices check that mentioned view controller is still
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone)
        return [self.navigationController.viewControllers containsObject:_lastMenuViewController];

    return YES;
}

- (void)closeMenuAndPanelsAnimated:(BOOL)animated
{
    // This fixes issue with stuck toolbar
    self.navigationController.toolbarHidden = YES;

    // Close all menus and panels
    [self closeMenuAnimated:animated];
    if (self.state == JASidePanelLeftVisible)
        [self toggleLeftPanel:self];
    else if (self.state == JASidePanelRightVisible)
        [self toggleRightPanel:self];
}

- (BOOL)handleIncomingURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    UIViewController* incomingURLViewController = [[OAFavoriteImportViewController alloc] initFor:url];
    if (incomingURLViewController == nil)
        return NO;

    [self closeMenuAndPanelsAnimated:NO];

    // Open incoming-URL view controller as menu
    [self openMenu:incomingURLViewController
          fromRect:CGRectZero
            inView:self.view
          ofParent:self
          animated:YES];

    return YES;
}

- (void)showNoInternetAlert
{
    [self showNoInternetAlertFor:nil];
}

- (void)showNoInternetAlertFor:(NSString*)actionTitle
{
    [[[UIAlertView alloc] initWithTitle:actionTitle
                                message:OALocalizedString(@"Internet connection required to perform this action. Please check your Internet connection.")
                       cancelButtonItem:[RIButtonItem itemWithLabel:OALocalizedString(@"Oh, OK then")]
                       otherButtonItems:nil] show];
}

#pragma mark - UIPopoverControllerDelegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if (_lastMenuPopoverController == popoverController)
    {
        if ([_lastMenuOriginViewController conformsToProtocol:@protocol(OAMenuOriginViewControllerProtocol)])
        {
            id<OAMenuOriginViewControllerProtocol> origin = (id<OAMenuOriginViewControllerProtocol>)_lastMenuOriginViewController;
            [origin notifyMenuClosed];
        }

        _lastMenuOriginViewController = nil;
        _lastMenuPopoverController = nil;
    }
}

#pragma mark -

+ (OARootViewController*)instance
{
    OAAppDelegate* appDelegate = [[UIApplication sharedApplication] delegate];
    return appDelegate.rootViewController;
}

@end
