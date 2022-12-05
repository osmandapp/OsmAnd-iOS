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
#import "OATableViewCustomHeaderView.h"
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
    OANetworkSettingsHelper *_settingsHelper;
    
    OATableDataModel *_data;
    NSInteger _itemSection;
    EOABackupSyncOperationType _operation;
}

- (instancetype)initWithLocalFile:(OALocalFile *)localeFile
                       remoteFile:(OARemoteFile *)remoteFile
                        operation:(EOABackupSyncOperationType)operation
{
    self = [super init];
    if (self)
    {
        _localFile = localeFile;
        _remoteFile = remoteFile;
        _operation = operation;
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
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];

    [self.closeButton setImage:nil forState:UIControlStateNormal];

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
            return OALocalizedString(@"remote_item");
        case EOABackupSyncOperationUpload:
            return OALocalizedString(@"local_item");
        case EOABackupSyncOperationDelete:
            return OALocalizedString(@"deleted_item");
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

- (void)populateConflictActions:(OASettingsItem *)item itemInfoSection:(OATableSectionData *)itemInfoSection
{
    OATableRowData *uploadLocalRow = [[OATableRowData alloc] initWithData:@{
        kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
        kCellKeyKey: @"uploadLocal",
        kCellTitleKey: OALocalizedString(@"upload_local_version"),
        kCellSecondaryIconName: @"ic_custom_globe_upload",
        kCellIconTint: @(color_primary_purple)
    }];
    
    OATableRowData *downloadCloudRow = [[OATableRowData alloc] initWithData:@{
        kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
        kCellKeyKey: @"downloadCloud",
        kCellTitleKey: OALocalizedString(@"dowload_cloud_version"),
        kCellSecondaryIconName: @"ic_custom_device_download",
        kCellIconTint: @(color_primary_purple)
    }];
    
    NSString *fileName = [OABackupHelper getItemFileName:item];
    BOOL enabled = [self isRowEnabled:fileName];
    [uploadLocalRow setObj:@(enabled) forKey:@"enabled"];
    [downloadCloudRow setObj:@(enabled) forKey:@"enabled"];
    [uploadLocalRow setDescr:[self.delegate getDescriptionForItemType:item.type
                                                             fileName:fileName
                                                              summary:OALocalizedString(@"shared_string_changed")]];
    
    [downloadCloudRow setDescr:[self.delegate generateTimeString:_remoteFile.updatetimems
                                                         summary:OALocalizedString(@"shared_string_changed")]];
    
    [itemInfoSection addRow:uploadLocalRow];
    [itemInfoSection addRow:downloadCloudRow];
}

- (void)populateDeleteActions:(OASettingsItem *)item itemInfoSection:(OATableSectionData *)itemInfoSection
{
    OATableRowData *deleteCloudRow = [[OATableRowData alloc] initWithData:@{
        kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
        kCellKeyKey: @"deleteCloud",
        kCellTitleKey: OALocalizedString(@"backup_delete_from_cloud"),
        kCellSecondaryIconName: @"ic_custom_remove",
        kCellIconTint: @(color_primary_red)
    }];
    
    OATableRowData *downloadCloudRow = [[OATableRowData alloc] initWithData:@{
        kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
        kCellKeyKey: @"downloadCloud",
        kCellTitleKey: OALocalizedString(@"dowload_cloud_version"),
        kCellSecondaryIconName: @"ic_custom_device_download",
        kCellIconTint: @(color_primary_purple)
    }];
    
    NSString *fileName = [OABackupHelper getItemFileName:item];
    BOOL enabled = [self isRowEnabled:fileName];
    [deleteCloudRow setObj:@(enabled) forKey:@"enabled"];
    [downloadCloudRow setObj:@(enabled) forKey:@"enabled"];
    [deleteCloudRow setDescr:[self.delegate getDescriptionForItemType:item.type
                                                             fileName:fileName
                                                              summary:OALocalizedString(@"shared_string_changed")]];
    
    [downloadCloudRow setDescr:[self.delegate generateTimeString:_remoteFile.updatetimems
                                                         summary:OALocalizedString(@"shared_string_changed")]];
    
    [itemInfoSection addRow:deleteCloudRow];
    [itemInfoSection addRow:downloadCloudRow];
}

- (void)populateUploadActions:(OASettingsItem *)item itemInfoSection:(OATableSectionData *)itemInfoSection
{
    OATableRowData *uploadLocalRow = [[OATableRowData alloc] initWithData:@{
        kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
        kCellKeyKey: @"uploadLocal",
        kCellTitleKey: OALocalizedString(@"upload_local_version"),
        kCellSecondaryIconName: @"ic_custom_globe_upload",
        kCellIconTint: @(color_primary_purple)
    }];
    
    NSString *fileName = [OABackupHelper getItemFileName:item];
    BOOL enabled = [self isRowEnabled:fileName];
    [uploadLocalRow setObj:@(enabled) forKey:@"enabled"];
    [uploadLocalRow setDescr:[self.delegate getDescriptionForItemType:item.type
                                                             fileName:fileName
                                                              summary:OALocalizedString(@"shared_string_changed")]];
    
    [itemInfoSection addRow:uploadLocalRow];
}

- (void)populateDownloadActions:(OASettingsItem *)item itemInfoSection:(OATableSectionData *)itemInfoSection
{
    OATableRowData *downloadCloudRow = [[OATableRowData alloc] initWithData:@{
        kCellTypeKey: [OARightIconTableViewCell getCellIdentifier],
        kCellKeyKey: @"downloadCloud",
        kCellTitleKey: OALocalizedString(@"dowload_cloud_version"),
        kCellSecondaryIconName: @"ic_custom_device_download",
        kCellIconTint: @(color_primary_purple)
    }];
    
    NSString *fileName = [OABackupHelper getItemFileName:item];
    BOOL enabled = [self isRowEnabled:fileName];
    [downloadCloudRow setObj:@(enabled) forKey:@"enabled"];
    
    [downloadCloudRow setDescr:[self.delegate generateTimeString:_remoteFile.updatetimems
                                                         summary:OALocalizedString(@"shared_string_changed")]];
    
    [itemInfoSection addRow:downloadCloudRow];
}

- (void)generateData
{
    _data = [[OATableDataModel alloc] init];
    OATableSectionData *itemInfoSection = [OATableSectionData sectionData];
    
    OASettingsItem *item = _operation != EOABackupSyncOperationUpload ? _remoteFile.item : _localFile.item;
    NSString *name = [item getPublicName];
    if ([item isKindOfClass:OAFileSettingsItem.class])
    {
        OAFileSettingsItem *flItem = (OAFileSettingsItem *) item;
        if (flItem.subtype == EOASettingsItemFileSubtypeVoiceTTS)
            name = [NSString stringWithFormat:@"%@ (%@)", name, OALocalizedString(@"tts")];
        else if (flItem.subtype == EOASettingsItemFileSubtypeVoice)
            name = [NSString stringWithFormat:@"%@ (%@)", name, OALocalizedString(@"recorded_voice")];
    }

    if (name)
    {
        OATableRowData *itemInfoRow = [[OATableRowData alloc] initWithData:@{
            kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
            kCellKeyKey: @"itemInfo",
            kCellTitleKey: name,
            kCellIconTint: @(color_icon_inactive)
        }];
        if (self.delegate)
        {
            [self.delegate setRowIcon:itemInfoRow item:item];
            long timestamp = 0;
            if (_operation != EOABackupSyncOperationUpload && _operation != EOABackupSyncOperationNone)
                timestamp = _remoteFile.updatetimems;
            else
                timestamp = _localFile.item.localModifiedTime * 1000;

            [itemInfoRow setDescr:[self.delegate generateTimeString:timestamp summary:[self.delegate localizedSummaryForOperation:_operation]]];
        }
        [itemInfoSection addRow:itemInfoRow];
    }
    if (_operation == EOABackupSyncOperationNone)
        [self populateConflictActions:item itemInfoSection:itemInfoSection];
    else if (_operation == EOABackupSyncOperationDelete)
        [self populateDeleteActions:item itemInfoSection:itemInfoSection];
    else if (_operation == EOABackupSyncOperationUpload)
        [self populateUploadActions:item itemInfoSection:itemInfoSection];
    else if (_operation == EOABackupSyncOperationDownload)
        [self populateDownloadActions:item itemInfoSection:itemInfoSection];
        
    
    if (_operation == EOABackupSyncOperationNone)
    {
        itemInfoSection.headerText = OALocalizedString(@"backup_conflicts_action_descr");
        itemInfoSection.footerText = OALocalizedString(@"cloud_contains_newer_changes");
    }

    [_data addSection:itemInfoSection];
    _itemSection = _data.sectionCount - 1;
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
            cell.separatorInset = UIEdgeInsetsMake(0., 0., 0., 0.);
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
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
            cell.rightIconView.tintColor = UIColorFromRGB(item.iconTint);
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

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    NSString *header = [_data sectionDataForIndex:section].headerText;
    if (header && section == _itemSection)
    {
        customHeader.label.text = header;
        customHeader.label.font = [UIFont systemFontOfSize:13.];
        [customHeader setYOffset:0.];
        return customHeader;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *header = [_data sectionDataForIndex:section].headerText;
    if (header && section == _itemSection)
    {
        return [OATableViewCustomHeaderView getHeight:header
                                                width:tableView.bounds.size.width
                                              xOffset:kPaddingOnSideOfContent
                                              yOffset:0.
                                                 font:[UIFont systemFontOfSize:13.]] + 9.;
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
            NSString *fileName = [OABackupHelper getItemFileName:_localFile ? _localFile.item : _remoteFile.item];
            if ([item.key isEqualToString:@"uploadLocal"])
                [_settingsHelper syncSettingsItems:fileName localFile:_localFile remoteFile:_remoteFile operation:EOABackupSyncOperationUpload];
            else if ([item.key isEqualToString:@"downloadCloud"])
                [_settingsHelper syncSettingsItems:fileName localFile:_localFile remoteFile:_remoteFile operation:EOABackupSyncOperationDownload];
            else if ([item.key isEqualToString:@"deleteCloud"])
                [_settingsHelper syncSettingsItems:fileName localFile:_localFile remoteFile:_remoteFile operation:EOABackupSyncOperationDelete];
        }];
    }
}

@end
