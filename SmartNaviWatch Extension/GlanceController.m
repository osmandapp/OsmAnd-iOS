//
//  GlanceController.m
//  SmartNaviWatch Extension
//
//  Created by egloff on 16/12/15.
//  Copyright © 2015 OsmAnd. All rights reserved.
//

#import "GlanceController.h"
#import "ExtensionDelegate.h"
#import "OASmartNaviWatchConstants.h"


@interface GlanceController()

@end


@implementation GlanceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    //register observer for changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI)
                                                 name:OA_SMARTNAVIWATCH_NOTIFICATION_LOCATION_CHANGED
                                               object:nil];}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    [self updateUI];
    
    //send location request
    ExtensionDelegate *delegate = (ExtensionDelegate*)([WKExtension sharedExtension].delegate);
    [delegate sendLocationRequest];
    
}

-(void)updateUI {
    ExtensionDelegate *delegate = (ExtensionDelegate*)([WKExtension sharedExtension].delegate);
    
    if (delegate.imageData.count > 0) {
        
        [self.mapImage setImageData:[delegate.imageData objectAtIndex:0]];
        [self.locationTitle setText:delegate.locationInfo];
        
    }

}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



