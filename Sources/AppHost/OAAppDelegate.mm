//
//  OAAppDelegate.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAAppDelegate.h"
#import "OALog.h"
#import "OAFetchBackgroundDataOperation.h"
#import <BackgroundTasks/BackgroundTasks.h>
#import "OsmAnd_Maps-Swift.h"

#define kFetchDataUpdatesId @"net.osmand.fetchDataUpdates"
#define kCheckUpdatesInterval 3600

@implementation OAAppDelegate {
    NSOperationQueue *_dataFetchQueue;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    if (!_dataFetchQueue)
    {
        // Set the background fetch
        _dataFetchQueue = [[NSOperationQueue alloc] init];
        @try
        {
            NSLog(@"BGTaskScheduler registerForTaskWithIdentifier");
            __weak OAAppDelegate *weakSelf = self;
            [BGTaskScheduler.sharedScheduler registerForTaskWithIdentifier:kFetchDataUpdatesId usingQueue:nil launchHandler:^(__kindof BGTask * _Nonnull task) {
                [weakSelf handleBackgroundDataFetch:(BGProcessingTask *)task];
            }];
        }
        @catch (NSException *e)
        {
            NSLog(@"Failed to schedule background fetch. Reason: %@", e.reason);
        }
    }
    
    return YES;
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{
    completionHandler();
}

- (void)application:(UIApplication *)application willChangeStatusBarFrame:(CGRect)newStatusBarFrame
{
    [OASharedVariables setStatusBarHeight:newStatusBarFrame.size.height];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[OsmAndApp instance] shutdown];
    OAMapViewController *mapVc = OARootViewController.instance.mapPanel.mapViewController;
    [mapVc onApplicationDestroyed];
    // Release OsmAnd core
    OsmAnd::ReleaseCore();
    
    // Deconfigure device
    UIDevice* device = [UIDevice currentDevice];
    device.batteryMonitoringEnabled = NO;
    [device endGeneratingDeviceOrientationNotifications];
}

- (void)handleBackgroundDataFetch:(BGProcessingTask *)task
{
    [self scheduleBackgroundDataFetch];
    
    OAFetchBackgroundDataOperation *operation = [[OAFetchBackgroundDataOperation alloc] init];
    [task setExpirationHandler:^{
        [operation cancel];
    }];
    __weak OAFetchBackgroundDataOperation *weakOperation = operation;
    [operation setCompletionBlock:^{
        [task setTaskCompletedWithSuccess:!weakOperation.isCancelled];
    }];
    
    [_dataFetchQueue addOperation:operation];
}

- (void)scheduleBackgroundDataFetch
{
    BGProcessingTaskRequest *request = [[BGProcessingTaskRequest alloc] initWithIdentifier:kFetchDataUpdatesId];
    request.requiresNetworkConnectivity = YES;
    // Check for updates every hour
    request.earliestBeginDate = [NSDate dateWithTimeIntervalSinceNow:kCheckUpdatesInterval];
    @try
    {
        NSLog(@"BGTaskScheduler submitTaskRequest");
        NSError *error = nil;
        // e -l objc -- (void)[[BGTaskScheduler sharedScheduler] _simulateLaunchForTaskWithIdentifier:@"net.osmand.fetchDataUpdates"]
        [BGTaskScheduler.sharedScheduler submitTaskRequest:request error:&error];
        if (error)
            NSLog(@"Could not schedule app refresh: %@", error.description);
    } @catch (NSException *e) {
        NSLog(@"Could not schedule app refresh: %@", e.reason);
    }
}

#pragma mark - UISceneSession Lifecycle

- (UISceneConfiguration *)application:(UIApplication *)application configurationForConnectingSceneSession:(UISceneSession *)connectingSceneSession options:(UISceneConnectionOptions *)options
{
    if (connectingSceneSession.role == CPTemplateApplicationSceneSessionRoleApplication)
    {
        return [[UISceneConfiguration alloc] initWithName:@"CarPlay Configuration" sessionRole:connectingSceneSession.role];
    }
    else if (connectingSceneSession.role == CPTemplateApplicationDashboardSceneSessionRoleApplication)
    {
        return [[UISceneConfiguration alloc] initWithName:@"CarPlay-Dashboard" sessionRole:connectingSceneSession.role];
    }
    return [[UISceneConfiguration alloc] initWithName:@"Default Configuration" sessionRole:connectingSceneSession.role];
}

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions
{
    OALog(@"didDiscardSceneSessions");
}

#pragma mark - URL's

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
    return [self openURL:url];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self openURL:url];
}

- (BOOL)openURL:(NSURL *)url
{
    UIScene *scene = UIApplication.sharedApplication.mainScene;
    SceneDelegate *sd = (SceneDelegate *)scene.delegate;
    return [sd openURL:url];
}

@end
