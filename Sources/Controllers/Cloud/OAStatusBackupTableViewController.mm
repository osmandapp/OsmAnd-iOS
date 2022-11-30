//
//  OACloudRecentChangesTableViewController.mm
//  OsmAnd Maps
//
//  Created by Skalii on 16.09.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OAStatusBackupTableViewController.h"
#import "OAStatusBackupViewController.h"
#import "OAStatusBackupConflictDetailsViewController.h"
#import "OAColors.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OASyncBackupTask.h"
#import "OAPrepareBackupResult.h"
#import "OABackupStatus.h"
#import "OABackupInfo.h"
#import "OASettingsItem.h"
#import "OAProfileSettingsItem.h"
#import "OAExportSettingsType.h"
#import "OABackupHelper.h"
#import "OASettingsHelper.h"
#import "OABackupDbHelper.h"
#import "OABackupListeners.h"
#import "OABackupHelper.h"
#import "OABackupError.h"
#import "OABackupStatus.h"
#import "OARemoteFile.h"
#import "OAFileSettingsItem.h"
#import "OASettingsItemType.h"
#import "OAOsmAndFormatter.h"
#import "Localization.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OALargeImageTitleDescrTableViewCell.h"
#import "OATitleIconProgressbarCell.h"
#import "FFCircularProgressView+isSpinning.h"
#import "OANetworkSettingsHelper.h"
#import "OAImportBackupTask.h"
#import "OAExportBackupTask.h"
#import "OALocalFile.h"
#import "OATableViewCustomHeaderView.h"
#import "OASizes.h"
#import "OAResourcesUIHelper.h"

typedef NS_ENUM(NSInteger, EOAItemStatusType)
{
    EOAItemStatusStartedType = 0,
    EOAItemStatusInProgressType,
    EOAItemStatusFinishedType
};

@interface OAStatusBackupTableViewController () <OAOnPrepareBackupListener, OAStatusBackupDelegate>

@end

@implementation OAStatusBackupTableViewController
{
    EOARecentChangesType _tableType;
    OATableDataModel *_data;
    NSIndexPath *_lastBackupIndexPath;
    NSInteger _itemsSection;
    
    OANetworkSettingsHelper *_settingsHelper;
    OABackupHelper *_backupHelper;
}

- (instancetype)initWithTableType:(EOARecentChangesType)type
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        _tableType = type;
        _settingsHelper = [OANetworkSettingsHelper sharedInstance];
        _backupHelper = [OABackupHelper sharedInstance];
        [self setupNotificationListeners];
        _itemsSection = -1;
        [_backupHelper addPrepareBackupListener:self];
    }
    return self;
}

- (void)setupNotificationListeners
{
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupFinished:) name:kBackupSyncFinishedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupStarted) name:kBackupSyncStartedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupProgressUpdate:) name:kBackupProgressUpdateNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupProgressItemFinished:) name:kBackupItemFinishedNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupItemProgress:) name:kBackupItemProgressNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onBackupItemStarted:) name:kBackupItemStartedNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.001, 0.001)];
    [self generateData];
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
}

- (void)dealloc
{
    [NSNotificationCenter.defaultCenter removeObserver:self];
    [_backupHelper removePrepareBackupListener:self];
}

- (void)updateData
{
    [self generateData];
    [self.tableView reloadData];
}

