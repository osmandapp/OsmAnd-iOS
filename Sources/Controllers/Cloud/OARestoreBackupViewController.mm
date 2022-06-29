//
//  OARestoreBackupViewController.m
//  OsmAnd
//
//  Created by Paul on 08.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OARestoreBackupViewController.h"
#import "OARootViewController.h"
#import "OANetworkSettingsHelper.h"
#import "OABackupHelper.h"
#import "Localization.h"
#import "OAProgressTitleCell.h"
#import "OASettingsHelper.h"
#import "OATableViewCustomHeaderView.h"
#import "OAExportSettingsType.h"
#import "OAImportBackupTask.h"
#import "OAPrepareBackupResult.h"
#import "OABackupInfo.h"
#import "OARemoteFile.h"
#import "OsmAndApp.h"
#import "OAColors.h"

@interface OARestoreBackupViewController () <OACheckDuplicatesListener, OAImportListener, OAOnPrepareBackupListener, OABackupCollectListener>

@end

@implementation OARestoreBackupViewController
{
    OANetworkSettingsHelper *_settingsHelper;
    OABackupHelper *_backupHelper;

    BOOL _exportStarted;
    BOOL _fetchingBackup;
    NSString *_fileSize;
    NSString *_headerLabel;
}

- (void)commonInit
{
    _settingsHelper = OANetworkSettingsHelper.sharedInstance;
    _backupHelper = OABackupHelper.sharedInstance;
    _fetchingBackup = YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    _fetchingBackup = YES;
    [self setupView];
    [_backupHelper addPrepareBackupListener:self];
    OAImportBackupTask *importTask = [_settingsHelper getImportTask:kRestoreItemsKey];
    if (importTask != nil)
    {
        if (!self.itemsMap)
        {
            self.itemsMap = [OASettingsHelper getSettingsToOperateByCategory:importTask.items importComplete:NO];
            _fetchingBackup = importTask.items.count == 0;
        }
        NSArray *duplicates = importTask.duplicates;
        NSArray<OASettingsItem *> *selectedItems = importTask.selectedItems;
        if (duplicates == nil)
        {
            importTask.duplicatesListener = self;
        }
        else if (duplicates.count == 0 && selectedItems != nil)
        {
            @try
            {
                [_settingsHelper importSettings:kRestoreItemsKey items:selectedItems forceReadData:NO listener:self];
            }
            @catch (NSException *e)
            {
                NSLog(@"Backup restoration error: %@", e.reason);
            }
        }
    }
    [self collectItems];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_backupHelper removePrepareBackupListener:self];
}

-(void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self setTableHeaderView:self.descriptionBoldText];
    } completion:nil];
}

- (void)setupView
{
    [self setTableHeaderView:self.descriptionBoldText];
    
    if (_exportStarted || _fetchingBackup)
    {
        OATableCollapsableGroup *group = [[OATableCollapsableGroup alloc] init];
        group.type = [OAProgressTitleCell getCellIdentifier];
        group.groupName = _fetchingBackup ? OALocalizedString(@"shared_string_preparing") : OALocalizedString(@"preparing_file");
        self.data = @[group];
        self.additionalNavBarButton.hidden = YES;
        return;
    }
    [self generateData];
    [self updateControls];
}

- (void) collectItems
{
    if (!_backupHelper.isBackupPreparing)
        [self collectAndReadSettings];
}

- (void) collectAndReadSettings
{
    @try
    {
        [_settingsHelper collectSettings:kRestoreItemsKey readData:YES listener:self];
    }
    @catch (NSException *e)
    {
        NSLog(@"Restore backup error: %@", e.reason);
    }
}

- (NSString *)descriptionText
{
    return _fetchingBackup ? OALocalizedString(@"shared_string_preparing") : OALocalizedString(@"choose_what_to_restore");
}

- (NSString *)descriptionBoldText
{
    return OALocalizedString(@"restore_from_osmand_cloud");
}

- (NSString *)getTitleForSection
{
    return [NSString stringWithFormat: @"%@\n%@", self.descriptionText, _fileSize];
}

