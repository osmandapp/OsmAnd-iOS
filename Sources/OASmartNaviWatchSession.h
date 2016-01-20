//
//  OASmartNaviWatchSession.h
//  OsmAnd
//
//  Created by egloff on 18/12/15.
//  Copyright © 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WatchConnectivity/WatchConnectivity.h>
#import <CoreLocation/CoreLocation.h>
#import "OASmartNaviWatchNavigationController.h"

@interface OASmartNaviWatchSession : NSObject <WCSessionDelegate> {
    //properties
    NSObject *observer;
    OASmartNaviWatchNavigationController *navigationController;
}

+ (id)sharedInstance;

-(BOOL)checkIfPluginEnabled;
-(void)activatePlugin;
-(void)sendImageData:(NSArray*)imageData forLocation:(CLLocation*)location;
-(void)registerObserverForUpdates:(NSObject*)observerToRegister;

+ (NSData *)imageDataWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end

