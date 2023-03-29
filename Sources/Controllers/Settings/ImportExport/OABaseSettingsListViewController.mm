//
//  OABaseSettingsListViewController.m
//  OsmAnd
//
//  Created by Paul on 08.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseSettingsListViewController.h"
#import "OAExportItemsSelectionViewController.h"
#import "OASettingsCategoryItems.h"
#import "OAExportSettingsType.h"
#import "OAProgressTitleCell.h"
#import "OARightIconTableViewCell.h"
#import "OAExportSettingsType.h"
#import "OAMenuSimpleCell.h"
#import "OAIconTextTableViewCell.h"
#import "OAActivityViewWithTitleCell.h"
#import "OAFileSettingsItem.h"
#import "OAExportSettingsCategory.h"
#import "Localization.h"
#import "OAColors.h"

@implementation OATableCollapsableGroup

-(instancetype) init
{
    self = [super init];
    if (self) {
        self.groupItems = [[NSMutableArray alloc] init];
    }
    return self;
}

@end

@interface OABaseSettingsListViewController () <UITableViewDelegate, UITableViewDataSource, OASettingItemsSelectionDelegate, OATableViewCellDelegate>

@end

@implementation OABaseSettingsListViewController

- (instancetype)init
{
    self = [super init];
    if (self) {
        _selectedItemsMap = [NSMutableDictionary new];
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
}

- (void)viewDidLoad
{
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);
    
    [self.additionalNavBarButton addTarget:self action:@selector(selectDeselectAllItems:) forControlEvents:UIControlEventTouchUpInside];
    self.secondaryBottomButton.hidden = YES;
    [self updateControls];
    self.backImageButton.hidden = YES;
    
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
}

- (void) generateData
{
    NSMutableArray *data = [NSMutableArray array];
    for (OAExportSettingsCategory *type in self.itemTypes)
    {
        OASettingsCategoryItems *categoryItems = self.itemsMap[type];
        OATableCollapsableGroup *group = [[OATableCollapsableGroup alloc] init];
        group.groupName = type.title;
        group.type = [OARightIconTableViewCell getCellIdentifier];
        group.isOpen = NO;
        for (OAExportSettingsType *type in categoryItems.getTypes)
        {
            [group.groupItems addObject:@{
                @"icon" :  type.icon,
                @"title" : type.title,
                @"type" : [OAMenuSimpleCell getCellIdentifier]
            }];
        }
        [data addObject:group];
    }
    
    self.data = [NSArray arrayWithArray:data];
}

- (void) applyLocalization
{
    [super applyLocalization];
    
    [self.backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.additionalNavBarButton setTitle:OALocalizedString(@"shared_string_select_all") forState:UIControlStateNormal];
    [self.primaryBottomButton setTitle:OALocalizedString(@"shared_string_continue") forState:UIControlStateNormal];
}

- (BOOL) hasSelection
{
    for (NSArray *items in self.selectedItemsMap.allValues)
    {
        if (items.count > 0)
            return YES;
    }
    return NO;
}

- (void) updateNavigationBarItem
{
    BOOL selected = [self hasSelection];
    [self.additionalNavBarButton setTitle:selected ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"shared_string_select_all") forState:UIControlStateNormal];
}

