//
//  OASettingsBackupViewController.h
//  OsmAnd Maps
//
//  Created by Skalii on 20.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

@protocol OACloudAccountLogoutDelegate;
@protocol OABackupTypesDelegate;

@interface OASettingsBackupViewController : OACompoundViewController

@property (nonatomic, weak) id<OABackupTypesDelegate> backupTypesDelegate;

@end
