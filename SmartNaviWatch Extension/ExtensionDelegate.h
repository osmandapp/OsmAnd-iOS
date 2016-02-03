//
//  ExtensionDelegate.h
//  SmartNaviWatch Extension
//
//  Created by egloff on 16/12/15.
//  Copyright © 2015 OsmAnd. All rights reserved.
//

#import <WatchKit/WatchKit.h>
@import WatchConnectivity;

@interface ExtensionDelegate : NSObject <WKExtensionDelegate, WCSessionDelegate> {
    
    NSInteger numberOfPages;
        
}

@property (nonatomic, retain) NSMutableArray *imageData;
@property (nonatomic, retain) NSString *locationInfo;
@property (nonatomic, retain) NSArray *waypoints;
@property (nonatomic, retain) NSString *currentNavigationTitle;
@property (nonatomic, retain) NSNumber *currentNavigationIndex;
@property (nonatomic, assign) BOOL mapInitialized;

-(void)sendLocationRequest;

@end
