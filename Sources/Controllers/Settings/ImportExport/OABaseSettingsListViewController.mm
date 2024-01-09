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
#import "OASimpleTableViewCell.h"
#import "OAActivityViewWithTitleCell.h"
#import "OAFileSettingsItem.h"
#import "OAExportSettingsCategory.h"
#import "Localization.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@implementation OATableCollapsableGroup

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.groupItems = [NSMutableArray array];
    }
    return self;
}

@end

@interface OABaseSettingsListViewController () <OASettingItemsSelectionDelegate, OATableViewCellDelegate>

@end

@implementation OABaseSettingsListViewController
{
    NSString *_activityIndicatorLabel;
}

#pragma mark - Initialization

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _selectedItemsMap = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Base UI

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

- (EOABaseNavbarStyle)getNavbarStyle
{
    return EOABaseNavbarStyleLargeTitle;
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return _activityIndicatorLabel && _activityIndicatorLabel.length > 0 ? nil
        : @[[self createRightNavbarButton:[self hasSelection] ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"shared_string_select_all")
                                 iconName:nil
                                   action:@selector(onRightNavbarButtonPressed)
                                     menu:nil]];
}

- (NSString *)getBottomButtonTitle
{
    return _activityIndicatorLabel && _activityIndicatorLabel.length > 0 ? @"" : OALocalizedString(@"shared_string_continue");
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return [self hasSelection] ? EOABaseButtonColorSchemePurple : EOABaseButtonColorSchemeInactive;
}

#pragma mark - Table data

- (void)generateData
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
                @"type" : [OASimpleTableViewCell getCellIdentifier],
                @"key" : @"exportItem"
            }];
        }
        [data addObject:group];
    }
    self.data = data;
}

#pragma mark - UITableViewDataSource

