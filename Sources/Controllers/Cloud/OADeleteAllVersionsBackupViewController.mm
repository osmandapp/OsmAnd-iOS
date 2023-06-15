//
//  OADeleteAllVersionsBackupViewController.mm
//  OsmAnd
//
//  Created by Skalii on 22.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OADeleteAllVersionsBackupViewController.h"
#import "OASettingsBackupViewController.h"
#import "OATextLineViewCell.h"
#import "OADownloadProgressBarCell.h"
#import "OAFilledButtonCell.h"
#import "OAColors.h"
#import "Localization.h"
#import "OABackupHelper.h"

@interface OADeleteAllVersionsBackupViewController () <OADeleteAllVersionsBackupDelegate, OAOnDeleteFilesListener>

@end

@implementation OADeleteAllVersionsBackupViewController
{
    EOADeleteBackupScreenType _screenType;
    NSMutableArray<NSMutableDictionary *> *_data;
    NSIndexPath *_progressIndexPath;
    NSString *_description;
    NSString *_sectionDescription;

    NSInteger _progressFilesCompleteCount;
    NSInteger _progressFilesTotalCount;
    BOOL _isDeleted;
}

#pragma mark - Initialization

- (instancetype)initWithScreenType:(EOADeleteBackupScreenType)screenType
{
    self = [super init];
    if (self)
    {
        _screenType = screenType;
        _progressFilesCompleteCount = 0;
        _progressFilesTotalCount = 1;
        [self postInit];
    }
    return self;
}

- (void)postInit
{
    _sectionDescription = @"";
    switch (_screenType)
    {
        case EOADeleteAllDataBackupScreenType:
        case EOADeleteAllDataConfirmBackupScreenType:
        {
            _description = OALocalizedString(@"backup_delete_all_data_warning");
            break;
        }
        case EOADeleteAllDataProgressBackupScreenType:
        {
            _description = OALocalizedString(@"shared_string_progress");
            _sectionDescription = OALocalizedString(@"backup_delete_all_data_in_progress");
            break;
        }
        case EOARemoveOldVersionsBackupScreenType:
        {
            _description = OALocalizedString(@"backup_delete_old_data_warning");
            break;
        }
        case EOARemoveOldVersionsProgressBackupScreenType:
        {
            _description = OALocalizedString(@"shared_string_progress");
            break;
        }
    }
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelection = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self deleteBackupFiles];
}

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
    switch (_screenType)
    {
        case EOADeleteAllDataBackupScreenType:
            return OALocalizedString(@"backup_delete_all_data");
        case EOADeleteAllDataConfirmBackupScreenType:
            return OALocalizedString(@"are_you_sure");
        case EOADeleteAllDataProgressBackupScreenType:
            return OALocalizedString(@"backup_deleting_all_data");
        case EOARemoveOldVersionsBackupScreenType:
            return OALocalizedString(@"backup_delete_old_data");
        case EOARemoveOldVersionsProgressBackupScreenType:
            return OALocalizedString(@"backup_delete_old_data");
    }
    return @"";
}

- (NSString *)getLeftNavbarButtonTitle
{
    return _screenType == EOARemoveOldVersionsBackupScreenType || _screenType == EOADeleteAllDataConfirmBackupScreenType ? OALocalizedString(@"shared_string_cancel") : @"";
}

- (UIImage *)getCustomIconForLeftNavbarButton
{
    NSString *iconName;
    if (_screenType == EOADeleteAllDataBackupScreenType)
        iconName = @"ic_navbar_chevron";
    else if (_screenType == EOADeleteAllDataProgressBackupScreenType || _screenType == EOARemoveOldVersionsProgressBackupScreenType)
        iconName = @"ic_navbar_close";
    return iconName ? [UIImage templateImageNamed:iconName] : nil;
}

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

- (EOABaseNavbarStyle)getNavbarStyle
{
    return EOABaseNavbarStyleLargeTitle;
}

- (NSString *)getTopButtonTitle
{
    if (_screenType == EOADeleteAllDataBackupScreenType)
        return OALocalizedString(@"backup_delete_all_data");

    return @"";
}

- (NSString *)getBottomButtonTitle
{
    switch (_screenType)
    {
        case EOADeleteAllDataBackupScreenType:
            return OALocalizedString(@"shared_string_cancel");
        case EOARemoveOldVersionsBackupScreenType:
            return OALocalizedString(@"shared_string_remove");
        case EOADeleteAllDataProgressBackupScreenType:
        case EOARemoveOldVersionsProgressBackupScreenType:
            return OALocalizedString(@"shared_string_close");
        default:
            return @"";
    }
}

