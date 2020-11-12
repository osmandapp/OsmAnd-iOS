//
//  OAImportDuplicatesViewControllers.h
//  OsmAnd
//
//  Created by nnngrach on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsWithBottomButtonsViewController.h"
#import "OASettingsHelper.h"

@interface OAImportDuplicatesViewController : OABaseSettingsWithBottomButtonsViewController

- (instancetype) initWithDuplicatesList:(NSArray *)duplicatesList settingsItems:(NSArray<OASettingsItem *> *)settingsItems file:(NSString *)file;

@end
