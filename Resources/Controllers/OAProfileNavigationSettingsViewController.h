//
//  OAProfileNavigationSettingsViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 22.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAAppSettingsViewController.h"

typedef enum
{
    kProfileNavigationSettingsScreenGeneral = 0,
    kProfileNavigationSettingsScreenNavigationType,
    kProfileNavigationSettingsScreenRouteParameter,
    kProfileNavigationSettingsScreenVoicePrompts,
    kProfileNavigationSettingsScreenScreenAlerts,
    kProfileNavigationSettingsScreenVehicleParameters,
    kProfileNavigationSettingsScreenMapBehavior
} kProfileNavigationSettingsScreen;


@interface OAProfileNavigationSettingsViewController : OAAppSettingsViewController

//@property (weak, nonatomic) IBOutlet UIView *navBarView;
//@property (weak, nonatomic) IBOutlet UIButton *backButton;
//@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
//@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
//@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, readonly) kProfileNavigationSettingsScreen settingsType;


@end
