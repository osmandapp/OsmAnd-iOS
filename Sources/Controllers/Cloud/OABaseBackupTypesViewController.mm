//
//  OABaseBackupTypesViewController.mm
//  OsmAnd Maps
//
//  Created by Skalii on 25.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseBackupTypesViewController.h"
#import "MBProgressHUD.h"
#import "OASwitchTableViewCell.h"
#import "OAValueTableViewCell.h"
#import "OAStorageStateValuesCell.h"
#import "OAExportSettingsType.h"
#import "OASettingsCategoryItems.h"
#import "OAPrepareBackupResult.h"
#import "OAFileSettingsItem.h"
#import "OALocalFile.h"
#import "OARemoteFile.h"
#import "OABackupHelper.h"
#import "OASettingsHelper.h"
#import "OAColors.h"
#import "OASizes.h"
#import "OAButtonTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OABaseBackupTypesViewController ()

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end

@implementation OABaseBackupTypesViewController
{
    OABackupHelper *_backupHelper;
    NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *_dataItems;
    NSMutableDictionary<OAExportSettingsType *, NSArray *> *_selectedItems;

    NSMutableArray<NSMutableDictionary *> *_data;
    NSIndexPath *_selectedIndexPath;
    NSInteger _progressFilesCompleteCount;
    NSInteger _progressFilesTotalCount;
    BOOL _isHeaderBlurred;
}

#pragma mark - Initialization

- (void)commonInit
{
    _backupHelper = [OABackupHelper sharedInstance];
    _dataItems = [self generateDataItems];
    _selectedItems = [self generateSelectedItems];
    _progressFilesCompleteCount = 0;
    _progressFilesTotalCount = 1;
}

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_backupHelper.backupListeners addDeleteFilesListener:self];
    [_backupHelper addPrepareBackupListener:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_backupHelper.backupListeners removeDeleteFilesListener:self];
    [_backupHelper removePrepareBackupListener:self];
}

#pragma mark - Base UI

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

#pragma mark - Table data

- (void)generateData
{
    _data = [NSMutableArray array]; // override;
}

