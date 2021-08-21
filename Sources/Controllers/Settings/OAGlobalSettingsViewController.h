//
//  OAGlobalSettingsViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.07.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

typedef enum
{
    EOAGlobalSettingsMain = 0,
    EOADefaultProfile,
    EOACarplayProfile,
    EOADialogsAndNotifications
} EOAGlobalSettingsScreen;

@interface OAGlobalSettingsViewController : OACompoundViewController

@property (weak, nonatomic) IBOutlet UIView *navbarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, readonly) EOAGlobalSettingsScreen settingsType;

- (instancetype) initWithSettingsType:(EOAGlobalSettingsScreen)settingsType;

@end