- (void)generateData
{
    _data = [[OATableDataModel alloc] init];
    OATableSectionData *statusSection = [OATableSectionData sectionData];
    NSString *backupTime = [OAOsmAndFormatter getFormattedPassedTime:OAAppSettings.sharedManager.backupLastUploadedTime.get def:OALocalizedString(@"shared_string_never")];
    if ([_settingsHelper isBackupSyncing])
    {
        OATableRowData *progressCell = [OATableRowData rowData];
        [progressCell setCellType:[OATitleIconProgressbarCell getCellIdentifier]];
        [progressCell setKey:@"backupProgress"];
        [progressCell setTitle:[OALocalizedString(@"syncing_progress") stringByAppendingString:[NSString stringWithFormat:@"%i%%", 0]]];
        [progressCell setIconName:@"ic_custom_cloud_upload"];
        [progressCell setIconTint:color_primary_purple];
        [progressCell setObj:@(0.) forKey:@"progress"];
        [statusSection addRow:progressCell];
    }
    else
    {
        OABackupStatus *status = [OABackupStatus getBackupStatus:_backupHelper.backup];
        [statusSection addRowFromDictionary:@{
            kCellTypeKey: [OASimpleTableViewCell getCellIdentifier],
            kCellKeyKey: @"lastBackup",
            kCellTitleKey: status.statusTitle,
            kCellDescrKey: backupTime,
            kCellIconNameKey: status.statusIconName,
            kCellIconTint: @(status.iconColor)
        }];
    }
    [_data addSection:statusSection];
    _lastBackupIndexPath = [NSIndexPath indexPathForRow:statusSection.rowCount - 1 inSection:_data.sectionCount - 1];
    
    OATableSectionData *itemsSection = [OATableSectionData sectionData];
    OABackupInfo *info = _backupHelper.backup.backupInfo;
    if (_tableType == EOARecentChangesLocal)
    {
        for (OALocalFile *file in info.filteredFilesToUpload)
        {
            [itemsSection addRow:[self rowFromItem:file
                                          iconName:@"ic_custom_cloud_upload_outline"
                                          mainTint:color_icon_inactive
                                     secondaryTint:color_primary_purple operation:EOABackupSyncOperationUpload]];
        }
        for (OARemoteFile *file in info.filteredFilesToDelete)
        {
            [itemsSection addRow:[self rowFromItem:file iconName:@"ic_custom_remove" mainTint:color_primary_purple secondaryTint:color_primary_red operation:EOABackupSyncOperationDelete]];
        }
    }
    else if (_tableType == EOARecentChangesRemote)
    {
        NSArray<NSArray *> *downloadItems = [OABackupHelper getItemsMapForRestore:info settingsItems:_backupHelper.backup.settingsItems];
        for (NSArray *pair in downloadItems)
        {
            [itemsSection addRow:[self rowFromItem:pair.firstObject
                                          iconName:@"ic_custom_cloud_download_outline"
                                          mainTint:color_icon_inactive
                                     secondaryTint:color_primary_purple
                                         operation:EOABackupSyncOperationDownload]];
        }
    }
    else if (_tableType == EOARecentChangesConflicts)
    {
        for (NSArray *items in info.filteredFilesToMerge)
        {
            [itemsSection addRow:[self rowFromConflictItems:items]];
        }
    }
    if (itemsSection.rowCount == 0)
    {
        [itemsSection addRowFromDictionary:@{
            kCellTypeKey: [OALargeImageTitleDescrTableViewCell getCellIdentifier],
            kCellKeyKey: @"epmtyState",
            kCellTitleKey: [self getLocalizedEmptyStateHeader],
            kCellDescrKey: OALocalizedString(@"cloud_all_changes_uploaded_descr"),
            kCellIconNameKey: @"ic_action_cloud_smile_face_colored"
        }];
    }
    if (!_backupHelper.isBackupPreparing)
    {
        _itemsSection = _data.sectionCount;
        [_data addSection:itemsSection];
    }
    if (_itemsSection != -1 && _tableType == EOARecentChangesConflicts && itemsSection.rowCount > 1)
        [_data sectionDataForIndex:_itemsSection].headerText = OALocalizedString(@"backup_conflicts_descr");
}

- (BOOL) hasItems
{
    switch (_tableType)
    {
        case EOARecentChangesRemote:
            return [OABackupHelper getItemsMapForRestore:_backupHelper.backup.backupInfo settingsItems:_backupHelper.backup.settingsItems].count > 0;
        case EOARecentChangesLocal:
            return _backupHelper.backup.backupInfo.filteredFilesToDelete.count + _backupHelper.backup.backupInfo.filteredFilesToUpload.count > 0;
        default:
            return NO;
    }
    
}