- (EOABaseButtonColorScheme)getTopButtonColorScheme
{
    return _screenType == EOADeleteAllDataBackupScreenType ? EOABaseButtonColorSchemeRed : EOABaseButtonColorSchemeInactive;
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return _screenType == EOARemoveOldVersionsBackupScreenType ? EOABaseButtonColorSchemeGrayAttn : EOABaseButtonColorSchemeGraySimple;
}

- (BOOL)isBottomSeparatorVisible
{
    return NO;
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray *data = [NSMutableArray array];
    BOOL isProgress = _screenType == EOADeleteAllDataProgressBackupScreenType
            || _screenType == EOARemoveOldVersionsProgressBackupScreenType;
    if (isProgress)
    {
        NSMutableArray<NSMutableDictionary *> *progressCells = [NSMutableArray array];
        NSMutableDictionary *progressSection = [NSMutableDictionary dictionary];
        progressSection[@"cells"] = progressCells;
        [data addObject:progressSection];

        NSMutableDictionary *progressData = [NSMutableDictionary dictionary];
        progressData[@"key"] = @"progress_cell";
        progressData[@"type"] = [OADownloadProgressBarCell getCellIdentifier];
        progressData[@"title"] = _description;
        [progressCells addObject:progressData];
        _progressIndexPath = [NSIndexPath indexPathForRow:[progressCells indexOfObject:progressData]
                                                inSection:[data indexOfObject:progressSection]];
    }
    else
    {
        NSMutableArray<NSMutableDictionary *> *descriptionCells = [NSMutableArray array];
        NSMutableDictionary *descriptionSection = [NSMutableDictionary dictionary];
        descriptionSection[@"cells"] = descriptionCells;
        [data addObject:descriptionSection];

        NSMutableDictionary *descriptionData = [NSMutableDictionary dictionary];
        descriptionData[@"key"] = @"description_cell";
        descriptionData[@"type"] = [OATextLineViewCell getCellIdentifier];
        descriptionData[@"title"] = _description;
        [descriptionCells addObject:descriptionData];

        if (_screenType == EOADeleteAllDataConfirmBackupScreenType)
        {
            NSMutableArray<NSMutableDictionary *> *deleteCells = [NSMutableArray array];
            NSMutableDictionary *deleteSection = [NSMutableDictionary dictionary];
            deleteSection[@"cells"] = deleteCells;
            [data addObject:deleteSection];

            NSMutableDictionary *deleteData = [NSMutableDictionary dictionary];
            deleteData[@"key"] = @"delete_cell";
            deleteData[@"type"] = [OAFilledButtonCell getCellIdentifier];
            deleteData[@"title"] = OALocalizedString(@"delete_all_confirmation");
            deleteData[@"action"] = @"onDeleteButtonPressed";
            [deleteCells addObject:deleteData];
        }
    }

    _data = data;
}

- (NSMutableDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][@"cells"][indexPath.row];
}

- (BOOL)hideFirstHeader
{
    return YES;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    if (_progressIndexPath && _progressIndexPath.section == section)
        return _sectionDescription;

    return [super getTitleForFooter:section];
}

- (NSInteger)rowsCount:(NSInteger)section;
{
    return ((NSArray *) _data[section][@"cells"]).count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath;
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *cellType = item[@"type"];
    UITableViewCell *outCell = nil;

    if ([cellType isEqualToString:[OATextLineViewCell getCellIdentifier]])
    {
        OATextLineViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OATextLineViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextLineViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextLineViewCell *) nib[0];
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.textView.text = item[@"title"];
        }
        outCell = cell;
    }
    else if ([cellType isEqualToString:[OADownloadProgressBarCell getCellIdentifier]])
    {
        OADownloadProgressBarCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OADownloadProgressBarCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADownloadProgressBarCell getCellIdentifier] owner:self options:nil];
            cell = (OADownloadProgressBarCell *) nib[0];
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.progressStatusLabel.text = item[@"title"];

            float progress = (float) _progressFilesCompleteCount / _progressFilesTotalCount;
            cell.progressValueLabel.text = [NSString stringWithFormat:@"%i%%", (int) (progress * 100)];
            [cell.progressBarView setProgress:progress];
        }

        outCell = cell;
    }
    else if ([cellType isEqualToString:[OAFilledButtonCell getCellIdentifier]])
    {
        OAFilledButtonCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAFilledButtonCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *) nib[0];
        }
        if (cell)
        {
            cell.backgroundColor = UIColor.clearColor;
            cell.button.backgroundColor = UIColorFromRGB(color_support_red);
            [cell.button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            cell.button.layer.cornerRadius = 9;
            cell.topMarginConstraint.constant = 9.;
            cell.heightConstraint.constant = 42.;
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self
                            action:NSSelectorFromString(item[@"action"])
                  forControlEvents:UIControlEventTouchUpInside];
        }
        outCell = cell;
    }

    [outCell updateConstraintsIfNeeded];
    return outCell;
}

