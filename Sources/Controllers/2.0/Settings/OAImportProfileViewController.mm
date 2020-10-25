//
//  OAImportProfileViewController.mm
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAImportProfileViewController.h"
#import "OACheckForProfileDuplicatesViewController.h"
#import "OAAppSettings.h"
#import "OASettingsImporter.h"
#import "OsmAndApp.h"
#import "OAQuickActionType.h"
#import "OATitleDescriptionCheckmarkCell.h"
#import "OAMultiIconTextDescCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAProfileDataObject.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16
#define kTopPadding 6
#define kBottomPadding 32
#define kCellTypeSectionHeader @"OATitleDescriptionCheckmarkCell"
#define kCellTypeTitleDescription @"OAMultiIconTextDescCell"
#define kCellTypeTitle @"OAIconTextCell"

@interface TableGroupToImport : NSObject
    @property NSString* type;
    @property BOOL isOpen;
    @property NSString* groupName;
    @property NSString *groupSubtitle;
    @property NSInteger selectedItems;
    @property NSMutableArray* groupItems;
@end

@implementation TableGroupToImport

-(id) init {
    self = [super init];
    if (self) {
        self.groupItems = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

@interface OAImportProfileViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation OAImportProfileViewController
{
    OAAppSettings *_settings;
    OASettingsHelper *_settingsHelper;
    NSMutableArray *_data;
    OsmAndAppInstance _app;
    
    NSArray<OASettingsItem *> *_settingsItems;
    //NSArray<OASettingsItem *> *_selectedItems
    NSMutableArray<NSIndexPath *> *_selectedItems;
    NSMutableDictionary *_items;
    NSArray <NSString *>*_itemsType;
    NSString *_file;
    
    CGFloat _heightForHeader;
}

- (instancetype) initWithItems:(NSArray<OASettingsItem *> *)items
{
    self = [super init];
    if (self)
    {
        _settings = [OAAppSettings sharedManager];
        _settingsHelper = OASettingsHelper.sharedInstance;
        _settingsItems = [NSArray arrayWithArray:items];
        _app = [OsmAndApp instance];
    }
    return self;
}

- (void) applyLocalization
{
    [super applyLocalization];
    
    [self.backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.additionalNavBarButton setTitle:OALocalizedString(@"select_all") forState:UIControlStateNormal];
    [self.primaryBottomButton setTitle:OALocalizedString(@"shared_string_continue") forState:UIControlStateNormal];
}

- (void) updateNavigationBarItem
{
    [self.additionalNavBarButton setTitle:_selectedItems.count >= 2 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"select_all") forState:UIControlStateNormal];
}

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"shared_string_import");
}

- (void) viewDidLoad
{
    [self setupView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView setEditing:YES];
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);
    
    [self.additionalNavBarButton addTarget:self action:@selector(selectDeselectAllItems:) forControlEvents:UIControlEventTouchUpInside];
    self.secondaryBottomButton.hidden = YES;
    self.backImageButton.hidden = YES;
    _selectedItems = [[NSMutableArray alloc] init]; //
    [super viewDidLoad];
}
 
