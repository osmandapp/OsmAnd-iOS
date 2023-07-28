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
#import "OANavigationController.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OAMapRendererView.h"
#import "OALaunchScreenViewController.h"
#import "OAOnlineTilesEditingViewController.h"
#import "OAMapLayers.h"
#import "OAPOILayer.h"
#import "OAMapViewState.h"
#import "OACarPlayMapViewController.h"
#import "OACarPlayPurchaseViewController.h"
#import "OACarPlayDashboardInterfaceController.h"
#import "OAIAPHelper.h"
#import "OAChoosePlanHelper.h"
#import "OACarPlayActiveViewController.h"
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

#include <QDir>
#include <QFile>

#include <OsmAndCore.h>
#include <OsmAndCore/IncrementalChangesManager.h>
#include <OsmAndCore/Logging.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QIODeviceLogSink.h>
#include <OsmAndCore/FunctorLogSink.h>

#import "OAFirstUsageWelcomeController.h"
#import "OsmAnd_Maps-Swift.h"

#define kCheckUpdatesInterval 3600

#define kFetchDataUpdatesId @"net.osmand.fetchDataUpdates"

@interface SceneDelegate()

@end

@implementation SceneDelegate
{
    id<OsmAndAppProtocol, OsmAndAppCppProtocol, OsmAndAppPrivateProtocol> _app;
    
    UIBackgroundTaskIdentifier _appInitTask;
    NSURL *_loadedURL;
    NSTimer *_checkUpdatesTimer;

//    OACarPlayMapViewController *_carPlayMapController API_AVAILABLE(ios(12.0));
//    OACarPlayDashboardInterfaceController *_carPlayDashboardController API_AVAILABLE(ios(12.0));
//    CPWindow *_windowToAttach API_AVAILABLE(ios(12.0));
//    CPInterfaceController *_carPlayInterfaceController API_AVAILABLE(ios(12.0));
    
    NSOperationQueue *_dataFetchQueue;
}

@synthesize window = _window;
@synthesize rootViewController = _rootViewController;
@synthesize appInitDone = _appInitDone;
@synthesize appInitializing = _appInitializing;



- (void)scene:(UIScene *)scene willConnectToSession:(UISceneSession *)session options:(UISceneConnectionOptions *)connectionOptions {
        
    UIWindowScene *windowScene = (UIWindowScene *)scene;
    self.window = [[UIWindow alloc] initWithWindowScene:windowScene];
    self.window.rootViewController = [[OALaunchScreenViewController alloc] init];
   // self.window.frame = windowScene.coordinateSpace.bounds;
    [self.window makeKeyAndVisible];
//
//    if (!_dataFetchQueue)
//    {
//        // Set the background fetch
//        _dataFetchQueue = [[NSOperationQueue alloc] init];
//        @try
//        {
//            NSLog(@"BGTaskScheduler registerForTaskWithIdentifier");
//            [BGTaskScheduler.sharedScheduler registerForTaskWithIdentifier:kFetchDataUpdatesId usingQueue:nil launchHandler:^(__kindof BGTask * _Nonnull task) {
//                [self handleBackgroundDataFetch:(BGProcessingTask *)task];
//            }];
//        }
//        @catch (NSException *e)
//        {
//            NSLog(@"Failed to schedule background fetch. Reason: %@", e.reason);
//        }
//    }
    
//    UIWindowScene *windowScene = (UIWindowScene *)scene;
//    if (!windowScene) {
//        return;
//    }
//
//    UIWindow *window = [[UIWindow alloc] initWithWindowScene:windowScene];
//
//    NSURL *url = connectionOptions.URLContexts[0].url
//    if (url) {
//        [ApplicationURLHandler handleURL:url];
//    }
//
//    NSUserActivity *userActivity = connectionOptions.userActivities[0];
//    if (userActivity.activityType == NSUserActivityTypeBrowsingWeb) {
//        NSURL *webpageURL = userActivity.webpageURL;
//        if (webpageURL && [[UIApplication sharedApplication] canOpenURL:webpageURL]) {
//            [ApplicationURLHandler handleURL:webpageURL];
//        }
//    }
    
//    guard let scene = (scene as? UIWindowScene) else { return }
//    let window = UIWindow(windowScene: scene)
//    window.backgroundColor = AppColor.background
//
//    if let url = connectionOptions.urlContexts.first?.url {
//        _ = ApplicationURLHandler.handle(url: url)
//    }
//
//    if let userActivity = connectionOptions.userActivities.first,
//       userActivity.activityType == NSUserActivityTypeBrowsingWeb,
//       let webpageURL = userActivity.webpageURL,
//       UIApplication.shared.canOpenURL(webpageURL) {
//       _ = ApplicationURLHandler.handle(url: webpageURL)
//    }

    [self initialize];
}