- (NSInteger)sectionsCount;
{
    return _data.count;
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    [self onCloseDeleteAllBackupData];
}

- (void)onTopButtonPressed
{
    [self onDeleteButtonPressed];
}

- (void)onBottomButtonPressed
{
    if (_screenType == EOARemoveOldVersionsBackupScreenType)
        [self onDeleteButtonPressed];
    else
        [self onCloseDeleteAllBackupData];
}

- (void)deleteBackupFiles
{
    BOOL isProgressOfDeleteAll = _screenType == EOADeleteAllDataProgressBackupScreenType;
    BOOL isProgressOfRemoveOld = _screenType == EOARemoveOldVersionsProgressBackupScreenType;
    if (isProgressOfDeleteAll)
        [[OABackupHelper sharedInstance] deleteAllFiles:nil listener:self];
    else if (isProgressOfRemoveOld)
        [[OABackupHelper sharedInstance] deleteOldFiles:nil listener:self];
}

- (void)updateAfterFinished
{
    if (_screenType == EOADeleteAllDataProgressBackupScreenType)
        _sectionDescription = OALocalizedString(@"backup_delete_all_data_finished");
    else if (_screenType == EOARemoveOldVersionsProgressBackupScreenType)
        _sectionDescription = OALocalizedString(@"backup_remove_old_versions_finished");

    [self generateData];
    [self.tableView reloadData];
    self.bottomButton.hidden = NO;

    [self onCompleteTasks];
    _isDeleted = YES;
}

- (void)onDeleteButtonPressed
{
    EOADeleteBackupScreenType nextScreen = _screenType;
    if (_screenType == EOADeleteAllDataBackupScreenType)
        nextScreen = EOADeleteAllDataConfirmBackupScreenType;
    else if (_screenType == EOADeleteAllDataConfirmBackupScreenType)
        nextScreen = EOADeleteAllDataProgressBackupScreenType;
    else if (_screenType == EOARemoveOldVersionsBackupScreenType)
        nextScreen = EOARemoveOldVersionsProgressBackupScreenType;

    OADeleteAllVersionsBackupViewController *deleteAllDataViewController = [[OADeleteAllVersionsBackupViewController alloc] initWithScreenType:nextScreen];
    deleteAllDataViewController.deleteDelegate = self;
    [self.navigationController pushViewController:deleteAllDataViewController animated:YES];
}

#pragma mark - OAOnDeleteFilesListener

- (void)onFilesDeleteStarted:(NSArray<OARemoteFile *> *)files
{
    _progressFilesTotalCount = files.count;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressIndexPath)
            [self.tableView reloadRowsAtIndexPaths:@[_progressIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)onFileDeleteProgress:(OARemoteFile *)file progress:(NSInteger)progress
{
    _progressFilesCompleteCount = progress;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_progressIndexPath)
            [self.tableView reloadRowsAtIndexPaths:@[_progressIndexPath] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (void)onFilesDeleteDone:(NSDictionary<OARemoteFile *, NSString *> *)errors
{
    _progressFilesCompleteCount = 1;
    _progressFilesTotalCount = 1;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAfterFinished];
    });
}

- (void)onFilesDeleteError:(NSInteger)status message:(NSString *)message
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateAfterFinished];
    });
}

#pragma mark - OADeleteAllVersionsBackupDelegate

- (void)onCloseDeleteAllBackupData
{
    BOOL isProgress = _screenType == EOADeleteAllDataProgressBackupScreenType
            || _screenType == EOARemoveOldVersionsProgressBackupScreenType;
    BOOL isConfirm = _screenType == EOADeleteAllDataConfirmBackupScreenType;
    if (isProgress || isConfirm)
    {
        for (UIViewController *controller in self.navigationController.viewControllers)
        {
            if ([controller isKindOfClass:[OASettingsBackupViewController class]])
            {
                [self.navigationController popToViewController:controller animated:YES];
                return;
            }
        }
    }

    [self dismissViewController];
}

- (void)onCompleteTasks
{
    if (!_isDeleted && self.deleteDelegate)
        [self.deleteDelegate onCompleteTasks];
}

@end
