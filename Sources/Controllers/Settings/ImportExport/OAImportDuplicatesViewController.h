//
//  OAImportDuplicatesViewControllers.h
//  OsmAnd
//
//  Created by nnngrach on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"
#import "OASettingsHelper.h"

@interface OAImportDuplicatesViewController : OABaseButtonsViewController

@property (nonatomic) NSArray *duplicatesList;
@property (nonatomic) NSArray<OASettingsItem *> *settingsItems;

@property (nonatomic) NSString *screenTitle;
@property (nonatomic) NSString *screenDescription;

- (instancetype) initWithDuplicatesList:(NSArray *)duplicatesList settingsItems:(NSArray<OASettingsItem *> *)settingsItems file:(NSString *)file;

- (void) setupImportingUI;

@end