- (NSString *) getLocalizedEmptyStateHeader
{
    switch (_tableType)
    {
        case EOARecentChangesLocal:
            return OALocalizedString(@"cloud_all_changes_uploaded");
        case EOARecentChangesRemote:
            return OALocalizedString(@"cloud_all_changes_downloaded");
        case EOARecentChangesConflicts:
            return OALocalizedString(@"cloud_no_conflicts");
        default:
            return @"";
    }
}

- (OATableRowData *) rowFromConflictItems:(NSArray *)items
{
    OALocalFile *localFile = (OALocalFile *) items.firstObject;
    OARemoteFile *remoteFile = (OARemoteFile *) items.lastObject;
    OATableRowData *rowData = [self rowFromItem:localFile
                                       iconName:@"ic_custom_cloud_info"
                                       mainTint:color_icon_inactive
                                  secondaryTint:color_tint_gray
                                      operation:EOABackupSyncOperationNone];
    [rowData setObj:localFile forKey:@"localConflictItem"];
    [rowData setObj:remoteFile forKey:@"remoteConflictItem"];
    NSString *conflictStr = [OALocalizedString(@"cloud_conflict") stringByAppendingString:@". "];
    NSMutableAttributedString *attributedDescr = [[NSMutableAttributedString alloc] initWithString:[conflictStr stringByAppendingString:rowData.descr]];
    [attributedDescr addAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:13 weight:UIFontWeightMedium],
                                      NSForegroundColorAttributeName : UIColorFromRGB(color_primary_red) }
                             range:[attributedDescr.string rangeOfString:conflictStr]];
    [attributedDescr addAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:13],
                                      NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer) }
                             range:[attributedDescr.string rangeOfString:rowData.descr]];
    [rowData setObj:attributedDescr forKey:@"descr_attr"];
    [rowData setObj:@"ic_custom_alert" forKey:@"secondary_icon_conflict"];
    [rowData setObj:@(color_primary_red) forKey:@"secondary_icon_color"];
    [rowData setIconTint:color_primary_purple];
    return rowData;
}

- (OATableRowData *) rowFromItem:(id)file iconName:(NSString *)iconName mainTint:(NSInteger)mainTint secondaryTint:(NSInteger)secondaryTint operation:(EOABackupSyncOperationType)operation
{
    OASettingsItem *item = nil;
    if ([file isKindOfClass:OALocalFile.class])
        item = ((OALocalFile *) file).item;
    else if ([file isKindOfClass:OARemoteFile.class])
        item = ((OARemoteFile *) file).item;
    OATableRowData *rowData = [OATableRowData rowData];
    [rowData setCellType:[OARightIconTableViewCell getCellIdentifier]];
    [rowData setObj:file forKey:@"file"];
    [rowData setObj:item forKey:@"settings_item"];
    [rowData setObj:@(operation) forKey:@"operation"];
    NSString *name = item.getPublicName;
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
    [rowData setObj:fileName forKey:@"file_name"];

    if (operation == EOABackupSyncOperationUpload || operation == EOABackupSyncOperationNone)
    {
        [rowData setDescr:[self getDescriptionForItemType:item.type
                                                 fileName:fileName
                                                  summary:[self localizedSummaryForOperation:operation]]];
    }
    else
    {
        [rowData setDescr:[self generateTimeString:((OARemoteFile *) file).updatetimems summary:[self localizedSummaryForOperation:operation]]];
    }
    [self setRowIcon:rowData item:item];

    [rowData setSecondaryIconName:iconName];
    [rowData setObj:@(secondaryTint) forKey:@"secondary_icon_color"];
    [rowData setIconTint:mainTint];
    return rowData;
}

- (NSString *) localizedSummaryForOperation:(EOABackupSyncOperationType)operation
{
    switch (operation) {
        case EOABackupSyncOperationDownload:
            return OALocalizedString(@"shared_string_added");
        case EOABackupSyncOperationUpload:
            return OALocalizedString(@"osm_modified");
        case EOABackupSyncOperationDelete:
            return OALocalizedString(@"osm_deleted");
        default:
            return OALocalizedString(@"osm_modified");
    }
}

