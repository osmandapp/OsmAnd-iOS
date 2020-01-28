//
//  OAImpassableRoadSelectionViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 06/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARouteBaseViewController.h"

@interface OAImpassableRoadSelectionViewController : OARouteBaseViewController <UITableViewDataSource, UITableViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UILabel *routeInfoLabel;
@property (weak, nonatomic) IBOutlet UILabel *elevationLabel;
@property (weak, nonatomic) IBOutlet UILabel *descentLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *clearAllButton;
@property (weak, nonatomic) IBOutlet UIButton *selectButton;
@property (weak, nonatomic) IBOutlet UIImageView *eleUpImageView;
@property (weak, nonatomic) IBOutlet UIImageView *eleDownImageView;
@property (weak, nonatomic) IBOutlet UIView *bottomToolBarDividerView;


@end
