//
//  OABaseBigTitleSettingsViewController.h
//  OsmAnd
//
//  Created by Paul on 01.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OACompoundViewController.h"

@interface OABaseBigTitleSettingsViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *backImageButton;

- (NSString *) getTableHeaderTitle;
- (void) setTableHeaderView:(NSString *)label;
- (CGFloat) heightForLabel:(NSString *)text;

@end
