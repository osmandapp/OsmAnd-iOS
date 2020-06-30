//
//  OAAppSettingsViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 25.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//
#import "OACompoundViewController.h"

@interface OAAppSettingsViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIView *navbarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (CGFloat) heightForLabel:(NSString *)text;
- (void) setupTableHeaderViewWithText:(NSString *)text;

@end
