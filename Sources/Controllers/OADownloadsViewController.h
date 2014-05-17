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

@interface OADownloadsViewController : OADownloadsBaseViewController <OAMenuViewControllerProtocol>

@property(weak) UIViewController* menuHostViewController;

@end
