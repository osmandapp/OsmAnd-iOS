//
//  OANavigationSettingsViewController.h
//  OsmAnd
//
//  Created by Alexey Kulish on 07/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

typedef enum
{
    kNavigationSettingsScreenGeneral = 0,
    kNavigationSettingsScreenAvoidRouting,
    
} kNavigationSettingsScreen;

@interface OANavigationSettingsViewController : OASuperViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readonly) kNavigationSettingsScreen settingsType;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;

- (id) initWithSettingsType:(kNavigationSettingsScreen)settingsType;


@end
