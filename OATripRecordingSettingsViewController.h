//
//  OATripRecordingSettingsViewController.h
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"

typedef enum
{
    kTripRecordingSettingsScreenGeneral = 0,
    kTripRecordingSettingsScreenRecInterval,
    kTripRecordingSettingsScreenNavRecInterval
    //TODO add settings
    
} kTripRecordingSettingsScreen;

@class OAApplicationMode;

@interface OATripRecordingSettingsViewController : OASuperViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readonly) kTripRecordingSettingsScreen settingsType;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *appModeButton;

- (id) initWithSettingsType:(kTripRecordingSettingsScreen)settingsType;
- (id) initWithSettingsType:(kTripRecordingSettingsScreen)settingsType applicationMode:(OAApplicationMode *)applicationMode;

@end
