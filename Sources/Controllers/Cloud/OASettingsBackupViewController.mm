//
//  OASettingsBackupViewController.mm
//  OsmAnd Maps
//
//  Created by Skalii on 20.08.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OASettingsBackupViewController.h"
#import "OACloudAccountLogoutViewController.h"
#import "OADeleteAllVersionsBackupViewController.h"
#import "OAMainSettingsViewController.h"
#import "OABaseBackupTypesViewController.h"
#import "OABackupTypesViewController.h"
#import "OAMultiIconsDescCustomCell.h"
#import "OAAppSettings.h"
#import "OABackupHelper.h"
#import "OAPrepareBackupResult.h"
#import "OAColors.h"
#import "Localization.h"

@interface OASettingsBackupViewController () <UITableViewDelegate, UITableViewDataSource, OACloudAccountLogoutDelegate, OADeleteAllVersionsBackupDelegate, OABackupTypesDelegate, OAOnDeleteFilesListener, OAOnPrepareBackupListener>

@property (weak, nonatomic) IBOutlet UIView *navigationBarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation OASettingsBackupViewController
{
    NSMutableArray<NSMutableArray<NSMutableDictionary *> *> *_data;
    NSMutableDictionary<NSNumber *, NSString *> *_headers;
    NSMutableDictionary<NSNumber *, NSString *> *_footers;

    OABackupHelper *_backupHelper;
    NSDictionary<NSString *, OARemoteFile *> *_uniqueRemoteFiles;

    NSIndexPath *_backupDataIndexPath;
    NSInteger _progressFilesCompleteCount;
    NSInteger _progressFilesTotalCount;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _backupHelper = [OABackupHelper sharedInstance];
    _uniqueRemoteFiles = [_backupHelper.backup getRemoteFiles:EOARemoteFilesTypeUnique];
    _progressFilesCompleteCount = 0;
    _progressFilesTotalCount = 1;
    _headers = [NSMutableDictionary dictionary];
    _footers = [NSMutableDictionary dictionary];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.sectionFooterHeight = 0.001;

    [self setupView];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [_backupHelper addPrepareBackupListener:self];
    if (![_backupHelper isBackupPreparing])
        [self onBackupPrepared:_backupHelper.backup];
    [_backupHelper.backupListeners addDeleteFilesListener:self];

    [self updateAfterDeleted];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_backupHelper removePrepareBackupListener:self];
    [_backupHelper.backupListeners removeDeleteFilesListener:self];
}

- (void)applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"shared_string_settings");
}

