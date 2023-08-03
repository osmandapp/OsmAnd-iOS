//
//  OAAppDelegate.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, InitStep) {
    InitStepStart,
    InitStepRestoreSession,
    InitStepSetupRoot,
    InitStepFirstLaunch
};

typedef void (^_Nullable InitStepHandler)(InitStep step);

@interface OAAppDelegate : UIResponder <UIApplicationDelegate>
@property (strong, nonatomic, nullable) UIWindow *savedWindow;

- (BOOL)initialize:(InitStepHandler)stepHandler;

- (void)scheduleBackgroundDataFetch;

- (void)applicationDidBecomeActive;
- (void)applicationWillEnterForeground;
- (void)applicationDidEnterBackground;
- (void)applicationWillResignActive;

@end
