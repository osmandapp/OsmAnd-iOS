//
//  OAStatusBackupConflictDetailsViewController.m
//  OsmAnd Maps
//
//  Created by Skalii on 27.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAStatusBackupConflictDetailsViewController.h"
#import "OAStatusBackupTableViewController.h"
#import "OATableViewCellSimple.h"
#import "OATableViewCellRightIcon.h"
#import "OATableViewCustomHeaderView.h"
#import "OATableViewDataModel.h"
#import "OATableViewSectionData.h"
#import "OATableViewRowData.h"
#import "OANetworkSettingsHelper.h"
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

@end

@implementation OAStatusBackupConflictDetailsViewController
{
    OALocalFile *_localeFile;
    OARemoteFile *_remoteFile;
    OANetworkSettingsHelper *_settingsHelper;
    id _backupExportImportListener;

    OATableViewDataModel *_data;
    NSInteger _itemSection;
}

- (instancetype)initWithLocalFile:(OALocalFile *)localeFile
                       remoteFile:(OARemoteFile *)remoteFile
       backupExportImportListener:(id)backupExportImportListener
{
    self = [super init];
    if (self)
    {
        _localeFile = localeFile;
        _remoteFile = remoteFile;
        _backupExportImportListener = backupExportImportListener;
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
    self.titleView.text = OALocalizedString(@"cloud_conflict");
}

- (CGFloat) initialHeight
{
    return DeviceScreenHeight / 2;
}

- (void)generateData
{
    _data = [[OATableViewDataModel alloc] init];
    OATableViewSectionData *itemInfoSection = [OATableViewSectionData sectionData];
    
    NSString *name = [_localeFile.item getPublicName];
    if ([_localeFile.item isKindOfClass:OAFileSettingsItem.class])
    {
        OAFileSettingsItem *flItem = (OAFileSettingsItem *) _localeFile.item;
        if (flItem.subtype == EOASettingsItemFileSubtypeVoiceTTS)
            name = [NSString stringWithFormat:@"%@ (%@)", name, OALocalizedString(@"tts")];
        else if (flItem.subtype == EOASettingsItemFileSubtypeVoice)
            name = [NSString stringWithFormat:@"%@ (%@)", name, OALocalizedString(@"recorded_voice")];
    }

    OATableViewRowData *itemInfoRow = [[OATableViewRowData alloc] initWithData:@{
        kCellTypeKey: [OATableViewCellSimple getCellIdentifier],
        kCellKeyKey: @"itemInfo",
        kCellTitleKey: name,
        kCellIconTint: @(color_icon_inactive)
    }];

    OATableViewRowData *uploadLocalRow = [[OATableViewRowData alloc] initWithData:@{
        kCellTypeKey: [OATableViewCellRightIcon getCellIdentifier],
        kCellKeyKey: @"uploadLocal",
        kCellTitleKey: OALocalizedString(@"upload_local_version"),
        kCellSecondaryIconName: @"ic_custom_globe_upload",
        kCellIconTint: @(color_primary_purple)
    }];

    OATableViewRowData *downloadCloudRow = [[OATableViewRowData alloc] initWithData:@{
        kCellTypeKey: [OATableViewCellRightIcon getCellIdentifier],
        kCellKeyKey: @"downloadCloud",
        kCellTitleKey: OALocalizedString(@"dowload_cloud_version"),
        kCellSecondaryIconName: @"ic_custom_device_download",
        kCellIconTint: @(color_primary_purple)
    }];

    NSString *fileName = [OABackupHelper getItemFileName:_localeFile.item];
    OAImportBackupTask *importTask = [_settingsHelper getImportTask:fileName];
    OAExportBackupTask *exportTask = [_settingsHelper getExportTask:fileName];
    BOOL enabled = exportTask == nil && importTask == nil;
    [uploadLocalRow setObj:@(enabled) forKey:@"enabled"];
    [downloadCloudRow setObj:@(enabled) forKey:@"enabled"];

    if (self.delegate)
    {
        [self.delegate setRowIcon:itemInfoRow item:_localeFile.item];
        [itemInfoRow setDescr:[self.delegate getDescriptionForItemType:_localeFile.item.type
                                                              fileName:fileName
                                                               summary:OALocalizedString(@"cloud_last_backup")]];

        [uploadLocalRow setDescr:[self.delegate getDescriptionForItemType:_localeFile.item.type
                                                                 fileName:fileName
                                                                  summary:OALocalizedString(@"shared_string_changed")]];

        [downloadCloudRow setDescr:[self.delegate getDescriptionForItemType:_remoteFile.item.type
                                                                   fileName:fileName
                                                                    summary:OALocalizedString(@"shared_string_changed")]];
    }
    [itemInfoSection addRow:itemInfoRow];
    [itemInfoSection addRow:uploadLocalRow];
    [itemInfoSection addRow:downloadCloudRow];
    
    itemInfoSection.headerText = OALocalizedString(@"backup_conflicts_action_descr");
    itemInfoSection.footerText = OALocalizedString(@"cloud_contains_newer_changes");

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
    OATableViewRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OATableViewCellSimple getCellIdentifier]])
    {
        OATableViewCellSimple *cell = [tableView dequeueReusableCellWithIdentifier:[OATableViewCellSimple getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATableViewCellSimple getCellIdentifier] owner:self options:nil];
            cell = (OATableViewCellSimple *) nib[0];
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
    else if ([item.cellType isEqualToString:[OATableViewCellRightIcon getCellIdentifier]])
    {
        OATableViewCellRightIcon *cell = [tableView dequeueReusableCellWithIdentifier:[OATableViewCellRightIcon getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATableViewCellRightIcon getCellIdentifier] owner:self options:nil];
            cell = (OATableViewCellRightIcon *) nib[0];
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

    OATableViewRowData *item = [_data itemForIndexPath:indexPath];
    if ([item boolForKey:@"enabled"])
    {
        [self hide:YES completion:^{
            NSString *fileName = [OABackupHelper getItemFileName:_localeFile.item];
            if ([item.key isEqualToString:@"uploadLocal"])
            {
                [_settingsHelper exportSettings:fileName items:@[_localeFile.item] itemsToDelete:@[] listener:_backupExportImportListener];
            }
            else if ([item.key isEqualToString:@"downloadCloud"])
            {
                OASettingsItem *settingsItem = _remoteFile.item;
                [settingsItem setShouldReplace:YES];
                [_settingsHelper importSettings:fileName items:@[settingsItem] forceReadData:YES listener:_backupExportImportListener];
            }
        }];
    }
}

@end
