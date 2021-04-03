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
#import "OAAppSettings.h"
#import "OASettingsImporter.h"
#import "OsmAndApp.h"
#import "OAQuickActionType.h"
#import "OAQuickAction.h"
#import "OAPOIUIFilter.h"
#import "OAMapSource.h"
#import "OAResourcesUIHelper.h"
#import "OAAvoidRoadInfo.h"
#import "OACustomSelectionCollapsableCell.h"
#import "OAExportSettingsType.h"
#import "OAMenuSimpleCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAActivityViewWithTitleCell.h"
#import "OAProfileDataObject.h"
#import "OAAvoidRoadInfo.h"
#import "OASQLiteTileSource.h"
#import "OAResourcesUIHelper.h"
#import "OAOsmNotePoint.h"
#import "OAOsmNotesSettingsItem.h"
#import "OAOsmEditsSettingsItem.h"
#import "OAExportSettingsType.h"
#import "OAProfileSettingsItem.h"
#import "OAFileSettingsItem.h"
#import "OAQuickActionsSettingsItem.h"
#import "OAPoiUiFilterSettingsItem.h"
#import "OAMapSourcesSettingsItem.h"
#import "OAAvoidRoadsSettingsItem.h"
#import "OAFileNameTranslationHelper.h"
#import "OAFavoritesSettingsItem.h"
#import "OAFavoritesHelper.h"
#import "OAOsmEditingPlugin.h"
#import "OAMarkersSettingsItem.h"
#import "OASettingsCategoryItems.h"
#import "OAExportSettingsCategory.h"
#import "OADestination.h"
#import "OAGpxSettingsItem.h"
#import "OAExportItemsSelectionViewController.h"
#import "OAGPXDatabase.h"
#import "OAProgressTitleCell.h"
#import "OAPluginSettingsItem.h"

#import "Localization.h"
#import "OAColors.h"

#define kSidePadding 16
#define kTopPadding 6
#define kBottomPadding 32
#define kCellTypeWithActivity @"OAActivityViewWithTitleCell"
#define kCellTypeSectionHeader @"OACustomSelectionCollapsableCell"
#define kCellTypeTitleDescription @"OAMenuSimpleCell"
#define kCellTypeTitle @"OAIconTextCell"
#define kCellTypeProgress @"OAProgressTitleCell"

@interface OATableGroupToImport : NSObject
    @property NSString* type;
    @property BOOL isOpen;
    @property NSString* groupName;
    @property NSMutableArray* groupItems;
@end

@implementation OATableGroupToImport

-(instancetype) init
{
    self = [super init];
    if (self) {
        self.groupItems = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

@interface OAImportSettingsViewController () <UITableViewDelegate, UITableViewDataSource, OASettingsImportExportDelegate, OASettingItemsSelectionDelegate>

@end

@implementation OAImportSettingsViewController
{
    OASettingsHelper *_settingsHelper;
    NSArray<OATableGroupToImport *> *_data;
    NSArray<OASettingsItem *> *_settingsItems;
    NSDictionary<OAExportSettingsCategory *, OASettingsCategoryItems *> *_itemsMap;
    NSArray<OAExportSettingsCategory *> *_itemTypes;
    NSMutableDictionary<OAExportSettingsType *, NSArray *> *_selectedItemsMap;
    NSString *_file;
    NSString *_descriptionText;
    NSString *_descriptionBoldText;
    CGFloat _heightForHeader;
}

- (instancetype) initWithItems:(NSArray<OASettingsItem *> *)items
{
    self = [super init];
    if (self)
    {
        _settingsItems = [NSArray arrayWithArray:items];
        [self commonInit];
    }
    return self;
}

- (instancetype) init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _settingsHelper = OASettingsHelper.sharedInstance;
}

- (void) applyLocalization
{
    [super applyLocalization];
    
    [self.backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.additionalNavBarButton setTitle:OALocalizedString(@"select_all") forState:UIControlStateNormal];
    [self.primaryBottomButton setTitle:OALocalizedString(@"shared_string_continue") forState:UIControlStateNormal];
}

- (BOOL) hasSelection
{
    for (NSArray *items in _selectedItemsMap.allValues)
    {
        if (items.count > 0)
            return YES;
    }
    return NO;
}

- (void) updateNavigationBarItem
{
    BOOL selected = [self hasSelection];
    [self.additionalNavBarButton setTitle:selected ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"select_all") forState:UIControlStateNormal];
}

