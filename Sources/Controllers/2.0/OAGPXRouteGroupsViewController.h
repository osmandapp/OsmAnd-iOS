//
//  OAGPXRouteGroupsViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 10/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

@protocol OAGPXRouteGroupsViewControllerDelegate <NSObject>

- (void)routeGroupsChanged;

@end

@interface OAGPXRouteGroupsViewController : OASuperViewController<UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;

@property (weak, nonatomic) id<OAGPXRouteGroupsViewControllerDelegate> delegate;

@end