- (void) setupView
{
    OAImportAsyncTask *importTask = _settingsHelper.importTask;
    if (importTask)
    {
        if (!_settingsItems)
            _settingsItems = [NSArray arrayWithArray:[importTask getItems]];
        if (!_file)
            _file = importTask.getFile;
        NSArray<NSObject *> *duplicates = [NSArray arrayWithArray:[importTask getDuplicates]];
        NSArray<OASettingsItem *> *selectedItems = [NSArray arrayWithArray:[importTask getSelectedItems]];
        //        if (duplicates == null) {
        //            importTask.setDuplicatesListener(getDuplicatesListener());
        //        } else if (duplicates.isEmpty()) {
        //            if (selectedItems != null && file != null) {
        //                settingsHelper.importSettings(file, selectedItems, "", 1, getImportListener());
        //            }
        //        }
        if (duplicates.count == 0)
            if (_selectedItems && _file)
                [_settingsHelper importSettings:_file items:selectedItems latestChanges:@"" version:1];
        
        //NSMutableDictionary *items = [NSMutableDictionary dictionary];
        if (_settingsItems)
        {
            _items = [NSMutableDictionary dictionaryWithDictionary:[self getSettingsToOperate:_settingsItems importComplete:NO]];
            _itemsType = [NSArray arrayWithArray:[_items allKeys]];
            [self generateData];
            //            adapter.updateSettingsList(itemsMap);
        }
        //        expandableList.setAdapter(adapter);
        //        toolbarLayout.setTitle(getString(R.string.shared_string_import));
        
        EOAImportType importTaskType = importTask.getImportType;
        if (importTaskType == EOAImportTypeCheckDuplicates)// && [_settingsHelper importDone])
        {
            
        }
        else if (importTaskType == EOAImportTypeImport)
        {
            
        }
        else
        {
            
        }
        if (_items.count == 1 && [_items objectForKey:[OAExportSettingsType typeName:EOAExportSettingsTypeProfile]])
        {
            TableGroupToImport* groupData = [_data objectAtIndex:0];
            groupData.isOpen = YES;
        }
    }
}