- (void)onGroupCheckmarkPressed:(UIButton *)sender
{
    [super onGroupCheckmarkPressed:sender];
    //    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

- (IBAction)primaryButtonPressed:(id)sender
{
    
}

#pragma mark - UITableViewDelegate

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
        [customHeader setYOffset:8];
        UITextView *headerLabel = customHeader.label;
        NSMutableAttributedString *newHeaderText = [[NSMutableAttributedString alloc] initWithString:self.descriptionText attributes:@{NSForegroundColorAttributeName:UIColorFromRGB(color_text_footer)}];
        headerLabel.attributedText = newHeaderText;
        headerLabel.font = [UIFont systemFontOfSize:15];
        return customHeader;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        NSString *title = [self getTitleForSection];
        return [OATableViewCustomHeaderView getHeight:title width:tableView.bounds.size.width] + 8;
    }
    return UITableViewAutomaticDimension;
}

- (void) setTableHeaderView:(NSString *)label
{
    _headerLabel = label;
    [super setTableHeaderView:label];
    self.titleLabel.text = label;
}

- (NSString *) getTableHeaderTitle
{
    return _headerLabel;
}

#pragma mark - OASettingItemsSelectionDelegate

- (void)onItemsSelected:(NSArray *)items type:(OAExportSettingsType *)type
{
    //    self.selectedItemsMap[type] = items;
    //    [self updateFileSize];
    //    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    //
    //    OAExportSettingsCategory * category = [type getCategory];
    //    NSInteger indexCategory = [self.itemTypes indexOfObject:category];
    //    if (category && indexCategory != 0)
    //        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:indexCategory] withRowAnimation:UITableViewRowAnimationNone];
    
    [self updateControls];
}

// MARK: OABackupCollectListener

- (void)onBackupCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items remoteFiles:(NSArray<OARemoteFile *> *)remoteFiles
{
    _fetchingBackup = NO;
    if (succeed)
    {
        OAPrepareBackupResult *backup = _backupHelper.backup;
        OABackupInfo *info = backup.backupInfo;
        NSMutableSet<OASettingsItem *> *itemsForRestore = [NSMutableSet set];
        if (info != nil)
        {
            for (OARemoteFile *remoteFile in info.filesToDownload)
            {
                OASettingsItem *restoreItem = [self getRestoreItem:items remoteFile:remoteFile];
                if (restoreItem != nil)
                    [itemsForRestore addObject:restoreItem];
            }
        }
        self.itemsMap = [OASettingsHelper getSettingsToOperateByCategory:items importComplete:NO];
        self.itemTypes = self.itemsMap.allKeys;
        [self setupView];
        [self.tableView reloadData];
    }
}

- (OASettingsItem *) getRestoreItem:(NSArray<OASettingsItem *> *)items remoteFile:(OARemoteFile *)remoteFile
{
    for (OASettingsItem *item in items)
    {
        if ([OABackupHelper applyItem:item type:remoteFile.type name:remoteFile.name])
            return item;
    }
    return nil;
}


- (void)onImportFinished:(BOOL)succeed needRestart:(BOOL)needRestart items:(NSArray<OASettingsItem *> *)items {
    if (succeed)
    {
        OsmAndAppInstance app = OsmAndApp.instance;
        app.resourcesManager->rescanUnmanagedStoragePaths();
        [app.localResourcesChangedObservable notifyEvent];
        [app loadRoutingFiles];
//        reloadIndexes(items);
//        AudioVideoNotesPlugin plugin = OsmandPlugin.getPlugin(AudioVideoNotesPlugin.class);
//        if (plugin != null) {
//            plugin.indexingFiles(true, true);
//        }
    }
    [self onSettingsImportFinished:succeed items:items];
}

- (void)onImportItemFinished:(NSString *)type fileName:(NSString *)fileName {
}

- (void)onImportItemProgress:(NSString *)type fileName:(NSString *)fileName value:(int)value {
}

- (void)onImportItemStarted:(NSString *)type fileName:(NSString *)fileName work:(int)work {
}

- (void)onBackupPrepared:(nonnull OAPrepareBackupResult *)backupResult {
    [self collectAndReadSettings];
}

- (void)onBackupPreparing {

}

- (void)onDuplicatesChecked:(NSArray<OASettingsItem *> *)duplicates items:(NSArray<OASettingsItem *> *)items {
//    long spentTime = NS
//    System.currentTimeMillis() - duplicateStartTime;
//    if (spentTime < MIN_DELAY_TIME_MS) {
//        long delay = MIN_DELAY_TIME_MS - spentTime;
//        app.runInUIThread(() -> processDuplicates(duplicates, items), delay);
//    } else {
//        processDuplicates(duplicates, items);
//    }
}

@end
