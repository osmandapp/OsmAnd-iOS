//
//  OAImportComplete.h
//  OsmAnd
//
//  Created by nnngrach on 19.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseSettingsWithBottomButtonsViewController.h"
#import "OASettingsHelper.h"

@interface OAImportCompleteViewController : OABaseSettingsWithBottomButtonsViewController

- (instancetype) initWithSettingsItems:(NSArray<OASettingsItem *> *)settingsItems fileName:(NSString *)fileName;

@end
