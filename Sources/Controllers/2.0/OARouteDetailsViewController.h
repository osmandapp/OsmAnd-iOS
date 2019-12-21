//
//  OAImpassableRoadViewController.h
//  OsmAnd
//
//  Created by Paul on 17/12/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATargetInfoViewController.h"

@interface OARouteDetailsViewController : OATargetMenuViewController <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UILabel *routeInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *elevationLabel;
@property (weak, nonatomic) IBOutlet UILabel *descentLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIImageView *eleUpImageView;
@property (weak, nonatomic) IBOutlet UIImageView *eleDownImageView;
@property (weak, nonatomic) IBOutlet UIView *bottomToolBarDividerView;

@end
