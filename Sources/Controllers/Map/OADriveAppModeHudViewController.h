//
//  OADriveAppModeHudViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OADestinationViewController;

@interface OADriveAppModeHudViewController : UIViewController

@property (nonatomic) OADestinationViewController *destinationViewController;

- (void)updateDestinationViewLayout;

@end
