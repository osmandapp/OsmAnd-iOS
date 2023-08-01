//
//  OAAppDelegate.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAAppDelegate.h"
#import "OALog.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAAppDelegate

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
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
