//
//  OADeleteCustomFiltersViewController.m
//  OsmAnd
//
// Created by Skalii Dmitrii on 15.04.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OADeleteCustomFiltersViewController.h"
#import "OAPOIFiltersHelper.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OAPOIHelper.h"
#import "GeneratedAssetSymbols.h"

@interface OADeleteCustomFiltersViewController () <OATableViewCellDelegate>

@end

@implementation OADeleteCustomFiltersViewController
{
    NSMutableArray<OAPOIUIFilter *> *_items;
    NSMutableArray<OAPOIUIFilter *> *_selectedItems;
}

#pragma mark - Initialization

- (instancetype)initWithFilters:(NSArray<OAPOIUIFilter *> *)filters
{
    self = [super init];
    if (self)
    {
        _selectedItems = [NSMutableArray new];
        _items = [NSMutableArray arrayWithArray:filters];
    }
    return self;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.editing = YES;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"delete_custom_categories");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (NSString *)getBottomButtonTitle
{
    return OALocalizedString(@"shared_string_delete");
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    BOOL hasSelection = _selectedItems.count != 0;
    return hasSelection ? EOABaseButtonColorSchemePurple : EOABaseButtonColorSchemeInactive;
}

#pragma mark - Table data

- (NSInteger)sectionsCount
{
    return 1;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    if (section == 0)
        return [NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, _items.count];
    return nil;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _items.count + 1;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSString *cellType = indexPath.row == 0 ? [OASimpleTableViewCell getCellIdentifier] : [OARightIconTableViewCell getCellIdentifier];
    if ([cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            [cell leftEditButtonVisibility:YES];
            cell.delegate = self;
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorActive];
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];

            UIButtonConfiguration *conf = [UIButtonConfiguration plainButtonConfiguration];
            conf.contentInsets = NSDirectionalEdgeInsetsMake(0., -6.5, 0., 0.);
            cell.leftEditButton.configuration = conf;
            cell.leftEditButton.layer.shadowColor = [UIColor colorNamed:ACColorNameIconColorDefault].CGColor;
            cell.leftEditButton.layer.shadowOffset = CGSizeMake(0., 0.);
            cell.leftEditButton.layer.shadowOpacity = 1.;
            cell.leftEditButton.layer.shadowRadius = 1.;
        }
        if (cell)
        {
            NSUInteger selectedAmount = _selectedItems.count;
            cell.titleLabel.text = selectedAmount > 0 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"shared_string_select_all");

            UIImage *selectionImage = nil;
            if (selectedAmount > 0)
                selectionImage = [UIImage imageNamed:selectedAmount < _items.count ? @"ic_system_checkbox_indeterminate" : @"ic_system_checkbox_selected"];
            else
                selectionImage = [UIImage imageNamed:@"ic_custom_checkbox_unselected"];
            [cell.leftEditButton setImage:selectionImage forState:UIControlStateNormal];
            [cell.leftEditButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.leftEditButton addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            [cell rightIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [[UIColor colorNamed:ACColorNameIconColorActive] colorWithAlphaComponent:.05];
            [cell setSelectedBackgroundView:bgColorView];
        }
        if (cell)
        {
            OAPOIUIFilter *filter = _items[indexPath.row - 1];
            BOOL selected = [_selectedItems containsObject:filter];
            UIImage *icon = [[OAPOIHelper getCustomFilterIcon:filter] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [cell.leftIconView setImage:icon ];
            UIColor *selectedColor = selected ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDisabled];
            cell.leftIconView.tintColor = selectedColor;
            cell.leftIconView.contentMode = UIViewContentModeCenter;
            cell.titleLabel.text = filter.getName ? filter.getName : @"";
            return cell;
        }
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0)
        [self selectDeselectGroup:nil];
    else
        [self selectDeselectItem:indexPath];
}

#pragma mark - Additions

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
    {
        [self.tableView beginUpdates];
        OAPOIUIFilter *filter = _items[indexPath.row - 1];
        if ([_selectedItems containsObject:filter])
            [_selectedItems removeObject:filter];
        else
            [_selectedItems addObject:filter];
        [self.tableView headerViewForSection:indexPath.section].textLabel.text = [[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int) _selectedItems.count, _items.count] upperCase];
        [self.tableView endUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:indexPath.section], indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
    [self updateBottomButtons];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
    {
        OAPOIUIFilter *item = _items[indexPath.row - 1];
        BOOL selected = [_selectedItems containsObject:item];
        [cell setSelected:selected animated:NO];
        if (selected)
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
        [self selectDeselectItem:indexPath];
}

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row != 0;
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)selectDeselectGroup:(UIButton *)sender
{
    [self onLeftEditButtonPressed:sender.tag];
}

- (void)onBottomButtonPressed
{
    if (self.delegate)
        [self.delegate removeFilters:_selectedItems];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - OATableViewCellDelegate

- (void)onLeftEditButtonPressed:(NSInteger)tag
{
    BOOL shouldSelect = _selectedItems.count == 0;
    if (!shouldSelect)
        [_selectedItems removeAllObjects];
    else
        [_selectedItems addObjectsFromArray:_items];

    for (NSInteger i = 0; i < _items.count; i++)
    {
        if (shouldSelect)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO];
    }
    [self.tableView beginUpdates];
    [self.tableView headerViewForSection:0].textLabel.text = [[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, _items.count] upperCase];
    [self.tableView endUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    [self updateBottomButtons];
}

@end
