//
//  OAAppDelegate.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAAppDelegate.h"

#import <UIKit/UIKit.h>
#import <BackgroundTasks/BackgroundTasks.h>
#import "OsmAnd_Maps-Swift.h"
#import "SceneDelegate.h"

#import "OsmAndApp.h"
#import "OsmAndAppPrivateProtocol.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OAMapRendererView.h"
#import "OAOnlineTilesEditingViewController.h"
#import "OAMapLayers.h"
#import "OAPOILayer.h"
#import "OAMapViewState.h"
#import "OAIAPHelper.h"
#import "OAChoosePlanHelper.h"
#import "Localization.h"
#import "OALog.h"
#import "OARoutingHelper.h"
#import "OATargetPointsHelper.h"
#import "OAMapActions.h"
#import "OADiscountHelper.h"
#import "OALinks.h"
#import "OABackupHelper.h"
#import "OAFetchBackgroundDataOperation.h"
#import "OACloudAccountVerificationViewController.h"
#import <AFNetworking/AFNetworkReachabilityManager.h>
#import "OsmAnd_Maps-Swift.h"

#include <QDir>
#include <QFile>

#include <OsmAndCore.h>
#include <OsmAndCore/IncrementalChangesManager.h>
#include <OsmAndCore/Logging.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QIODeviceLogSink.h>
#include <OsmAndCore/FunctorLogSink.h>

#define kFetchDataUpdatesId @"net.osmand.fetchDataUpdates"

static const NSTimeInterval kCheckUpdatesInterval = 3600;

NSNotificationName const OALaunchUpdateStateNotification = @"OALaunchUpdateStateNotification";

@implementation OAAppDelegate
{
    id<OsmAndAppProtocol, OsmAndAppCppProtocol, OsmAndAppPrivateProtocol> _app;
    
    UIBackgroundTaskIdentifier _appInitTask;
    BOOL _appInitDone;
    BOOL _appInitializing;
    BOOL _didFinishLaunching;
    NSTimer *_checkUpdatesTimer;
    NSOperationQueue *_dataFetchQueue;
    dispatch_queue_t initializeQueue;
}

@synthesize rootViewController = _rootViewController;
@synthesize appLaunchEvent = _appLaunchEvent;


