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

#import "OAAppDelegate.h"

#include <QDir>
#include <QFile>

#include <OsmAndCore.h>
#include <OsmAndCore/IncrementalChangesManager.h>
#include <OsmAndCore/Logging.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QIODeviceLogSink.h>
#include <OsmAndCore/FunctorLogSink.h>

#import "OAFirstUsageWizardController.h"
#import "OsmAnd_Maps-Swift.h"

#define kCheckUpdatesInterval 3600

@interface SceneDelegate()

@end

@implementation SceneDelegate {
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
    NSLog(@"SceneDelegate willConnectToSession");
    _windowScene = (UIWindowScene *)scene;
    if (!_windowScene) {
        NSLog(@"SceneDelegate _windowScene in nil");
        return;
    }
    
    _window = [[UIWindow alloc] initWithWindowScene:_windowScene];
    
    OAAppDelegate *appDelegate = [self appDelegate];
    [appDelegate initialize];

    _rootViewController = appDelegate.rootViewController;

    [self configureServices];
    
    if (connectionOptions.URLContexts.count > 0) {
        NSURL *url = [connectionOptions.URLContexts allObjects].firstObject.URL;
        [self openURL:url];
    }
    
    if (connectionOptions.userActivities.count > 0) {
        NSUserActivity *userActivity = [connectionOptions.userActivities allObjects].firstObject;
        if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
            NSURL *webpageURL = userActivity.webpageURL;
            if ([[UIApplication sharedApplication] canOpenURL:webpageURL]) {
                [self openURL:webpageURL];
            }
        }
    }
    [self configureSceneState:appDelegate.appLaunchEvent];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(launchUpdateStateNotification:)
                                                     name:OALaunchUpdateStateNotification object:nil];
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

- (void)sceneDidDisconnect:(UIScene *)scene {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)launchUpdateStateNotification:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    if (info[@"event"]) {
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

- (OAAppDelegate *)appDelegate {
    return (OAAppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)openURL:(NSURL *)url
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
        self.loadedURL = url;
        return NO;
    }
}

- (BOOL)handleIncomingActionsURL:(NSURL *)url
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

- (BOOL)handleIncomingFileURL:(NSURL *)url
{
    if (_rootViewController && [url.scheme.lowercaseString isEqualToString:kFileScheme])
        return [_rootViewController handleIncomingURL:url];
    return NO;
}

- (BOOL)handleIncomingNavigationURL:(NSURL *)url
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

- (BOOL)handleIncomingMoveMapToLocationURL:(NSURL *)url
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

- (BOOL)handleIncomingOpenLocationMenuURL:(NSURL *)url
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

- (BOOL)handleIncomingTileSourceURL:(NSURL *)url
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

- (BOOL)handleIncomingOsmAndCloudURL:(NSURL *)url
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

- (void)moveMapToLat:(double)lat lon:(double)lon zoom:(int)zoom withTitle:(NSString *)title
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
            [OsmAndApp instance].initialURLMapState = state;
            return;
        }

        [_rootViewController.mapPanel moveMapToLat:lat lon:lon zoom:zoom withTitle:title];
    });
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts
{
    if ([URLContexts allObjects].count > 0) {
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
