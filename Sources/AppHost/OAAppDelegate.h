//
//  OAAppDelegate.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, AppLaunchEvent) {
    AppLaunchEventNone,
    AppLaunchEventStart,
    AppLaunchEventFirstLaunch,
    AppLaunchEventRestoreSession,
    AppLaunchEventSetupRoot
};

FOUNDATION_EXPORT NSNotificationName const OALaunchUpdateStateNotification;

@class OARootViewController;

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

NS_ASSUME_NONNULL_END