- (void)sceneDidDisconnect:(UIScene *)scene {
    // Called as the scene is being released by the system.
    // This occurs shortly after the scene enters the background, or when its session is discarded.
    // Release any resources associated with this scene that can be re-created the next time the scene connects.
    // The scene may re-connect later, as its session was not neccessarily discarded (see `application:didDiscardSceneSessions` instead).
    
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


- (void)sceneDidBecomeActive:(UIScene *)scene {
    // Called when the scene has moved from an inactive state to an active state.
    // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
    if (_appInitDone)
    {
        _checkUpdatesTimer = [NSTimer scheduledTimerWithTimeInterval:kCheckUpdatesInterval target:self selector:@selector(performUpdatesCheck) userInfo:nil repeats:YES];
        [_app onApplicationDidBecomeActive];
    }
}



- (void)sceneWillResignActive:(UIScene *)scene {
    // Called when the scene will move from an active state to an inactive state.
    // This may occur due to temporary interruptions (ex. an incoming phone call).
    
    if (_appInitDone)
        [_app onApplicationWillResignActive];
}


- (void)sceneWillEnterForeground:(UIScene *)scene {
    // Called as the scene transitions from the background to the foreground.
    // Use this method to undo the changes made on entering the background.
    
    if (_appInitDone)
        [_app onApplicationWillEnterForeground];
    else
        [self initialize];
}


- (void)sceneDidEnterBackground:(UIScene *)scene {
    // Called as the scene transitions from the foreground to the background.
    // Use this method to save data, release shared resources, and store enough scene-specific state information
    // to restore the scene back to its current state.
    
    if (_checkUpdatesTimer)
    {
        [_checkUpdatesTimer invalidate];
        _checkUpdatesTimer = nil;
    }
    if (_appInitDone)
        [_app onApplicationDidEnterBackground];
    
    [BGTaskScheduler.sharedScheduler cancelAllTaskRequests];
    [self scheduleBackgroundDataFetch];
}

- (BOOL) initialize
{
    if (_appInitDone || _appInitializing)
        return YES;

    _appInitializing = YES;

    NSLog(@"OAAppDelegate initialize start");

    // Configure device
    UIDevice* device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    device.batteryMonitoringEnabled = YES;
    
    // Create instance of OsmAnd application
    _app = (id<OsmAndAppProtocol, OsmAndAppCppProtocol, OsmAndAppPrivateProtocol>)[OsmAndApp instance];
    
    // Create window
//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    self.window.rootViewController = [[OALaunchScreenViewController alloc] init];
//    [self.window makeKeyAndVisible];
    
    _appInitTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"appInitTask" expirationHandler:^{
        
        [[UIApplication sharedApplication] endBackgroundTask:_appInitTask];
        _appInitTask = UIBackgroundTaskInvalid;
    }];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSLog(@"OAAppDelegate beginBackgroundTask");

        // Initialize OsmAnd core
        [_app initializeCore];

        // Initialize application in background
        //[_app initialize];

        dispatch_async(dispatch_get_main_queue(), ^{
            
            // Initialize application in main thread
            [_app initialize];

            [self askReview];

            // Update app execute counter
            NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
            NSInteger execCount = [settings integerForKey:kAppExecCounter];
            [settings setInteger:++execCount forKey:kAppExecCounter];
            
            if ([settings doubleForKey:kAppInstalledDate] == 0)
                [settings setDouble:[[NSDate date] timeIntervalSince1970] forKey:kAppInstalledDate];
            
            [settings synchronize];
            
            // Create root view controller
            _rootViewController = [[OARootViewController alloc] init];
            self.window.rootViewController = [[OANavigationController alloc] initWithRootViewController:_rootViewController];
            
            BOOL mapInstalled = NO;
            for (const auto& resource : _app.resourcesManager->getLocalResources())
            {
                if (resource->type == OsmAnd::ResourcesManager::ResourceType::MapRegion)
                {
                    mapInstalled = YES;
                    break;
                }
            }
            // Show intro screen
            if (execCount == 1 || !mapInstalled)
            {
                OAFirstUsageWelcomeController* welcome = [[OAFirstUsageWelcomeController alloc] init];
                [self.rootViewController.navigationController pushViewController:welcome animated:NO];
            }
            
            if (_loadedURL)
            {
                [self openURL:_loadedURL];
                _loadedURL = nil;
            }
            [OAUtilities clearTmpDirectory];

            [self requestUpdatesOnNetworkReachable];

            _appInitDone = YES;
            _appInitializing = NO;
            
            [[UIApplication sharedApplication] endBackgroundTask:_appInitTask];
            _appInitTask = UIBackgroundTaskInvalid;

            NSLog(@"OAAppDelegate endBackgroundTask");

            // Check for updates every hour when the app is in the foreground
            _checkUpdatesTimer = [NSTimer scheduledTimerWithTimeInterval:kCheckUpdatesInterval target:self selector:@selector(performUpdatesCheck) userInfo:nil repeats:YES];

            // show map in carPlay if it is a cold start
//            if (_windowToAttach && _carPlayInterfaceController)
//            {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    [self presentInCarPlay:_carPlayInterfaceController window:_windowToAttach];
//                    _carPlayInterfaceController = nil;
//                    _windowToAttach = nil;
//                });
//            }
        });
    });
    
    NSLog(@"OAAppDelegate initialize finish");
    return YES;
}

