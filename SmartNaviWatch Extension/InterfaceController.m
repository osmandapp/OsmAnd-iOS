//
//  InterfaceController.m
//  SmartNaviWatch Extension
//
//  Created by egloff on 16/12/15.
//  Copyright © 2015 OsmAnd. All rights reserved.
//

#import "InterfaceController.h"
#import "ExtensionDelegate.h"
#import "OASmartNaviWatchConstants.h"

@interface InterfaceController()

@end


@implementation InterfaceController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];

    // Configure interface objects here.
    
    //register observer for changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateUI)
                                                 name:OA_SMARTNAVIWATCH_NOTIFICATION_LOCATION_CHANGED
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(showMessage)
                                                 name:OA_SMARTNAVIWATCH_NOTIFICATION_SHOW_MESSAGE
                                               object:nil];

    
    ExtensionDelegate *delegate = (ExtensionDelegate*)([WKExtension sharedExtension].delegate) ;

    if (!delegate.mapInitialized) {
        [self sendLocationRequest];
    }
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    [self updateUI];

    
}

-(void)updateUI {
    
    ExtensionDelegate *delegate = (ExtensionDelegate*)([WKExtension sharedExtension].delegate) ;
    if (delegate.imageData != nil) {
        NSMutableArray *pickerItems = [[NSMutableArray alloc] initWithCapacity:delegate.imageData.count];
        if (delegate.imageData != nil && delegate.imageData.count == 3) {
            
            for (int i=0; i<delegate.imageData.count; ++i) {
                
                WKPickerItem *item = [[WKPickerItem alloc] init];
                [item setContentImage:[WKImage imageWithImageData:[delegate.imageData objectAtIndex:i]]];
                [pickerItems addObject:item];
                
            }
        }
        
        [self.mapImages setItems:pickerItems];
        errorMessageShown = NO;
        
    } else {
        
        if (!errorMessageShown) {
            [self showMessage];
            errorMessageShown = YES;
        }
       
        
    }
    
    
    [self setTitle:delegate.locationInfo];
    
    
}

-(void)showMessage {
    [self presentControllerWithName:@"ErrorMessageController" context:@"Please open the map view on OsmAnd on your iPhone."];
}

- (IBAction)onMenuItemShowLocation {
    
    [self sendLocationRequest];

}

-(void)sendLocationRequest {
    
    errorMessageShown = NO;
    
    //send location request
    ExtensionDelegate *delegate = (ExtensionDelegate*)([WKExtension sharedExtension].delegate) ;
    [delegate sendLocationRequest];
    
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



