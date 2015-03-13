//
//  OABrowseMapAppModeHudViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OADestinationViewController;

@interface OABrowseMapAppModeHudViewController : UIViewController<UIGestureRecognizerDelegate>

@property (nonatomic) OADestinationViewController *destinationViewController;

- (void)updateDestinationViewLayout;

@end