- (void) setupButtonView
{
    BOOL hasSelection = [self hasSelection];
    self.primaryBottomButton.backgroundColor = hasSelection ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_button_gray_background);
    [self.primaryBottomButton setTintColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [self.primaryBottomButton setTitleColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
    [self.primaryBottomButton setUserInteractionEnabled:hasSelection];
}

- (void) updateControls
{
    [self updateNavigationBarItem];
    [self setupButtonView];
}

- (NSArray *)getSelectedItems
{
    NSMutableArray *selectedItems = [NSMutableArray new];
    for (NSArray *items in self.selectedItemsMap.allValues)
        [selectedItems addObjectsFromArray:items];
    
    return selectedItems;
}

- (void) selectDeselectAllItems:(id)sender
{
    if (self.selectedItemsMap.count > 0)
    {
        [self.selectedItemsMap removeAllObjects];
    }
    else
    {
        for (OAExportSettingsCategory *category in self.itemsMap)
        {
            OASettingsCategoryItems *items = self.itemsMap[category];
            for (OAExportSettingsType *type in items.getTypes)
            {
                self.selectedItemsMap[type] = [items getItemsForType:type];
            }
        }
    }
    [self.tableView reloadData];
    [self updateControls];
}

- (void) onGroupCheckmarkPressed:(UIButton *)sender
{
    [self onLeftEditButtonPressed:sender.tag];
}

- (void) selectAllItems:(OASettingsCategoryItems *)categoryItems section:(NSInteger)section
{
    for (OAExportSettingsType *type in categoryItems.getTypes)
    {
        self.selectedItemsMap[type] = [categoryItems getItemsForType:type];
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) deselectAllItemsForCategory:(OASettingsCategoryItems *)categoryItems section:(NSInteger)section
{
    for (OAExportSettingsType *type in categoryItems.getTypes)
    {
        [self.selectedItemsMap removeObjectForKey:type];
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
    OATableCollapsableGroup* groupData = [self.data objectAtIndex:indexPath.section];
    groupData.isOpen = !groupData.isOpen;
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
    UITableViewScrollPosition scrollPosition = !groupData.isOpen ? UITableViewScrollPositionNone : UITableViewScrollPositionTop;
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
}

- (void) showActivityIndicatorWithLabel:(NSString *)labelText
{
    OATableCollapsableGroup *tableGroup = [[OATableCollapsableGroup alloc] init];
    tableGroup.type = [OAActivityViewWithTitleCell getCellIdentifier];
    tableGroup.groupName = labelText;
    self.data = @[tableGroup];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    [self.tableView reloadData];
    self.bottomBarView.hidden = YES;
}

- (long) calculateItemsSize:(NSArray *)items
{
    long itemsSize = 0;
    for (id item in items)
    {
        if ([item isKindOfClass:OAFileSettingsItem.class])
        {
            itemsSize += [self getItemSize:((OAFileSettingsItem *) item).filePath];
        }
        else if ([item isKindOfClass:NSString.class])
        {
            itemsSize += [self getItemSize:item];
        }
    }
    return itemsSize;
}

- (void) updateUI:(NSString *)toolbarTitleRes descriptionRes:(NSString *)descriptionRes activityLabel:(NSString *)activityLabel
{
    // override
}

- (long)getItemSize:(NSString *)item
{
    return 0; //override
}

- (NSInteger) getSelectedItemsAmount:(OAExportSettingsType *)type
{
    return self.selectedItemsMap[type].count;
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    OATableCollapsableGroup* groupData = [self.data objectAtIndex:section];
    if (groupData.isOpen)
        return [groupData.groupItems count] + 1;
    return 1;
}

- (UITableViewCell *) tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATableCollapsableGroup* groupData = [self.data objectAtIndex:indexPath.section];
    if (indexPath.row == 0)
    {
        if ([groupData.type isEqualToString:[OAActivityViewWithTitleCell getCellIdentifier]])
        {
            OAActivityViewWithTitleCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAActivityViewWithTitleCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAActivityViewWithTitleCell getCellIdentifier] owner:self options:nil];
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
        else if ([groupData.type isEqualToString:[OAProgressTitleCell getCellIdentifier]])
        {
            OAProgressTitleCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAProgressTitleCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAProgressTitleCell getCellIdentifier] owner:self options:nil];
                cell = (OAProgressTitleCell *)[nib objectAtIndex:0];
            }
            if (cell)
            {
                cell.titleLabel.text = groupData.groupName;
                [cell.activityIndicator startAnimating];
            }
            return cell;
        }
        else if ([groupData.type isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
        {
            OARightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OARightIconTableViewCell *) nib[0];
                [cell leftEditButtonVisibility:YES];
                [cell leftIconVisibility:NO];
                [cell setCustomLeftSeparatorInset:YES];
                cell.delegate = self;
                cell.separatorInset = UIEdgeInsetsZero;
                cell.rightIconView.tintColor = UIColorFromRGB(color_primary_purple);

                UIButtonConfiguration *conf = [UIButtonConfiguration plainButtonConfiguration];
                conf.contentInsets = NSDirectionalEdgeInsetsMake(0., -6.5, 0., 0.);
                cell.leftEditButton.configuration = conf;
                cell.leftEditButton.layer.shadowColor = UIColorFromRGB(color_tint_gray).CGColor;
                cell.leftEditButton.layer.shadowOffset = CGSizeMake(0., 0.);
                cell.leftEditButton.layer.shadowOpacity = 1.;
                cell.leftEditButton.layer.shadowRadius = 1.;
            }
            if (cell)
            {
                OASettingsCategoryItems *itemTypes = self.itemsMap[_itemTypes[indexPath.section]];
                NSInteger itemSelectionCount = 0;
                NSInteger itemCount = itemTypes.getTypes.count;
                BOOL partiallySelected = NO;
                long size = 0;
                for (OAExportSettingsType *type in itemTypes.getTypes)
                {
                    NSInteger allItemsCount = [itemTypes getItemsForType:type].count;
                    NSInteger selectedItemsCount = self.selectedItemsMap[type].count;
                    size += [self calculateItemsSize:self.selectedItemsMap[type]];
                    if (selectedItemsCount > 0)
                        itemSelectionCount++;
                    partiallySelected = partiallySelected || allItemsCount != selectedItemsCount;
                }
                cell.titleLabel.text = groupData.groupName;
                cell.descriptionLabel.text = [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_of"), itemSelectionCount, itemCount];
                if (size > 0)
                {
                    cell.descriptionLabel.text = [cell.descriptionLabel.text stringByAppendingFormat:@" • %@",
                                                  [NSByteCountFormatter stringFromByteCount:size
                                                                                 countStyle:NSByteCountFormatterCountStyleFile]];
                }

                UIImage *selectionImage;
                if (itemSelectionCount > 0)
                    selectionImage = [UIImage imageNamed:partiallySelected ? @"ic_system_checkbox_indeterminate" : @"ic_system_checkbox_selected"];
                else
                    selectionImage = [UIImage imageNamed:@"ic_custom_checkbox_unselected"];
                [cell.leftEditButton setImage:selectionImage forState:UIControlStateNormal];
                cell.leftEditButton.tag = indexPath.section << 10 | indexPath.row;
                [cell.leftEditButton removeTarget:nil action:nil forControlEvents:UIControlEventAllEvents];
                [cell.leftEditButton addTarget:self action:@selector(onGroupCheckmarkPressed:) forControlEvents:UIControlEventTouchUpInside];

                if (groupData.isOpen)
                {
                    cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_up"];
                }
                else
                {
                    cell.rightIconView.image = [UIImage templateImageNamed:@"ic_custom_arrow_down"].imageFlippedForRightToLeftLayoutDirection;
                    if ([cell isDirectionRTL])
                        [cell.rightIconView setImage:cell.rightIconView.image.imageFlippedForRightToLeftLayoutDirection];
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
        if ([cellType isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
        {
            OAMenuSimpleCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
                cell = (OAMenuSimpleCell *)[nib objectAtIndex:0];
                cell.separatorInset = UIEdgeInsetsMake(0., 70., 0., 0.);
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                cell.descriptionView.textColor = UIColorFromRGB(color_text_footer);
            }
            if (cell)
            {
                cell.imgView.image = [item[@"icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
                cell.textView.text = item[@"title"];
                OASettingsCategoryItems *items = self.itemsMap[_itemTypes[indexPath.section]];
                OAExportSettingsType *settingType = items.getTypes[indexPath.row - 1];
                NSInteger selectedAmount = [self getSelectedItemsAmount:settingType];
                NSInteger itemsTotal = [items getItemsForType:settingType].count;
                NSString *selectedStr = selectedAmount == 0 ? OALocalizedString(@"shared_string_none") : (selectedAmount == itemsTotal ? OALocalizedString(@"shared_string_all") : [NSString stringWithFormat:OALocalizedString(@"ltr_or_rtl_combine_via_of"), selectedAmount, itemsTotal]);
                
                long size = [self calculateItemsSize:self.selectedItemsMap[settingType]];
                if (size > 0)
                {
                    selectedStr = [selectedStr stringByAppendingFormat:@" • %@", [NSByteCountFormatter stringFromByteCount:size countStyle:NSByteCountFormatterCountStyleFile]];
                }
                
                UIColor *color = selectedAmount == 0 ? UIColorFromRGB(color_tint_gray) : item[@"color"];
                cell.imgView.tintColor = color;
                
                cell.descriptionView.text = selectedStr;
            }
            return cell;
        }
        else if ([cellType isEqualToString:[OAIconTextTableViewCell getCellIdentifier]])
        {
            
            OAIconTextTableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTextTableViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTextTableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OAIconTextTableViewCell *)[nib objectAtIndex:0];
                cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
                cell.arrowIconView.hidden = YES;
            }
            if (cell)
            {
                cell.textView.text = item[@"title"];
                cell.iconView.image = [UIImage templateImageNamed:item[@"icon"]];
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
    return [self getHeaderForTableView:tableView withFirstSectionText:self.descriptionText boldFragment:self.descriptionBoldText forSection:section];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [self getHeightForHeaderWithFirstHeaderText:self.descriptionText boldFragment:self.descriptionBoldText inSection:section];
}

- (void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row != 0)
    {
        OASettingsCategoryItems *items = self.itemsMap[_itemTypes[indexPath.section]];
        OAExportSettingsType *type = [items getTypes][indexPath.row - 1];
        if (type != OAExportSettingsType.NAVIGATION_HISTORY && type != OAExportSettingsType.SEARCH_HISTORY && type != OAExportSettingsType.HISTORY_MARKERS && type != OAExportSettingsType.GLOBAL)
        {
            OAExportItemsSelectionViewController *selectionVC = [[OAExportItemsSelectionViewController alloc] initWithItems:[items getItemsForType:type] type:type selectedItems:self.selectedItemsMap[type]];
            selectionVC.delegate = self;
            [self presentViewController:selectionVC animated:YES completion:nil];
        }
        else
        {
            if (self.selectedItemsMap[type].count == 0)
                self.selectedItemsMap[type] = [items getItemsForType:type];
            else
                [self.selectedItemsMap removeObjectForKey:type];
            
            [tableView reloadRowsAtIndexPaths:@[indexPath, [NSIndexPath indexPathForRow:0 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    else
    {
        [self openCloseGroup:indexPath];
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self updateControls];
}

// MARK: OASettingItemsSelectionDelegate

- (void)onItemsSelected:(NSArray *)items type:(OAExportSettingsType *)type
{
    self.selectedItemsMap[type] = items;
    [self.tableView reloadData];
    [self updateControls];
}

// MARK: OASettingsImportExportDelegate

- (void) onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items {
}

- (void) onDuplicatesChecked:(NSArray<OASettingsItem *> *)duplicates items:(NSArray<OASettingsItem *> *)items
{
}

- (void)onSettingsCollectFinished:(BOOL)succeed empty:(BOOL)empty items:(NSArray<OASettingsItem *> *)items
{
}

- (void)onSettingsExportFinished:(NSString *)file succeed:(BOOL)succeed
{
}

#pragma mark - OATableViewCellDelegate

- (void)onLeftEditButtonPressed:(NSInteger)tag
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:tag & 0x3FF inSection:tag >> 10];
    OAExportSettingsCategory *settingsCategory = _itemTypes[indexPath.section];
    OASettingsCategoryItems *items = self.itemsMap[settingsCategory];
    OAExportSettingsType *type = items.getTypes[indexPath.row];
    BOOL doSelect = self.selectedItemsMap[type].count == 0;
    
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

@end
