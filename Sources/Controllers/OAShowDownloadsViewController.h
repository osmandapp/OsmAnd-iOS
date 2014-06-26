//
//  OAShowDownloadsViewController.h
//  OsmAnd
//
//  Created by Feschenko Fedor on 5/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OADownloadsTabBarController.h"

#import "OAWorldRegion.h"

@interface OAShowDownloadsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, OADownloadsRefreshButtonDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
