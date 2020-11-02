//
//  OACheckForProfileDuplicatesViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACheckForProfileDuplicatesViewController.h"
#import "OAImportDuplicatesViewController.h"
#import "OAImportCompleteViewController.h"
#import "OAActivityViewWithTitleCell.h"
#import "OASettingsHelper.h"
#import "OASettingsImporter.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OAQuickAction.h"
#import "OAPOIUIFilter.h"
#import "OAMapSource.h"
#import "OAResourcesUIHelper.h"
#import "OAAvoidRoadInfo.h"
#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16
#define kTopPadding 6
#define kBottomPadding 32
#define kCellTypeWithActivity @"OAActivityViewWithTitleCell"

@interface OACheckForProfileDuplicatesViewController() <UITableViewDelegate, UITableViewDataSource, OASettingsImportExportDelegate>

@end

@implementation OACheckForProfileDuplicatesViewController
{
    OASettingsHelper *_settingsHelper;
    CGFloat _heightForHeader;
    NSArray<OASettingsItem *> *_settingsItems;
    NSArray<OASettingsItem *> *_selectedItems;
    NSString *_file;
    BOOL _checkingDuplicates;
}

- (instancetype) initWithItems:(NSArray<OASettingsItem *> *)items file:(NSString *)file selectedItems:(NSArray<OASettingsItem *> *)selectedItems
{
    self = [super init];
    if (self)
    {
        _settingsHelper = OASettingsHelper.sharedInstance;
        _settingsItems = [NSArray arrayWithArray:items];
        _file = file;
        _selectedItems = [NSArray arrayWithArray:selectedItems];
    }
    return self;
}

- (void) applyLocalization
{
    [self.backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"Preparing");
}

- (void) viewDidLoad
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    self.bottomBarView.hidden = YES;
    self.primaryBottomButton.hidden = YES;
    self.secondaryBottomButton.hidden = YES;
    self.additionalNavBarButton.hidden = YES;
    [super viewDidLoad];
}

- (void) prepareToImport
{
    NSArray <OASettingsItem *> *selectedSettingsItems = [self getSettingsItemsFromData];
    if (_file && _settingsItems)
    {
        OAImportAsyncTask *task = [[OAImportAsyncTask alloc] initWithFile:_file items:_settingsItems selectedItems:selectedSettingsItems];
        task.delegate = self;
        [task execute];
    }
}

- (OAProfileSettingsItem *) getBaseProfileSettingsItem:(OAApplicationModeBean *)modeBean
{
    for (OASettingsItem *settingsItem in _settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeProfile)
        {
            OAProfileSettingsItem *profileItem = (OAProfileSettingsItem *)settingsItem;
            OAApplicationModeBean *bean = [profileItem modeBean];
            if ([bean.stringKey isEqualToString:modeBean.stringKey] && [bean.userProfileName isEqualToString:modeBean.userProfileName])
                return profileItem;
        }
    }
    
    return nil;
}

- (OAQuickActionsSettingsItem *) getBaseQuickActionsSettingsItem
{
    for (OASettingsItem * settingsItem in _settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeQuickActions)
            return (OAQuickActionsSettingsItem *)settingsItem;
    }
    return nil;
}
 
- (OAPoiUiFilterSettingsItem *) getBasePoiUiFiltersSettingsItem
{
    for (OASettingsItem * settingsItem in _settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypePoiUIFilters)
            return (OAPoiUiFilterSettingsItem *)settingsItem;
    }
    return nil;
}

- (OAMapSourcesSettingsItem *) getBaseMapSourcesSettingsItem
{
    for (OASettingsItem * settingsItem in _settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeMapSources)
            return (OAMapSourcesSettingsItem *)settingsItem;
    }
    return nil;
}

- (OAAvoidRoadsSettingsItem *) getBaseAvoidRoadsSettingsItem
{
    for (OASettingsItem * settingsItem in _settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeAvoidRoads)
            return (OAAvoidRoadsSettingsItem *)settingsItem;
    }
    return nil;
}

