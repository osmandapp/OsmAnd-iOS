//
//  OASelectSubcategoryViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OASelectSubcategoryViewController.h"
#import "Localization.h"
#import "OAMultiselectableHeaderView.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"
#import "OACustomSelectionButtonCell.h"
#import "OAMenuSimpleCell.h"
#import "OAColors.h"
#import "OAPOIUIFilter.h"

@interface OASelectSubcategoryViewController () <UITableViewDataSource, UITableViewDelegate, OAMultiselectableHeaderDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *applyButton;

@end

@implementation OASelectSubcategoryViewController
{
    OAPOICategory *_category;
    OAPOIUIFilter *_filter;
    NSMutableArray *_items;
    NSMutableArray *_selectedItems;
}

- (instancetype)initWithCategory:(OAPOICategory *)category filter:(OAPOIUIFilter *)filter
{
    self = [super init];
    if (self)
    {
        _category = category;
        _filter = filter;
        [self initData];
    }
    return self;
}

- (void)initData
{
    if (_category)
    {
        NSSet<NSString *> *acceptedTypes = [[_filter getAcceptedTypes] objectForKey:_category];
        NSSet<NSString *> *acceptedSubtypes = [_filter getAcceptedSubtypes:_category];
        NSArray<OAPOIType *> *types = _category.poiTypes;

        _selectedItems = [NSMutableArray new];
        _items = [NSMutableArray arrayWithArray:[types sortedArrayUsingComparator:^NSComparisonResult(OAPOIType * _Nonnull t1, OAPOIType * _Nonnull t2) {
            return [t1.nameLocalized localizedCaseInsensitiveCompare:t2.nameLocalized];
        }]];

        if (acceptedSubtypes == [OAPOIBaseType nullSet] || acceptedTypes.count == types.count)
            _selectedItems = [NSMutableArray arrayWithArray:_items];
        else
            for (OAPOIType *poiType in _items)
                if ([acceptedTypes containsObject:poiType.name])
                    [_selectedItems addObject:poiType];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    if (_category)
        self.titleLabel.text = _category.nameLocalized;
    else
        self.titleLabel.text = @"";

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.editing = YES;
    self.tableView.tintColor = UIColorFromRGB(color_primary_purple);
    self.tableView.rowHeight = kEstimatedRowHeight;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;

    [self.tableView beginUpdates];
    for (NSInteger i = 0; i < _items.count; i++)
        if ([_selectedItems containsObject:_items[i]])
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.tableView endUpdates];
}

-(void)applyLocalization
{
    self.applyButton.titleLabel.text = OALocalizedString(@"shared_string_apply");
}

- (IBAction)onBackButtonClicked:(id)sender
{
    if (_delegate)
        [_delegate selectSubcategoryCancel];

    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onApplyButtonClicked:(id)sender
{
    if (_delegate)
    {
        NSMutableSet<NSString *> *selectedKeys = [NSMutableSet set];
        for (OAPOIType *poiType in _selectedItems)
            [selectedKeys addObject:poiType.name];

        [_delegate selectSubcategoryDone:_category keys:selectedKeys allSelected:_selectedItems.count == _items.count];
    }

    [self.navigationController popViewControllerAnimated:YES];
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
}

#pragma mark - UITableViewDataSource

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellType = indexPath.row == 0 ? [OACustomSelectionButtonCell getCellIdentifier] : [OAMenuSimpleCell getCellIdentifier];
    if ([cellType isEqualToString:[OACustomSelectionButtonCell getCellIdentifier]])
    {
        OACustomSelectionButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACustomSelectionButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomSelectionButtonCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., 65., 0., 0.);
            cell.tintColor = UIColorFromRGB(color_primary_purple);
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
            [cell setSelectedBackgroundView:bgColorView];
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
                UIImage *selectionImage = selectedAmount < _items.count ? [UIImage imageNamed:@"ic_system_checkbox_indeterminate"] : [UIImage imageNamed:@"ic_system_checkbox_selected"];
                [cell.selectionButton setImage:selectionImage forState:UIControlStateNormal];
            }
            else
            {
                [cell.selectionButton setImage:nil forState:UIControlStateNormal];
            }
            return cell;
        }
    }
    else if ([cellType isEqualToString:[OAMenuSimpleCell getCellIdentifier]])
    {
        OAMenuSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 65.0, 0.0, 0.0);
            cell.tintColor = UIColorFromRGB(color_primary_purple);
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
            [cell setSelectedBackgroundView:bgColorView];
        }
        if (cell)
        {
            OAPOIType *poiType = _items[indexPath.row - 1];
            BOOL selected = [_selectedItems containsObject:poiType];

            UIColor *selectedColor = selected ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
            UIImage *poiIcon = [UIImage templateImageNamed:poiType.iconName];
            cell.imgView.image = poiIcon ? poiIcon : [UIImage templateImageNamed:@"ic_custom_search_categories"];
            cell.imgView.tintColor = selectedColor;

            if (poiIcon.size.width < cell.imgView.frame.size.width && poiIcon.size.height < cell.imgView.frame.size.height)
                cell.imgView.contentMode = UIViewContentModeCenter;
            else
                cell.imgView.contentMode = UIViewContentModeScaleAspectFit;

            cell.textView.text = poiType.nameLocalized ? poiType.nameLocalized : @"";
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
        OAPOIType *item = _items[indexPath.row - 1];
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

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _items.count + 1;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath.row != 0;
}

@end
