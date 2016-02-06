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
#import "OASmartNaviWatchConstants.h"

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


-(void)updateSignificantLocationChange:(CLLocation*)newLocation {
    if ([self checkIfPluginEnabled]) {
        
        //only take into account measurement if quality is sufficient enough
        if (newLocation.speed < 1 && (newLocation.horizontalAccuracy == 0.0 || newLocation.horizontalAccuracy > 50)) {
            //do nothing
            if (currentLocation == nil) {
                currentLocation = newLocation;
            }
        } else {
        if (currentLocation == nil) currentLocation = newLocation;
            double significantDistance = [currentLocation distanceFromLocation:newLocation];
            
            if (significantDistance >= 20) {
                currentLocation = newLocation;
                
                if ([navigationController calculateClosestWaypointIndexFromLocation:newLocation]) {
                    [self initiateUpdate];
                }
                

            }
           
        }
        
        
    }
}

-(void)sendImageData:(NSArray *)imageData forLocation:(CLLocation*)location {
    WCSession* session = [WCSession defaultSession];
    
    if (!session.watchAppInstalled) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connection error" message:@"Please install app on your Apple Watch." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
        
    }
    
    if (!session.isPaired) {
        
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Connection error" message:@"Please pair your Apple Watch with your iPhone." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        return;
        
    }
    
    //scale picture to device resolution in order to save data
    NSMutableDictionary *dataDict = [[NSMutableDictionary alloc] init];
    
    for (int i=0; i<imageData.count; ++i) {
        NSData *data = [OASmartNaviWatchSession compressedImageDataWithImage:(UIImage*)[imageData objectAtIndex:i] scaledToSize:CGSizeMake(140, 140)];
        if (data.length > 2200) {
            [dataDict setObject:data forKey:[NSString stringWithFormat:@"image%d",i]];
        } else {
            [dataDict setObject:@"1" forKey:OA_SMARTNAVIWATCH_KEY_LOCATION_ERROR_IMAGE_DATA];
        }
    }
    
    //request location info
    OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
    NSString *address = [mapPanel findRoadNameByLat:location.coordinate.latitude lon:location.coordinate.longitude];
        
    if (address != nil) {
        [dataDict setObject:address forKey:OA_SMARTNAVIWATCH_KEY_LOCATION_INFO];
        
    }
    
    //check if no active route
    if (!newNavigationDataAvailable) {
        [self setActiveRouteWithForceRefresh:NO];
    } else {
        newNavigationDataAvailable = NO;
    }
    
    //get routing data
    if (navigationUpdateNeeded) {
        NSDictionary *routingData = [navigationController getActiveRouteInfoForCurrentLocation:location];
        [dataDict setObject:routingData forKey:OA_SMARTNAVIWATCH_KEY_NAVIGATION_UPDATE];
    }
    
    [session sendMessage:dataDict
            replyHandler:^(NSDictionary *reply) {
                //handle reply from iPhone app here
            }
            errorHandler:^(NSError *error) {
                //TODO code == 7007
                // open Watch App in order to get navigation updates
                NSString *message;
                switch (error.code) {
                    case 7007: {
                        message = @"Please open the OsmAnd Watch App.";
                    }
                        

                        break;
                        
                    default:
                        break;
                }
                
                if (![message isEqualToString:@""]) {
//                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Error") message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
//                    [alertView show];
                }

            }
     ];
    

    }

-(void)setActiveRouteWithForceRefresh:(BOOL)forced {
    
    if (forced) {
        newNavigationDataAvailable = YES;
    }
    
    if (forced || [navigationController hasActiveRoute:currentLocation]) {
        [navigationController setActiveRouteForLocation:currentLocation];
        navigationController.currentIndexForRouting = -2;
        navigationUpdateNeeded = YES;
        if (currentLocation != nil) {
            [navigationController calculateClosestWaypointIndexFromLocation:currentLocation];
            if (forced) {
                [self initiateUpdate];
            }
        }
    } else {
        navigationUpdateNeeded = NO;
    }
    
}

-(void)initiateUpdate {
    [(OAMapViewController*)observer smartNaviWatchRequestLocationUpdate];
}



#pragma mark WCSessionDelegate

-(void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *,id> *)message {
    
    if ([message objectForKey:OA_SMARTNAVIWATCH_KEY_LOCATION_REQUEST]) {
        [self initiateUpdate];
    }
    
}

-(void)sessionReachabilityDidChange:(WCSession *)session {
    //handle reachability changes
}

#pragma helper methods

-(void)activatePlugin {
    if ([self checkIfPluginEnabled] && [WCSession isSupported]) {
        WCSession* session = [WCSession defaultSession];
        session.delegate = self;
        [session activateSession];
    }
}

-(void)deactivatePlugin {
    if ([WCSession isSupported]) {
        WCSession* session = [WCSession defaultSession];
        session.delegate = nil;
    }
}

-(BOOL)isAppInstalledOnWatch {
    return [[WCSession defaultSession] isWatchAppInstalled];
}


-(BOOL)checkIfPluginEnabled {
    return ![[OAIAPHelper sharedInstance] isProductDisabled:kInAppId_Addon_SmartNaviWatch];
}

+ (NSData *)compressedImageDataWithImage:(UIImage *)image scaledToSize:(CGSize)newSize {

    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    //use jpg compression in order to create smaller paylords, 40% compression quality
    NSData *compressedImageData= UIImageJPEGRepresentation(newImage,0.4);

    return compressedImageData;
}

@end