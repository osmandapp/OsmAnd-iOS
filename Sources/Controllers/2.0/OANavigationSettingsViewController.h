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
    kNavigationSettingsScreenPreferRouting,
    kNavigationSettingsScreenReliefFactor,
    kNavigationSettingsScreenRoutingParameter,
    kNavigationSettingsScreenAutoFollowRoute,
    kNavigationSettingsScreenAutoZoomMap,
    kNavigationSettingsScreenShowRoutingAlarms,
    kNavigationSettingsScreenSpeakRoutingAlarms,
    kNavigationSettingsScreenKeepInforming,
    kNavigationSettingsScreenArrivalDistanceFactor,
    kNavigationSettingsScreenSpeedSystem,
    kNavigationSettingsScreenSpeedLimitExceed,
    kNavigationSettingsScreenSwitchMapDirectionToCompass,
    kNavigationSettingsScreenWakeOnVoice,
    kNavigationSettingsScreenVoiceGudanceLanguage
    
} kNavigationSettingsScreen;

@class OAApplicationMode;

@interface OANavigationSettingsViewController : OASuperViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readonly) kNavigationSettingsScreen settingsType;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *appModeButton;

- (id) initWithSettingsType:(kNavigationSettingsScreen)settingsType;
- (id) initWithSettingsType:(kNavigationSettingsScreen)settingsType applicationMode:(OAApplicationMode *)applicationMode;


@end
