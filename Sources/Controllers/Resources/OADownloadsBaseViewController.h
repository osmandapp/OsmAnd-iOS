//
//  OADownloadsBaseViewController.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 5/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OAWorldRegion.h"

@interface OADownloadsBaseViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property(weak, nonatomic) IBOutlet UITableView *tableView;

@property OAWorldRegion* worldRegion;

- (void)reloadList;
- (void)loadDynamicContent;

@end
