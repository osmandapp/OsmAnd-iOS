//
//  OADestinationListViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

@interface OADestinationCardsViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

+ (OADestinationCardsViewController *)sharedInstance;

- (void)doViewAppear;
- (void)doViewDisappear;

@end