- (NSDictionary *) getSettingsToOperate:(NSArray <OASettingsItem *> *)settingsItems importComplete:(BOOL)importComplete
{
    NSMutableDictionary *settingsToOperate = [NSMutableDictionary dictionary];
    NSMutableArray<OAApplicationModeBean *> *profiles = [NSMutableArray array];
    NSMutableArray<OAQuickAction *> *quickActions = [NSMutableArray array];
    NSMutableArray<OAPOIUIFilter *> *poiUIFilters = [NSMutableArray array];
    NSMutableArray<OALocalResourceItem *> *tileSourceTemplates = [NSMutableArray array];
    NSMutableArray<NSString *> *routingFilesList = [NSMutableArray array];
    NSMutableArray<NSString *> *renderFilesList = [NSMutableArray array];
    NSMutableArray<OAAvoidRoadInfo *> *avoidRoads = [NSMutableArray array];
    for (OASettingsItem *item in settingsItems)
    {
        switch (item.type) {
            case EOASettingsItemTypeProfile:
            {
                [profiles addObject:[(OAProfileSettingsItem *)item modeBean]];
                break;
            }
            case EOASettingsItemTypeFile:
            {
                OAFileSettingsItem *fileItem = (OAFileSettingsItem *)item;
                if (fileItem.subtype == EOASettingsItemFileSubtypeRenderingStyle)
                    [renderFilesList addObject:fileItem.filePath];
                else if (fileItem.subtype == EOASettingsItemFileSubtypeRoutingConfig)
                    [renderFilesList addObject:fileItem.filePath];
                break;
            }
            case EOASettingsItemTypeQuickActions:
            {
                OAQuickActionsSettingsItem *quickActionsItem = (OAQuickActionsSettingsItem *) item;
                if (importComplete)
                    [quickActions addObjectsFromArray:quickActionsItem.appliedItems];
                else
                    [quickActions addObjectsFromArray:quickActionsItem.items];
                break;
            }
            case EOASettingsItemTypePoiUIFilters:
            {
                OAPoiUiFilterSettingsItem *poiUiFilterItem = (OAPoiUiFilterSettingsItem *) item;
                if (importComplete)
                    [poiUIFilters addObjectsFromArray:poiUiFilterItem.appliedItems];
                else
                    [poiUIFilters addObjectsFromArray:poiUiFilterItem.items];
                break;
            }
            case EOASettingsItemTypeMapSources:
            {
                OAMapSourcesSettingsItem *mapSourcesItem = (OAMapSourcesSettingsItem *) item;
                if (importComplete)
                    [tileSourceTemplates addObjectsFromArray:mapSourcesItem.appliedItems];
                else
                    [tileSourceTemplates addObjectsFromArray:mapSourcesItem.items];
                break;
            }
            case EOASettingsItemTypeAvoidRoads:
            {
                OAAvoidRoadsSettingsItem *avoidRoadsItem = (OAAvoidRoadsSettingsItem *) item;
                if (importComplete)
                    [avoidRoads addObjectsFromArray:avoidRoadsItem.appliedItems];
                else
                    [avoidRoads addObjectsFromArray:avoidRoadsItem.items];
                break;
            }
            default:
                break;
        }
    }
    if (profiles.count > 0)
        [settingsToOperate setObject:profiles forKey:[OAExportSettingsType typeName:EOAExportSettingsTypeProfile]];
    if (quickActions.count > 0)
        [settingsToOperate setObject:quickActions forKey:[OAExportSettingsType typeName:EOAExportSettingsTypeQuickActions]];
    if (poiUIFilters.count > 0)
        [settingsToOperate setObject:poiUIFilters forKey:[OAExportSettingsType typeName:EOAExportSettingsTypePoiTypes]];
    if (tileSourceTemplates.count > 0)
        [settingsToOperate setObject:tileSourceTemplates forKey:[OAExportSettingsType typeName:EOAExportSettingsTypeMapSources]];
    if (renderFilesList.count > 0)
        [settingsToOperate setObject:renderFilesList forKey:[OAExportSettingsType typeName:EOAExportSettingsTypeCustomRendererStyle]];
    if (routingFilesList.count > 0)
        [settingsToOperate setObject:routingFilesList forKey:[OAExportSettingsType typeName:EOAExportSettingsTypeCustomRouting]];
    if (avoidRoads.count > 0)
        [settingsToOperate setObject:avoidRoads forKey:[OAExportSettingsType typeName:EOAExportSettingsTypeAvoidRoads]];
    return settingsToOperate;
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray array];
    TableGroupToImport *profilesSection = [[TableGroupToImport alloc] init];
    TableGroupToImport *quickActionsSection = [[TableGroupToImport alloc] init];
    TableGroupToImport *poiTypesSection = [[TableGroupToImport alloc] init];
    TableGroupToImport *mapSourcesSection = [[TableGroupToImport alloc] init];
    TableGroupToImport *customRendererStyleSection = [[TableGroupToImport alloc] init];
    TableGroupToImport *customRoutingSection = [[TableGroupToImport alloc] init];
    TableGroupToImport *avoidRoadsStyleSection = [[TableGroupToImport alloc] init];
    for (NSString *type in [_items allKeys])
    {
        EOAExportSettingsType itemType = [OAExportSettingsType parseType:type];
        switch (itemType)
        {
            case EOAExportSettingsTypeProfile:
            {
                NSArray *settings = [NSArray arrayWithArray:[_items objectForKey:type]];
                NSInteger totalNumberOfProfiles = settings.count;
                NSInteger selectedNumberOfItems = profilesSection.selectedItems; // to change
                profilesSection.groupName = OALocalizedString(@"shared_string_profiles");
                profilesSection.groupSubtitle = [NSString stringWithFormat: OALocalizedString(@"selected_profiles"), selectedNumberOfItems, totalNumberOfProfiles]; // ???
                profilesSection.type = kCellTypeSectionHeader;
                profilesSection.isOpen = NO;
                for (OAApplicationModeBean *modeBean in settings)
                {
                    OAApplicationMode *appMode = [OAApplicationMode fromModeBean:modeBean];
                    NSString *title = modeBean.userProfileName;
                    if (title.length == 0)
                        title =  [OAUtilities capitalizeFirstLetterAndLowercase:[appMode.stringKey stringByReplacingOccurrencesOfString:@"_" withString:@" "]];
                    
                    NSString *routingProfile = modeBean.routingProfile;
                    if (routingProfile.length > 0)
                        routingProfile = [NSString stringWithFormat: OALocalizedString(@"nav_type_hint"), [OAUtilities capitalizeFirstLetterAndLowercase:[routingProfile stringByReplacingOccurrencesOfString:@"_" withString:@" "]]];
                    
                    [profilesSection.groupItems addObject:@{
                        @"app_mode" : appMode,
                        @"title" : title,
                        @"description" : routingProfile,
                        @"type" : kCellTypeTitleDescription,
                    }];
                }
                [data addObject:profilesSection];
                break;
            }
            case EOAExportSettingsTypeQuickActions:
            {
                quickActionsSection.groupName = OALocalizedString(@"shared_string_quick_actions");
                quickActionsSection.groupSubtitle = @"0 of 20"; //
                quickActionsSection.type = kCellTypeSectionHeader;
                quickActionsSection.isOpen = NO;
                for (OAQuickActionType *quickAction in [_items objectForKey:type])
                {
                    [quickActionsSection.groupItems addObject:@{
                        @"icon" : [quickAction iconName],
                        @"color" : UIColor.orangeColor, //
                        @"title" : [quickAction name],
                        @"type" : kCellTypeTitle,
                    }];
                }
                [data addObject:quickActionsSection];
                break;
            }
            case EOAExportSettingsTypePoiTypes:
            {
                poiTypesSection.groupName = OALocalizedString(@"poi_type"); // to check
                poiTypesSection.groupSubtitle = @"0 of 20"; //
                poiTypesSection.type = kCellTypeSectionHeader;
                poiTypesSection.isOpen = NO;
                
                [data addObject:poiTypesSection];
                break;
            }
            case EOAExportSettingsTypeMapSources:
            {
                mapSourcesSection.groupName = OALocalizedString(@"map_sources");
                mapSourcesSection.groupSubtitle = @"0 of 20"; //
                mapSourcesSection.type = kCellTypeSectionHeader;
                mapSourcesSection.isOpen = NO;
                
                [data addObject:mapSourcesSection];
                break;
            }
            case EOAExportSettingsTypeCustomRendererStyle:
            {
                customRendererStyleSection.groupName = OALocalizedString(@"shared_string_rendering_styles");
                customRendererStyleSection.groupSubtitle = @"0 of 20"; //
                customRendererStyleSection.type = kCellTypeSectionHeader;
                customRendererStyleSection.isOpen = NO;
                
                [data addObject:customRendererStyleSection];
                break;
            }
            case EOAExportSettingsTypeCustomRouting:
            {
                customRoutingSection.groupName = OALocalizedString(@"shared_string_routing");
                customRoutingSection.groupSubtitle = @"0 of 20"; //
                customRoutingSection.type = kCellTypeSectionHeader;
                customRoutingSection.isOpen = NO;
                
                [data addObject:customRoutingSection];
                break;
            }
            case EOAExportSettingsTypeAvoidRoads:
            {
                avoidRoadsStyleSection.groupName = OALocalizedString(@"impassable_road");
                avoidRoadsStyleSection.groupSubtitle = @"0 of 20"; //
                avoidRoadsStyleSection.type = kCellTypeSectionHeader;
                avoidRoadsStyleSection.isOpen = NO;
                
                [data addObject:avoidRoadsStyleSection];
                break;
            }
            default:
                break;
        }
    }
    _data = [NSMutableArray arrayWithArray:data];
}

