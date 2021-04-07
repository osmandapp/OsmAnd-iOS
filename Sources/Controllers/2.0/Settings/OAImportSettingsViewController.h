//
//  OAImportProfileViewController.h
//  OsmAnd
//
//  Created by Anna Bibyk on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsWithBottomButtonsViewController.h"
#import "OASettingsHelper.h"

@interface OAImportSettingsViewController : OABaseSettingsWithBottomButtonsViewController

- (instancetype) initWithItems:(NSArray<OASettingsItem *> *)items;

- (void)onItemsCollected:(NSArray<OASettingsItem *> *)items;

@end