- (void)setRowIcon:(OATableRowData *)rowData item:(OASettingsItem *)item
{
    if ([item isKindOfClass:OAProfileSettingsItem.class])
    {
        OAProfileSettingsItem *profileItem = (OAProfileSettingsItem *) item;
        OAApplicationMode *mode = profileItem.appMode;
        [rowData setObj:[UIImage templateImageNamed:[mode getIconName]] forKey:@"icon"];
    }
    else
    {
        OAExportSettingsType *type = [OAExportSettingsType getExportSettingsTypeForItem:item];
        if (type != nil)
            [rowData setObj:type.icon forKey:@"icon"];
    }
}

- (NSArray *) rowAndIndexForType:(NSString *)type fileName:(NSString *)fileName
{
    EOASettingsItemType intType = [OASettingsItemType parseType:type];
    OATableSectionData *section = [_data sectionDataForIndex:_itemsSection];
    for (NSInteger i = 0; i < section.rowCount; i++)
    {
        OATableRowData *row = [section getRow:i];
        OASettingsItem *item = [row objForKey:@"settings_item"];
        if (item.type == intType && [[row objForKey:@"file_name"] isEqualToString:fileName])
            return @[row, @(i)];
    }
    return nil;
}

- (void)updateCellProgress:(NSString * _Nonnull)fileName
                      type:(NSString * _Nonnull)type
          itemProgressType:(EOAItemStatusType)itemProgressType
                     value:(NSInteger)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *rowIndex = [self rowAndIndexForType:type fileName:fileName];
        if (rowIndex)
        {
            NSIndexPath *indPath = [NSIndexPath indexPathForRow:[rowIndex.lastObject integerValue] inSection:_itemsSection];
            OATableRowData *item = [_data itemForIndexPath:indPath];
            BOOL hasConflict = [item objForKey:@"remoteConflictItem"] != nil;
            OARightIconTableViewCell *cell = [self.tableView cellForRowAtIndexPath:indPath];
            if (cell)
            {
                [cell rightIconVisibility:hasConflict];
                FFCircularProgressView *progressView = (FFCircularProgressView *) cell.accessoryView;
                if (!progressView)
                {
                    progressView = [[FFCircularProgressView alloc] initWithFrame:CGRectMake(0., 0., 25., 25.)];
                    progressView.iconView = [[UIView alloc] init];
                    progressView.tintColor = UIColorFromRGB(color_primary_purple);
                    cell.accessoryView = progressView;
                }

                if (itemProgressType == EOAItemStatusStartedType)
                {
                    progressView.iconPath = [UIBezierPath bezierPath];
                    progressView.progress = 0.;
                    if (!progressView.isSpinning)
                        [progressView startSpinProgressBackgroundLayer];
                    [progressView setNeedsDisplay];
                }
                else if (itemProgressType == EOAItemStatusInProgressType)
                {
                    progressView.iconPath = nil;
                    if (progressView.isSpinning)
                        [progressView stopSpinProgressBackgroundLayer];
                    progressView.progress = value / 100. - 0.001;
                }
                else if (itemProgressType == EOAItemStatusFinishedType)
                {
                    progressView.iconPath = [OAResourcesUIHelper tickPath:progressView];
                    progressView.progress = 0.;
                    if (!progressView.isSpinning)
                        [progressView startSpinProgressBackgroundLayer];

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t) (1. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [cell rightIconVisibility:YES];
                        BOOL hasConflict = [item objForKey:@"remoteConflictItem"] != nil;
                        [item setIconTint:color_primary_purple];
                        [item setObj:hasConflict ? @(color_primary_red) : @(color_primary_purple) forKey:@"secondary_icon_color"];
                        [self.tableView reloadRowsAtIndexPaths:@[indPath] withRowAnimation:UITableViewRowAnimationNone];
                    });
                }
            }
        }
    });
}

