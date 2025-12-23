//
//  SceneDelegate.m
//  OsmAnd Maps
//
//  Created by Oleksandr Panchenko on 27.07.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "SceneDelegate.h"
#import <UIKit/UIKit.h>
#import <BackgroundTasks/BackgroundTasks.h>
#import "OsmAndApp.h"
#import "OsmAndAppPrivateProtocol.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OANavigationController.h"
#import "OAMapRendererView.h"
#import "OALaunchScreenViewController.h"
#import "OACarPlayDashboardInterfaceController.h"
#import "OAIAPHelper.h"
#import "OAChoosePlanHelper.h"
#import "OACarPlayActiveViewController.h"
#import "Localization.h"
#import "OADiscountHelper.h"
#import "OALinks.h"
#import "OAFetchBackgroundDataOperation.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "OAAppDelegate.h"
#import "OAFirstUsageWizardController.h"
#import "StartupLogging.h"

#include <QDir>
#include <QFile>
#include <OsmAndCore.h>
#include <OsmAndCore/IncrementalChangesManager.h>
#include <OsmAndCore/Logging.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QIODeviceLogSink.h>
#include <OsmAndCore/FunctorLogSink.h>

#define kCheckUpdatesInterval 3600

@interface SceneDelegate()

@end

@implementation SceneDelegate
{
    UIWindowScene *_windowScene;
}

@synthesize window = _window;
@synthesize rootViewController = _rootViewController;

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        NSLog(@"SceneDelegate initialized");
    }
    return self;
}

- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions
{
    LogStartup(@"scene willConnectToSession");
    
    _windowScene = (UIWindowScene *)scene;
    if (!_windowScene)
    {
        LogStartup(@"windowScene is nil — abort");
        return;
    }
    
    _window = [[UIWindow alloc] initWithWindowScene:_windowScene];
    LogStartup(@"UIWindow created");
    
    OAAppDelegate *appDelegate = [self appDelegate];
    [appDelegate initialize];
    LogStartup(@"appDelegate initialize called");
    
    _rootViewController = appDelegate.rootViewController;
    LogStartup(@"rootViewController assigned");
    
    [self configureServices];
    LogStartup(@"services configured");
    
    if (connectionOptions.URLContexts.count > 0)
    {
        UIOpenURLContext *context = connectionOptions.URLContexts.allObjects.firstObject;
        NSURL *url = context.URL;
        
        if (url)
        {
            [self openURL:url];
            
            NSString *urlDescription = [url absoluteString];
            NSString *handledMessage = [NSString stringWithFormat:@"Handled URL context: %@", urlDescription];
            LogStartup(handledMessage);
        }
        else
        {
            LogStartup(@"Handled URL context, but URL was nil");
        }
    }
    
    if (connectionOptions.userActivities.count > 0)
    {
        NSUserActivity *userActivity = connectionOptions.userActivities.allObjects.firstObject;
        if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb])
        {
            NSURL *webpageURL = userActivity.webpageURL;
            
            if (webpageURL && [[UIApplication sharedApplication] canOpenURL:webpageURL])
            {
                [self openURL:webpageURL];
                
                NSString *urlDescription = [webpageURL absoluteString];
                NSString *handledMessage = [NSString stringWithFormat:@"Handled Universal Link: %@", urlDescription];
                LogStartup(handledMessage);
            }
            else
            {
                LogStartup(@"Attempted to handle Universal Link, but URL was nil or cannot be opened.");
            }
        }
    }
    
    [self configureSceneState:appDelegate.appLaunchEvent];
    LogStartup(@"scene state configured");
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(launchUpdateStateNotification:)
                                                 name:OALaunchUpdateStateNotification
                                               object:nil];
    LogStartup(@"scene setup complete");
}


- (void)sceneDidBecomeActive:(UIScene *)scene
{
    [[self appDelegate] applicationDidBecomeActive];
}

- (void)sceneWillResignActive:(UIScene *)scene
{
    [[self appDelegate] applicationWillResignActive];
}

- (void)sceneWillEnterForeground:(UIScene *)scene
{
    [[self appDelegate] applicationWillEnterForeground];
}

- (void)sceneDidEnterBackground:(UIScene *)scene
{
    [[self appDelegate] applicationDidEnterBackground];
}

- (void)sceneDidDisconnect:(UIScene *)scene
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)launchUpdateStateNotification:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    if (info[@"event"])
    {
        NSNumber *num = info[@"event"];
        NSLog(@"launchUpdateStateNotification: %@", num);
        [self configureSceneState:(AppLaunchEvent)num.intValue];
    }
}

- (void)configureSceneState:(AppLaunchEvent)event
{
    switch (event) {
        case AppLaunchEventStart:
            NSLog(@"AppLaunchEventStart");
            _window.rootViewController = [OALaunchScreenViewController new];
            [_window makeKeyAndVisible];
            break;
        case AppLaunchEventFirstLaunch:
            NSLog(@"AppLaunchEventFirstLaunch");
            [_rootViewController.navigationController pushViewController:[OAFirstUsageWizardController new] animated:NO];
            break;
        case AppLaunchEventRestoreSession:
            NSLog(@"AppLaunchEventRestoreSession");
            _rootViewController = [OARootViewController new];
            if ([self appDelegate].rootViewController == nil)
                [self appDelegate].rootViewController = _rootViewController;

            _window.rootViewController = [[OANavigationController alloc] initWithRootViewController:_rootViewController];
            [_window makeKeyAndVisible];
            break;
        case AppLaunchEventSetupRoot:
            NSLog(@"AppLaunchEventSetupRoot");
            [self configureLaunchEventSetupRootState];
            break;
        default:
            break;
    }
}

- (void)configureLaunchEventSetupRootState
{
    // setup rootViewController if CarPlay(another scenes) was launched first
    if ([self appDelegate].rootViewController == nil)
        [self appDelegate].rootViewController = [OARootViewController new];

    _rootViewController = [self appDelegate].rootViewController;

    _window.rootViewController = [[OANavigationController alloc] initWithRootViewController:_rootViewController];
    [_window makeKeyAndVisible];
}

- (void)configureServices
{
    [BLEInitHeader configure];
}

- (OAAppDelegate *)appDelegate
{
    return (OAAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)openURL:(NSURL *)url
{
    if (_rootViewController)
    {
        return [[DeepLinkManager shared] handleDeepLinkWithUrl:url rootViewController:_rootViewController];
    }
    else
    {
        self.loadedURL = url;
        return NO;
    }
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts
{
    if ([URLContexts allObjects].count > 0)
    {
        NSURL *url = [[URLContexts allObjects] firstObject].URL;
        [self openURL:url];
    }
}

- (void)scene:(UIScene *)scene continueUserActivity:(NSUserActivity *)userActivity
{
    [self openURL:userActivity.webpageURL];
}

- (UIInterfaceOrientation)getUIIntefaceOrientation
{
    return _windowScene.interfaceOrientation;
}

@end
