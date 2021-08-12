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
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftTableViewPadding;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *rightTableViewPadding;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet UIToolbar *bottomToolBar;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *leftToolbarPadding;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *rightToolbarPadding;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *historyViewButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *appearanceViewButton;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *toolBarHeight;

@property (nonatomic, readonly) BOOL isVisible;
@property (nonatomic, readonly) BOOL isHiding;

+ (OADestinationCardsViewController *)sharedInstance;

- (void)doViewWillDisappear;

@end
