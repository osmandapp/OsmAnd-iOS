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

@interface OATableGroupToImport : NSObject
    @property NSString* type;
    @property BOOL isOpen;
    @property NSString* groupName;
    @property NSMutableArray* groupItems;
@end

@implementation OATableGroupToImport

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
    OASettingsHelper *_settingsHelper;
    NSMutableArray *_data;
    
    NSArray<OASettingsItem *> *_settingsItems;
    NSMutableDictionary<NSString *, NSArray *> *_items;
    NSArray <NSString *>*_itemsType;
    NSMutableArray<OASettingsItem *> *_selectedItems;
    NSMutableArray<NSIndexPath *> *_selectedIndexPaths;
    NSString *_file;
    
    CGFloat _heightForHeader;
}

- (instancetype) initWithItems:(NSArray<OASettingsItem *> *)items
{
    self = [super init];
    if (self)
    {
        _settingsHelper = OASettingsHelper.sharedInstance;
        _settingsItems = [NSArray arrayWithArray:items];
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
    [self.additionalNavBarButton setTitle:_selectedIndexPaths.count >= 2 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"select_all") forState:UIControlStateNormal];
}

- (void) updateButtonView
{
    self.primaryBottomButton.userInteractionEnabled = _selectedItems.count > 0;
    self.primaryBottomButton.backgroundColor = _selectedItems.count > 0 ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_route_button_inactive);
    [self.primaryBottomButton setTintColor:_selectedItems.count > 0 ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [self.primaryBottomButton setTitleColor:_selectedItems.count > 0 ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
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
    [self updateButtonView];
    self.backImageButton.hidden = YES;
    _selectedIndexPaths = [[NSMutableArray alloc] init];
    _selectedItems = [[NSMutableArray alloc] init];
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
        if (_settingsItems)
        {
            _items = [NSMutableDictionary dictionaryWithDictionary:[self getSettingsToOperate:_settingsItems importComplete:NO]];
            _itemsType = [NSArray arrayWithArray:[_items allKeys]];
            [self generateData];
        }
        if (_items.count == 1 && [_items objectForKey:[OAExportSettingsType typeName:EOAExportSettingsTypeProfile]])
        {
            OATableGroupToImport* groupData = [_data objectAtIndex:0];
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
    NSMutableArray<NSString *> *gpxFilesList = [NSMutableArray array];
    NSMutableArray<NSString *> *mapFilesList = [NSMutableArray array];
    NSMutableArray<OAAvoidRoadInfo *> *avoidRoads = [NSMutableArray array];
    for (OASettingsItem *item in settingsItems)
    {
        switch (item.type)
        {
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
                    [routingFilesList addObject:fileItem.filePath];
                else if (fileItem.subtype == EOASettingsItemFileSubtypeGpx)
                    [gpxFilesList addObject:fileItem.filePath];
                else if (fileItem.subtype == EOASettingsItemFileSubtypeObfMap)
                    [mapFilesList addObject:fileItem.filePath];
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
    if (gpxFilesList.count > 0)
        [settingsToOperate setObject:gpxFilesList forKey:[OAExportSettingsType typeName:EOAExportSettingsTypeGPX]];
    if (mapFilesList.count > 0)
        [settingsToOperate setObject:mapFilesList forKey:[OAExportSettingsType typeName:EOAExportSettingsTypeMapFile]];
    if (avoidRoads.count > 0)
        [settingsToOperate setObject:avoidRoads forKey:[OAExportSettingsType typeName:EOAExportSettingsTypeAvoidRoads]];
    return settingsToOperate;
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray array];
    OATableGroupToImport *profilesSection = [[OATableGroupToImport alloc] init];
    OATableGroupToImport *quickActionsSection = [[OATableGroupToImport alloc] init];
    OATableGroupToImport *poiTypesSection = [[OATableGroupToImport alloc] init];
    OATableGroupToImport *mapSourcesSection = [[OATableGroupToImport alloc] init];
    OATableGroupToImport *customRendererStyleSection = [[OATableGroupToImport alloc] init];
    OATableGroupToImport *customRoutingSection = [[OATableGroupToImport alloc] init];
    OATableGroupToImport *customGPXSection = [[OATableGroupToImport alloc] init];
    OATableGroupToImport *customObgMapSection = [[OATableGroupToImport alloc] init];
    OATableGroupToImport *avoidRoadsStyleSection = [[OATableGroupToImport alloc] init];
    for (NSString *type in [_items allKeys])
    {
        EOAExportSettingsType itemType = [OAExportSettingsType parseType:type];
        NSArray *settings = [NSArray arrayWithArray:[_items objectForKey:type]];
        switch (itemType)
        {
            case EOAExportSettingsTypeProfile:
            {
                profilesSection.groupName = OALocalizedString(@"shared_string_profiles");
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
                poiTypesSection.groupName = OALocalizedString(@"poi_type");
                poiTypesSection.type = kCellTypeSectionHeader;
                poiTypesSection.isOpen = NO;
                
                [data addObject:poiTypesSection];
                break;
            }
            case EOAExportSettingsTypeMapSources:
            {
                mapSourcesSection.groupName = OALocalizedString(@"map_sources");
                mapSourcesSection.type = kCellTypeSectionHeader;
                mapSourcesSection.isOpen = NO;
                
                [data addObject:mapSourcesSection];
                break;
            }
            case EOAExportSettingsTypeCustomRendererStyle:
            {
                customRendererStyleSection.groupName = OALocalizedString(@"shared_string_rendering_style");
                customRendererStyleSection.type = kCellTypeSectionHeader;
                customRendererStyleSection.isOpen = NO;
                for (NSString *rendererItem in [_items objectForKey:type])
                {
                    NSString *rendererName = [[[rendererItem lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                    [customRendererStyleSection.groupItems addObject:@{
                        @"icon" : @"ic_custom_map_style",
                        @"title" : [rendererName stringByDeletingPathExtension],
                        @"type" : kCellTypeTitle,
                    }];
                }
                [data addObject:customRendererStyleSection];
                break;
            }
            case EOAExportSettingsTypeCustomRouting:
            {
                customRoutingSection.groupName = OALocalizedString(@"shared_string_routing");
                customRoutingSection.type = kCellTypeSectionHeader;
                customRoutingSection.isOpen = NO;
                for (NSString *routingItem in [_items objectForKey:type])
                {
                    NSString *routingName = [[[routingItem lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                    [customRoutingSection.groupItems addObject:@{
                        @"icon" : @"ic_custom_route",
                        @"title" : routingName,
                        @"type" : kCellTypeTitle,
                    }];
                }
                [data addObject:customRoutingSection];
                break;
            }
            case EOAExportSettingsTypeGPX:
            {
                customGPXSection.groupName = @"GPX"; // check
                customGPXSection.type = kCellTypeSectionHeader;
                customGPXSection.isOpen = NO;
                for (NSString *gpxItem in [_items objectForKey:type])
                {
                    NSString *routingName = [[[gpxItem lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                    [customGPXSection.groupItems addObject:@{
                        @"icon" : @"ic_custom_trip",
                        @"title" : routingName,
                        @"type" : kCellTypeTitle,
                    }];
                }
                [data addObject:customGPXSection];
                break;
            }
            case EOAExportSettingsTypeMapFile:
            {
                customObgMapSection.groupName = @"Maps"; // check
                customObgMapSection.type = kCellTypeSectionHeader;
                customObgMapSection.isOpen = NO;
                for (NSString *mapItem in [_items objectForKey:type])
                {
                    NSString *routingName = [[[mapItem lastPathComponent] stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
                    [customObgMapSection.groupItems addObject:@{
                        @"icon" : @"ic_custom_map_style",
                        @"title" : routingName,
                        @"type" : kCellTypeTitle,
                    }];
                }
                [data addObject:customObgMapSection];
                break;
            }
            case EOAExportSettingsTypeAvoidRoads:
            {
                avoidRoadsStyleSection.groupName = OALocalizedString(@"impassable_road");
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

- (NSInteger) getSelectedItemsAmount:(NSArray *)listItems
{
    NSInteger amount = 0;
    for (OASettingsItem *item in listItems)
        if ([_selectedItems containsObject:item])
            amount++;
    return amount;
}

#pragma mark - Actions

- (IBAction) primaryButtonPressed:(id)sender
{
    if (_selectedItems.count > 0)
    {
        OACheckForProfileDuplicatesViewController* checkForDuplicates = [[OACheckForProfileDuplicatesViewController alloc] initWithItems:_settingsItems file:(NSString *)_file selectedItems:_selectedItems];
        [checkForDuplicates prepareToImport];
        [self.navigationController pushViewController:checkForDuplicates animated:YES];
    }
}

- (void) selectDeselectAllItems:(id)sender
{
    if (_selectedIndexPaths.count > 1)
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
    OATableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
    if (groupData.isOpen)
    {
        groupData.isOpen = NO;
        [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
        if ([_selectedIndexPaths containsObject: [NSIndexPath indexPathForRow:0 inSection:indexPath.section]])
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
    OATableGroupToImport* groupData = [_data objectAtIndex:section];
    if (groupData.isOpen)
        return [groupData.groupItems count] + 1;
    return 1;
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self getHeaderForTableView:tableView withFirstSectionText:(NSString *)OALocalizedString(@"import_profile_select_descr") boldFragment:nil forSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self getHeightForHeaderWithFirstHeaderText:OALocalizedString(@"import_profile_select_descr") boldFragment:nil inSection:section];
}

- (UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
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
            NSInteger selectedAmount = [self getSelectedItemsAmount:[_items objectForKey:_itemsType[indexPath.section]]];
            cell.textView.text = groupData.groupName;
            cell.descriptionView.text = [NSString stringWithFormat: OALocalizedString(@"selected_profiles"), selectedAmount, groupData.groupItems.count];
            if (selectedAmount == groupData.groupItems.count)
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:indexPath.row inSection:indexPath.section] animated:YES scrollPosition:UITableViewScrollPositionNone];
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
                cell.iconView.tintColor = item[@"color"] ? item[@"color"] : UIColorFromRGB(color_tint_gray);
            }
            return cell;
        }
    }
    return nil;
}

#pragma mark - Items selection

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
    OATableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
    if (!groupData.isOpen)
        for (NSInteger i = 0; i <= groupData.groupItems.count; i++)
            [self addIndexPathToSelectedCellsArray:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
    [self selectAllItemsInGroup:indexPath selectHeader:YES];
}

- (void) deselectAllGroup:(NSIndexPath *)indexPath
{
    NSMutableArray *tmp = [[NSMutableArray alloc] initWithArray:_selectedIndexPaths];
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
    NSArray* objects = [NSArray arrayWithArray:[_items objectForKey:_itemsType[indexPath.section]]];
    if (![_selectedIndexPaths containsObject:indexPath])
    {
        [_selectedIndexPaths addObject:indexPath];
        if (indexPath.row != 0)
            [_selectedItems addObject:objects[indexPath.row - 1]];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationNone];
        [self updateButtonView];
    }
}

- (void) removeIndexPathFromSelectedCellsArray:(NSIndexPath *)indexPath
{
    NSArray* objects = [NSArray arrayWithArray:[_items objectForKey:_itemsType[indexPath.section]]];
    if ([_selectedIndexPaths containsObject:indexPath])
    {
        [_selectedIndexPaths removeObject:indexPath];
        if (indexPath.row != 0)
            [_selectedItems removeObject:objects[indexPath.row - 1]];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationNone];
        [self updateButtonView];
    }
}

- (void) selectPreselectedCells:(NSIndexPath *)indexPath
{
    for (NSIndexPath *itemPath in _selectedIndexPaths)
        if (itemPath.section == indexPath.section)
            [self.tableView selectRowAtIndexPath:itemPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

@end
