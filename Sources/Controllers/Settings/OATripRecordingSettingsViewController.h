//
//  OATripRecordingSettingsViewController.h
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

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

@interface OATripRecordingSettingsViewController : OABaseSettingsViewController<UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, readonly) kTripRecordingSettingsScreen settingsType;

- (id) initWithSettingsType:(kTripRecordingSettingsScreen)settingsType applicationMode:(OAApplicationMode *)applicationMode;

@end
