//
//  OAMainSettingsViewController.h
//  OsmAnd
//
//  Created by Paul on 07.30.2020
//  Copyright (c) 2020 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@class OAApplicationMode;

@interface OAMainSettingsViewController : OACompoundViewController<UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *settingsTableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

- (instancetype) initWithTargetAppMode:(OAApplicationMode *)mode targetScreenKey:(NSString *)targetScreenKey;

@end
