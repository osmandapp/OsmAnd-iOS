//
//  OAMappersViewController.h
//  OsmAnd
//
//  Created by Skalii on 05.09.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"

@protocol OAAccountSettingDelegate;

@interface OAMappersViewController : OABaseSettingsViewController

@property (nonatomic, weak) id<OAAccountSettingDelegate> accountDelegate;

@end
