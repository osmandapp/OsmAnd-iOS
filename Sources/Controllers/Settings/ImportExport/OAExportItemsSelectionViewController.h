//
//  OAExportItemsSelectionViewController.h
//  OsmAnd
//
//  Created by Paul on 31.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACompoundViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class OAExportSettingsType;

@protocol OASettingItemsSelectionDelegate

- (void) onItemsSelected:(NSArray *)items type:(OAExportSettingsType *)type;

@end

@interface OAExportItemsSelectionViewController : OACompoundViewController

@property (nonatomic, weak) id<OASettingItemsSelectionDelegate> delegate;

- (instancetype) initWithItems:(NSArray *)items type:(OAExportSettingsType *)type selectedItems:(NSArray *)selectedItems;

@end

NS_ASSUME_NONNULL_END
