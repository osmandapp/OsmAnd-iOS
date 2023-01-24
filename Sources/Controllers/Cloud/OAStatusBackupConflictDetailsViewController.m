//
//  OAStatusBackupConflictDetailsViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 27.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAStatusBackupConflictDetailsViewController.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OAStatusBackupTableViewController.h"
#import "OATableRowData.h"
#import "OABackupHelper.h"
#import "OABackupDbHelper.h"
#import "OALocalFile.h"
#import "OARemoteFile.h"
#import "OASettingsItem.h"
#import "OAFileSettingsItem.h"
#import "OAProfileSettingsItem.h"
#import "OAOsmAndFormatter.h"
#import "OASizes.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAStatusBackupConflictDetailsViewController () <UITableViewDelegate, UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *closeButton;
@property (weak, nonatomic) IBOutlet UILabel *titleView;

@end

@implementation OAStatusBackupConflictDetailsViewController
{
    OALocalFile *_localFile;
    OARemoteFile *_remoteFile;
    NSString *_fileName;
    OANetworkSettingsHelper *_settingsHelper;
    
    OATableDataModel *_data;
    NSInteger _itemInfoSection;
    EOABackupSyncOperationType _operation;
    EOARecentChangesType _recentChangesType;
}

- (instancetype)initWithLocalFile:(OALocalFile *)localeFile
                       remoteFile:(OARemoteFile *)remoteFile
                        operation:(EOABackupSyncOperationType)operation
                recentChangesType:(EOARecentChangesType)recentChangesType
{
    self = [super init];
    if (self)
    {
        _localFile = localeFile;
        _remoteFile = remoteFile;
        _operation = operation;
        _recentChangesType = recentChangesType;
        _fileName = [OABackupHelper getItemFileName:_recentChangesType == EOARecentChangesLocal && _localFile ? _localFile.item : _remoteFile.item];
    }
    return self;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    return [super initWithNibName:@"OAStatusBackupConflictDetailsViewController" bundle:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _settingsHelper = [OANetworkSettingsHelper sharedInstance];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.sectionHeaderHeight = 0.001;
    self.tableView.sectionFooterHeight = 0.001;

    [self generateData];
}

- (void)applyLocalization
{
    [self.closeButton setTitle:OALocalizedString(@"shared_string_close") forState:UIControlStateNormal];
    self.titleView.text = [self titleForOperation:_operation];
}

- (NSString *) titleForOperation:(EOABackupSyncOperationType)operation
{
    switch (operation)
    {
        case EOABackupSyncOperationDownload:
            return OALocalizedString(!_localFile ? @"new_file" : @"modified_file");
        case EOABackupSyncOperationUpload:
            return OALocalizedString(!_remoteFile ? @"new_file" : @"modified_file");
        case EOABackupSyncOperationDelete:
            return OALocalizedString(@"deleted_file");
        default:
            return OALocalizedString(@"cloud_conflict");
    }
}

- (CGFloat) initialHeight
{
    return DeviceScreenHeight / 2;
}

- (BOOL) isRowEnabled:(NSString *)fileName
{
    OAImportBackupTask *importTask = [_settingsHelper getImportTask:fileName];
    OAExportBackupTask *exportTask = [_settingsHelper getExportTask:fileName];
    return exportTask == nil && importTask == nil;
}

- (void)generateData
{
    _data = [[OATableDataModel alloc] init];
    BOOL deleteOperation = _operation == EOABackupSyncOperationDelete;
    OASettingsItem *settingsItem = nil;
    if (_recentChangesType == EOARecentChangesLocal)
    {
        settingsItem = _localFile.item;
        if (!settingsItem)
            settingsItem = _remoteFile.item;
    }
    else
    {
        settingsItem = _remoteFile.item;
        if (!settingsItem)
            settingsItem = _localFile.item;
    }

    OATableSectionData *itemInfoSection = [OATableSectionData sectionData];
    [_data addSection:itemInfoSection];
    _itemInfoSection = _data.sectionCount - 1;
    if (_recentChangesType == EOARecentChangesConflicts)
        itemInfoSection.footerText = OALocalizedString(@"cloud_conflict_descr");

    NSString *name = @"";
    if ([settingsItem isKindOfClass:OAProfileSettingsItem.class])
    {
        name = [((OAProfileSettingsItem *) settingsItem).appMode toHumanString];
    }
    else
    {
        name = [settingsItem getPublicName];
        if ([settingsItem isKindOfClass:OAFileSettingsItem.class])
        {
            OAFileSettingsItem *fileItem = (OAFileSettingsItem *) settingsItem;
            if (fileItem.subtype == EOASettingsItemFileSubtypeVoiceTTS)
                name = [NSString stringWithFormat:@"%@ (%@)", name, OALocalizedString(@"tts_title")];
            else if (fileItem.subtype == EOASettingsItemFileSubtypeVoice)
                name = [NSString stringWithFormat:@"%@ (%@)", name, OALocalizedString(@"shared_string_recorded")];
        }
        else if (!name)
        {
            name = OALocalizedString(@"res_unknown");
        }
    }

    OATableRowData *itemInfoRow = [[OATableRowData alloc] initWithData:@{
        kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
        kCellKeyKey: @"itemInfo",
        kCellTitleKey: name,
        kCellIconTint: @(color_icon_inactive)
    }];
    [itemInfoSection addRow:itemInfoRow];

    if (deleteOperation && _recentChangesType == EOARecentChangesLocal)
    {
        [itemInfoRow setDescr:OALocalizedString(@"poi_remove_success")];
    }
    else if (self.delegate)
    {
        long timeMs = _recentChangesType == EOARecentChangesLocal || _recentChangesType == EOARecentChangesConflicts
            ? _localFile.localModifiedTime * 1000
            : _recentChangesType == EOARecentChangesRemote && deleteOperation ? _localFile.uploadTime : _remoteFile.updatetimems;
        NSString *summary = OALocalizedString(deleteOperation && _recentChangesType != EOARecentChangesLocal ? @"poi_remove_success" : @"osm_modified");
        [itemInfoRow setDescr:[self.delegate generateTimeString:timeMs summary:summary]];
    }

    if (self.delegate)
    {
        [self.delegate setRowIcon:itemInfoRow item:settingsItem];

        long timeMs = _recentChangesType == EOARecentChangesRemote && deleteOperation ? _localFile.uploadTime : _remoteFile.updatetimems;
        NSString *lastSyncDescr = [self.delegate generateTimeString:timeMs
                                                            summary:OALocalizedString(@"last_synchronization")];

        OATableRowData *itemDescrRow = [[OATableRowData alloc] initWithData:@{
            kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
            kCellKeyKey: @"itemDescr",
            kCellDescrKey: lastSyncDescr,
        }];
        [itemInfoSection addRow:itemDescrRow];
    }

    OATableSectionData *itemActionSection = [OATableSectionData sectionData];
    [itemActionSection addRow:[self populateUploadAction]];
    [itemActionSection addRow:[self populateDownloadAction]];
    [_data addSection:itemActionSection];
}

- (OATableRowData *)populateUploadAction
{
    BOOL deleteOperation = _operation == EOABackupSyncOperationDelete;
    BOOL enabled = [self isRowEnabled:_fileName] && (_localFile || deleteOperation);
    NSString *title = OALocalizedString(deleteOperation ? @"upload_change" : @"upload_local_version");
    NSString *description = @"";
    if (self.delegate)
    {
        if (deleteOperation)
        {
            description = _recentChangesType == EOARecentChangesLocal
                ? OALocalizedString(@"cloud_version_will_be_removed")
                : [self.delegate generateTimeString:_localFile.localModifiedTime * 1000
                                            summary:OALocalizedString(@"osm_modified")];
        }
        else if (!_localFile)
        {
            description = OALocalizedString(@"shared_string_do_not_exist");
        }
        else
        {
            description = [self.delegate generateTimeString:_localFile.item.localModifiedTime * 1000
                                                    summary:OALocalizedString(@"osm_modified")];
            if (_recentChangesType == EOARecentChangesRemote)
            {
                description = [description stringByAppendingFormat:@"\n%@",
                               OALocalizedString(@"cloud_changes_will_be_dismissed")];
            }
        }
    }

    return [[OATableRowData alloc] initWithData:@{
        kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
        kCellKeyKey: deleteOperation ? @"deleteItem" : @"uploadLocal",
        kCellTitleKey: title,
        kCellDescrKey: description,
        kCellSecondaryIconName: @"ic_custom_cloud_upload_outline",
        kCellIconTint: @(color_primary_purple),
        @"enabled": @(enabled)
    }];
}

- (OATableRowData *)populateDownloadAction
{
    BOOL deleteOperation = _operation == EOABackupSyncOperationDelete;
    BOOL enabled = [self isRowEnabled:_fileName] && (_remoteFile || deleteOperation);
    NSString *description = @"";
    if (self.delegate)
    {
        if (deleteOperation)
        {
            EOASettingsItemType type = _remoteFile ? _remoteFile.item.type : _localFile.item.type;
            BOOL isLocalChanges = _recentChangesType == EOARecentChangesLocal;
            if (isLocalChanges)
            {
                description = [NSString stringWithFormat:@"%@\n%@",
                               [self.delegate getDescriptionForItemType:type
                                                               fileName:_fileName
                                                                summary:OALocalizedString(@"shared_string_uploaded")],
                               OALocalizedString(@"local_file_will_be_restored")
                ];
            }
            else
            {
                description = [self.delegate generateTimeString:_localFile.uploadTime
                                                        summary:OALocalizedString(@"poi_remove_success")];
            }
        }
        else if (!_remoteFile)
        {
            description = OALocalizedString(@"shared_string_do_not_exist");
        }
        else
        {
            
            description = [self.delegate generateTimeString:_remoteFile.updatetimems
                                                    summary:OALocalizedString(@"shared_string_uploaded")];
            if (_recentChangesType == EOARecentChangesLocal)
            {
                description = [description stringByAppendingFormat:@"\n%@",
                               OALocalizedString(@"local_changes_will_be_dismissed")];
            }
        }
    }

    return [[OATableRowData alloc] initWithData:@{
        kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
        kCellKeyKey: deleteOperation ? @"deleteItem" : @"downloadCloud",
        kCellTitleKey: OALocalizedString(@"dowload_cloud_version"),
        kCellDescrKey: description,
        kCellSecondaryIconName: @"ic_custom_cloud_download_outline",
        kCellIconTint: @(color_primary_purple),
        @"enabled": @(enabled)
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].rowCount;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingToLeftOfContentWithIcon, 0., 0.);
            NSString *title = item.title;
            [cell titleVisibility:title != nil];
            cell.titleLabel.text = title;
            cell.descriptionLabel.text = item.descr;
            cell.leftIconView.image = [item objForKey:@"icon"];
            cell.leftIconView.tintColor = UIColorFromRGB(item.iconTint);
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            cell.titleLabel.font = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingOnSideOfContent, 0., 0.);
            BOOL enabled = [item boolForKey:@"enabled"];
            cell.selectionStyle = enabled ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.titleLabel.textColor = enabled ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_text_footer);
            cell.titleLabel.text = item.title;
            cell.descriptionLabel.text = item.descr;
            cell.rightIconView.image = [UIImage templateImageNamed:item.secondaryIconName];
            cell.rightIconView.tintColor = enabled ? UIColorFromRGB(item.iconTint) : UIColorFromRGB(color_footer_icon_gray);
        }
        return cell;
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == _itemInfoSection ? 0.001 : kHeaderHeightDefault;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSString *footer = [_data sectionDataForIndex:section].footerText;
    if (footer)
    {
        UIFont *font = [UIFont systemFontOfSize:13.];
        CGFloat footerHeight = [OAUtilities calculateTextBounds:footer
                                                          width:tableView.frame.size.width - (kPaddingOnSideOfContent + [OAUtilities getLeftMargin]) * 2
                                                           font:font].height + kPaddingOnSideOfFooterWithText;
        return footerHeight;
    }

    return 0.001;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item boolForKey:@"enabled"])
    {
        [self dismissViewControllerAnimated:YES completion:^{
            if ([item.key isEqualToString:@"uploadLocal"])
                [_settingsHelper syncSettingsItems:_fileName localFile:_localFile remoteFile:_remoteFile operation:EOABackupSyncOperationUpload];
            else if ([item.key isEqualToString:@"downloadCloud"])
                [_settingsHelper syncSettingsItems:_fileName localFile:_localFile remoteFile:_remoteFile operation:EOABackupSyncOperationDownload];
            else if ([item.key isEqualToString:@"deleteItem"])
                [_settingsHelper syncSettingsItems:_fileName localFile:_localFile remoteFile:_remoteFile operation:EOABackupSyncOperationDelete];
        }];
    }
}

@end
