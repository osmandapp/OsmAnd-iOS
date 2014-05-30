//
//  OAShowDownloadsViewController.h
//  OsmAnd
//
//  Created by Feschenko Fedor on 5/25/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OAWorldRegion.h"

@interface OAShowDownloadsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
