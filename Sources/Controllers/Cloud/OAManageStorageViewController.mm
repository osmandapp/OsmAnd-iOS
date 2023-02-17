//
//  OABackupTypesViewController.mm
//  OsmAnd Maps
//
//  Created by Skalii on 25.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OAManageStorageViewController.h"
#import "OAIconTitleValueCell.h"
#import "OAStorageStateValuesCell.h"
#import "OAExportSettingsCategory.h"
#import "OAExportSettingsType.h"
#import "OASettingsCategoryItems.h"
#import "OAPrepareBackupResult.h"
#import "OABackupHelper.h"
#import "OAColors.h"
#import "Localization.h"

@implementation OAManageStorageViewController
{
    OABackupHelper *_backupHelper;
}

#pragma mark - Initialization

- (void)commonInit
{
    _backupHelper = [OABackupHelper sharedInstance];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"manage_storage");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"backup_data");
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *data = [NSMutableArray array];

    NSMutableArray<NSMutableDictionary *> *manageStorageCells = [NSMutableArray array];
    NSMutableDictionary *manageStorageSection = [NSMutableDictionary dictionary];
    manageStorageSection[@"cells"] = manageStorageCells;
    [data addObject:manageStorageSection];

    NSMutableDictionary *manageStorageProgressData = [NSMutableDictionary dictionary];
    manageStorageProgressData[@"key"] = @"manage_storage_progress_cell";
    manageStorageProgressData[@"type"] = [OAStorageStateValuesCell getCellIdentifier];
    manageStorageProgressData[@"show_description"] = @(NO);
    [manageStorageCells addObject:manageStorageProgressData];

    NSMutableDictionary *resourcesData = [NSMutableDictionary dictionary];
    resourcesData[@"key"] = @"resources_storage_cell";
    resourcesData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
    resourcesData[@"title"] = OALocalizedString(@"shared_string_resources");
    resourcesData[@"has_empty_icon"] = @(YES);
    resourcesData[@"icon_color"] = UIColorFromRGB(backup_restore_icons_blue);
    [manageStorageCells addObject:resourcesData];

    NSMutableDictionary *myPlacesData = [NSMutableDictionary dictionary];
    myPlacesData[@"key"] = @"my_places_storage_cell";
    myPlacesData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
    myPlacesData[@"title"] = OALocalizedString(@"shared_string_my_places");
    myPlacesData[@"has_empty_icon"] = @(YES);
    myPlacesData[@"icon_color"] = UIColorFromRGB(backup_restore_icons_yellow);
    [manageStorageCells addObject:myPlacesData];

    NSMutableDictionary *settingsData = [NSMutableDictionary dictionary];
    settingsData[@"key"] = @"settings_storage_cell";
    settingsData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
    settingsData[@"title"] = OALocalizedString(@"shared_string_settings");
    settingsData[@"has_empty_icon"] = @(YES);
    settingsData[@"icon_color"] = UIColorFromRGB(backup_restore_icons_green);
    [manageStorageCells addObject:settingsData];

    NSMutableArray<NSMutableDictionary *> *myPlacesCells = [NSMutableArray array];
    NSMutableDictionary *myPlacesSection = [NSMutableDictionary dictionary];
    myPlacesSection[@"header"] = OALocalizedString(@"shared_string_my_places");
    myPlacesSection[@"cells"] = myPlacesCells;
    [data addObject:myPlacesSection];

    NSMutableArray<NSMutableDictionary *> *resourcesCells = [NSMutableArray array];
    NSMutableDictionary *resourcesSection = [NSMutableDictionary dictionary];
    resourcesSection[@"header"] = OALocalizedString(@"shared_string_resources");
    resourcesSection[@"cells"] = resourcesCells;
    [data addObject:resourcesSection];

    NSMutableArray<NSMutableDictionary *> *settingsCells = [NSMutableArray array];
    NSMutableDictionary *settingsSection = [NSMutableDictionary dictionary];
    settingsSection[@"header"] = OALocalizedString(@"shared_string_settings");
    settingsSection[@"cells"] = settingsCells;
    [data addObject:settingsSection];

    NSInteger resourcesSize = 0;
    NSInteger myPlacesSize = 0;
    NSInteger settingsSize = 0;
    for (OAExportSettingsCategory *category in [self getDataItems].allKeys)
    {
        OASettingsCategoryItems *categoryItems = [self getDataItems][category];
        for (OAExportSettingsType *type in [categoryItems getTypes])
        {
            NSInteger size = [self.class calculateItemsSize:[categoryItems getItemsForType:type]];
            if (size > 0)
            {
                NSMutableDictionary *itemData = [NSMutableDictionary dictionary];
                itemData[@"key"] = [type.name stringByAppendingString:@"_cell"];
                itemData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
                itemData[@"setting"] = type;
                itemData[@"description"] = [NSByteCountFormatter stringFromByteCount:size
                                                                          countStyle:NSByteCountFormatterCountStyleFile];

                if (type.isMyPlacesCategory)
                {
                    [myPlacesCells addObject:itemData];
                    myPlacesSize += size;
                }
                else if (type.isResourcesCategory)
                {
                    [resourcesCells addObject:itemData];
                    resourcesSize += size;
                }
                else if (type.isSettingsCategory)
                {
                    [settingsCells addObject:itemData];
                    settingsSize += size;
                }
            }
        }
    }

    NSInteger totalSize = [_backupHelper getMaximumAccountSize];
    NSString *totalSizeStr = [NSByteCountFormatter stringFromByteCount:[_backupHelper getMaximumAccountSize]
                                                            countStyle:NSByteCountFormatterCountStyleFile];
    NSString *usedSizeStr = [NSByteCountFormatter stringFromByteCount:resourcesSize + myPlacesSize + settingsSize
                                                           countStyle:NSByteCountFormatterCountStyleFile];
    manageStorageProgressData[@"title"] = [NSString stringWithFormat:OALocalizedString(@"cloud_storage_used"), usedSizeStr, totalSizeStr];
    manageStorageProgressData[@"total_progress"] = @(totalSize);
    manageStorageProgressData[@"first_progress"] = @(resourcesSize);
    manageStorageProgressData[@"second_progress"] = @(myPlacesSize);
    manageStorageProgressData[@"third_progress"] = @(settingsSize);

    resourcesData[@"description"] = [NSByteCountFormatter stringFromByteCount:resourcesSize
                                                                   countStyle:NSByteCountFormatterCountStyleFile];
    myPlacesData[@"description"] = [NSByteCountFormatter stringFromByteCount:myPlacesSize
                                                                   countStyle:NSByteCountFormatterCountStyleFile];
    settingsData[@"description"] = [NSByteCountFormatter stringFromByteCount:settingsSize
                                                                   countStyle:NSByteCountFormatterCountStyleFile];

    NSMutableDictionary *emptyData = [NSMutableDictionary dictionary];
    if (myPlacesCells.count == 0)
    {
        emptyData[@"key"] = @"empty_cell_my_places_section";
        emptyData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
        emptyData[@"title"] = OALocalizedString(@"backup_empty_data_from_category");
        [myPlacesCells addObject:emptyData];
    }

    if (resourcesCells.count == 0)
    {
        emptyData[@"key"] = @"empty_cell_resources_section";
        emptyData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
        emptyData[@"title"] = OALocalizedString(@"backup_empty_data_from_category");
        [resourcesCells addObject:emptyData];
    }

    if (settingsCells.count == 0)
    {
        emptyData[@"key"] = @"empty_cell_settings_section";
        emptyData[@"type"] = [OAIconTitleValueCell getCellIdentifier];
        emptyData[@"title"] = OALocalizedString(@"backup_empty_data_from_category");
        [settingsCells addObject:emptyData];
    }

    [self setData:data];
}

#pragma mark - Selectors

- (void)onCellSelected
{
    NSDictionary *item = [self getItem:[self getSelectedIndexPath]];
    if (![item[@"key"] isEqualToString:@"manage_storage_progress_cell"])
        [self showClearTypeScreen:item[@"setting"]];
}

- (void)onTypeSelected:(OAExportSettingsType *)type selected:(BOOL)selected
{
}

- (void)showClearTypeScreen:(OAExportSettingsType *)type
{
    OAManageTypeViewController *manageTypeViewController =
            [[OAManageTypeViewController alloc] initWithSettingsType:type
                                                                size:[self getItem:[self getSelectedIndexPath]][@"description"]];
    manageTypeViewController.manageTypeDelegate = self;
    [self.navigationController presentViewController:manageTypeViewController animated:YES completion:nil];
}

#pragma mark - Additions

- (EOARemoteFilesType)getRemoteFilesType
{
    return EOARemoteFilesTypeUnique;
}

@end