#pragma mark - Actions

- (IBAction) primaryButtonPressed:(id)sender
{
    OACheckForProfileDuplicatesViewController* checkForDuplicates = [[OACheckForProfileDuplicatesViewController alloc] init];
    [self.navigationController pushViewController:checkForDuplicates animated:YES];
}

- (void) selectDeselectAllItems:(id)sender
{
    if (_selectedItems.count > 0)
        for (NSInteger section = 0; section < [self.tableView numberOfSections]; section++)
            [self deselectAllGroup:[NSIndexPath indexPathForRow:0 inSection:section]];
    else
        for (NSInteger section = 0; section < [self.tableView numberOfSections]; section++)
            [self selectAllGroup:[NSIndexPath indexPathForRow:0 inSection:section]];
    [self updateNavigationBarItem];
}

- (void) openCloseGroupButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    
    [self openCloseGroup:indexPath];
}

- (void) openCloseGroup:(NSIndexPath *)indexPath
{
    TableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
    
    if (groupData.isOpen)
    {
        groupData.isOpen = NO;
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        if ([_selectedItems containsObject: [NSIndexPath indexPathForRow:0 inSection:indexPath.section]])
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        groupData.isOpen = YES;
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        [self selectPreselectedCells:indexPath];
    }
}

#pragma mark - Table View

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    TableGroupToImport* groupData = [_data objectAtIndex:section];

    if (groupData.isOpen)
        return [groupData.groupItems count] + 1;
    return 1;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        UIView *vw = [[UIView alloc] initWithFrame:CGRectMake(0, 0.0, tableView.bounds.size.width - OAUtilities.getLeftMargin * 2, _heightForHeader)];
        CGFloat textWidth = self.tableView.bounds.size.width - (kSidePadding + OAUtilities.getLeftMargin) * 2;
        UILabel *description = [[UILabel alloc] initWithFrame:CGRectMake(kSidePadding + OAUtilities.getLeftMargin, 6.0, textWidth, _heightForHeader)];
        UIFont *labelFont = [UIFont systemFontOfSize:15.0];
        description.font = labelFont;
        [description setTextColor: UIColorFromRGB(color_text_footer)];
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:6];
        description.attributedText = [[NSAttributedString alloc] initWithString:OALocalizedString(@"import_profile_select_descr") attributes:@{NSParagraphStyleAttributeName : style}];
        description.numberOfLines = 0;
        [vw addSubview:description];
        return vw;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        _heightForHeader = [self heightForLabel:OALocalizedString(@"import_profile_select_descr")];
        return _heightForHeader + kBottomPadding + kTopPadding;
    }
    return UITableViewAutomaticDimension;
}