- (NSArray <OASettingsItem *>*) getSettingsItemsFromData
{
    NSMutableArray<OASettingsItem *> *settingsItems = [NSMutableArray array];
    NSMutableArray<OAApplicationModeBean *> *appModeBeans = [NSMutableArray array];
    NSMutableArray<OAQuickAction *> *quickActions = [NSMutableArray array];
    NSMutableArray<OAPOIUIFilter *> *poiUIFilters = [NSMutableArray array];
    NSMutableArray<OAMapSource *> *tileSourceTemplates = [NSMutableArray array]; // to check type
    NSMutableArray<OAAvoidRoadInfo *> *avoidRoads = [NSMutableArray array];
    
    for (NSObject *object in _selectedItems)
    {
        if ([object isKindOfClass:OAApplicationModeBean.class])
            [appModeBeans addObject:(OAApplicationModeBean *)object];
        else if ([object isKindOfClass:OAQuickAction.class])
            [quickActions addObject:(OAQuickAction *)object];
        else if ([object isKindOfClass:OAPOIUIFilter.class])
            [poiUIFilters addObject:(OAPOIUIFilter *)object];
        else if ([object isKindOfClass:OASqliteDbResourceItem.class] || [object isKindOfClass:OAOnlineTilesResourceItem.class])
            [tileSourceTemplates addObject:(OAMapSource *)object]; // to check type
        else if ([object isKindOfClass:NSString.class]) // to check all
            [settingsItems addObject: [[OAFileSettingsItem alloc] initWithFilePath:(NSString *)object error:nil]];
        else if ([object isKindOfClass:OAAvoidRoadInfo.class])
            [avoidRoads addObject:(OAAvoidRoadInfo *)object];
    }
    if (appModeBeans.count > 0)
        for (OAApplicationModeBean *modeBean in appModeBeans)
            [settingsItems addObject:[self getBaseProfileSettingsItem:modeBean]];
    if (quickActions.count > 0)
        [settingsItems addObject:[self getBaseQuickActionsSettingsItem]];
    if (poiUIFilters.count > 0)
        [settingsItems addObject:[self getBasePoiUiFiltersSettingsItem]];
    if (tileSourceTemplates.count > 0)
        [settingsItems addObject:[self getBaseMapSourcesSettingsItem]];
    if (avoidRoads.count > 0)
        [settingsItems addObject:[self getBaseAvoidRoadsSettingsItem]];
    return settingsItems;
}

#pragma mark - Table View

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self generateHeaderForTableView:tableView withFirstSectionText:(NSString *)OALocalizedString(@"checking_for_duplicates_descr") boldFragment:[_file lastPathComponent] forSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self generateHeightForHeaderWithFirstHeaderText:OALocalizedString(@"checking_for_duplicates_descr") boldFragment:[_file lastPathComponent] inSection:section];
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const identifierCell = kCellTypeWithActivity;
    OAActivityViewWithTitleCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
        cell = (OAActivityViewWithTitleCell *)[nib objectAtIndex:0];
    }
    if (cell)
    {
        cell.titleView.text = OALocalizedString(@"checking_for_duplicates");
        
        BOOL inProgress = YES; // to change
        if (inProgress)
        {
            cell.activityIndicatorView.hidden = NO;
            [cell.activityIndicatorView startAnimating];
        }
        else
        {
            cell.activityIndicatorView.hidden = YES;
            [cell.activityIndicatorView startAnimating];
        }
    }
    return cell;
}

//MARK: OASettingsImportExportDelegate

- (void) onDuplicatesChecked:(NSArray<OASettingsItem *>*)duplicates items:(NSArray<OASettingsItem *>*)items
{
    if (duplicates.count == 0)
    {
        [_settingsHelper importSettings:_file items:[self getSettingsItemsFromData] latestChanges:@"" version:1 delegate:self];
    }
    else
    {
        OAImportDuplicatesViewController *dublicatesVC = [[OAImportDuplicatesViewController alloc] initWithDuplicatesList:duplicates settingsItems:[self getSettingsItemsFromData] file:_file];
        [self.navigationController pushViewController:dublicatesVC animated:YES];
    }
}

- (void) onSettingsImportFinished:(BOOL)succeed items:(nonnull NSArray<OASettingsItem *> *)items {
    if (succeed)
    {
        OAImportCompleteViewController* importCompleteVC = [[OAImportCompleteViewController alloc] initWithSettingsItems:items fileName:[_file lastPathComponent]];
        [self.navigationController pushViewController:importCompleteVC animated:YES];
        _settingsHelper.importTask = nil;
    }
}

@end
