//
//  OADeleteAllVersionsBackupViewController.h
//  OsmAnd
//
//  Created by Skalii on 22.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseBigTitleSettingsViewController.h"

typedef NS_ENUM(NSInteger, EOADeleteBackupScreenType)
{
    EOADeleteAllDataBackupScreenType = 0,
    EOADeleteAllDataConfirmBackupScreenType,
    EOADeleteAllDataProgressBackupScreenType,
    EOARemoveOldVersionsBackupScreenType,
    EOARemoveOldVersionsProgressBackupScreenType
};

@protocol OADeleteAllVersionsBackupDelegate <NSObject>

@required

- (void)onCloseDeleteAllBackupData;
- (void)onAllFilesDeleted;

@end

@interface OADeleteAllVersionsBackupViewController : OABaseBigTitleSettingsViewController

- (instancetype)initWithScreenType:(EOADeleteBackupScreenType)screenType;

@property (nonatomic, weak) id<OADeleteAllVersionsBackupDelegate> deleteDelegate;

@end