- (instancetype)init
{
    self = [super init];
    if (self)
    {
        NSLog(@"AppDelegate initialized");
        initializeQueue = dispatch_queue_create("OAAppDelegateInitializeQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_USER_INTERACTIVE, 0));
    }
    return self;
}

- (BOOL)initialize
{
    @synchronized (self) {
        if (_appInitDone)
        {
            if (_didFinishLaunching)
            {
                _didFinishLaunching = NO;
                //[self configureAppLaunchEvent:AppLaunchEventRestoreSession];
                [self configureAppLaunchEvent:AppLaunchEventSetupRoot];
            }
            return YES;
        }

        if (_appInitializing)
            return NO;

        _appInitializing = YES;
    }

    [self configureAppLaunchEvent:AppLaunchEventStart];

    NSLog(@"OAAppDelegate initialize start");

    // Configure device
    UIDevice* device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    device.batteryMonitoringEnabled = YES;
    
    // Update app execute counter
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    NSInteger execCount = [settings integerForKey:kAppExecCounter];
    [settings setInteger:++execCount forKey:kAppExecCounter];

    if ([settings doubleForKey:kAppInstalledDate] == 0)
        [settings setDouble:[[NSDate date] timeIntervalSince1970] forKey:kAppInstalledDate];

    [settings synchronize];

    // Create instance of OsmAnd application
    _app = (id<OsmAndAppProtocol, OsmAndAppCppProtocol, OsmAndAppPrivateProtocol>)[OsmAndApp instance];
    
    _appInitTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"appInitTask" expirationHandler:^{
        
        [[UIApplication sharedApplication] endBackgroundTask:_appInitTask];
        _appInitTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(initializeQueue, ^{
        
        NSLog(@"OAAppDelegate beginBackgroundTask");

        // Initialize OsmAnd core
        if (![_app initializeCore])
        {
            NSLog(@"OAAppDelegate failed to initialize core");
            return;
        }

        // Initialize application in background
        if (![_app initialize])
        {
            NSLog(@"OAAppDelegate failed to initialize app");
            return;
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Initialize application in main thread
            //[_app initialize];
            [[OAScreenOrientationHelper sharedInstance] updateSettings];
            
            [OALocationIcon initialize];

            // Configure ThemeManager
            OAAppSettings *appSettings = [OAAppSettings sharedManager];
            OAApplicationMode *initialAppMode = [appSettings.useLastApplicationModeByDefault get] ?
            [OAApplicationMode valueOfStringKey:[appSettings.lastUsedApplicationMode get] def:OAApplicationMode.DEFAULT] : appSettings.defaultApplicationMode.get;
            [[ThemeManager shared] configureWithAppMode:initialAppMode];
            
            [OAOsmOAuthHelper logOutIfNeeded];

            [self askReview];

            // Create root view controller
            [self configureAppLaunchEvent:AppLaunchEventSetupRoot];
            BOOL mapInstalled = NO;
            for (const auto& resource : _app.resourcesManager->getLocalResources())
            {
                if (resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion
                    && resource->id != QString::fromNSString(kWorldMiniBasemapKey.lowercaseString))
                {
                    mapInstalled = YES;
                    break;
                }
            }
            // Show intro screen
            if (!mapInstalled)
            {
                [self configureAppLaunchEvent:AppLaunchEventFirstLaunch];
            }
            UIScene *scene = UIApplication.sharedApplication.mainScene;
            SceneDelegate *sd = (SceneDelegate *)scene.delegate;
            if (sd.loadedURL)
            {
                [self openURL:sd.loadedURL];
                sd.loadedURL = nil;
            }
            [OAUtilities clearTmpDirectory];

            [self requestUpdatesOnNetworkReachable];

            _appInitDone = YES;
            _appInitializing = NO;
            
            [[UIApplication sharedApplication] endBackgroundTask:_appInitTask];
            _appInitTask = UIBackgroundTaskInvalid;

            NSLog(@"OAAppDelegate endBackgroundTask");
            
            // Check for updates every hour when the app is in the foreground
            [self initCheckUpdatesTimer];
        });
    });
    
    NSLog(@"OAAppDelegate initialize finish");
    return YES;
}

- (BOOL)isAppInitializing
{
    return _appInitializing;
}

- (void)configureAppLaunchEvent:(AppLaunchEvent)event
{
    _appLaunchEvent = event;
    [[NSNotificationCenter defaultCenter] postNotificationName:
     OALaunchUpdateStateNotification object:nil userInfo:@{@"event": @(_appLaunchEvent)}];
}

- (void)requestUpdatesOnNetworkReachable
{
    [AFNetworkReachabilityManager.sharedManager startMonitoring];
    [AFNetworkReachabilityManager.sharedManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        [NSNotificationCenter.defaultCenter postNotificationName:kReachabilityChangedNotification object:nil];

        if (status == AFNetworkReachabilityStatusReachableViaWWAN || status == AFNetworkReachabilityStatusReachableViaWiFi)
        {
            [_app checkAndDownloadOsmAndLiveUpdates:YES];
            [_app checkAndDownloadWeatherForecastsUpdates];
        }
    }];
}

- (void) askReview
{
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
    double appInstalledTime = [settings doubleForKey:kAppInstalledDate];
    int appInstalledDays = (int)((currentTime - appInstalledTime) / (24 * 60 * 60));
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL isReviewed = [userDefaults boolForKey:@"isReviewed"];
    if (appInstalledDays < 15 || appInstalledDays > 45)
        return;
    UIScene *windowScene = UIApplication.sharedApplication.mainScene;
    if (!isReviewed && windowScene)
    {
        [SKStoreReviewController requestReviewInScene:(UIWindowScene *) windowScene];
        [userDefaults setBool:true forKey:@"isReviewed"];
    }
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    return [self openURL:userActivity.webpageURL];
}

- (void)performUpdatesCheck
{
    [_app checkAndDownloadOsmAndLiveUpdates:YES];
    [_app checkAndDownloadWeatherForecastsUpdates];
}

