//
//  ExtensionDelegate.m
//  SmartNaviWatch Extension
//
//  Created by egloff on 16/12/15.
//  Copyright © 2015 OsmAnd. All rights reserved.
//

#import "ExtensionDelegate.h"
#import "OASmartNaviWatchConstants.h"
#import "OASmartNaviWatchNavigationWaypoint.h"

@implementation ExtensionDelegate

- (void)applicationDidFinishLaunching {
    // Perform any final initialization of your application.
    
    // register delegate for WCSession
    [WCSession defaultSession].delegate = self;
    [[WCSession defaultSession] activateSession];
}

- (void)applicationDidBecomeActive {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillResignActive {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, etc.
}

#pragma mark WCSessionDelegate

-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message {
    
    //loop for all three images and save in array
    if ([message objectForKey:OA_SMARTNAVIWATCH_KEY_LOCATION_ERROR_IMAGE_DATA]) {
        self.imageData = nil;
    } else {
        self.imageData = [[NSMutableArray alloc] initWithCapacity:3];
        for (int i=0; i<3; ++i) {
            NSData *data = [message objectForKey:[NSString stringWithFormat:@"image%d",i]];
            UIImage *image = [UIImage imageWithData:data];
            [self.imageData addObject:image];
        }
    }
    
    
    //update location info
    self.locationInfo = [message objectForKey:OA_SMARTNAVIWATCH_KEY_LOCATION_INFO];

    
    // notify all observers
    [[NSNotificationCenter defaultCenter] postNotificationName:OA_SMARTNAVIWATCH_NOTIFICATION_LOCATION_CHANGED object:self];
    
    
    if ([message objectForKey:OA_SMARTNAVIWATCH_KEY_NAVIGATION_UPDATE] != nil) {
                
        NSDictionary *navigationDict = [message objectForKey:OA_SMARTNAVIWATCH_KEY_NAVIGATION_UPDATE];
        NSArray *unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithData:[navigationDict objectForKey:OA_SMARTNAVIWATCH_KEY_NAVIGATION_WAYPOINTS]];

        self.waypoints = unarchivedData;
        
        self.currentNavigationTitle = [navigationDict objectForKey:OA_SMARTNAVIWATCH_KEY_NAVIGATION_TITLE];

        self.currentNavigationIndex = [navigationDict objectForKey:OA_SMARTNAVIWATCH_KEY_NAVIGATION_CURRENT_WAYPOINT_INDEX];
        
        
        [self updateUIWithNavigation:YES];

        
    } else {
        
        [self updateUIWithNavigation:NO];

        
    }
    self.mapInitialized = YES;

    
    [[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeNotification];

}

-(void)updateUIWithNavigation:(BOOL)navigationViewAvailable {
    
    if (navigationViewAvailable) {
        //update table UI
        if (numberOfPages == 2) {
            [[NSNotificationCenter defaultCenter] postNotificationName:OA_SMARTNAVIWATCH_NOTIFICATION_INIT_ROUTE_DATA
                                                                object:nil];
        } else {
            [WKInterfaceController reloadRootControllersWithNames:@[@"InterfaceController", @"NavigationController"] contexts:nil];
        }
        numberOfPages = 2;

    } else {
        //hide/disable page view controller
        [WKInterfaceController reloadRootControllersWithNames:@[@"InterfaceController"] contexts:nil];
        numberOfPages = 1;
    }
    
}

-(void)sendLocationRequest {
    WCSession* session = [WCSession defaultSession];
    NSDictionary *dataDict = @{OA_SMARTNAVIWATCH_KEY_LOCATION_REQUEST : @""};
    
    [session sendMessage:dataDict
            replyHandler:^(NSDictionary *reply) {
                //handle reply from iPhone app here
            }
            errorHandler:^(NSError *error) {
                
                switch (error.code) {
                    case 7004:
                        [[NSNotificationCenter defaultCenter] postNotificationName:OA_SMARTNAVIWATCH_NOTIFICATION_SHOW_MESSAGE
                                                                            object:nil];
                        break;
                        
                    default:
                        break;
                }
            }
     ];
}

-(void)session:(WCSession *)session didReceiveApplicationContext:(NSDictionary<NSString *,id> *)applicationContext {
    //working ;-)
    [[WKInterfaceDevice currentDevice] playHaptic:WKHapticTypeNotification];

}

@end
