//
//  OABaseCloudBackupViewController.h
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 18.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseBigTitleSettingsViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface OABaseCloudBackupViewController : OABaseBigTitleSettingsViewController

- (NSDictionary *)getLocalBackupSectionData;

- (void)onBackupIntoFilePressed;
- (void)onRestoreFromFilePressed;

@end

NS_ASSUME_NONNULL_END
