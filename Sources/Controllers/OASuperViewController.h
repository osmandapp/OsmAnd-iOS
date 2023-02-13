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

- (CGFloat)getNavbarEstimatedHeight;
- (void)updateNavbarEstimatedHeight;
- (void)resetNavbarEstimatedHeight;
- (void)adjustScrollStartPosition;
- (void)applyLocalization;
- (BOOL)isModal;
- (BOOL)isScreenLoaded;

- (void)onContentSizeChanged:(NSNotification *)notification;
- (IBAction)onLeftNavbarButtonPressed:(UIButton *)sender;

- (void)dismissViewController;
- (void)showViewController:(UIViewController *)viewController;

@end