- (void) setupButtonView
{
    BOOL hasSelection = [self hasSelection];
    self.primaryBottomButton.backgroundColor = hasSelection ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_route_button_inactive);
    [self.primaryBottomButton setTintColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [self.primaryBottomButton setTitleColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
    [self.primaryBottomButton setUserInteractionEnabled:hasSelection];
}

- (void) updateControls
{
    [self updateNavigationBarItem];
    [self setupButtonView];
}

- (void) viewDidLoad
{
    _descriptionText = OALocalizedString(@"import_profile_select_descr");
    _descriptionBoldText = nil;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);
    
    [self.additionalNavBarButton addTarget:self action:@selector(selectDeselectAllItems:) forControlEvents:UIControlEventTouchUpInside];
    self.secondaryBottomButton.hidden = YES;
    [self updateControls];
    self.backImageButton.hidden = YES;
    _selectedItemsMap = [[NSMutableDictionary alloc] init];
    [self setTableHeaderView:OALocalizedString(@"shared_string_import")];
    
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self setupView];
    [self.tableView reloadData];
    self.bottomBarView.hidden = NO;
}

- (void) setupView
{
    OAImportAsyncTask *importTask = _settingsHelper.importTask;
    if (importTask && _settingsItems)
    {
        if (!_file)
            _file = importTask.getFile;
            
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
        _itemsMap = [OASettingsHelper getSettingsToOperateByCategory:_settingsItems importComplete:NO];
        _itemTypes = _itemsMap.allKeys;
        [self generateData];
    }
    else
    {
        OATableGroupToImport *group = [[OATableGroupToImport alloc] init];
        group.type = kCellTypeProgress;
        group.groupName = OALocalizedString(@"reading_file");
        _data = @[group];
    }
    
    EOAImportType importTaskType = [importTask getImportType];
    
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

- (NSInteger) getSelectedItemsAmount:(OAExportSettingsType *)type
{
    return _selectedItemsMap[type].count;
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray array];
    for (OAExportSettingsCategory *type in _itemTypes)
    {
        OASettingsCategoryItems *categoryItems = _itemsMap[type];
        OATableGroupToImport *group = [[OATableGroupToImport alloc] init];
        group.groupName = type.title;
        group.type = kCellTypeSectionHeader;
        group.isOpen = NO;
        for (OAExportSettingsType *type in categoryItems.getTypes)
        {
            [group.groupItems addObject:@{
                @"icon" :  type.icon,
                @"title" : type.title,
                @"type" : kCellTypeTitleDescription
            }];
        }
        [data addObject:group];
    }
    
    _data = [NSArray arrayWithArray:data];
}

- (void) showActivityIndicatorWithLabel:(NSString *)labelText
{
    OATableGroupToImport *tableGroup = [[OATableGroupToImport alloc] init];
    tableGroup.type = kCellTypeWithActivity;
    tableGroup.groupName = labelText;
    _data = @[tableGroup];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView reloadData];
    self.bottomBarView.hidden = YES;
}

#pragma mark - Actions

- (IBAction) primaryButtonPressed:(id)sender
{
    [self importItems];
}

- (IBAction) backButtonPressed:(id)sender
{
    [NSFileManager.defaultManager removeItemAtPath:_file error:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSArray *)getSelectedItems
{
    NSMutableArray *selectedItems = [NSMutableArray new];
    for (NSArray *items in _selectedItemsMap.allValues)
        [selectedItems addObjectsFromArray:items];
    
    return selectedItems;
}

- (void) importItems
{
    [self updateUI:OALocalizedString(@"shared_string_preparing") descriptionRes:OALocalizedString(@"checking_for_duplicate_description") activityLabel:OALocalizedString(@"checking_for_duplicates")];
    NSArray <OASettingsItem *> *selectedItems = [_settingsHelper prepareSettingsItems:[self getSelectedItems] settingsItems:_settingsItems doExport:NO];
    
    if (_file && _settingsItems)
        [_settingsHelper checkDuplicates:_file items:_settingsItems selectedItems:selectedItems delegate:self];
}

- (void) selectDeselectAllItems:(id)sender
{
    if (_selectedItemsMap.count > 0)
    {
        [_selectedItemsMap removeAllObjects];
    }
    else
    {
        for (OAExportSettingsCategory *category in _itemsMap)
        {
            OASettingsCategoryItems *items = _itemsMap[category];
            for (OAExportSettingsType *type in items.getTypes)
            {
                _selectedItemsMap[type] = [items getItemsForType:type];
            }
        }
    }
    [self.tableView reloadData];
    [self updateControls];
}

- (void) openCloseGroupButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    
    [self openCloseGroup:indexPath];
}