- (UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
    if (indexPath.row == 0)
    {
        static NSString* const identifierCell = @"OATitleDescriptionCheckmarkCell";
        OATitleDescriptionCheckmarkCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = (OATitleDescriptionCheckmarkCell *)[nib objectAtIndex:0];
            cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.openCloseGroupButton.hidden = NO;
        }
        if (cell)
        {
            cell.textView.text = groupData.groupName;
            cell.descriptionView.text = groupData.groupSubtitle;
            cell.openCloseGroupButton.tag = indexPath.section << 10 | indexPath.row;
            [cell.openCloseGroupButton addTarget:self action:@selector(openCloseGroupButtonAction:) forControlEvents:UIControlEventTouchUpInside];
            if (groupData.isOpen)
            {
                cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_up"]
                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            else
            {
                cell.iconView.image = [[UIImage imageNamed:@"ic_custom_arrow_down"]
                imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
                if ([cell isDirectionRTL])
                    [cell.iconView setImage:cell.iconView.image.imageFlippedForRightToLeftLayoutDirection];
            }
        }
        return cell;
    }
    else
    {
        NSInteger dataIndex = indexPath.row - 1;
        NSDictionary* item = [groupData.groupItems objectAtIndex:dataIndex];
        NSString *cellType = item[@"type"];
        if ([cellType isEqualToString:kCellTypeTitleDescription])
        {
            static NSString* const identifierCell = kCellTypeTitleDescription;
            OAMultiIconTextDescCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
                cell = (OAMultiIconTextDescCell *)[nib objectAtIndex:0];
                cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
                cell.overflowButton.alpha = 0.;
            }
            if (cell)
            {
                OAApplicationMode *am = item[@"app_mode"];
                UIImage *img = am.getIcon;
                cell.iconView.image = [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.iconView.tintColor = UIColorFromRGB(am.getIconColor);
                cell.textView.text = item[@"title"];
                cell.descView.text = item[@"description"];
            }
            return cell;
        }
        else if ([cellType isEqualToString:kCellTypeTitle])
        {
            
            static NSString* const identifierCell = kCellTypeTitle;
            OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
                cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
                cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
                cell.arrowIconView.hidden = YES;
            }
            if (cell)
            {
                cell.textView.text = item[@"title"];
                cell.iconView.image = [[UIImage imageNamed:item[@"icon"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.iconView.tintColor = item[@"color"];
            }
            return cell;
        }
    }
    return nil;
}

#pragma mark - Items selection

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        [self selectAllGroup:indexPath];
    else
        [self selectGroupItem:indexPath];
    [self updateNavigationBarItem];
}

- (void) tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        [self deselectAllGroup:indexPath];
    else
        [self deselectGroupItem:indexPath];
    [self updateNavigationBarItem];
}

- (void) selectAllItemsInGroup:(NSIndexPath *)indexPath selectHeader:(BOOL)selectHeader
{
    NSInteger rowsCount = [self.tableView numberOfRowsInSection:indexPath.section];

    [self.tableView beginUpdates];
    if (selectHeader)
        for (int i = 0; i < rowsCount; i++)
        {
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        }
    else
        for (int i = 0; i < rowsCount; i++)
        {
            [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section] animated:YES];
        }
    [self.tableView endUpdates];
}

