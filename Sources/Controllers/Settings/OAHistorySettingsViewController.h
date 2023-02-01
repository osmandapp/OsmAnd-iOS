//
//  OAHistorySettingsViewController.h
//  OsmAnd Maps
//
//  Created by ДМИТРИЙ СВЕТЛИЧНЫЙ on 30.01.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

typedef enum
{
    EOASearchHistoryProfile,
    EOANavigationHistoryProfile,
    EOAMarkersHistoryProfile
} EOAGlobalSettingsHistoryScreen;

@interface OAHistorySettingsViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *editButton;
@property (weak, nonatomic) IBOutlet UIButton *selectAllButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *editToolbarView;
@property (weak, nonatomic) IBOutlet UIButton *exportButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (nonatomic, readonly) EOAGlobalSettingsHistoryScreen settingsType;

- (instancetype) initWithSettingsType:(EOAGlobalSettingsHistoryScreen)settingsType;

@end