- (void) onGroupCheckmarkPressed:(UIButton *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    OAExportSettingsCategory *settingsCategory = _itemTypes[indexPath.section];
    OASettingsCategoryItems *items = _itemsMap[settingsCategory];
    OAExportSettingsType *type = items.getTypes[indexPath.row];
    BOOL doSelect = _selectedItemsMap[type].count == 0;
    
    if (doSelect)
    {
        [self selectAllItems:items section:indexPath.section];
    }
    else
    {
        [self deselectAllItemsForCategory:items section:indexPath.section];
    }
    [self updateControls];
}

- (void) selectAllItems:(OASettingsCategoryItems *)categoryItems section:(NSInteger)section
{
    for (OAExportSettingsType *type in categoryItems.getTypes)
    {
        _selectedItemsMap[type] = [categoryItems getItemsForType:type];
    }
    
    NSInteger itemsCount = [self.tableView numberOfRowsInSection:section];
    for (NSInteger i = 0; i < itemsCount; i++)
    {
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) deselectAllItemsForCategory:(OASettingsCategoryItems *)categoryItems section:(NSInteger)section
{
    for (OAExportSettingsType *type in categoryItems.getTypes)
    {
        [_selectedItemsMap removeObjectForKey:type];
    }
    
    NSInteger itemsCount = [self.tableView numberOfRowsInSection:section];
    for (NSInteger i = 0; i < itemsCount; i++)
    {
        [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES];
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) openCloseGroup:(NSIndexPath *)indexPath
{
    OATableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
    groupData.isOpen = !groupData.isOpen;
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UITableViewDataSource

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

- (UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableGroupToImport* groupData = [_data objectAtIndex:indexPath.section];
    if (indexPath.row == 0)
    {
        if ([groupData.type isEqualToString:kCellTypeWithActivity])
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
                cell.titleView.text = groupData.groupName;
                cell.activityIndicatorView.hidden = NO;
                [cell.activityIndicatorView startAnimating];
                
            }
            return cell;
        }
        else if ([groupData.type isEqualToString:kCellTypeProgress])
        {
            static NSString* const identifierCell = kCellTypeProgress;
            OAProgressTitleCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
                cell = (OAProgressTitleCell *)[nib objectAtIndex:0];
            }
            if (cell)
            {
                cell.titleLabel.text = groupData.groupName;
                [cell.activityIndicator startAnimating];
            }
            return cell;
        }
        else if ([groupData.type isEqualToString:@"OACustomSelectionCollapsableCell"])
        {
            static NSString* const identifierCell = @"OACustomSelectionCollapsableCell";
            OACustomSelectionCollapsableCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
                cell = (OACustomSelectionCollapsableCell *)[nib objectAtIndex:0];
                cell.iconView.tintColor = UIColorFromRGB(color_primary_purple);
                cell.openCloseGroupButton.hidden = NO;
                cell.separatorInset = UIEdgeInsetsZero;
            }
            if (cell)
            {
                OASettingsCategoryItems *itemTypes = _itemsMap[_itemTypes[indexPath.section]];
                NSInteger itemSelectionCount = 0;
                NSInteger itemCount = itemTypes.getTypes.count;
                BOOL partiallySelected = NO;
                for (OAExportSettingsType *type in itemTypes.getTypes)
                {
                    NSInteger allItemsCount = [itemTypes getItemsForType:type].count;
                    NSInteger selectedItemsCount = _selectedItemsMap[type].count;
                    if (selectedItemsCount > 0)
                        itemSelectionCount++;
                    partiallySelected = partiallySelected || allItemsCount != selectedItemsCount;
                }
                cell.textView.text = groupData.groupName;
                cell.descriptionView.text = [NSString stringWithFormat: OALocalizedString(@"selected_profiles"), itemSelectionCount, itemCount];
                cell.openCloseGroupButton.tag = indexPath.section << 10 | indexPath.row;
                [cell.openCloseGroupButton addTarget:self action:@selector(openCloseGroupButtonAction:) forControlEvents:UIControlEventTouchUpInside];
                
                cell.selectionButton.tag = indexPath.section << 10 | indexPath.row;
                [cell.selectionButton addTarget:self action:@selector(onGroupCheckmarkPressed:) forControlEvents:UIControlEventTouchUpInside];
                
                if (itemSelectionCount > 0)
                {
                    UIImage *selectionImage = partiallySelected ? [UIImage imageNamed:@"ic_system_checkbox_indeterminate"] : [UIImage imageNamed:@"ic_system_checkbox_selected"];
                    [cell.selectionButton setImage:selectionImage forState:UIControlStateNormal];
                }
                else
                {
                    [cell.selectionButton setImage:nil forState:UIControlStateNormal];
                }
                
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
    }
    else
    {
        NSInteger dataIndex = indexPath.row - 1;
        NSDictionary* item = [groupData.groupItems objectAtIndex:dataIndex];
        NSString *cellType = item[@"type"];
        if ([cellType isEqualToString:kCellTypeTitleDescription])
        {
            static NSString* const identifierCell = kCellTypeTitleDescription;
            OAMenuSimpleCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
                cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
                cell.separatorInset = UIEdgeInsetsMake(0., 70., 0., 0.);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            }
            if (cell)
            {
                cell.imgView.image = [item[@"icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                cell.imgView.tintColor = item[@"color"];
                cell.textView.text = item[@"title"];
                OASettingsCategoryItems *items = _itemsMap[_itemTypes[indexPath.section]];
                OAExportSettingsType *settingType = items.getTypes[indexPath.row - 1];
                NSInteger selectedAmount = [self getSelectedItemsAmount:settingType];
                NSInteger itemsTotal = [items getItemsForType:settingType].count;
                NSString *selectedStr = selectedAmount == 0 ? OALocalizedString(@"sett_no_ext_input") : (selectedAmount == itemsTotal ? OALocalizedString(@"shared_string_all") : [NSString stringWithFormat:OALocalizedString(@"some_of"), selectedAmount, itemsTotal]);
                cell.descriptionView.text = selectedStr;
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

#pragma mark - UITableViewDelegate

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return [self getHeaderForTableView:tableView withFirstSectionText:_descriptionText boldFragment:_descriptionBoldText forSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self getHeightForHeaderWithFirstHeaderText:_descriptionText boldFragment:_descriptionBoldText inSection:section];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row != 0)
    {
        OASettingsCategoryItems *items = _itemsMap[_itemTypes[indexPath.section]];
        OAExportSettingsType *type = [items getTypes][indexPath.row - 1];
        OAExportItemsSelectionViewController *selectionVC = [[OAExportItemsSelectionViewController alloc] initWithItems:[items getItemsForType:type] type:type selectedItems:_selectedItemsMap[type]];
        selectionVC.delegate = self;
        [self presentViewController:selectionVC animated:YES completion:nil];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self updateControls];
}

#pragma mark - OASettingsImportExportDelegate

- (void) onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items {
    if (succeed)
    {
        [self.tableView reloadData];
        OAImportCompleteViewController* importCompleteVC = [[OAImportCompleteViewController alloc] initWithSettingsItems:[OASettingsHelper getSettingsToOperate:items importComplete:YES] fileName:[_file lastPathComponent]];
        [self.navigationController pushViewController:importCompleteVC animated:YES];
        _settingsHelper.importTask = nil;
    }
    [NSFileManager.defaultManager removeItemAtPath:_file error:nil];
}

- (void) onDuplicatesChecked:(NSArray<OASettingsItem *> *)duplicates items:(NSArray<OASettingsItem *> *)items
{
    [self processDuplicates:duplicates items:items];
}

- (void)onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items
{
    
}

- (void)onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed
{
    
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

// MARK: OASettingItemsSelectionDelegate

- (void)onItemsSelected:(NSArray *)items type:(OAExportSettingsType *)type
{
    _selectedItemsMap[type] = items;
    [self.tableView reloadData];
    [self updateControls];
}

- (void)onItemsCollected:(NSArray<OASettingsItem *> *)items
{
    _settingsItems = items;
    if (_settingsItems)
    {
        [self setupView];
        [self.tableView reloadData];
    }
}

@end
