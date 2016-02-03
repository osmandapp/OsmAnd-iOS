//
//  NavigationController.m
//  OsmAnd
//
//  Created by egloff on 23/01/16.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "NavigationController.h"
#import "ExtensionDelegate.h"
#import "OASmartNaviWatchNavigationWaypoint.h"
#import "NavigationItem.h"
#import "OASmartNaviWatchConstants.h"

@implementation NavigationController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(initRouteData)
                                                 name:OA_SMARTNAVIWATCH_NOTIFICATION_INIT_ROUTE_DATA
                                               object:nil];
    
    [self initRouteData];
    
    errorMessageShown = NO;

    
}

-(void)initTableData {
    
    ExtensionDelegate *delegate = (ExtensionDelegate*)([WKExtension sharedExtension].delegate);
    
    if (delegate.waypoints != nil && delegate.waypoints.count > 0) {
        
        [self.navigationTable setNumberOfRows:delegate.waypoints.count withRowType:@"NavigationItemId"];
        
        NSLog(@"init table with size %d", self.navigationTable.numberOfRows);
        
        // Iterate over the rows and set the label for each one
        for (NSInteger i = 0; i < delegate.waypoints.count; i++) {
            
            // Get the data for this item
            OASmartNaviWatchNavigationWaypoint *wp = [delegate.waypoints objectAtIndex:i];
            
            // Assign all the data to the row's view
            NavigationItem* row = [self.navigationTable rowControllerAtIndex:i];
            
            [row.nameLabel setText:wp.name];
            [row.distanceLabel setText:[NSString stringWithFormat:@"%.f m", wp.distance]];
            
            UIImage *bearingImageFile = [UIImage imageNamed:[NSString stringWithFormat:@"map_pedestrian_bearing_%.f.png",wp.bearing]];
            [row.bearingImage setImage:bearingImageFile];
            
        }
        
        [self scrollToCurrentIndex];

        
    }
    
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    
    [self scrollToCurrentIndex];
    
}

-(void)scrollToCurrentIndex {
    ExtensionDelegate *delegate = (ExtensionDelegate*)([WKExtension sharedExtension].delegate);
    // scroll to current index
    [self.navigationTable scrollToRowAtIndex:[delegate.currentNavigationIndex integerValue]];
}

-(void)initRouteData {
    
    ExtensionDelegate *delegate = (ExtensionDelegate*)([WKExtension sharedExtension].delegate);
    if (delegate.currentNavigationTitle != nil) {
        [self setTitle:delegate.currentNavigationTitle];
    }
    
    //check if data available
    if (delegate.waypoints != nil && delegate.waypoints.count > 0) {
        [self initTableData];
    } else {
        if (!errorMessageShown) {
            [self presentControllerWithName:@"ErrorMessageController" context:@"Please plan a trip on OsmAnd on your iPhone."];
            errorMessageShown = YES;
        }
        
    }

    

}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
    
}

@end
