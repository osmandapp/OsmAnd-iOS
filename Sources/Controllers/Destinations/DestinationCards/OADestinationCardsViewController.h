//
//  OADestinationListViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 11/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

@interface OADestinationCardsViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *cardsView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIToolbar *bottomToolBar;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *historyViewButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *appearanceViewButton;

@property (nonatomic, readonly) BOOL isVisible;
@property (nonatomic, readonly) BOOL isHiding;

+ (OADestinationCardsViewController *)sharedInstance;

- (void)doViewWillDisappear;

@end
