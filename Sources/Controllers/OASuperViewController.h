//
//  OASuperViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OAAutoObserverProxy;

@interface OASuperViewController : UIViewController

- (void)registerNotifications;
- (void)addNotification:(NSNotificationName)name selector:(SEL)selector;
- (void)registerObservers;
- (OAAutoObserverProxy *)addObserver:(OAAutoObserverProxy *)observer;

- (void)applyLocalization;
- (void)addAccessibilityLabels;
- (BOOL)isModal;
- (BOOL)isScreenLoaded;
- (CGFloat)getNavbarHeight;

- (void)onLeftNavbarButtonPressed;
- (void)onContentSizeChanged:(NSNotification *)notification;

- (void)dismissViewControllerWithAnimated:(BOOL)flag completion:(void (^ __nullable)(void))completion;
- (void)dismissViewController;
- (void)showViewController:(UIViewController *)viewController;
- (void)showModalViewController:(UIViewController *)viewController;
- (void)showMediumSheetViewController:(UIViewController *)viewController isLargeAvailable:(BOOL)isLargeAvailable;

@end
