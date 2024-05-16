//
//  OAExportItemsViewController.h
//  OsmAnd
//
//  Created by Paul on 08.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseSettingsListViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OAApplicationMode;

@interface OAExportItemsViewController : OABaseSettingsListViewController

- (instancetype) initWithAppMode:(OAApplicationMode *)appMode hostVC:(UIViewController *)hostVC;
- (instancetype) initWithTracks:(NSArray<NSString *> *)tracks hostVC:(UIViewController *)hostVC;
- (instancetype) initWithType:(OAExportSettingsType *)type selectedItems:(NSArray *)selectedItems hostVC:(UIViewController *)hostVC;
- (instancetype) initWithTypes:(NSDictionary<OAExportSettingsType *, NSArray<id> *> *)typesItems hostVC:(UIViewController *)hostVC;

@end

NS_ASSUME_NONNULL_END
