//
//  OAShowUpdatesViewController.h
//  OsmAnd
//
//  Created by Feschenko Fedor on 5/28/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OADownloadsTabBarViewController.h"

@interface OAShowUpdatesViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, OADownloadsRefreshButtonDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