- (void) requestUpdatesOnNetworkReachable
{
    [AFNetworkReachabilityManager.sharedManager startMonitoring];
    [AFNetworkReachabilityManager.sharedManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        [NSNotificationCenter.defaultCenter postNotificationName:kReachabilityChangedNotification object:nil];

        if (status == AFNetworkReachabilityStatusReachableViaWWAN || status == AFNetworkReachabilityStatusReachableViaWiFi)
        {
            [_app checkAndDownloadOsmAndLiveUpdates];
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
    if (!isReviewed)
    {
        [SKStoreReviewController requestReview];
        [userDefaults setBool:true forKey:@"isReviewed"];
    }
}

- (BOOL) openURL:(NSURL *)url
{
    if (_rootViewController)
    {
        return [self handleIncomingFileURL:url]
            || [self handleIncomingActionsURL:url]
            || [self handleIncomingNavigationURL:url]
            || [self handleIncomingSetPinOnMapURL:url]
            || [self handleIncomingMoveMapToLocationURL:url]
            || [self handleIncomingOpenLocationMenuURL:url]
            || [self handleIncomingTileSourceURL:url]
            || [self handleIncomingOsmAndCloudURL:url];
    }
    else
    {
        _loadedURL = url;
        return NO;
    }
}

- (BOOL) handleIncomingActionsURL:(NSURL *)url
{
    // osmandmaps://?lat=45.6313&lon=34.9955&z=8&title=New+York
    if (_rootViewController && [url.scheme.lowercaseString isEqualToString:kOsmAndActionScheme])
    {
        NSDictionary<NSString *, NSString *> *params = [OAUtilities parseUrlQuery:url];
        double lat = [params[@"lat"] doubleValue];
        double lon = [params[@"lon"] doubleValue];
        int zoom = [params[@"z"] intValue];
        NSString *title = params[@"title"];
        NSString *host = url.host;

        if ([host isEqualToString:kNavigateActionHost])
        {
            OAMapViewController *mapViewController = [_rootViewController.mapPanel mapViewController];
            OATargetPoint *targetPoint = [mapViewController.mapLayers.contextMenuLayer getUnknownTargetPoint:lat longitude:lon];
            if (title.length > 0)
                targetPoint.title = title;

            [_rootViewController.mapPanel navigate:targetPoint];
            [_rootViewController.mapPanel closeRouteInfo];
            [_rootViewController.mapPanel startNavigation];
        }
        else
        {
            [self moveMapToLat:lat lon:lon zoom:zoom withTitle:title];
        }
    }
    return NO;
}

- (BOOL) handleIncomingFileURL:(NSURL *)url
{
    if (_rootViewController && [url.scheme.lowercaseString isEqualToString:kFileScheme])
        return [_rootViewController handleIncomingURL:url];
    return NO;
}

- (BOOL) handleIncomingNavigationURL:(NSURL *)url
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    NSArray<NSURLQueryItem *> *queryItems = components.queryItems;
    BOOL hasNavigationDestination = NO;
    NSString *startLatLonParam;
    NSString *endLatLonParam;
    NSString *appModeKeyParam;
    for (NSURLQueryItem *queryItem in queryItems)
    {
        if ([queryItem.name.lowercaseString isEqualToString:@"end"])
        {
            hasNavigationDestination = YES;
            endLatLonParam = queryItem.value;
        }
        else if ([queryItem.name.lowercaseString isEqualToString:@"start"])
        {
            startLatLonParam = queryItem.value;
        }
        else if ([queryItem.name.lowercaseString isEqualToString:@"mode"])
        {
            appModeKeyParam = queryItem.value;
        }
    }

    if (_rootViewController && hasNavigationDestination && [OAUtilities isOsmAndMapUrl:url])
    {
        if (!endLatLonParam || endLatLonParam.length == 0)
        {
            OALog(@"Malformed OsmAnd navigation URL: destination location is missing");
            return YES;
        }

        CLLocation *startLatLon = [OAUtilities parseLatLon:startLatLonParam];
        if (startLatLonParam && !startLatLon)
            OALog(@"Malformed OsmAnd navigation URL: start location is broken");
        
        CLLocation *endLatLon = [OAUtilities parseLatLon:endLatLonParam];
        if (!endLatLon)
        {
            OALog(@"Malformed OsmAnd navigation URL: destination location is broken");
            return YES;
        }

        OAApplicationMode *appMode = [OAApplicationMode valueOfStringKey:appModeKeyParam def:nil];
        if (appModeKeyParam && appModeKeyParam.length > 0 && !appMode)
            OALog(@"App mode with specified key not available, using default navigation app mode");

        [_rootViewController.mapPanel buildRoute:startLatLon end:endLatLon appMode:appMode];
        return YES;
    }
    return NO;
}

- (BOOL)handleIncomingSetPinOnMapURL:(NSURL *)url
{
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    NSArray<NSURLQueryItem *> *queryItems = components.queryItems;
    BOOL hasPin = NO;
    NSString *latLonParam;
    for (NSURLQueryItem *queryItem in queryItems)
    {
        if ([queryItem.name.lowercaseString isEqualToString:@"pin"])
        {
            hasPin = YES;
            latLonParam = queryItem.value;
        }
    }

    if (_rootViewController && hasPin && [OAUtilities isOsmAndMapUrl:url])
    {
        CLLocation *latLon = !latLonParam || latLonParam.length == 0 ? nil : [OAUtilities parseLatLon:latLonParam];
        if (latLon)
        {
            double lat = latLon.coordinate.latitude;
            double lon = latLon.coordinate.longitude;
            int zoom;

            NSString *pathPrefix = [@"/map?pin=" stringByAppendingString:latLonParam];
            NSInteger pathStartIndex = [[url.absoluteString stringByRemovingPercentEncoding] indexOf:pathPrefix];
            NSArray<NSString *> *params = [[[url.absoluteString stringByRemovingPercentEncoding] substringFromIndex:pathStartIndex + pathPrefix.length] componentsSeparatedByString:@"/"];
            if (params.count == 3) //  #15/52.3187/4.8801
                zoom = [[params.firstObject stringByReplacingOccurrencesOfString:@"#" withString:@""] intValue];
            else
                zoom = _rootViewController.mapPanel.mapViewController.mapView.zoom;

            [self moveMapToLat:lat lon:lon zoom:zoom withTitle:nil];
            return YES;
        }
    }
    return NO;
}

- (BOOL) handleIncomingMoveMapToLocationURL:(NSURL *)url
{
    NSString *pathPrefix = @"/map#";
    NSInteger pathStartIndex = [url.absoluteString indexOf:pathPrefix];
    if (_rootViewController && pathStartIndex != -1 && [OAUtilities isOsmAndMapUrl:url])
    {
        NSArray<NSString *> *params = [[url.absoluteString substringFromIndex:pathStartIndex + pathPrefix.length] componentsSeparatedByString:@"/"];
        if (params.count == 3)
        {
            int zoom = [params[0] intValue];
            double lat = [params[1] doubleValue];
            double lon = [params[2] doubleValue];
            [self moveMapToLat:lat lon:lon zoom:zoom withTitle:nil];
            return YES;
        }
    }
    return NO;
}

- (BOOL) handleIncomingOpenLocationMenuURL:(NSURL *)url
{
    if ([OAUtilities isOsmAndGoUrl:url])
    {
        NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
        NSArray<NSURLQueryItem *> *queryItems = components.queryItems;
        NSString *latParam;
        NSString *lonParam;
        NSString *zoomParam;
        NSString *titleParam;
        for (NSURLQueryItem *queryItem in queryItems)
        {
            if ([queryItem.name.lowercaseString isEqualToString:@"lat"])
                latParam = queryItem.value;
            else if ([queryItem.name.lowercaseString isEqualToString:@"lon"])
                lonParam = queryItem.value;
            else if ([queryItem.name.lowercaseString isEqualToString:@"z"])
                zoomParam = queryItem.value;
            else if ([queryItem.name.lowercaseString isEqualToString:@"title"])
                titleParam = queryItem.value;
        }

        if (_rootViewController && latParam && lonParam)
        {
            double lat = [latParam doubleValue];
            double lon = [lonParam doubleValue];
            int zoom = _rootViewController.mapPanel.mapViewController.mapView.zoom;
            if (zoomParam)
                zoom = [zoomParam intValue];
            [self moveMapToLat:lat lon:lon zoom:zoom withTitle:titleParam];
            return YES;
        }
    }
    return NO;
}

- (BOOL) handleIncomingTileSourceURL:(NSURL *)url
{
    if (_rootViewController && [OAUtilities isOsmAndSite:url] && [OAUtilities isPathPrefix:url pathPrefix:@ "/add-tile-source"])
    {
        NSDictionary<NSString *, NSString *> *params = [OAUtilities parseUrlQuery:url];
        // https://osmand.net/add-tile-source?name=&url_template=&min_zoom=&max_zoom=
        OAOnlineTilesEditingViewController *editTileSourceController = [[OAOnlineTilesEditingViewController alloc] initWithUrlParameters:params];
        [_rootViewController.navigationController pushViewController:editTileSourceController animated:NO];
        return YES;
    }
    return NO;
}

- (BOOL) handleIncomingOsmAndCloudURL:(NSURL *)url
{
    if (![OAUtilities isOsmAndSite:url] || ![OAUtilities isPathPrefix:url pathPrefix:@ "/premium/device-registration"])
        return NO;
    NSURLComponents *components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:YES];
    NSArray<NSURLQueryItem *> *queryItems = components.queryItems;
    NSString *tokenParam;
    for (NSURLQueryItem *queryItem in queryItems)
    {
        if ([queryItem.name.lowercaseString isEqualToString:@"token"])
            tokenParam = queryItem.value;
    }
    
    UIViewController *vc = _rootViewController.navigationController.visibleViewController;
    
    if ([vc isKindOfClass:OACloudAccountVerificationViewController.class])
    {
        if ([OABackupHelper isTokenValid:tokenParam])
        {
            [OABackupHelper.sharedInstance registerDevice:tokenParam];
        }
        else
        {
            OACloudAccountVerificationViewController *verificationVC = (OACloudAccountVerificationViewController *)vc;
            verificationVC.errorMessage = OALocalizedString(@"backup_error_invalid_token");
            [verificationVC updateScreen];
        }
    }
    else
    {
        _rootViewController.token = tokenParam;
    }
    return YES;
}

