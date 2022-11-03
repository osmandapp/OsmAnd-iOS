//
//  OABaseCloudBackupViewController.h
//  OsmAnd Maps
//
//  Created by Yuliia Stetsenko on 18.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OABaseBigTitleSettingsViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OATableSectionData;

@interface OABaseCloudBackupViewController : OABaseBigTitleSettingsViewController

- (NSDictionary *)getLocalBackupSectionData;
- (OATableSectionData *)getLocalBackupSectionDataObj;

- (void)onBackupIntoFilePressed;
- (void)onRestoreFromFilePressed;

@end

NS_ASSUME_NONNULL_END
