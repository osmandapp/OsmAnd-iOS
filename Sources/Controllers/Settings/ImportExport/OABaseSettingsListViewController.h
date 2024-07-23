//
//  OABaseSettingsListViewController.h
//  OsmAnd
//
//  Created by Paul on 08.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseButtonsViewController.h"
#import "OASettingsHelper.h"

NS_ASSUME_NONNULL_BEGIN

@class OAExportSettingsType, OAExportSettingsCategory, OASettingsCategoryItems, OATableCollapsableGroup;

typedef NS_ENUM(NSInteger, EOATableCollapsableGroup)
{
    EOATableCollapsableGroupMapSettingsRoutes = 0,
    EOATableCollapsableGroupMapSettingsOSM
};

@interface OATableCollapsableGroup : NSObject

@property NSString *type;
@property BOOL isOpen;
@property NSString *groupName;
@property NSMutableArray *groupItems;
@property EOATableCollapsableGroup groupType;

@end

@interface OABaseSettingsListViewController : OABaseButtonsViewController<OASettingsImportExportDelegate>

@property (nonatomic, readonly) BOOL exportMode;

@property (nonatomic, readonly) NSMutableDictionary<OAExportSettingsType *, NSArray *> *selectedItemsMap;
@property (nonatomic) NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *itemsMap;
@property (nonatomic) NSArray<OAExportSettingsCategory *> *itemTypes;
@property (nonatomic) NSArray<OATableCollapsableGroup *> *data;

- (NSArray *)getSelectedItems;
- (void)showActivityIndicatorWithLabel:(NSString *)labelText;
- (void)resetActivityIndicatorLabel;

- (long)calculateItemsSize:(NSArray *)items;
- (void)onGroupCheckmarkPressed:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
