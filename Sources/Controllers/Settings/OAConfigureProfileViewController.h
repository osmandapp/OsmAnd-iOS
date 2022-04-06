//
//  OAConfigureProfileViewController.h
//  OsmAnd
//
//  Created by Paul on 01.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseBigTitleSettingsViewController.h"

#define kGeneralSettings @"general_settings"
#define kNavigationSettings @"nav_settings"
#define kProfileAppearanceSettings @"profile_appearance"
#define kExportProfileSettings @"export_profile"
#define kTrackRecordingSettings @"trip_rec"
#define kOsmEditsSettings @"osm_edits"
#define kWeatherSettings @"weather"

@class OAApplicationMode;

@interface OAConfigureProfileViewController : OABaseBigTitleSettingsViewController

- (instancetype) initWithAppMode:(OAApplicationMode *)mode targetScreenKey:(NSString *)targetScreenKey;

@end