- (void)setupView
{
    NSMutableArray<NSMutableArray <NSMutableDictionary *> *> *data = [NSMutableArray array];

    NSMutableArray<NSMutableDictionary *> *osmAndCloudCells = [NSMutableArray array];
    [data addObject:osmAndCloudCells];
    _headers[@(data.count - 1)] = OALocalizedString(@"osmand_cloud");
    _footers[@(data.count - 1)] = OALocalizedString(@"select_backup_data_descr");

    NSMutableDictionary *backupData = [NSMutableDictionary dictionary];
    backupData[@"key"] = @"backup_data_cell";
    backupData[@"type"] = [OAMultiIconsDescCustomCell getCellIdentifier];
    backupData[@"title"] = OALocalizedString(@"backup_data");
    backupData[@"left_icon"] = @"ic_custom_cloud_upload_colored_day";
    NSString *sizeBackupDataString = [NSByteCountFormatter stringFromByteCount:
            [OABaseBackupTypesViewController calculateItemsSize:_uniqueRemoteFiles.allValues]
                                                     countStyle:NSByteCountFormatterCountStyleFile];
    backupData[@"right_icon"] = @"ic_custom_arrow_right";
    backupData[@"description"] = sizeBackupDataString;
    [osmAndCloudCells addObject:backupData];
    _backupDataIndexPath = [NSIndexPath indexPathForRow:[osmAndCloudCells indexOfObject:backupData]
                                              inSection:[data indexOfObject:osmAndCloudCells]];

    NSMutableArray<NSMutableDictionary *> *accountCells = [NSMutableArray array];
    [data addObject:accountCells];
    _headers[@(data.count - 1)] = OALocalizedString(@"shared_string_account");

    NSMutableDictionary *accountData = [NSMutableDictionary dictionary];
    accountData[@"key"] = @"account_cell";
    accountData[@"type"] = [OAMultiIconsDescCustomCell getCellIdentifier];
    accountData[@"title"] = [[OAAppSettings sharedManager].backupUserEmail get];
    accountData[@"right_icon"] = @"ic_custom_arrow_right";
    [accountCells addObject:accountData];

    NSMutableArray<NSMutableDictionary *> *dangerZoneCells = [NSMutableArray array];
    [data addObject:dangerZoneCells];
    _headers[@(data.count - 1)] = OALocalizedString(@"backup_danger_zone");
    _footers[@(data.count - 1)] = OALocalizedString(@"backup_delete_all_data_or_versions_descr");

    NSMutableDictionary *deleteAllData = [NSMutableDictionary dictionary];
    deleteAllData[@"key"] = @"delete_all_cell";
    deleteAllData[@"type"] = [OAMultiIconsDescCustomCell getCellIdentifier];
    deleteAllData[@"title"] = OALocalizedString(@"backup_delete_all_data");
    deleteAllData[@"text_color"] = UIColorFromRGB(color_support_red);
    deleteAllData[@"right_icon"] = @"ic_custom_arrow_right";
    [dangerZoneCells addObject:deleteAllData];

    NSMutableDictionary *removeVersionsData = [NSMutableDictionary dictionary];
    removeVersionsData[@"key"] = @"remove_versions_cell";
    removeVersionsData[@"type"] = [OAMultiIconsDescCustomCell getCellIdentifier];
    removeVersionsData[@"title"] = OALocalizedString(@"backup_delete_old_data");
    removeVersionsData[@"text_color"] = UIColorFromRGB(color_support_red);
    removeVersionsData[@"right_icon"] = @"ic_custom_arrow_right";
    [dangerZoneCells addObject:removeVersionsData];

    _data = data;
}

- (NSMutableDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (void)updateAfterDeleted
{
    if (_backupDataIndexPath)
    {
        NSString *sizeBackupDataString = [NSByteCountFormatter stringFromByteCount:
                [OABaseBackupTypesViewController calculateItemsSize:_uniqueRemoteFiles.allValues]
                                                                        countStyle:NSByteCountFormatterCountStyleFile];
        _data[_backupDataIndexPath.section][_backupDataIndexPath.row][@"description"] = sizeBackupDataString;
        [UIView performWithoutAnimation:^{
            [self.tableView reloadRowsAtIndexPaths:@[_backupDataIndexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
        }];

        if (self.backupTypesDelegate)
            [self.backupTypesDelegate onAllFilesDeleted];
    }
}

- (IBAction)backButtonClicked:(id)sender
{
    [self dismissViewController];
}

#pragma mark - OACloudAccountLogoutDelegate

- (void)onLogout
{
    [[OABackupHelper sharedInstance] logout];

    for (UIViewController *controller in self.navigationController.viewControllers)
    {
        if ([controller isKindOfClass:OAMainSettingsViewController.class])
        {
            [self.navigationController popToViewController:controller animated:YES];
            return;
        }
    }

    [self dismissViewController];
}

#pragma mark - OADeleteAllVersionsBackupDelegate

- (void)onCloseDeleteAllBackupData
{
}

- (void)onAllFilesDeleted
{
    [_backupHelper prepareBackup];
}

#pragma mark - OABackupTypesDelegate

- (void)setProgressTotal:(NSInteger)total
{
    _progressFilesTotalCount = total;
}

#pragma mark - OAOnDeleteFilesListener

- (void)onFilesDeleteStarted:(NSArray<OARemoteFile *> *)files
{
    _progressFilesTotalCount = files.count;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            [self.progressView setProgress:0.0 animated:NO];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            [self.progressView setProgress:1.0 animated:YES];
        } completion:^(BOOL finished) {
            self.progressView.hidden = YES;
            [_backupHelper prepareBackup];
            _progressFilesCompleteCount = 0;
            _progressFilesTotalCount = 1;
        }];
    });
}

- (void) onFilesDeleteError:(NSInteger)status message:(NSString *)message
{
    [_backupHelper prepareBackup];
    _progressFilesCompleteCount = 0;
    _progressFilesTotalCount = 1;
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressView setProgress:_progressFilesCompleteCount animated:NO];
    });
}

#pragma mark - OAOnPrepareBackupListener

