//
//  OASmartNaviWatchSession.h
//  OsmAnd
//
//  Created by egloff on 18/12/15.
//  Copyright © 2015 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WatchConnectivity/WatchConnectivity.h>

@interface OASmartNaviWatchSession : NSObject <WCSessionDelegate> {
    //properties
    NSObject *observer;
}

//@property (nonatomic, retain) NSString *someProperty;

+ (id)sharedInstance;

-(BOOL)checkIfPluginEnabled;
-(void)activatePlugin;
-(void)sendData:(NSData*)data;
-(void)sendImageData:(NSArray*)imageData;
-(void)registerObserverForUpdates:(NSObject*)observerToRegister;

+ (NSData *)imageDataWithImage:(UIImage *)image scaledToSize:(CGSize)newSize;

@end

