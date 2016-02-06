//
//  OASmartNaviWatchSession.h
//  OsmAnd
//
//  Created by egloff on 18/12/15.
//  Copyright © 2015 OsmAnd. All rights reserved.
//
/**
 *  This singleton class is responsible for every data connection to the
 *  Apple Watch. It registers sessions as well as provides information such
 *  as whether or not the plugin is activated.
 */
//

#import <Foundation/Foundation.h>

#import <WatchConnectivity/WatchConnectivity.h>
#import <CoreLocation/CoreLocation.h>
#import "OASmartNaviWatchNavigationController.h"

@interface OASmartNaviWatchSession : NSObject <WCSessionDelegate> {

    NSObject *observer;
    OASmartNaviWatchNavigationController *navigationController;
    CLLocation *currentLocation;
    BOOL navigationUpdateNeeded;
    BOOL newNavigationDataAvailable;
    
}

/**
 *  singleton instance
 *
 *  @return self
 */
+ (id)sharedInstance;

/**
 *  whether or not the SmartNaviWatch plugin has been activated
 *
 *  @return true if activated
 */
-(BOOL)checkIfPluginEnabled;

/**
 *  activates the plugin and activates session
 */
-(void)activatePlugin;

/**
 *  deactivates the plugin and its session
 */
-(void)deactivatePlugin;

/**
 *  send rendered map images of the current location to the watch
 *
 *  @param imageData NSArray of UIImage images
 *  @param location  the location around which the map is rendered
 */
-(void)sendImageData:(NSArray*)imageData forLocation:(CLLocation*)location;

/**
 *  registers an observer such as the map panel for updates
 *
 *  @param observerToRegister observer to be registered
 */
-(void)registerObserverForUpdates:(NSObject*)observerToRegister;

/**
 *  Call this method when new location data has been acquired.
 *  The following criterias are relevant when it comes to the provided
 *  fix:
 *  speed > 1
 *  horizontal accuracy <= 50
 *  every 20 meters from the last provided valid fix, new distances and
 *  bearing on the current navigation route is calculated
 *
 *  @param newLocation the CLLocation fix
 */
-(void)updateSignificantLocationChange:(CLLocation*)newLocation;

/**
 *  takes a UIImage and scales it down to the given size
 *  further it compresses the images with jpg and converts
 *  into NSData
 *
 *  @param image   the image to be scaled and compressed
 *  @param newSize the target size of the scale down
 *
 *  @return NSData of the compressed and scaled image
 */
+ (NSData *)compressedImageDataWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

/**
 *  gathers all the current information such as current image data, location
 *  and navigation instructions
 */
-(void)initiateUpdate;

/**
 *  sets the active route of the OsmAnd navigation mode if any
 *  calculates new distances and bearings
 *  initiatesUpdate if forced
 *
 *  @param forced initiatesUpdate if true
 */
-(void)setActiveRouteWithForceRefresh:(BOOL)forced;

/**
 *  checks whether or not the watch extension is installed on the watch
 *
 *  @return true if installed
 */
-(BOOL)isAppInstalledOnWatch;

@end