- (void)invalidateIfNeededCheckUpdatesTimer
{
    if (_checkUpdatesTimer)
    {
        [_checkUpdatesTimer invalidate];
        _checkUpdatesTimer = nil;
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    _didFinishLaunching = YES;
    if (!_dataFetchQueue)
    {
        // Set the background fetch
        _dataFetchQueue = [[NSOperationQueue alloc] init];
        @try
        {
            NSLog(@"BGTaskScheduler registerForTaskWithIdentifier");
            [BGTaskScheduler.sharedScheduler registerForTaskWithIdentifier:kFetchDataUpdatesId usingQueue:nil launchHandler:^(__kindof BGTask * _Nonnull task) {
                [self handleBackgroundDataFetch:(BGProcessingTask *)task];
            }];
        }
        @catch (NSException *e)
        {
            NSLog(@"Failed to schedule background fetch. Reason: %@", e.reason);
        }
    }

    return YES;
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

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{
    completionHandler();
}

- (void)applicationWillResignActive
{
    NSLog(@"OAAppDelegate applicationWillResignActive %d", _appInitDone);
    if (_appInitDone)
        [_app onApplicationWillResignActive];
}

- (void)applicationDidEnterBackground
{
    NSLog(@"OAAppDelegate applicationDidEnterBackground %d", _appInitDone);
    [self invalidateIfNeededCheckUpdatesTimer];
    if (_appInitDone)
        [_app onApplicationDidEnterBackground];
    
    [BGTaskScheduler.sharedScheduler cancelAllTaskRequests];
    [self scheduleBackgroundDataFetch];
}

- (void)applicationWillEnterForeground
{
    NSLog(@"OAAppDelegate applicationWillEnterForeground %d", _appInitDone);
    if (_appInitDone)
    {
        [_app onApplicationWillEnterForeground];

        // Start suspended resource download task if such exists
        if (![_app.downloadsManager hasActiveDownloadTasks] && [_app.downloadsManager.keysOfDownloadTasks count] > 0)
        {
            id<OADownloadTask> nextTask = [_app.downloadsManager firstDownloadTasksWithKey:[_app.downloadsManager.keysOfDownloadTasks objectAtIndex:0]];
            if (nextTask)
            {
                NSLog(@"Resume suspended download %@", nextTask.key);
                [nextTask resume];
            }
        }
    }
}

- (void)applicationDidBecomeActive
{
    NSLog(@"OAAppDelegate applicationDidBecomeActive %d", _appInitDone);
    if (_appInitDone)
    {
        [self initCheckUpdatesTimer];
        [_app onApplicationDidBecomeActive];
    }
}

- (void)initCheckUpdatesTimer
{
    [self invalidateIfNeededCheckUpdatesTimer];
    _checkUpdatesTimer = [NSTimer scheduledTimerWithTimeInterval:kCheckUpdatesInterval target:self selector:@selector(performUpdatesCheck) userInfo:nil repeats:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    NSLog(@"OAAppDelegate applicationWillTerminate");
    [_app shutdown];
    OAMapViewController *mapVc = OARootViewController.instance.mapPanel.mapViewController;
    [mapVc onApplicationDestroyed];
    // Release OsmAnd core
    OsmAnd::ReleaseCore();

    // Deconfigure device
    UIDevice* device = [UIDevice currentDevice];
    device.batteryMonitoringEnabled = NO;
    [device endGeneratingDeviceOrientationNotifications];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    NSLog(@"OAAppDelegate applicationDidReceiveMemoryWarning");
}

- (void)applicationProtectedDataWillBecomeUnavailable:(UIApplication *)application
{
    NSLog(@"OAAppDelegate applicationProtectedDataWillBecomeUnavailable");
}

- (void)applicationProtectedDataDidBecomeAvailable:(UIApplication *)application
{
    NSLog(@"OAAppDelegate applicationProtectedDataDidBecomeAvailable");
}

#pragma mark - UISceneSession Lifecycle

- (void)application:(UIApplication *)application didDiscardSceneSessions:(NSSet<UISceneSession *> *)sceneSessions
{
    OALog(@"didDiscardSceneSessions: %@", sceneSessions);
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

#pragma mark - Orientation

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    return [[OAScreenOrientationHelper sharedInstance] getUserInterfaceOrientationMask];
}

- (UIInterfaceOrientation)interfaceOrientation
{
    UIScene *scene = UIApplication.sharedApplication.mainScene;
    SceneDelegate *sd = (SceneDelegate *) scene.delegate;
    return [sd getUIIntefaceOrientation];
}

@end