- (NSInteger)rowsCount:(NSInteger)section
{
    OATableCollapsableGroup* groupData = [self.data objectAtIndex:section];
    if (groupData.isOpen)
        return [groupData.groupItems count] + 1;
    return 1;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableCollapsableGroup* groupData = [self.data objectAtIndex:indexPath.section];
    if (indexPath.row == 0)
    {
        if ([groupData.type isEqualToString:[OAActivityViewWithTitleCell getCellIdentifier]])
        {
            OAActivityViewWithTitleCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAActivityViewWithTitleCell getCellIdentifier]];
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
            OAProgressTitleCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OAProgressTitleCell getCellIdentifier]];
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
            OARightIconTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OARightIconTableViewCell *) nib[0];
                [cell leftEditButtonVisibility:YES];
                [cell leftIconVisibility:NO];
                [cell setCustomLeftSeparatorInset:YES];
                cell.delegate = self;
                cell.separatorInset = UIEdgeInsetsZero;
                cell.rightIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];

                UIButtonConfiguration *conf = [UIButtonConfiguration plainButtonConfiguration];
                conf.contentInsets = NSDirectionalEdgeInsetsMake(0., -6.5, 0., 0.);
                cell.leftEditButton.configuration = conf;
                cell.leftEditButton.layer.shadowColor = [UIColor colorNamed:ACColorNameIconColorDisabled].CGColor;
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
        BOOL isExportItem = [item[@"key"] isEqualToString:@"exportItem"];
        if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
        {
            OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
            if (cell == nil)
            {
                NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
                cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            }
            if (cell)
            {
                if (isExportItem)
                {
                    [cell descriptionVisibility:YES];
                    cell.leftIconView.image = [item[@"icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate].imageFlippedForRightToLeftLayoutDirection;
                    cell.titleLabel.text = item[@"title"];
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
                    
                    UIColor *color = selectedAmount == 0 ? [UIColor colorNamed:ACColorNameIconColorDisabled] : item[@"color"];
                    cell.leftIconView.tintColor = color;
                    cell.descriptionLabel.text = selectedStr;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                }
                else
                {
                    [cell descriptionVisibility:NO];
                    cell.titleLabel.text = item[@"title"];
                    cell.leftIconView.image = [UIImage templateImageNamed:item[@"icon"]];
                    cell.leftIconView.tintColor = item[@"color"] ? item[@"color"] : [UIColor colorNamed:ACColorNameIconColorDisabled];
                    cell.descriptionLabel.text = nil;
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
            }
            return cell;
        }
    }
    return nil;
}

- (NSInteger)sectionsCount
{
    return self.data.count;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (indexPath.row != 0)
    {
        OASettingsCategoryItems *items = self.itemsMap[_itemTypes[indexPath.section]];
        OAExportSettingsType *type = [items getTypes][indexPath.row - 1];
        if (type != OAExportSettingsType.NAVIGATION_HISTORY && type != OAExportSettingsType.SEARCH_HISTORY && type != OAExportSettingsType.HISTORY_MARKERS && type != OAExportSettingsType.GLOBAL)
        {
            OAExportItemsSelectionViewController *selectionVC = [[OAExportItemsSelectionViewController alloc] initWithItems:[items getItemsForType:type] type:type selectedItems:self.selectedItemsMap[type]];
            selectionVC.delegate = self;
            UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:selectionVC];
            [self.navigationController presentViewController:navigationController animated:YES completion:nil];
        }
        else
        {
            if (self.selectedItemsMap[type].count == 0)
                self.selectedItemsMap[type] = [items getItemsForType:type];
            else
                [self.selectedItemsMap removeObjectForKey:type];
            
            [self.tableView reloadRowsAtIndexPaths:@[indexPath, [NSIndexPath indexPathForRow:0 inSection:indexPath.section]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
    else
    {
        [self openCloseGroup:indexPath];
    }

    [self applyLocalization];
    [self updateNavbar];
    [self updateBottomButtons];
}

#pragma mark - Additions

- (NSArray *)getSelectedItems
{
    NSMutableArray *selectedItems = [NSMutableArray new];
    for (NSArray *items in self.selectedItemsMap.allValues)
    {
        [selectedItems addObjectsFromArray:items];
    }
    return selectedItems;
}

- (NSInteger)getSelectedItemsAmount:(OAExportSettingsType *)type
{
    return self.selectedItemsMap[type].count;
}

- (long)calculateItemsSize:(NSArray *)items
{
    long itemsSize = 0;
    for (id item in items)
    {
        if ([item isKindOfClass:OAFileSettingsItem.class])
            itemsSize += [self getItemSize:((OAFileSettingsItem *) item).filePath];
        else if ([item isKindOfClass:NSString.class])
            itemsSize += [self getItemSize:item];
    }
    return itemsSize;
}

- (long)getItemSize:(NSString *)item
{
    return 0; //override
}

- (BOOL)hasSelection
{
    for (NSArray *items in self.selectedItemsMap.allValues)
    {
        if (items.count > 0)
            return YES;
    }
    return NO;
}

- (void)selectAllItems:(OASettingsCategoryItems *)categoryItems section:(NSInteger)section
{
    for (OAExportSettingsType *type in categoryItems.getTypes)
    {
        self.selectedItemsMap[type] = [categoryItems getItemsForType:type];
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:section] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)deselectAllItemsForCategory:(OASettingsCategoryItems *)categoryItems section:(NSInteger)section
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

- (void)openCloseGroup:(NSIndexPath *)indexPath
{
    OATableCollapsableGroup* groupData = [self.data objectAtIndex:indexPath.section];
    groupData.isOpen = !groupData.isOpen;
    [self.tableView reloadSections:[[NSIndexSet alloc] initWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationNone];
    UITableViewScrollPosition scrollPosition = !groupData.isOpen ? UITableViewScrollPositionNone : UITableViewScrollPositionTop;
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
}

- (void)showActivityIndicatorWithLabel:(NSString *)labelText
{
    [UIView transitionWithView:self.view
                      duration:.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^(void)
                    {
                        _activityIndicatorLabel = labelText;
                        OATableCollapsableGroup *tableGroup = [[OATableCollapsableGroup alloc] init];
                        tableGroup.type = [OAActivityViewWithTitleCell getCellIdentifier];
                        tableGroup.groupName = _activityIndicatorLabel;
                        self.data = @[tableGroup];
                        [self.tableView reloadData];
                        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

                        [self applyLocalization];
                        [self updateNavbar];
                        [self updateBottomButtons];
                    }
                    completion:nil];
}

- (void)resetActivityIndicatorLabel
{
    _activityIndicatorLabel = nil;
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
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
    [self applyLocalization];
    [self updateNavbar];
    [self updateBottomButtons];
}

- (void)openCloseGroupButtonAction:(id)sender
{
    UIButton *button = (UIButton *)sender;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
    [self openCloseGroup:indexPath];
}

- (void)onGroupCheckmarkPressed:(UIButton *)sender
{
    [self onLeftEditButtonPressed:sender.tag];
}

#pragma mark - OASettingItemsSelectionDelegate

- (void)onItemsSelected:(NSArray *)items type:(OAExportSettingsType *)type
{
    self.selectedItemsMap[type] = items;
    [self.tableView reloadData];
    [self applyLocalization];
    [self updateNavbar];
    [self updateBottomButtons];
}

#pragma mark - OASettingsImportExportDelegate

- (void)onSettingsImportFinished:(BOOL)succeed items:(NSArray<OASettingsItem *> *)items
{
}

- (void)onDuplicatesChecked:(NSArray<OASettingsItem *> *)duplicates items:(NSArray<OASettingsItem *> *)items
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
    [self applyLocalization];
    [self updateNavbar];
    [self updateBottomButtons];
}

@end