- (NSString *)generateTimeString:(long)timeMs summary:(NSString *)summary
{
    if (timeMs != -1)
    {
        NSString *time = [OAOsmAndFormatter getFormattedPassedTime:(timeMs / 1000)
                                                               def:OALocalizedString(@"shared_string_never")];
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), summary, time];
    }
    else
    {
        return [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_colon"), summary, OALocalizedString(@"shared_string_never")];
    }
}

- (NSString *)getDescriptionForItemType:(EOASettingsItemType)type fileName:(NSString *)fileName summary:(NSString *)summary
{
    OAUploadedFileInfo *info = [[OABackupDbHelper sharedDatabase] getUploadedFileInfo:[OASettingsItemType typeName:type] name:fileName];
    return [self generateTimeString:info.uploadTime summary:summary];
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
            cell.titleLabel.text = item.title;
            cell.descriptionLabel.text = item.descr;
            cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
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
        }
        if (cell)
        {
            BOOL hasConflict = [item objForKey:@"remoteConflictItem"] != nil;
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingToLeftOfContentWithIcon, 0., 0.);
            cell.selectionStyle = hasConflict ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
            cell.accessoryType = hasConflict ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;

            NSString *description = item.descr;
            NSAttributedString *descriptionAttributed = [item objForKey:@"descr_attr"];
            [cell descriptionVisibility:description != nil || descriptionAttributed != nil];
            if (descriptionAttributed)
            {
                cell.descriptionLabel.text = nil;
                cell.descriptionLabel.attributedText = descriptionAttributed;
            }
            else
            {
                cell.descriptionLabel.attributedText = nil;
                cell.descriptionLabel.text = description;
            }

            cell.titleLabel.text = item.title;
            cell.leftIconView.image = [item objForKey:@"icon"];
            cell.leftIconView.tintColor = UIColorFromRGB(item.iconTint);

            NSString *secondaryIconName = hasConflict ? [item stringForKey:@"secondary_icon_conflict"] : item.secondaryIconName;
            cell.rightIconView.image = secondaryIconName ? [UIImage templateImageNamed:secondaryIconName] : nil;
            cell.rightIconView.tintColor = UIColorFromRGB([item integerForKey:@"secondary_icon_color"]);
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OALargeImageTitleDescrTableViewCell getCellIdentifier]])
    {
        OALargeImageTitleDescrTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OALargeImageTitleDescrTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OALargeImageTitleDescrTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OALargeImageTitleDescrTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell showButton:NO];
            cell.titleLabel.font = [UIFont systemFontOfSize:17. weight:UIFontWeightRegular];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:item.descr];
            NSRange range = NSMakeRange(0, str.length);
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineSpacing = 4;
            paragraphStyle.alignment = NSTextAlignmentCenter;
            [str addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
            [str addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_text_footer) range:range];
            [str addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:15.] range:range];
            cell.descriptionLabel.attributedText = str;
            [cell.cellImageView setImage:[UIImage imageNamed:item.iconName]];

            if (cell.needsUpdateConstraints)
                [cell updateConstraints];
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OATitleIconProgressbarCell getCellIdentifier]])
    {
        OATitleIconProgressbarCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATitleIconProgressbarCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleIconProgressbarCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleIconProgressbarCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.progressBar setProgressTintColor:UIColorFromRGB(color_primary_purple)];
        }
        if (cell)
        {
            cell.textView.text = item.title;
            cell.imageView.image = [UIImage templateImageNamed:item.iconName];
            cell.imageView.tintColor = UIColorFromRGB(item.iconTint);

            [cell.progressBar setProgress:[[item objForKey:@"progress"] floatValue] animated:NO];
        }
        return cell;
    }
    return nil;
}

