//
//  OACloudRecentChangesTableViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 16.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAStatusBackupTableViewController.h"
#import "OAColors.h"
#import "OATableViewDataModel.h"
#import "OATableViewSectionData.h"
#import "OATableViewRowData.h"
#import "OAPrepareBackupResult.h"
#import "OABackupStatus.h"
#import "OABackupInfo.h"
#import "OASettingsItem.h"
#import "OAProfileSettingsItem.h"
#import "OAExportSettingsType.h"
#import "OABackupHelper.h"
#import "OABackupDbHelper.h"
#import "OAFileSettingsItem.h"
#import "OASettingsItemType.h"
#import "OAOsmAndFormatter.h"
#import "Localization.h"
#import "OAMultiIconTextDescCell.h"
#import "OACustomBasicTableCell.h"

@implementation OAStatusBackupTableViewController
{
    EOARecentChangesTable _tableType;
    OATableViewDataModel *_data;
    
    OABackupStatus *_status;
    OAPrepareBackupResult *_backup;
}

- (instancetype)initWithTableType:(EOARecentChangesTable)type backup:(OAPrepareBackupResult *)backup status:(OABackupStatus *)status
{
    self = [super init];
    if (self)
    {
        _tableType = type;
        _backup = backup;
        _status = status;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundColor = UIColorFromRGB(color_tableview_background);
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.001, 0.001)];
    [self generateData];
}

- (void)generateData
{
    _data = [[OATableViewDataModel alloc] init];
    OATableViewSectionData *statusSection = [OATableViewSectionData sectionData];
    NSString *backupTime = [OAOsmAndFormatter getFormattedPassedTime:OAAppSettings.sharedManager.backupLastUploadedTime.get def:OALocalizedString(@"shared_string_never")];
    [statusSection addRowFromDictionary:@{
        kCellTypeKey: OAMultiIconTextDescCell.getCellIdentifier,
        kCellKeyKey: @"lastBackup",
        kCellTitleKey: _status.statusTitle,
        kCellDescrKey: backupTime,
        kCellIconNameKey: _status.statusIconName
    }];
    [_data addSection:statusSection];
    
    OATableViewSectionData *itemsSection = [OATableViewSectionData sectionData];
    if (_tableType == EOARecentChangesAll)
    {
        for (OASettingsItem *item in _backup.backupInfo.itemsToUpload)
        {
            [itemsSection addRow:[self rowFromItem:item toDelete:NO]];
        }
        for (OASettingsItem *item in _backup.backupInfo.itemsToDelete)
        {
            [itemsSection addRow:[self rowFromItem:item toDelete:YES]];
        }
    }
    [_data addSection:itemsSection];
}

- (OATableViewRowData *) rowFromItem:(OASettingsItem *)item toDelete:(BOOL)toDelete
{
    OATableViewRowData *rowData = [OATableViewRowData rowData];
    [rowData setCellType:OACustomBasicTableCell.getCellIdentifier];
    NSString *name = item.name;
    if ([item isKindOfClass:OAFileSettingsItem.class])
    {
        OAFileSettingsItem *flItem = (OAFileSettingsItem *)item;
        if (flItem.subtype == EOASettingsItemFileSubtypeVoiceTTS)
            name = [NSString stringWithFormat:@"%@ (%@)", name, OALocalizedString(@"tts")];
        else if (flItem.subtype == EOASettingsItemFileSubtypeVoice)
            name = [NSString stringWithFormat:@"%@ (%@)", name, OALocalizedString(@"recorded_voice")];
    }
    [rowData setTitle:name];
    NSString *fileName = [OABackupHelper getItemFileName:item];
    NSString *summary = OALocalizedString(@"cloud_last_backup");
    OAUploadedFileInfo *info = [OABackupDbHelper.sharedDatabase getUploadedFileInfo:[OASettingsItemType typeName:item.type] name:fileName];
    if (info)
    {
        NSString *time = [OAOsmAndFormatter getFormattedPassedTime:info.uploadTime def:OALocalizedString(@"shared_string_never")];
        [rowData setDescr:[NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), summary, time]];
    }
    else
    {
        [rowData setDescr:[NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), summary, OALocalizedString(@"shared_string_never")]];
    }
    [self setRowIcon:rowData item:item];
    [rowData setSecondaryIconName:toDelete ? @"ic_custom_remove" : @"ic_custom_cloud_done"];
    return rowData;
}

- (void) setRowIcon:(OATableViewRowData *)rowData item:(OASettingsItem *)item
{
    if ([item isKindOfClass:OAProfileSettingsItem.class])
    {
        OAProfileSettingsItem *profileItem = (OAProfileSettingsItem *) item;
        OAApplicationMode *mode = profileItem.appMode;
        [rowData setData:mode.getIcon forKey:@"icon"];
        [rowData setIconTint:mode.getIconColor];
    }
    OAExportSettingsType *type = [OAExportSettingsType getExportSettingsTypeForItem:item];
    if (type != nil)
    {
        [rowData setData:type.icon forKey:@"icon"];
    }
}

// MARK: UITableViewDataSoure

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableViewRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:OAMultiIconTextDescCell.getCellIdentifier])
    {
        OAMultiIconTextDescCell* cell = [tableView dequeueReusableCellWithIdentifier:OAMultiIconTextDescCell.getCellIdentifier];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconTextDescCell getCellIdentifier] owner:self options:nil];
            cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(nav_bar_day);
            [cell setOverflowVisibility:YES];
        }
        cell.textView.text = item.title;
        cell.descView.text = item.descr;
        [cell.iconView setImage:[UIImage templateImageNamed:item.iconName]];
        return cell;
    }
    else if ([item.cellType isEqualToString:OACustomBasicTableCell.getCellIdentifier])
    {
        OACustomBasicTableCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACustomBasicTableCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomBasicTableCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomBasicTableCell *) nib[0];
//            [cell switchVisibility:NO];
//            [cell valueVisibility:NO];
            cell.rightIconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.descriptionLabel.text = item.descr;
            cell.leftIconView.image = [item objForKey:@"icon"];
            if ([item objForKey:kCellIconTint])
                cell.leftIconView.tintColor = UIColorFromRGB(item.iconTint);
            else
                cell.leftIconView.tintColor = UIColorFromRGB(color_icon_inactive);
            cell.rightIconView.image = [UIImage templateImageNamed:item.secondaryIconName];
        }
        return cell;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}

@end
