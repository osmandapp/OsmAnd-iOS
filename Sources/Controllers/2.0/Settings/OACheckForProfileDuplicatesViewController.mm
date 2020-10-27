//
//  OACheckForProfileDuplicatesViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 19.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OACheckForProfileDuplicatesViewController.h"
#import "OAImportDuplicatesViewController.h"
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

- (OAProfileSettingsItem *)getBaseProfileSettingsItem:(OAApplicationModeBean *)modeBean
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

- (OAQuickActionsSettingsItem *)getBaseQuickActionsSettingsItem
{
    for (OASettingsItem * settingsItem in _settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeQuickActions)
            return (OAQuickActionsSettingsItem *)settingsItem;
    }
    return nil;
}
 
- (OAPoiUiFilterSettingsItem *)getBasePoiUiFiltersSettingsItem
{
    for (OASettingsItem * settingsItem in _settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypePoiUIFilters)
            return (OAPoiUiFilterSettingsItem *)settingsItem;
    }
    return nil;
}

- (OAMapSourcesSettingsItem *)getBaseMapSourcesSettingsItem
{
    for (OASettingsItem * settingsItem in _settingsItems)
    {
        if (settingsItem.type == EOASettingsItemTypeMapSources)
            return (OAMapSourcesSettingsItem *)settingsItem;
    }
    return nil;
}

- (OAAvoidRoadsSettingsItem *)getBaseAvoidRoadsSettingsItem
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
    /*
     if (!appModeBeans.isEmpty()) {
         for (ApplicationModeBean modeBean : appModeBeans) {
             settingsItems.add(new ProfileSettingsItem(app, getBaseProfileSettingsItem(modeBean), modeBean));
         }
     }
     if (!quickActions.isEmpty()) {
         settingsItems.add(new QuickActionsSettingsItem(app, getBaseQuickActionsSettingsItem(), quickActions));
     }
     if (!poiUIFilters.isEmpty()) {
         settingsItems.add(new PoiUiFiltersSettingsItem(app, getBasePoiUiFiltersSettingsItem(), poiUIFilters));
     }
     if (!tileSourceTemplates.isEmpty()) {
         settingsItems.add(new MapSourcesSettingsItem(app, getBaseMapSourcesSettingsItem(), tileSourceTemplates));
     }
     if (!avoidRoads.isEmpty()) {
         settingsItems.add(new AvoidRoadsSettingsItem(app, getBaseAvoidRoadsSettingsItem(), avoidRoads));
     }
     */
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
    if (section == 0)
    {
        NSString *descriptionString = [NSString stringWithFormat:OALocalizedString(@"checking_for_duplicates_descr"), [_file lastPathComponent]];
        CGFloat textWidth = tableView.bounds.size.width - 32;
        CGFloat heightForHeader = [OAUtilities heightForHeaderViewText:descriptionString width:textWidth font:[UIFont systemFontOfSize:15] lineSpacing:6.] + 16;
        UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0., 0., tableView.bounds.size.width, heightForHeader)];
        UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(16., 8., textWidth, heightForHeader)];
        UIFont *labelFont = [UIFont systemFontOfSize:15.0];
        description.font = labelFont;
        [description setTextColor: UIColorFromRGB(color_text_footer)];
        description.attributedText = [OAUtilities getStringWithBoldPart:descriptionString mainString:[NSString stringWithFormat:OALocalizedString(@"checking_for_duplicates_descr"), [_file lastPathComponent]] boldString:[_file lastPathComponent] lineSpacing:4. highlightColor:UIColor.blackColor];
        description.numberOfLines = 0;
        description.lineBreakMode = NSLineBreakByWordWrapping;
        description.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [vw addSubview:description];
        return vw;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        _heightForHeader = [self heightForLabel:OALocalizedString(@"checking_for_duplicates_descr")];
        return _heightForHeader + kBottomPadding + kTopPadding;
    }
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
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

// ???
- (void) checkForDuplicates
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BOOL animated = _checkingDuplicates;
        _checkingDuplicates = NO;
        [self reloadDataAnimated:animated];
    });
}

- (void) reloadDataAnimated:(BOOL)animated
{
    
}


//MARK: OASettingsImportExportDelegate

- (void) onDuplicatesChecked:(NSArray<OASettingsItem *>*)duplicates items:(NSArray<OASettingsItem *>*)items
{
    OAImportDuplicatesViewController *dublicatesVC = [[OAImportDuplicatesViewController alloc] initWithDuplicatesList:duplicates settingsItems:_settingsItems file:_file];
    [self.navigationController pushViewController:dublicatesVC animated:YES];
}

@end
