//
//  OABaseBackupTypesViewController.h
//  OsmAnd Maps
//
//  Created by Skalii on 25.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseSettingsViewController.h"
#import "OABackupListeners.h"
#import "OAPrepareBackupTask.h"
#import "OAManageTypeViewController.h"

@class OAExportSettingsType, OAExportSettingsCategory, OASettingsCategoryItems;

@protocol OABackupTypesDelegate <NSObject>

@required

- (void)onCompleteTasks;
- (void)setProgressTotal:(NSInteger)total;

@end

@interface OABaseBackupTypesViewController : OABaseSettingsViewController <OAManageTypeDelegate, OAOnDeleteFilesListener, OAOnPrepareBackupListener, OABackupTypesDelegate>

- (void)commonInit;

- (NSMutableDictionary<OAExportSettingsType *, NSArray *> *)getSelectedItems;
- (NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *)getDataItems;

- (void)onTypeSelected:(OAExportSettingsType *)type selected:(BOOL)selected;
- (NSArray *)getItemsForType:(OAExportSettingsType *)type;

+ (NSInteger)calculateItemsSize:(NSArray *)items;

- (NSIndexPath *)getSelectedIndexPath;
- (void)setData:(NSMutableArray<NSMutableDictionary *> *)data;
- (NSMutableDictionary *)getItem:(NSIndexPath *)indexPath;

@property (nonatomic, weak) id<OABackupTypesDelegate> backupTypesDelegate;

@end
