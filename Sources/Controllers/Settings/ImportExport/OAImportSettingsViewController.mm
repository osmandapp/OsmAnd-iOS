//
//  OAImportProfileViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAImportSettingsViewController.h"
#import "OAImportDuplicatesViewController.h"
#import "OAImportCompleteViewController.h"
#import "OASettingsImporter.h"
#import "OsmAndApp.h"
#import "OAProgressTitleCell.h"
#import "Localization.h"

#include <OsmAndCore/ArchiveReader.h>

@implementation OAImportSettingsViewController
{
    OASettingsHelper *_settingsHelper;
    NSArray<OASettingsItem *> *_settingsItems;
    BOOL _isNewItems;
    NSString *_file;
    QList<OsmAnd::ArchiveReader::Item> _archiveItems;

    BOOL _importStarted;
}

#pragma mark - Initialization

- (instancetype)initWithItems:(NSArray<OASettingsItem *> *)items
{
    self = [super init];
    if (self)
    {
        _settingsItems = [NSArray arrayWithArray:items];
        [self postInit];
    }
    return self;
}

- (void)commonInit
{
    [super commonInit];

    _settingsHelper = [OASettingsHelper sharedInstance];
}

- (void)postInit
{
    OAImportAsyncTask *importTask = _settingsHelper.importTask;
    if (!_isNewItems && importTask && _settingsItems)
    {
        if (!_file)
        {
            _file = importTask.getFile;
            _archiveItems = OsmAnd::ArchiveReader(QString::fromNSString(_file)).getItems();
        }

        NSArray *duplicates = [importTask getDuplicates];
        NSArray *selectedItems = [importTask getSelectedItems];

        if (!duplicates)
        {
            importTask.delegate = self;
        }
        else if (duplicates.count == 0)
        {
            if (selectedItems && _file)
                [_settingsHelper importSettings:_file items:selectedItems latestChanges:@"" version:1 delegate:self];
        }
    }

    if (_settingsItems)
    {
        self.itemsMap = [OASettingsHelper getSettingsToOperateByCategory:_settingsItems importComplete:NO addEmptyItems:NO];
        self.itemTypes = self.itemsMap.allKeys;
    }
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated
{
    if (_importStarted)
    {
        _importStarted = NO;
        [self showActivityIndicatorWithLabel:@""];
    }

    [super viewWillAppear:animated];
}

#pragma mark - Base setup UI

- (void)updateUI
{
    [super updateUI];
    _isNewItems = NO;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    OAImportAsyncTask *importTask = _settingsHelper.importTask;
    EOAImportType importTaskType = _isNewItems ? EOAImportTypeCollect : [importTask getImportType];
    if (importTaskType == EOAImportTypeCheckDuplicates)
        return OALocalizedString(@"shared_string_preparing");
    else if (importTaskType == EOAImportTypeImport)
        return OALocalizedString(@"importing_from");
    else
        return OALocalizedString(@"shared_string_import");
}

- (NSString *)getTableHeaderDescription
{
    OAImportAsyncTask *importTask = _settingsHelper.importTask;
    EOAImportType importTaskType = _isNewItems ? EOAImportTypeCollect : [importTask getImportType];
    if (importTaskType == EOAImportTypeCheckDuplicates)
        return OALocalizedString(@"checking_for_duplicate_description");
    else if (importTaskType == EOAImportTypeImport)
        return OALocalizedString(@"shared_string_importing");
    else if (_settingsItems)
        return OALocalizedString(@"select_data_to_import");
    else
        return @"";
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return _importStarted ? nil : [super getRightNavbarButtons];
}

#pragma mark - Table data

- (void)generateData
{
    if (_settingsItems)
    {
        [super generateData];
    }
    else
    {
        OATableCollapsableGroup *group = [[OATableCollapsableGroup alloc] init];
        group.type = [OAProgressTitleCell getCellIdentifier];
        group.groupName = OALocalizedString(@"reading_file");
        self.data = @[group];
    }
}

- (BOOL)hideFirstHeader
{
    return YES;
}

- (BOOL)refreshOnAppear
{
    return _importStarted;
}

#pragma mark - Additions

- (long)getItemSize:(NSString *)item
{
    NSString *fileName = item.lastPathComponent;
    const auto fileNameStr = QString::fromNSString(fileName);
    for (const auto& item : _archiveItems)
    {
        if (item.name.endsWith(fileNameStr))
            return item.size;
    }
    return 0;
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    [OAUtilities denyAccessToFile:_file removeFromInbox:YES];
    [self dismissViewController];
}

- (void)onBottomButtonPressed
{
    _importStarted = YES;

    if (_file)
        [self showActivityIndicatorWithLabel:OALocalizedString(@"checking_for_duplicates")];

    NSArray <OASettingsItem *> *selectedItems = [_settingsHelper prepareSettingsItems:[self getSelectedItems] settingsItems:_settingsItems doExport:NO];
    if (_file && _settingsItems)
        [_settingsHelper checkDuplicates:_file items:_settingsItems selectedItems:selectedItems delegate:self];
}

#pragma mark - OASettingsImportExportDelegate

- (void)onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items
{
    if (succeed)
    {
        [self.tableView reloadData];
        OAImportCompleteViewController* importCompleteVC = [[OAImportCompleteViewController alloc] initWithSettingsItems:[OASettingsHelper getSettingsToOperate:items importComplete:YES addEmptyItems:NO] fileName:[_file lastPathComponent]];
        [self showViewController:importCompleteVC];
        _settingsHelper.importTask = nil;
        [OAUtilities denyAccessToFile:_file removeFromInbox:YES];
    }
    _settingsHelper.importTask = nil;
}

- (void)onDuplicatesChecked:(NSArray<OASettingsItem *> *)duplicates items:(NSArray<OASettingsItem *> *)items
{
    [self processDuplicates:duplicates items:items];
}

- (void)processDuplicates:(NSArray<OASettingsItem *> *)duplicates items:(NSArray<OASettingsItem *> *)items
{
    if (_file)
    {
        if (duplicates.count == 0)
        {
            [self showActivityIndicatorWithLabel:OALocalizedString(@"shared_string_importing")];
            [_settingsHelper importSettings:_file items:items latestChanges:@"" version:1 delegate:self];
        }
        else
        {
            OAImportDuplicatesViewController *dublicatesVC = [[OAImportDuplicatesViewController alloc] initWithDuplicatesList:duplicates settingsItems:items file:_file];
            [self showViewController:dublicatesVC];
        }
    }
}

- (void)onItemsCollected:(NSArray<OASettingsItem *> *)items filePath:(NSString *)filePath
{
    _isNewItems = YES;
    _settingsItems = items;
    _file = filePath;
    _archiveItems = OsmAnd::ArchiveReader(QString::fromNSString(_file)).getItems();
    if (_settingsItems)
    {
        [self postInit];
        [self updateUI];
    }
}

@end
