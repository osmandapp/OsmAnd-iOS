//
//  OASuperViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OASuperViewController : UIViewController

- (void)registerNotifications;
- (void)addNotification:(NSNotificationName)name selector:(SEL)selector;

- (CGFloat)getNavbarEstimatedHeight;
- (void)updateNavbarEstimatedHeight;
- (void)resetNavbarEstimatedHeight;
- (void)applyLocalization;
- (BOOL)isModal;

- (void)onContentSizeChanged:(NSNotification *)notification;
- (IBAction)backButtonClicked:(id)sender;

- (void)dismissViewController;
- (void)showViewController:(UIViewController *)viewController;

@end
