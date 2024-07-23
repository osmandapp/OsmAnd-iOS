//
//  OASuperViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class OAAutoObserverProxy;

@interface OASuperViewController : UIViewController

- (void)registerNotifications;
- (void)addNotification:(nullable NSNotificationName)name selector:(SEL)selector;
- (void)registerObservers;
- (OAAutoObserverProxy *)addObserver:(OAAutoObserverProxy *)observer;

- (void)applyLocalization;
- (void)addAccessibilityLabels;
- (BOOL)isModal;
- (BOOL)isScreenLoaded;
- (CGFloat)getNavbarHeight;

- (void)onLeftNavbarButtonPressed;
- (void)onContentSizeChanged:(NSNotification *)notification;

- (void)dismissViewControllerWithAnimated:(BOOL)flag completion:(nullable void (^)(void))completion;
- (void)dismissViewController;
- (void)showViewController:(UIViewController *)viewController;
- (void)showModalViewController:(UIViewController *)viewController;
- (void)showMediumSheetViewController:(UIViewController *)viewController isLargeAvailable:(BOOL)isLargeAvailable;

@end

NS_ASSUME_NONNULL_END
