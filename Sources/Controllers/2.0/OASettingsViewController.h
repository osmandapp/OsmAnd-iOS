//
//  OASettingsViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

typedef enum
{
    kSettingsScreenMain = 0,
    kSettingsScreenGeneral,
    kSettingsScreenNavigation,
    kSettingsScreenAppMode,
    kSettingsScreenRotateMap,
    kSettingsScreenDrivingRegion,
    kSettingsScreenMetricSystem,
    kSettingsScreenGeoCoords,
    
} kSettingsScreen;

@interface OASettingsViewController : OASuperViewController<UITableViewDelegate, UITableViewDataSource>

- (id) initWithSettingsType:(kSettingsScreen)settingsType;

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *settingsTableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (nonatomic, readonly) kSettingsScreen settingsType;

@end
