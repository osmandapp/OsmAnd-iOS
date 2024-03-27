//
//  OAAppDelegate.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OARootViewController.h"

typedef NS_ENUM(NSInteger, AppLaunchEvent) {
    AppLaunchEventNone,
    AppLaunchEventStart,
    AppLaunchEventFirstLaunch,
    AppLaunchEventRestoreSession,
    AppLaunchEventSetupRoot
};

FOUNDATION_EXPORT NSNotificationName _Nonnull const OALaunchUpdateStateNotification;

@interface OAAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic, nullable) OARootViewController *rootViewController;
@property (nonatomic, assign) AppLaunchEvent appLaunchEvent;
@property (nonatomic, assign) UIInterfaceOrientation interfaceOrientation;

- (BOOL)initialize;
- (BOOL)isAppInitializing;

- (void)scheduleBackgroundDataFetch;

- (void)applicationDidBecomeActive;
- (void)applicationWillEnterForeground;
- (void)applicationDidEnterBackground;
- (void)applicationWillResignActive;

@end
