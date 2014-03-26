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
#import "OARootViewController.h"

#import "TestFlight.h"

#include <QStandardPaths>
#include <QDir>
#include <QFile>

#include <OsmAndCore.h>
#include <OsmAndCore/Logging.h>

@implementation OAAppDelegate
{
    OsmAndAppInstance _app;
}

@synthesize window = _window;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Initialize TestFlight SDK
    [TestFlight takeOff:@"c3934cca-2d7e-4c09-a019-c7018422633f"];

    // Configure device
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    // Create instance of OsmAnd application
    _app = [OsmAndApp instance];
    
    // Initialize OsmAnd core
    OsmAnd::InitializeCore();
    
#if defined(DEBUG)
    // If this is a debug build, duplicate all core logs to a file
    std::shared_ptr<QIODevice> loggingDevice(new QFile(QStandardPaths::writableLocation(QStandardPaths::DocumentsLocation)
                                                       + QDir::separator()
                                                       + QLatin1String("core.log")));
    loggingDevice->open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text);
    OsmAnd::SaveLogsTo(loggingDevice, true);
#endif

    // Create window
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    // Create root view controller
    self.window.rootViewController = [[OARootViewController alloc] init];
    [self.window makeKeyAndVisible];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    [_app saveState];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    // Release OsmAnd core
    OsmAnd::ReleaseCore();
    
    // Deconfigure device
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

@end
