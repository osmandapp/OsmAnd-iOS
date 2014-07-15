//
//  OADownloadsViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/1/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OADownloadsBaseViewController.h"
#import "OAMenuViewControllerProtocol.h"
#import "OADownloadsTabBarViewController.h"

@interface OADownloadsViewController : OADownloadsBaseViewController <OAMenuViewControllerProtocol, OADownloadsRefreshButtonDelegate>

@property(weak) UIViewController* menuHostViewController;

@end
