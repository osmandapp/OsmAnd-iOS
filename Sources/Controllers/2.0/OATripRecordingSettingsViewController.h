//
//  OATripRecordingSettingsViewController.h
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

typedef enum
{
    kTripRecordingSettingsScreenGeneral = 0,
    kTripRecordingSettingsScreenRecInterval,
    kTripRecordingSettingsScreenNavRecInterval,
    kTripRecordingSettingsScreenMinDistance,
    kTripRecordingSettingsScreenAccuracy,
    kTripRecordingSettingsScreenMinSpeed
    //TODO add settings
} kTripRecordingSettingsScreen;

@class OAApplicationMode;

@interface OATripRecordingSettingsViewController : OACompoundViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readonly) kTripRecordingSettingsScreen settingsType;
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *appModeButton;

- (id) initWithSettingsType:(kTripRecordingSettingsScreen)settingsType;
- (id) initWithSettingsType:(kTripRecordingSettingsScreen)settingsType applicationMode:(OAApplicationMode *)applicationMode;

@end
