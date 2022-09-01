//
//  OAManageTypeViewController.h
//  OsmAnd
//
//  Created by Skalii on 26.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseBigTitleSettingsViewController.h"

@class OAExportSettingsType, OASettingsCategoryItems;

@protocol OAManageTypeDelegate <NSObject>

@required

- (void)onDeleteTypeData:(OAExportSettingsType *)settingsType;

@end

@interface OAManageTypeViewController : OABaseBigTitleSettingsViewController

- (instancetype)initWithSettingsType:(OAExportSettingsType *)settingsType size:(NSString *)size;

@property (nonatomic, weak) id<OAManageTypeDelegate> manageTypeDelegate;

@end
