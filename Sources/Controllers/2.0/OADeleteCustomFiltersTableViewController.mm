//
//  OADeleteCustomFiltersTableViewController.m
//  OsmAnd
//
// Created by Skalii Dmitrii on 15.04.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OADeleteCustomFiltersTableViewController.h"
#import "OAPOIFiltersHelper.h"
#import "Localization.h"
#import "OAColors.h"
#import "OACustomSelectionButtonCell.h"
#import "OAMenuSimpleCell.h"

#define kCellTypeSelectionButton @"OACustomSelectionButtonCell"
#define kCellTypeTitle @"OAMenuSimpleCell"

@interface OADeleteCustomFiltersTableViewController () <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@end

@implementation OADeleteCustomFiltersTableViewController
{
    NSMutableArray *_items;
    NSMutableArray *_selectedItems;
}

-(instancetype)initWithFilters:(NSArray<OAPOIUIFilter *> *)filters
{
    self = [super init];
    if (self)
    {
        _selectedItems = [NSMutableArray new];
        _items = [[[NSArray alloc] initWithArray:filters] mutableCopy];
        [_items insertObject:[[OACustomSelectionButtonCell alloc] init] atIndex:0];
    }
    return self;
}

-(void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self.tableView setEditing:YES];
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 49.;

    self.deleteButton.layer.cornerRadius = 9.0;
}

- (void)applyLocalization
{
    self.titleView.text = OALocalizedString(@"delete_custom_categories");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.deleteButton setTitle:OALocalizedString(@"shared_string_delete") forState:UIControlStateNormal];
}

- (IBAction)onCancelButtonClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onDeleteButtonClicked:(id)sender
{
    if (self.delegate)
        [self.delegate removeFilters:_selectedItems];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)selectDeselectGroup:(id)sender
{
    BOOL shouldSelect = _selectedItems.count == 0;
    if (!shouldSelect)
        [_selectedItems removeAllObjects];
    else
    {
        [_selectedItems addObjectsFromArray:_items];
        [_selectedItems removeObjectAtIndex: 0];
    }

    for (NSInteger i = 1; i < _items.count; i++)
    {
        if (shouldSelect)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO];
    }
    [self.tableView beginUpdates];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView headerViewForSection:0].textLabel.text = [[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, _items.count - 1] upperCase];
    [self.tableView endUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
    {
        [self.tableView beginUpdates];
        OAPOIUIFilter *filter = _items[indexPath.row];
        if ([_selectedItems containsObject:filter])
            [_selectedItems removeObject:filter];
        else
            [_selectedItems addObject:filter];
        [self.tableView headerViewForSection:indexPath.section].textLabel.text = [[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int) _selectedItems.count, _items.count - 1] upperCase];
        [self.tableView endUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:indexPath.section], indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - UITableViewDataSource

- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    NSString* identifierCell = indexPath.row == 0 ? kCellTypeSelectionButton : kCellTypeTitle;
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
        cell = (UITableViewCell *) nib[0];
        cell.separatorInset = UIEdgeInsetsMake(0., 65., 0., 0.);
        if ([cell isKindOfClass:OAMenuSimpleCell.class])
        {
            cell.tintColor = UIColorFromRGB(color_primary_purple);
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.05];
            [cell setSelectedBackgroundView:bgColorView];
        }
    }

    if ([cell isKindOfClass:OACustomSelectionButtonCell.class])
    {
        OACustomSelectionButtonCell *selectionButtonCell = (OACustomSelectionButtonCell *) cell;
        NSString *selectionText = _selectedItems.count > 0 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"select_all");
        [selectionButtonCell.selectDeselectButton setTitle:selectionText forState:UIControlStateNormal];
        [selectionButtonCell.selectDeselectButton addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];
        [selectionButtonCell.selectionButton addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];

        NSInteger selectedAmount = _selectedItems.count;
        if (selectedAmount > 0) {
            UIImage *selectionImage = selectedAmount < _items.count - 1 ? [UIImage imageNamed:@"ic_system_checkbox_indeterminate"] : [UIImage imageNamed:@"ic_system_checkbox_selected"];
            [selectionButtonCell.selectionButton setImage:selectionImage forState:UIControlStateNormal];
        } else {
            [selectionButtonCell.selectionButton setImage:nil forState:UIControlStateNormal];
        }
        return selectionButtonCell;
    }
    else if ([cell isKindOfClass:OAMenuSimpleCell.class])
    {
        OAMenuSimpleCell *itemCell = (OAMenuSimpleCell *) cell;
        OAPOIUIFilter *filter = _items[indexPath.row];
        UIImage *poiIcon = [UIImage templateImageNamed:filter.getIconId];
        itemCell.imgView.image = poiIcon ? poiIcon : [UIImage templateImageNamed:@"ic_custom_user"];
        itemCell.textView.text = filter.getName ? filter.getName : @"";
        itemCell.descriptionView.hidden = true;
        BOOL selected = [_selectedItems containsObject:filter];
        UIColor *selectedColor = selected ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_tint_gray);
        itemCell.imgView.tintColor = selectedColor;
        if ([itemCell needsUpdateConstraints])
            [itemCell updateConstraints];
        return itemCell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row > 0)
    {
        OAPOIUIFilter *item = _items[indexPath.row];
        BOOL selected = [_selectedItems containsObject:item];
        [cell setSelected:selected animated:NO];
        if (selected)
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
        return [NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, _items.count - 1];
    return nil;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row != 0;
}

@end