- (void) moveMapToLat:(double)lat lon:(double)lon zoom:(int)zoom withTitle:(NSString *)title
{
    Point31 pos31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon))];
    dispatch_async(dispatch_get_main_queue(), ^{
        OAMapViewController *mapViewController = [_rootViewController.mapPanel mapViewController];

        if (!_rootViewController || !mapViewController || !mapViewController.mapViewLoaded)
        {
            OAMapViewState *state = [[OAMapViewState alloc] init];
            state.target31 = pos31;
            state.zoom = zoom;
            state.azimuth = 0.0f;
            _app.initialURLMapState = state;
            return;
        }

        [_rootViewController.mapPanel moveMapToLat:lat lon:lon zoom:zoom withTitle:title];
    });
}

- (void) performUpdatesCheck
{
    [_app checkAndDownloadOsmAndLiveUpdates];
    [_app checkAndDownloadWeatherForecastsUpdates];
}

- (void) handleBackgroundDataFetch:(BGProcessingTask *)task
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

- (void) scheduleBackgroundDataFetch
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

////
///
//
- (BOOL) application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    return [self openURL:userActivity.webpageURL];
}


- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{
    completionHandler();
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [self openURL:url];
}

- (void) application:(UIApplication *)application willChangeStatusBarFrame:(CGRect)newStatusBarFrame
{
    [OASharedVariables setStatusBarHeight:newStatusBarFrame.size.height];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
    return [self openURL:url];
}



@end