- (void)onBackupPreparing
{
    [UIView animateWithDuration:0.3 animations:^{
        [self.progressView setProgress:0.1 animated:NO];
        self.progressView.hidden = NO;
    }];
}

- (void)onBackupPrepared:(OAPrepareBackupResult *)backupResult
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 animations:^{
            [self.progressView setProgress:1.0 animated:YES];
            _uniqueRemoteFiles = [backupResult getRemoteFiles:EOARemoteFilesTypeUnique];
            [self updateAfterDeleted];
        } completion:^(BOOL finished) {
            self.progressView.hidden = YES;
        }];
    });
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *cellType = item[@"type"];
    UITableViewCell *outCell = nil;

    if ([cellType isEqualToString:[OAMultiIconsDescCustomCell getCellIdentifier]])
    {
        OAMultiIconsDescCustomCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAMultiIconsDescCustomCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMultiIconsDescCustomCell getCellIdentifier] owner:self options:nil];
            cell = (OAMultiIconsDescCustomCell *) nib[0];
            [cell valueVisibility:NO];
        }
        if (cell)
        {
            BOOL leftIconVisible = [item.allKeys containsObject:@"left_icon"];
            cell.separatorInset = UIEdgeInsetsMake(0., leftIconVisible ? 66. : 20., 0., 0.);

            [cell leftIconVisibility:leftIconVisible];
            cell.leftIconView.image = [UIImage imageNamed:item[@"left_icon"]];

            [cell rightIconVisibility:[item.allKeys containsObject:@"right_icon"]];
            cell.rightIconView.image = [UIImage templateImageNamed:item[@"right_icon"]];
            cell.rightIconView.tintColor = UIColorFromRGB(color_tint_gray);

            [cell descriptionVisibility:[item.allKeys containsObject:@"description"]];
            cell.descriptionLabel.text = item[@"description"];

            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.textColor = [item.allKeys containsObject:@"text_color"] ? item[@"text_color"] : UIColor.blackColor;
        }
        outCell = cell;
    }

    return outCell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _headers[@(section)];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _footers[@(section)];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *header = _headers[@(section)];
    if (header)
    {
        UIFont *font = [UIFont systemFontOfSize:13.];
        CGFloat headerHeight = [OAUtilities calculateTextBounds:header
                                                          width:tableView.frame.size.width - (20. + [OAUtilities getLeftMargin]) * 2
                                                           font:font].height + 38.;
        return headerHeight;
    }

    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSString *footer = _footers[@(section)];
    if (footer)
    {
        UIFont *font = [UIFont systemFontOfSize:13.];
        CGFloat footerHeight = [OAUtilities calculateTextBounds:footer
                                                          width:tableView.frame.size.width - (20. + [OAUtilities getLeftMargin]) * 2
                                                           font:font].height + 16.;
        return footerHeight;
    }

    return 0.001;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *key = item[@"key"];

    if ([key isEqualToString:@"backup_data_cell"])
    {
        OABackupTypesViewController *backupDataController = [[OABackupTypesViewController alloc] init];
        backupDataController.backupTypesDelegate = self;
        [self.navigationController pushViewController:backupDataController animated:YES];
    }
    else if ([key isEqualToString:@"account_cell"])
    {
        OACloudAccountLogoutViewController *logoutViewController = [[OACloudAccountLogoutViewController alloc] init];
        logoutViewController.logoutDelegate = self;
        [self presentViewController:logoutViewController animated:YES completion:nil];
    }
    else if ([key isEqualToString:@"delete_all_cell"])
    {
        OADeleteAllVersionsBackupViewController *deleteAllDataViewController = [[OADeleteAllVersionsBackupViewController alloc] initWithScreenType:EOADeleteAllDataBackupScreenType];
        deleteAllDataViewController.deleteDelegate = self;
        [self.navigationController pushViewController:deleteAllDataViewController animated:YES];
    }
    else if ([key isEqualToString:@"remove_versions_cell"])
    {
        OADeleteAllVersionsBackupViewController *removeOldVersionsViewController = [[OADeleteAllVersionsBackupViewController alloc] initWithScreenType:EOARemoveOldVersionsBackupScreenType];
        removeOldVersionsViewController.deleteDelegate = self;
        [self.navigationController pushViewController:removeOldVersionsViewController animated:YES];
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
