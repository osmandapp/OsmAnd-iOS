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
    NSString *_descriptionText;
    NSString *_descriptionBoldText;
    QList<OsmAnd::ArchiveReader::Item> _archiveItems;
    NSString *_headerLabel;
}

- (instancetype) initWithItems:(NSArray<OASettingsItem *> *)items
{
    self = [super init];
    if (self)
    {
        _settingsItems = [NSArray arrayWithArray:items];
    }
    return self;
}

- (void)commonInit
{
    _settingsHelper = OASettingsHelper.sharedInstance;
}

- (void) viewDidLoad
{
    _descriptionText = OALocalizedString(@"import_profile_select_descr");
    _descriptionBoldText = nil;
    [super viewDidLoad];
}

- (void) setupView
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
        self.itemsMap = [OASettingsHelper getSettingsToOperateByCategory:_settingsItems importComplete:NO];
        self.itemTypes = self.itemsMap.allKeys;
        [self generateData];
    }
    else
    {
        OATableCollapsableGroup *group = [[OATableCollapsableGroup alloc] init];
        group.type = [OAProgressTitleCell getCellIdentifier];
        group.groupName = OALocalizedString(@"reading_file");
        self.data = @[group];
    }
    
    EOAImportType importTaskType = _isNewItems ? EOAImportTypeCollect : [importTask getImportType];
    
    if (importTaskType == EOAImportTypeCheckDuplicates)
    {
        [self updateUI:OALocalizedString(@"shared_string_preparing") descriptionRes:OALocalizedString(@"checking_for_duplicate_description") activityLabel:OALocalizedString(@"checking_for_duplicates")];
    }
    else if (importTaskType == EOAImportTypeImport)
    {
        [self updateUI:OALocalizedString(@"shared_string_importing") descriptionRes:OALocalizedString(@"importing_from") activityLabel:OALocalizedString(@"shared_string_importing")];
    }
    else
        [self setTableHeaderView:OALocalizedString(@"shared_string_import")];

    _isNewItems = NO;
}

- (void) updateUI:(NSString *)toolbarTitleRes descriptionRes:(NSString *)descriptionRes activityLabel:(NSString *)activityLabel
{
    if (_file)
    {
        NSString *filename = [_file lastPathComponent];
        [self setTableHeaderView:toolbarTitleRes];
        _descriptionText = [NSString stringWithFormat:descriptionRes, filename];
        _descriptionBoldText = filename;
        self.bottomBarView.hidden = YES;
        [self showActivityIndicatorWithLabel:activityLabel];
        [self.tableView reloadData];
    }
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

- (NSString *) descriptionText
{
    return _descriptionText;
}

- (NSString *) descriptionBoldText
{
    return _descriptionBoldText;
}

- (long)getItemSize:(NSString *)item
{
    NSString *fileName = item.lastPathComponent;
    const auto fileNameStr = QString::fromNSString(fileName);
    for (const auto& item : _archiveItems)
    {
        if (item.name.endsWith(fileNameStr))
        {
            return item.size;
        }
    }
    return 0;
}

- (void) importItems
{
    [self updateUI:OALocalizedString(@"shared_string_preparing") descriptionRes:OALocalizedString(@"checking_for_duplicate_description") activityLabel:OALocalizedString(@"checking_for_duplicates")];
    NSArray <OASettingsItem *> *selectedItems = [_settingsHelper prepareSettingsItems:[self getSelectedItems] settingsItems:_settingsItems doExport:NO];
    
    if (_file && _settingsItems)
        [_settingsHelper checkDuplicates:_file items:_settingsItems selectedItems:selectedItems delegate:self];
}

#pragma mark - Actions

- (IBAction) primaryButtonPressed:(id)sender
{
    [self importItems];
}

- (IBAction) backButtonPressed:(id)sender
{
    [OAUtilities denyAccessToFile:_file removeFromInbox:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - OASettingsImportExportDelegate

- (void) onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items
{
    if (succeed)
    {
        [self.tableView reloadData];
        OAImportCompleteViewController* importCompleteVC = [[OAImportCompleteViewController alloc] initWithSettingsItems:[OASettingsHelper getSettingsToOperate:items importComplete:YES] fileName:[_file lastPathComponent]];
        [self.navigationController pushViewController:importCompleteVC animated:YES];
        _settingsHelper.importTask = nil;
        [OAUtilities denyAccessToFile:_file removeFromInbox:YES];
    }
}

- (void) onDuplicatesChecked:(NSArray<OASettingsItem *> *)duplicates items:(NSArray<OASettingsItem *> *)items
{
    [self processDuplicates:duplicates items:items];
}

- (void) processDuplicates:(NSArray<OASettingsItem *> *)duplicates items:(NSArray<OASettingsItem *> *)items
{
    if (_file)
    {
        if (duplicates.count == 0)
        {
            [self updateUI:OALocalizedString(@"shared_string_importing") descriptionRes:OALocalizedString(@"importing_from") activityLabel:OALocalizedString(@"shared_string_importing")];
            [_settingsHelper importSettings:_file items:items latestChanges:@"" version:1 delegate:self];
        }
        else
        {
            OAImportDuplicatesViewController *dublicatesVC = [[OAImportDuplicatesViewController alloc] initWithDuplicatesList:duplicates settingsItems:items file:_file];
            [self.navigationController pushViewController:dublicatesVC animated:YES];
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
        [self setupView];
        [self.tableView reloadData];
    }
}

@end
