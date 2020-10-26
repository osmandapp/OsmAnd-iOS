//
//  OACheckForProfileDuplicatesViewController.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsWithBottomButtonsViewController.h"
#import "OASettingsHelper.h"

@interface OACheckForProfileDuplicatesViewController : OABaseSettingsWithBottomButtonsViewController

- (instancetype) initWithItems:(NSArray<OASettingsItem *> *)items file:(NSString *)file selectedItems:(NSArray<OASettingsItem *> *)selectedItems;
- (void) prepareToImport;

@end