- (NSMutableDictionary *)getItem:(NSIndexPath *)indexPath
{
    return ((NSArray *) _data[indexPath.section][@"cells"])[indexPath.row];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return _data[section][@"header"];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return ((NSArray *) _data[section][@"cells"]).count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    UITableViewCell *outCell = nil;

    NSDictionary *item = [self getItem:indexPath];
    NSString *cellType = item[@"type"];
    OAExportSettingsType *settingsType = item[@"setting"];
    BOOL emptyCell = [item[@"key"] hasPrefix:@"empty_cell_"];
    BOOL hasEmptyIcon = [item[@"has_empty_icon"] boolValue];

    if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., kPaddingToLeftOfContentWithIcon + [OAUtilities getLeftMargin], 0., 0.);
            cell.switchView.on = [_selectedItems.allKeys containsObject:settingsType];
            cell.titleLabel.text = settingsType.title;
            cell.leftIconView.image = settingsType.icon;
            cell.leftIconView.tintColor = cell.switchView.on ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDisabled];

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([cellType isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.selectionStyle = emptyCell || hasEmptyIcon ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;

            cell.titleLabel.text = settingsType ? settingsType.title : item[@"title"];
            cell.valueLabel.text = [item.allKeys containsObject:@"description"] ? item[@"description"] : @"";

            [cell leftIconVisibility:!emptyCell];
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            if (!(emptyCell || hasEmptyIcon))
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            if (hasEmptyIcon)
            {
                cell.leftIconView.image = nil;
                cell.leftIconView.backgroundColor = item[@"icon_color"];
                cell.leftIconView.layer.cornerRadius = cell.leftIconView.layer.frame.size.width / 2;
                cell.leftIconView.clipsToBounds = YES;
            }
            else
            {
                cell.leftIconView.image = settingsType ? settingsType.icon : [UIImage templateImageNamed:item[@"icon"]];
                cell.leftIconView.backgroundColor = nil;
                cell.leftIconView.layer.cornerRadius = 0.;
                cell.leftIconView.clipsToBounds = NO;
            }
        }
        outCell = cell;
    }
    else if ([cellType isEqualToString:[OAStorageStateValuesCell getCellIdentifier]])
    {
        OAStorageStateValuesCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAStorageStateValuesCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAStorageStateValuesCell getCellIdentifier] owner:self options:nil];
            cell = (OAStorageStateValuesCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            BOOL showDescription = [item[@"show_description"] boolValue];
            cell.separatorInset = UIEdgeInsetsMake(0., showDescription ? 0. : CGFLOAT_MAX, 0., 0.);

            cell.titleLabel.text = item[@"title"];
            [cell showDescription:showDescription];
            [cell setTotalAvailableValue:[item[@"total_progress"] integerValue]];
            [cell setFirstValue:[item[@"first_progress"] integerValue]];
            [cell setSecondValue:[item[@"second_progress"] integerValue]];
            [cell setThirdValue:[item[@"third_progress"] integerValue]];
        }
        outCell = cell;
    }
    else if ([cellType isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
    {
        OAButtonTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellType];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:cellType owner:self options:nil];
            cell = nib[0];
            [cell leftIconVisibility:YES];
            [cell titleVisibility:YES];
            [cell descriptionVisibility:NO];
            [cell leftEditButtonVisibility:NO];
            UIButtonConfiguration *conf = [UIButtonConfiguration plainButtonConfiguration];
            conf.contentInsets = NSDirectionalEdgeInsetsMake(0., 0, 0, 0.);
            cell.button.configuration = conf;
            [cell.button setImage:[UIImage imageNamed:@"ic_payment_label_pro"] forState:UIControlStateNormal];
            [cell.button setTitle:@"" forState:UIControlStateNormal];
            cell.button.imageView.tintColor = [UIColor clearColor];
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorDisabled];
            [cell.button addTarget:self action:NSSelectorFromString(item[@"action"]) forControlEvents:UIControlEventTouchUpInside];
        }
        cell.titleLabel.text = settingsType.title;
        cell.leftIconView.image = settingsType.icon;

        
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell setNeedsUpdateConstraints];

    return outCell;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    BOOL emptyCell = [item[@"key"] hasPrefix:@"empty_cell_"];
    BOOL hasEmptyIcon = [item[@"has_empty_icon"] boolValue];
    if (!(emptyCell || hasEmptyIcon))
    {
        _selectedIndexPath = indexPath;
        [self onCellSelected];
    }
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
        _selectedIndexPath = indexPath;
        NSMutableDictionary *item = [self getItem:indexPath];

        [self onTypeSelected:item[@"setting"] selected:switchView.isOn view:switchView];
    }
}

- (void)onCellSelected
{
    // override
}

