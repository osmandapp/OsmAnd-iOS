//
//  OAMapSettingsViewController.h
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 12.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASuperViewController.h"
#import "OACommonTypes.h"
#import "OADashboardViewController.h"
#import "OAMapSettingsScreen.h"


@interface OAMapSettingsViewController : OADashboardViewController

@property (nonatomic) id<OAMapSettingsScreen> screenObj;
@property (nonatomic, readonly) EMapSettingsScreen settingsScreen;

- (instancetype) initWithSettingsScreen:(EMapSettingsScreen)settingsScreen;
- (instancetype) initWithSettingsScreen:(EMapSettingsScreen)settingsScreen param:(id)param;

@end
