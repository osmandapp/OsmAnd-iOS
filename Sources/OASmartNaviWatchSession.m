//
//  OASmartNaviWatchSession.m
//  OsmAnd
//
//  Created by egloff on 18/12/15.
//  Copyright © 2015 OsmAnd. All rights reserved.
//

#import "OASmartNaviWatchSession.h"
#import "OAIAPHelper.h"
#import "OATargetPointView.h"
#import "OAMapViewController.h"
#import "OADestinationsHelper.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"

@implementation OASmartNaviWatchSession

#pragma mark Singleton Methods

+ (id)sharedInstance {
    static OASmartNaviWatchSession *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    if (self = [super init]) {
        //init properties here
        navigationController = [[OASmartNaviWatchNavigationController alloc] init];
    }
    return self;
}

-(void)registerObserverForUpdates:(NSObject*)observerToRegister {
    observer = observerToRegister;
}

-(void)activatePlugin {
    if ([self checkIfPluginEnabled] && [WCSession isSupported]) {
        WCSession* session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
}

-(BOOL)isAppInstalledOnWatch {
    return [[WCSession defaultSession] isWatchAppInstalled];
}


-(BOOL)checkIfPluginEnabled {
    return ![[OAIAPHelper sharedInstance] isProductDisabled:kInAppId_Addon_SmartNaviWatch];
}

-(void)sendImageData:(NSArray *)imageData forLocation:(CLLocation*)location {
    WCSession* session = [WCSession defaultSession];
    
    if (session.watchAppInstalled) {
        //TODO show message
    }
    
    //scale picture to device resolution in order to save data
    
        if (session.isPaired) {
            
            NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] init];

            for (int i=0; i<imageData.count; ++i) {
                NSData *data = [OASmartNaviWatchSession imageDataWithImage:(UIImage*)[imageData objectAtIndex:i] scaledToSize:CGSizeMake(140, 140)];
                [dataDict setObject:data forKey:[NSString stringWithFormat:@"image%d",i]];
            }
            
            //request location info
            OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
            NSString *address = [mapPanel findRoadNameByLat:location.coordinate.latitude lon:location.coordinate.longitude];

            if (address != nil) {
                [dataDict setObject:address forKey:@"locationInfo"];

            }
            
            //TODO move this to some other method

            
            

            //get routing data
            NSDictionary *routingData = [navigationController getActiveRouteInfoForCurrentLocation:location.coordinate];
            
//            [dataDict setObject:routingData forKey:@"routingInfo"];
            
            [session sendMessage:dataDict
                    replyHandler:^(NSDictionary *reply) {
                        //handle reply from iPhone app here
                    }
                    errorHandler:^(NSError *error) {
                        //catch any errors here
                    }
             ];
        }

    }
    





#pragma mark WCSessionDelegate

-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message {
    
    if ([message objectForKey:@"locationRequest"]) {
        //TODO render location image
//        [self sendImageData:nil];
//        [(OATargetPointView*)observer smartNaviWatchRequestLocationUpdate];
        [(OAMapViewController*)observer smartNaviWatchRequestLocationUpdate];
    }
    
}

-(void)sessionReachabilityDidChange:(WCSession *)session {
    //TODO
}

#pragma helper methods
+ (NSData *)imageDataWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *compressedImageData= UIImageJPEGRepresentation(newImage,0.5 /*compressionQuality*/);

    return compressedImageData;
}

@end