// MARK: UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    NSString *header = [_data sectionDataForIndex:section].headerText;
    if (header && section == _itemsSection && _tableType == EOARecentChangesConflicts)
    {
        customHeader.label.text = header;
        customHeader.label.font = [UIFont systemFontOfSize:13.];
        [customHeader setYOffset:2.];
        return customHeader;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *header = [_data sectionDataForIndex:section].headerText;
    if (section == _itemsSection)
    {
        if (header && _tableType == EOARecentChangesConflicts)
        {
            return [OATableViewCustomHeaderView getHeight:header
                                                    width:tableView.bounds.size.width
                                                  xOffset:kPaddingOnSideOfContent
                                                  yOffset:2.
                                                     font:[UIFont systemFontOfSize:13.]] + 15.;
        }
        return kHeaderHeightDefault;
    }
    return 0.001;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    OARemoteFile *remoteConflictItem = [item objForKey:@"remoteConflictItem"];
    if (remoteConflictItem)
    {
        OAStatusBackupConflictDetailsViewController *conflictDetailsViewController =
        [[OAStatusBackupConflictDetailsViewController alloc] initWithLocalFile:[item objForKey:@"localConflictItem"]
                                                                    remoteFile:[item objForKey:@"remoteConflictItem"]
                                                        operation:EOABackupSyncOperationNone];
        conflictDetailsViewController.delegate = self;
        [self presentViewController:conflictDetailsViewController animated:YES completion:nil];
    }
    else if ([item objForKey:@"settings_item"] && [item objForKey:@"operation"] && !_settingsHelper.isBackupSyncing)
    {
        EOABackupSyncOperationType operation = (EOABackupSyncOperationType) [item integerForKey:@"operation"];
        id file = [item objForKey:@"file"];
        OALocalFile *localFile = nil;
        OARemoteFile *remoteFile = nil;
        if (operation != EOABackupSyncOperationUpload)
            remoteFile = (OARemoteFile *) file;
        else
            localFile = (OALocalFile *) file;
        
        
        OAStatusBackupConflictDetailsViewController *conflictDetailsViewController =
        [[OAStatusBackupConflictDetailsViewController alloc] initWithLocalFile:localFile
                                                                    remoteFile:remoteFile
                                                                     operation:operation];
        conflictDetailsViewController.delegate = self;
        [self presentViewController:conflictDetailsViewController animated:YES completion:nil];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// MARK: OAOnPrepareBackupListener

- (void)onBackupPrepared:(nonnull OAPrepareBackupResult *)backupResult
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateData];
    });
}

- (void)onBackupPreparing
{
}

// MARK: Sync callbacks

- (void)onBackupFinished:(NSNotification *)notification
{
}

- (void)onBackupStarted
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateData];
    });
}

- (void)onBackupProgressUpdate:(NSNotification *)notification
{
    dispatch_async(dispatch_get_main_queue(), ^{
        float value = [notification.userInfo[@"progress"] floatValue];
        NSIndexPath *progressIdxPath = [NSIndexPath indexPathForRow:0 inSection:0];
        OATableRowData *row = [_data itemForIndexPath:progressIdxPath];
        if (row && [row.key isEqualToString:@"backupProgress"])
        {
            [row setObj:@(value) forKey:@"progress"];
            [row setTitle:[OALocalizedString(@"syncing_progress") stringByAppendingString:[NSString stringWithFormat:@"%i%%", (int) (value * 100)]]];
            OATitleIconProgressbarCell *cell = (OATitleIconProgressbarCell *) [self.tableView cellForRowAtIndexPath:progressIdxPath];
            if (cell)
                cell.progressBar.progress = value;
        }
    });
}

- (void)onBackupProgressItemFinished:(NSNotification *)notification
{
    [self updateCellProgress:notification.userInfo[@"name"] type:notification.userInfo[@"type"] itemProgressType:EOAItemStatusFinishedType value:100];
}

- (void)onBackupItemProgress:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    [self updateCellProgress:info[@"name"] type:info[@"type"] itemProgressType:EOAItemStatusInProgressType value:[info[@"value"] integerValue]];
}

- (void)onBackupItemStarted:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    [self updateCellProgress:info[@"name"] type:info[@"type"] itemProgressType:EOAItemStatusStartedType value:0];
}

@end
