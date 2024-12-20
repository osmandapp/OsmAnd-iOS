//
//  OABackupTypesViewController.mm
//  OsmAnd Maps
//
//  Created by Skalii on 25.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABackupTypesViewController.h"
#import "OASettingsBackupViewController.h"
#import "OAManageStorageViewController.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OAStorageStateValuesCell.h"
#import "OAExportSettingsCategory.h"
#import "OAExportSettingsType.h"
#import "OASettingsCategoryItems.h"
#import "OAPrepareBackupResult.h"
#import "OABackupInfo.h"
#import "OABackupHelper.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAButtonTableViewCell.h"
#import "OAIAPHelper.h"
#import "OAChoosePlanHelper.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OABackupTypesViewController
{
    OABackupHelper *_backupHelper;
}

#pragma mark - Initialization

- (void)commonInit
{
    _backupHelper = [OABackupHelper sharedInstance];
    [super commonInit];
}

#pragma mark - UIViewController

- (void)viewWillDisappear:(BOOL)animated
{
    for (UIViewController *controller in self.navigationController.viewControllers)
    {
        if ([controller isKindOfClass:[OASettingsBackupViewController class]])
        {
            [self.navigationController setNavigationBarHidden:NO animated:YES];
            return;
        }
    }
    [super viewWillDisappear:animated];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"backup_data");
}

- (void)registerNotifications
{
    [self addNotification:OAIAPProductPurchasedNotification selector:@selector(productPurchased:)];
}

- (void)productPurchased:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
        [self.tableView reloadData];
    });
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
    manageStorageProgressData[@"show_description"] = @(YES);
    [manageStorageCells addObject:manageStorageProgressData];

    NSMutableDictionary *manageStorageData = [NSMutableDictionary dictionary];
    manageStorageData[@"key"] = @"manage_storage_cell";
    manageStorageData[@"type"] = [OAValueTableViewCell getCellIdentifier];
    manageStorageData[@"title"] = OALocalizedString(@"manage_storage");
    manageStorageData[@"icon"] = @"ic_custom_storage";
    [manageStorageCells addObject:manageStorageData];

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
            NSMutableDictionary *itemData = [NSMutableDictionary dictionary];
            itemData[@"key"] = [type.name stringByAppendingString:@"_cell"];
            if ([OAIAPHelper isOsmAndProAvailable])
            {
                itemData[@"type"] = [OASwitchTableViewCell getCellIdentifier];
            }
            else
            {
                if (type.isAllowedInFreeVersion)
                {
                    itemData[@"type"] = [OASwitchTableViewCell getCellIdentifier];
                }
                else
                {
                    itemData[@"type"] = [OAButtonTableViewCell getCellIdentifier];
                    itemData[@"action"] = @"onPurchaseButtonTap";
                }
            }
 
            itemData[@"setting"] = type;
            itemData[@"category"] = categoryItems;

            NSInteger size = [self.class calculateItemsSize:[categoryItems getItemsForType:type]];
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

    NSInteger totalSize = [_backupHelper getMaximumAccountSize];
    NSString *totalSizeStr = [NSByteCountFormatter stringFromByteCount:[_backupHelper getMaximumAccountSize]
                                                            countStyle:NSByteCountFormatterCountStyleFile];
    NSString *usedSizeStr = [NSByteCountFormatter stringFromByteCount:resourcesSize + myPlacesSize + settingsSize
                                                           countStyle:NSByteCountFormatterCountStyleFile];
    manageStorageProgressData[@"title"] = [_backupHelper isBackupPreparing] ? OALocalizedString(@"calculating_progress") : [NSString stringWithFormat:OALocalizedString(@"cloud_storage_used"), usedSizeStr, totalSizeStr];
    manageStorageProgressData[@"total_progress"] = @(totalSize);
    manageStorageProgressData[@"first_progress"] = @(resourcesSize);
    manageStorageProgressData[@"second_progress"] = @(myPlacesSize);
    manageStorageProgressData[@"third_progress"] = @(settingsSize);

    [self setData:data];
}

#pragma mark - Selectors

- (void)onPurchaseButtonTap
{
    [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.OSMAND_CLOUD navController:self.navigationController];
}

- (void)onCellSelected
{
    NSDictionary *item = [self getItem:[self getSelectedIndexPath]];
    NSString *key = item[@"key"];
    if ([key isEqualToString:@"manage_storage_cell"])
    {
        OAManageStorageViewController *manageStorageViewController = [[OAManageStorageViewController alloc] init];
        manageStorageViewController.backupTypesDelegate = self;
        [self.navigationController pushViewController:manageStorageViewController animated:YES];
    }
    else
    {
        if (![OAIAPHelper isOsmAndProAvailable])
        {
            [self onPurchaseButtonTap];
        }
    }
}

- (void)onTypeSelected:(OAExportSettingsType *)type selected:(BOOL)selected view:(UIView *)view
{
    [super onTypeSelected:type selected:selected view:view];
    [[BackupUtils getBackupTypePref:type] set:selected];
    [_backupHelper.backup.backupInfo createItemCollections];
}

- (void)showClearTypeScreen:(OAExportSettingsType *)type view:(UIView *)view
{
    UIAlertController *alert =
            [UIAlertController alertControllerWithTitle:OALocalizedString(@"backup_delete_types_descr")
                                                message:nil
                                         preferredStyle:UIAlertControllerStyleActionSheet];
    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
    popPresenter.sourceView = self.view;
    popPresenter.sourceRect = view.frame;
    popPresenter.permittedArrowDirections = UIPopoverArrowDirectionUp;

    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_delete")
                                                           style:UIAlertActionStyleDestructive
                                                         handler:^(UIAlertAction * _Nonnull action)
                                                         {
                                                             [_backupHelper deleteAllFiles:@[type] listener:self];
                                                         }
    ];

    UIAlertAction *leaveAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_leave")
                                                          style:UIAlertActionStyleDefault
                                                        handler:nil
    ];

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel")
                                                           style:UIAlertActionStyleCancel
                                                         handler:^(UIAlertAction *action)
                                                         {
                                                             [self onTypeSelected:type selected:YES view:nil];
                                                         }
    ];

    [alert addAction:deleteAction];
    [alert addAction:leaveAction];
    [alert addAction:cancelAction];

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Additions

- (EOARemoteFilesType)getRemoteFilesType
{
    return EOARemoteFilesTypeUnique;
}

- (NSMutableDictionary<OAExportSettingsType *, NSArray *> *)generateSelectedItems
{
    NSMutableDictionary<OAExportSettingsType *, NSArray *> *selectedItemsMap = [NSMutableDictionary dictionary];
    for (OAExportSettingsType *type in [OAExportSettingsType getAllValues])
    {
        if ([[BackupUtils getBackupTypePref:type] get])
            selectedItemsMap[type] = [self getItemsForType:type];
    }
    return selectedItemsMap;
}

@end
