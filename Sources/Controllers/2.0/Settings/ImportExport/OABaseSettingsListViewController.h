//
//  OABaseSettingsListViewController.h
//  OsmAnd
//
//  Created by Paul on 08.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OABaseSettingsWithBottomButtonsViewController.h"
#import "OASettingsHelper.h"

NS_ASSUME_NONNULL_BEGIN

@class OAExportSettingsType, OAExportSettingsCategory, OASettingsCategoryItems, OATableGroupToImport;

@interface OATableGroupToImport : NSObject

    @property NSString* type;
    @property BOOL isOpen;
    @property NSString* groupName;
    @property NSMutableArray* groupItems;

@end

@interface OABaseSettingsListViewController : OABaseSettingsWithBottomButtonsViewController <OASettingsImportExportDelegate>

@property (nonatomic, readonly) BOOL exportMode;

@property (nonatomic, readonly) NSString *descriptionBoldText;
@property (nonatomic, readonly) NSString *descriptionText;

@property (nonatomic, readonly) NSMutableDictionary<OAExportSettingsType *, NSArray *> *selectedItemsMap;
@property (nonatomic) NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *itemsMap;
@property (nonatomic) NSArray<OAExportSettingsCategory *> *itemTypes;
@property (nonatomic) NSArray<OATableGroupToImport *> *data;

- (NSArray *)getSelectedItems;
- (void)showActivityIndicatorWithLabel:(NSString *)labelText;

- (void)generateData;

- (void)updateControls;
- (long)calculateItemsSize:(NSArray *)items;
- (void)onGroupCheckmarkPressed:(UIButton *)sender;

@end

NS_ASSUME_NONNULL_END