- (void)onTypeSelected:(OAExportSettingsType *)type selected:(BOOL)selected view:(UIView *)view
{
    NSArray *items = [self getItemsForType:type];
    if (selected)
        _selectedItems[type] = items;
    else
        [_selectedItems removeObjectForKey:type];

    if (!selected && items.count > 0)
        [self showClearTypeScreen:type view:view];

    if (_selectedIndexPath)
        [self.tableView reloadRowsAtIndexPaths:@[_selectedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)showClearTypeScreen:(OAExportSettingsType *)type view:(UIView *)view
{
    // override
}

#pragma mark - Additions

- (EOARemoteFilesType)getRemoteFilesType
{
    return EOARemoteFilesTypeAll;
}

- (NSMutableDictionary<OAExportSettingsType *, NSArray *> *)getSelectedItems
{
    return _selectedItems;
}

- (NSMutableDictionary<OAExportSettingsType *, NSArray *> *)generateSelectedItems
{
    return [NSMutableDictionary dictionary]; // override
}

- (NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *)getDataItems
{
    return _dataItems;
}

- (NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *)generateDataItems
{
    NSDictionary<NSString *, OARemoteFile *> *remoteFiles = [_backupHelper.backup getRemoteFiles:[self getRemoteFilesType]];
    if (!remoteFiles)
        remoteFiles = [NSDictionary dictionary];

    NSMutableDictionary<OAExportSettingsType *, NSArray *> *settingsToOperate = [NSMutableDictionary dictionary];
    for (OAExportSettingsType *type in [OAExportSettingsType getEnabledTypes])
    {
        NSMutableArray<OARemoteFile *> *filesByType = [NSMutableArray array];
        for (OARemoteFile *remoteFile in remoteFiles.allValues)
        {
            if ([OAExportSettingsType getExportSettingsTypeForRemoteFile:remoteFile] == type)
                [filesByType addObject:remoteFile];
        }
        settingsToOperate[type] = filesByType;
    }
    return [OASettingsHelper getSettingsToOperateByCategory:settingsToOperate addEmptyItems:YES];
}

- (NSArray *)getItemsForType:(OAExportSettingsType *)type
{
    for (OASettingsCategoryItems *categoryItems in _dataItems.allValues)
    {
        if ([[categoryItems getTypes] containsObject:type])
            return [categoryItems getItemsForType:type];
    }
    return @[];
}

+ (NSInteger)calculateItemsSize:(NSArray *)items
{
    NSInteger itemsSize = 0;
    for (id item in items)
    {
        if ([item isKindOfClass:OAFileSettingsItem.class])
            itemsSize += ((OAFileSettingsItem *) item).size;
        else if ([item isKindOfClass:OALocalFile.class])
            itemsSize += [[[NSFileManager defaultManager] attributesOfItemAtPath:((OALocalFile *) item).filePath error:nil] fileSize];
        else if ([item isKindOfClass:OARemoteFile.class])
            itemsSize += ((OARemoteFile *) item).zipSize;
    }
    return itemsSize;
}

- (NSIndexPath *)getSelectedIndexPath
{
    return _selectedIndexPath;
};

- (void)setData:(NSMutableArray<NSMutableDictionary *> *)data
{
    _data = data;
}

#pragma mark - OAManageTypeDelegate

- (void)onDeleteTypeData:(OAExportSettingsType *)settingsType
{
    [_backupHelper deleteAllFiles:@[settingsType] listener:self];
}

#pragma mark - OABackupTypesDelegate

- (void)onCompleteTasks
{
    if (self.backupTypesDelegate)
        [self.backupTypesDelegate onCompleteTasks];
}

- (void)setProgressTotal:(NSInteger)total
{
    if (self.backupTypesDelegate)
        [self.backupTypesDelegate setProgressTotal:total];
}

#pragma mark - OAOnDeleteFilesListener

- (void)onFilesDeleteStarted:(NSArray<OARemoteFile *> *)files
{
    _progressFilesCompleteCount = 0;
    _progressFilesTotalCount = files.count;
    if (self.backupTypesDelegate)
        [self.backupTypesDelegate setProgressTotal:_progressFilesTotalCount];
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            [self.progressView setProgress:_progressFilesCompleteCount animated:NO];
            self.progressView.hidden = NO;
        }];
    });
}

- (void)onFileDeleteProgress:(OARemoteFile *)file progress:(NSInteger)progress
{
    _progressFilesCompleteCount = progress;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            if (self.progressView.hidden)
                self.progressView.hidden = NO;
            float progressValue = (float) _progressFilesCompleteCount / _progressFilesTotalCount;
            [self.progressView setProgress:progressValue animated:YES];
        }];
    });
}

- (void)onFilesDeleteDone:(NSDictionary<OARemoteFile *, NSString *> *)errors
{
    NSTimeInterval duration = 0.3;
    _progressFilesCompleteCount = 1;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:duration animations:^{
            [self.progressView setProgress:_progressFilesCompleteCount animated:YES];
        } completion:^(BOOL finished) {
            self.progressView.hidden = YES;
            _progressFilesCompleteCount = 0;
            _progressFilesTotalCount = 1;
            [self.progressView setProgress:_progressFilesCompleteCount animated:NO];
            if (self.backupTypesDelegate)
                [self.backupTypesDelegate onCompleteTasks];
        }];
    });
}

- (void)onFilesDeleteError:(NSInteger)status message:(NSString *)message
{
    _progressFilesCompleteCount = 0;
    _progressFilesTotalCount = 1;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:_progressFilesCompleteCount animated:NO];
        if (self.backupTypesDelegate)
            [self.backupTypesDelegate onCompleteTasks];
    });
}

#pragma mark - OAOnPrepareBackupListener

- (void)onBackupPreparing
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            [self.progressView setProgress:0.1 animated:NO];
            self.progressView.hidden = NO;
        }];
    });
}

- (void)onBackupPrepared:(OAPrepareBackupResult *)backupResult
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            [self.progressView setProgress:1.0 animated:YES];

            _dataItems = [self generateDataItems];
            _selectedItems = [self generateSelectedItems];
            [self generateData];
            [self.tableView reloadData];
        } completion:^(BOOL finished) {
            self.progressView.hidden = YES;
            [self.progressView setProgress:0.0 animated:NO];
        }];
    });
}

@end
