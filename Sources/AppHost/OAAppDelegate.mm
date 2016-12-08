//
//  OAAppDelegate.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/15/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAAppDelegate.h"

#import <UIKit/UIKit.h>

#import "OsmAndApp.h"
#import "OsmAndAppPrivateProtocol.h"
#import "OARootViewController.h"
#import "OANavigationController.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OAMapRendererView.h"
#include "CoreResourcesFromBundleProvider.h"

#include <QDir>
#include <QFile>

#include <OsmAndCore.h>
#include <OsmAndCore/Logging.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/QIODeviceLogSink.h>
#include <OsmAndCore/FunctorLogSink.h>

#import "OAFirstUsageWelcomeController.h"
#import "Firebase.h"

@implementation OAAppDelegate
{
    id<OsmAndAppProtocol, OsmAndAppCppProtocol, OsmAndAppPrivateProtocol> _app;
}

@synthesize window = _window;
@synthesize rootViewController = _rootViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
#if !defined(OSMAND_IOS_DEV)
    // Use Firebase library to configure APIs
    [FIRApp configure];
#endif // defined(OSMAND_IOS_DEV)
    
    // Configure device
    UIDevice* device = [UIDevice currentDevice];
    [device beginGeneratingDeviceOrientationNotifications];
    device.batteryMonitoringEnabled = YES;

    // Create instance of OsmAnd application
    _app = (id<OsmAndAppProtocol, OsmAndAppCppProtocol, OsmAndAppPrivateProtocol>)[OsmAndApp instance];

    // Initialize OsmAnd core
    const std::shared_ptr<CoreResourcesFromBundleProvider> coreResourcesFromBundleProvider(new CoreResourcesFromBundleProvider());
    OsmAnd::InitializeCore(coreResourcesFromBundleProvider);

    // Initialize application
    [_app initialize];
    
    // Update app execute counter
    NSInteger execCount = [[NSUserDefaults standardUserDefaults] integerForKey:kAppExecCounter];
    [[NSUserDefaults standardUserDefaults] setInteger:++execCount forKey:kAppExecCounter];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // Create window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Create root view controller
    _rootViewController = [[OARootViewController alloc] init];
    self.window.rootViewController = [[OANavigationController alloc] initWithRootViewController:_rootViewController];
    [self.window makeKeyAndVisible];

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

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    NSString *scheme = [[url scheme] lowercaseString];

    if ([scheme isEqualToString:@"file"])
    {
        return [_rootViewController handleIncomingURL:url
                                    sourceApplication:sourceApplication
                                           annotation:annotation];
    }
    else if ([scheme isEqualToString:@"osmandmaps"])
    {
        NSDictionary *params = [OAUtilities parseUrlQuery:url];
        
        // osmandmaps://?lat=12.6313&lon=-7.9955&z=8&title=New+York
        double lat = [params[@"lat"] doubleValue];
        double lon = [params[@"lon"] doubleValue];
        double zoom = [params[@"z"] doubleValue];
        NSString *title = params[@"title"];
        
        Point31 pos31 = [OANativeUtilities convertFromPointI:OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lat, lon))];
        dispatch_async(dispatch_get_main_queue(), ^{
            
            OAMapViewController* mapViewController = [_rootViewController.mapPanel mapViewController];
            
            UIViewController *top = _rootViewController.navigationController.topViewController;
            
            if (![top isKindOfClass:[JASidePanelController class]])
                [_rootViewController.navigationController popToRootViewControllerAnimated:NO];

            if (_rootViewController.state != JASidePanelCenterVisible)
                [_rootViewController showCenterPanelAnimated:NO];

            [_rootViewController.mapPanel closeMapSettings];
            
            [mapViewController goToPosition:pos31 andZoom:zoom animated:NO];
            
            OAMapSymbol *symbol = [[OAMapSymbol alloc] init];
            symbol.caption = title;
            symbol.location = CLLocationCoordinate2DMake(lat, lon);
            symbol.touchPoint = CGPointMake(DeviceScreenWidth / 2.0, DeviceScreenHeight / 2.0);
            symbol.type = OAMapSymbolContext;
            
            [OAMapViewController postTargetNotification:symbol];
        });
        
        return YES;
    }
    
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

    [_app onApplicationWillResignActive];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    [_app onApplicationDidEnterBackground];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

    [_app onApplicationWillEnterForeground];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

    [_app onApplicationDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    [_app shutdown];
    
    // Release OsmAnd core
    OsmAnd::ReleaseCore();
    
    // Deconfigure device
    UIDevice* device = [UIDevice currentDevice];
    device.batteryMonitoringEnabled = NO;
    [device endGeneratingDeviceOrientationNotifications];
}


@end
