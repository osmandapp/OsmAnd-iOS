//
//  OAProfileAppearanceViewController.h
//  OsmAnd
//
//  Created by Anna Bibyk on 17.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"
#import "OAApplicationMode.h"

@interface OAProfileAppearanceViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIView *profileIconView;
@property (weak, nonatomic) IBOutlet UIImageView *profileIconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

- (instancetype) initWithParentProfile:(OAApplicationMode *)profile;
- (instancetype) initWithProfile:(OAApplicationMode *)profile;

@end
