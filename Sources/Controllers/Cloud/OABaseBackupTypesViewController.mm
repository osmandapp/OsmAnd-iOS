//
//  OABaseBackupTypesViewController.mm
//  OsmAnd Maps
//
//  Created by Skalii on 25.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABaseBackupTypesViewController.h"
#import "MBProgressHUD.h"
#import "OAIconTextDividerSwitchCell.h"
#import "OAIconTitleValueCell.h"
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

@interface OABaseBackupTypesViewController () <UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate>

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

- (instancetype)init
{
    self = [super initWithNibName:@"OABaseBackupTypesViewController" bundle:nil];
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _backupHelper = [OABackupHelper sharedInstance];
    _dataItems = [self generateDataItems];
    _selectedItems = [self generateSelectedItems];
    _progressFilesCompleteCount = 0;
    _progressFilesTotalCount = 1;
    [self generateData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(
            self.navbarView.frame.size.height - [OAUtilities getTopMargin],
            self.tableView.contentInset.left,
            self.tableView.contentInset.bottom,
            self.tableView.contentInset.bottom
    );
}

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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.tableView reloadData];
    } completion:nil];
}

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

- (void)onCellSelected
{
    // override
}

- (void)onTypeSelected:(OAExportSettingsType *)type selected:(BOOL)selected
{
    NSArray *items = [self getItemsForType:type];
    if (selected)
        _selectedItems[type] = items;
    else
        [_selectedItems removeObjectForKey:type];

    if (!selected && items.count > 0)
        [self showClearTypeScreen:type];

    if (_selectedIndexPath)
        [self.tableView reloadRowsAtIndexPaths:@[_selectedIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)showClearTypeScreen:(OAExportSettingsType *)type
{
    // override
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

- (UIStatusBarStyle)preferredStatusBarStyle
{
    if (@available(iOS 13.0, *))
        return UIStatusBarStyleDarkContent;

    return UIStatusBarStyleDefault;
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

- (void)generateData
{
    _data = [NSMutableArray array]; // override;
}

- (NSMutableDictionary *)getItem:(NSIndexPath *)indexPath
{
    return ((NSArray *) _data[indexPath.section][@"cells"])[indexPath.row];
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

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
        _selectedIndexPath = indexPath;
        NSMutableDictionary *item = [self getItem:indexPath];

        [self onTypeSelected:item[@"setting"] selected:switchView.isOn];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ((NSArray *) _data[section][@"cells"]).count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *outCell = nil;

    NSDictionary *item = [self getItem:indexPath];
    NSString *cellType = item[@"type"];
    OAExportSettingsType *settingsType = item[@"setting"];
    BOOL emptyCell = [item[@"key"] hasPrefix:@"empty_cell_"];
    BOOL hasEmptyIcon = [item[@"has_empty_icon"] boolValue];

    if ([cellType isEqualToString:[OAIconTextDividerSwitchCell getCellIdentifier]])
    {
        OAIconTextDividerSwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextDividerSwitchCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextDividerSwitchCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTextDividerSwitchCell *) nib[0];
            [cell showIcon:YES];
            cell.dividerView.hidden = YES;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., 66. + [OAUtilities getLeftMargin], 0., 0.);
            cell.switchView.on = [_selectedItems.allKeys containsObject:settingsType];
            cell.textView.text = settingsType.title;
            cell.iconView.image = settingsType.icon;
            cell.iconView.tintColor = cell.switchView.on ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_tint_gray);

            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([cellType isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., 66. + [OAUtilities getLeftMargin], 0., 0.);
            cell.selectionStyle = emptyCell || hasEmptyIcon ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;

            cell.textView.text = settingsType ? settingsType.title : item[@"title"];
            cell.descriptionView.text = [item.allKeys containsObject:@"description"] ? item[@"description"] : @"";

            [cell showRightIcon:!(emptyCell || hasEmptyIcon)];
            [cell showLeftIcon:!emptyCell];
            cell.leftIconView.tintColor = UIColorFromRGB(color_primary_purple);

            if (hasEmptyIcon)
            {
                cell.leftIconView.image = nil;
                cell.leftIconView.backgroundColor = item[@"icon_color"];
                cell.leftIconView.layer.cornerRadius = cell.rightIconView.layer.frame.size.width / 2;
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
        OAStorageStateValuesCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAStorageStateValuesCell getCellIdentifier]];
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

    if ([outCell needsUpdateConstraints])
        [outCell setNeedsUpdateConstraints];

    return outCell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _data[section][@"header"];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    BOOL emptyCell = [item[@"key"] hasPrefix:@"empty_cell_"];
    BOOL hasEmptyIcon = [item[@"has_empty_icon"] boolValue];
    if (!(emptyCell || hasEmptyIcon))
    {
        _selectedIndexPath = indexPath;
        [self onCellSelected];
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

#pragma mark - UIScrollViewDelegate

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat y = scrollView.contentOffset.y + scrollView.contentInset.top;

    if (!_isHeaderBlurred && y > 0)
    {
        _isHeaderBlurred = YES;
        [UIView animateWithDuration:.2 animations:^{
            [self.navbarView addBlurEffect:YES cornerRadius:0. padding:0.];
        }];
    }
    else if (_isHeaderBlurred && y <= 0.)
    {
        _isHeaderBlurred = NO;
        [UIView animateWithDuration:.2 animations:^{
            [self.navbarView removeBlurEffect:UIColorFromRGB(color_bottom_sheet_background)];
        }];
    }
}

@end
