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
#import "OAColors.h"
#import "OACustomSelectionButtonCell.h"
#import "OAMenuSimpleCell.h"

#define kCellTypeSelectionButton @"OACustomSelectionButtonCell"
#define kCellTypeTitle @"OAMenuSimpleCell"

@interface OADeleteCustomFiltersViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end

@implementation OADeleteCustomFiltersViewController
{
    NSMutableArray<OAPOIUIFilter *> *_items;
    NSMutableArray<OAPOIUIFilter *> *_selectedItems;
}

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

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.editing = YES;
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);

    [self setupDeleteButtonView];
}

- (void)applyLocalization
{
    self.titleLabel.text = OALocalizedString(@"delete_custom_categories");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.deleteButton setTitle:OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
}

- (IBAction)onCancelButtonClicked:(id)sender
{
    [self dismissViewController];
}

- (IBAction)onDeleteButtonClicked:(id)sender
{
    if (self.delegate)
        [self.delegate removeFilters:_selectedItems];
    [self dismissViewController];
}

- (void)selectDeselectGroup:(id)sender
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
    [self setupDeleteButtonView];
}

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
    [self setupDeleteButtonView];
}

- (void)setupDeleteButtonView
{
    BOOL hasSelection = _selectedItems.count != 0;
    self.deleteButton.backgroundColor = hasSelection ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_route_button_inactive);
    [self.deleteButton setTintColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [self.deleteButton setTitleColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
    [self.deleteButton setUserInteractionEnabled:hasSelection];
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSString *cellType = indexPath.row == 0 ? kCellTypeSelectionButton : kCellTypeTitle;
    if ([cellType isEqualToString:kCellTypeSelectionButton])
    {
        static NSString * const identifierCell = kCellTypeSelectionButton;
        OACustomSelectionButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 65.0, 0.0, 0.0);
        }
        if (cell)
        {
            NSString *selectionText = _selectedItems.count > 0 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"select_all");
            [cell.selectDeselectButton setTitle:selectionText forState:UIControlStateNormal];
            [cell.selectDeselectButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.selectDeselectButton addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];
            [cell.selectionButton removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.selectionButton addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];

            NSInteger selectedAmount = _selectedItems.count;
            if (selectedAmount > 0)
            {
                UIImage *selectionImage = selectedAmount < _items.count - 1 ? [UIImage imageNamed:@"ic_system_checkbox_indeterminate"] : [UIImage imageNamed:@"ic_system_checkbox_selected"];
                [cell.selectionButton setImage:selectionImage forState:UIControlStateNormal];
            }
            else
            {
                [cell.selectionButton setImage:nil forState:UIControlStateNormal];
            }
            return cell;
        }
    }
    else if ([cellType isEqualToString:kCellTypeTitle])
    {
        OAMenuSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellTypeTitle];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kCellTypeTitle owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., 65., 0., 0.);
            cell.tintColor = UIColorFromRGB(color_primary_purple);
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.05];
            [cell setSelectedBackgroundView:bgColorView];
        }
        if (cell)
        {
            OAPOIUIFilter *filter = _items[indexPath.row - 1];
            BOOL selected = [_selectedItems containsObject:filter];

            UIImage *icon;
            NSObject *res = [filter getIconResource];
            if ([res isKindOfClass:[NSString class]])
            {
                NSString *iconName = (NSString *)res;
                icon = [[OAUtilities getMxIcon:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            }
            if (!icon)
                icon = [UIImage templateImageNamed:@"ic_custom_search_categories"];
            [cell.imgView setImage:icon ];
            UIColor *selectedColor = selected ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_tint_gray);
            cell.imgView.tintColor = selectedColor;
            cell.imgHeightPrimary.constant = 24.0;
            cell.imgWidthPrimary.constant = 24.0;

            cell.textView.text = filter.getName ? filter.getName : @"";
            cell.descriptionView.hidden = true;

            if ([cell needsUpdateConstraints])
                [cell updateConstraints];
            return cell;
        }
    }
    return nil;
}

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
        [self selectDeselectItem:indexPath];
    else
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
        [self selectDeselectItem:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return [NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, _items.count];
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count + 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row != 0;
}

@end