- (void) selectAllGroup:(NSIndexPath *)indexPath
{
    TableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
    
    if (!groupData.isOpen)
        for (NSInteger i = 0; i <= groupData.groupItems.count; i++)
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
    [self selectAllItemsInGroup:indexPath selectHeader:YES];
}

- (void) deselectAllGroup:(NSIndexPath *)indexPath
{
    NSMutableArray *tmp = [[NSMutableArray alloc] initWithArray:_selectedItems];
    for (NSUInteger i = 0; i < tmp.count; i++)
        [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
    [self selectAllItemsInGroup:indexPath selectHeader: NO];
}

- (void) selectGroupItem:(NSIndexPath *)indexPath
{
    BOOL isGroupHeaderSelected = [self.tableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    NSInteger numberOfRowsInSection = [self.tableView numberOfRowsInSection:indexPath.section] - 1;
    NSInteger numberOfSelectedRowsInSection = 0;
    for (NSIndexPath *item in selectedRows)
    {
        if(item.section == indexPath.section)
            numberOfSelectedRowsInSection++;
        [self addIndexPathToSelectedCellsArray:item];
    }
    if (numberOfSelectedRowsInSection == numberOfRowsInSection && !isGroupHeaderSelected)
    {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
        [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
    }
    else
    {
        [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
    }
    return;
}

- (void) deselectGroupItem:(NSIndexPath *)indexPath
{
    BOOL isGroupHeaderSelected = [self.tableView.indexPathsForSelectedRows containsObject:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
    NSArray *selectedRows = [self.tableView indexPathsForSelectedRows];
    NSInteger numberOfRowsInSection = [self.tableView numberOfRowsInSection:indexPath.section] - 1;
    NSInteger numberOfSelectedRowsInSection = 0;
    for (NSIndexPath *item in selectedRows)
    {
        if(item.section == indexPath.section)
            numberOfSelectedRowsInSection++;
    }
    [self removeIndexPathFromSelectedCellsArray:indexPath];
    
    if (indexPath.row == 0)
    {
        [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
    }
    else if (numberOfSelectedRowsInSection == numberOfRowsInSection && isGroupHeaderSelected)
    {
        [self removeIndexPathFromSelectedCellsArray:[NSIndexPath indexPathForRow:0 inSection:indexPath.section]];
        [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:indexPath.section] animated:YES];
    }
    return;
}

- (void) addIndexPathToSelectedCellsArray:(NSIndexPath *)indexPath
{
    if (![_selectedItems containsObject:indexPath])
         [_selectedItems addObject:indexPath];
    
}

- (void) removeIndexPathFromSelectedCellsArray:(NSIndexPath *)indexPath
{
    if ([_selectedItems containsObject:indexPath])
        [_selectedItems removeObject:indexPath];
}

- (void) selectPreselectedCells:(NSIndexPath *)indexPath
{
    for (NSIndexPath *itemPath in _selectedItems)
        if (itemPath.section == indexPath.section)
            [self.tableView selectRowAtIndexPath:itemPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

@end
