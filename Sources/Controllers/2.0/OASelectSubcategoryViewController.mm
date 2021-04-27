//
//  OASelectSubcategoryViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OASelectSubcategoryViewController.h"
#import "OATextLineViewCell.h"
#import "OAPOISearchHelper.h"
#import "Localization.h"
#import "OAMultiselectableHeaderView.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"
#import "OAPOIHelper.h"
#import "OACustomSelectionButtonCell.h"
#import "OAMenuSimpleCell.h"
#import "OAColors.h"

#define kCellTypeSelectionButton @"OACustomSelectionButtonCell"
#define kCellTypeTitle @"OAMenuSimpleCell"
#define kDataTypePoi @"OAPOIType"

@interface OASelectSubcategoryViewController () <UITableViewDataSource, UITableViewDelegate, OAMultiselectableHeaderDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *topView;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UILabel *textLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation OASelectSubcategoryViewController
{
    OAMultiselectableHeaderView *_headerView;
    NSArray<NSString *> *_keys;
    NSArray<NSString *> *_data;
    OAPOICategory *_category;
    NSSet<NSString *> *_subcategories;
    NSMutableArray *_items;
    NSMutableArray *_selectedItems;
    BOOL _selectAll;
}

- (instancetype)initWithCategory:(OAPOICategory *)category subcategories:(NSSet<NSString *> *)subcategories selectAll:(BOOL)selectAll
{
    self = [super init];
    if (self)
    {
        _category = category;
        _subcategories = subcategories;
        _selectAll = selectAll;
        [self initData];
    }
    return self;
}

- (void)initData
{
    if (_category)
    {
        _items = [NSMutableArray arrayWithArray:_category.poiTypes];
        [_items insertObject:[[OACustomSelectionButtonCell alloc] init] atIndex:0];

        OAPOIHelper *helper = [OAPOIHelper sharedInstance];
        NSMutableDictionary<NSString *, NSString *> *subMap = [NSMutableDictionary dictionary];
        for (NSString *name in _subcategories)
            [subMap setObject:[helper getPhraseByName:name] forKey:name];

        for (OAPOIType *pt in _category.poiTypes)
            [subMap setObject:pt.nameLocalized forKey:pt.name];
        
        NSMutableArray<NSString *> *keys = [NSMutableArray arrayWithArray:subMap.allKeys];
        NSMutableArray<NSString *> *data = [NSMutableArray arrayWithArray:subMap.allValues];
        
        [keys sortUsingComparator:^NSComparisonResult(NSString * _Nonnull name1, NSString * _Nonnull name2) {
            return [[subMap objectForKey:name1] localizedCaseInsensitiveCompare:[subMap objectForKey:name2]];
        }];
        [data sortUsingComparator:^NSComparisonResult(NSString * _Nonnull nameLoc1, NSString * _Nonnull nameLoc2) {
            return [nameLoc1 localizedCaseInsensitiveCompare:nameLoc2];
        }];

        _data = [NSArray arrayWithArray:data];
        _keys = [NSArray arrayWithArray:keys];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (_category)
        self.textLabel.text = _category.nameLocalized;
    else
        self.textLabel.text = @"";
    
    // add header
    _headerView = [[OAMultiselectableHeaderView alloc] initWithFrame:CGRectMake(0.0, 1.0, 100.0, 44.0)];
    [_headerView setTitleText:OALocalizedString(@"select_all")];
    
    _headerView.section = 0;
    _headerView.delegate = self;
    
    self.tableView.editing = YES;
    if (_selectAll)
    {
        _headerView.selected = YES;
        [self.tableView beginUpdates];
        for (int i = 0; i < _data.count; i++)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self.tableView endUpdates];
    }
    else
    {
        _headerView.selected = _subcategories.count == _keys.count;
        [self.tableView beginUpdates];
        for (int i = 0; i < _keys.count; i++)
        {
            NSString *name = _keys[i];
            if ([_subcategories containsObject:name])
                [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        [self.tableView endUpdates];
    }
    [self applySafeAreaMargins];
}

-(UIView *) getTopView
{
    return _topView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(void)applyLocalization
{
    self.descriptionLabel.text = OALocalizedString(@"subcategories");
}

- (IBAction)cancelPress:(id)sender
{
    if (_delegate)
        [_delegate selectSubcategoryCancel];

    [self dismissViewController];
}

- (IBAction)donePress:(id)sender
{
    if (_delegate)
    {
        NSMutableSet<NSString *> *selectedKeys = [NSMutableSet set];
        NSArray<NSIndexPath *> *rows = [self.tableView indexPathsForSelectedRows];
        for (NSIndexPath *index in rows)
            [selectedKeys addObject:_keys[index.row]];

        [_delegate selectSubcategoryDone:_category keys:selectedKeys allSelected:_keys.count == selectedKeys.count];
    }

    [self dismissViewController];
}

- (void)selectDeselectGroup:(id)sender
{
    BOOL shouldSelect = _selectedItems.count == 0;
    if (!shouldSelect)
        [_selectedItems removeAllObjects];
    else
    {
        [_selectedItems addObjectsFromArray:_items];
        [_selectedItems removeObjectAtIndex:0];
    }

    for (NSInteger i = 1; i < _items.count; i++)
    {
        if (shouldSelect)
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO];
    }
    [self.tableView beginUpdates];
    [self.tableView headerViewForSection:0].textLabel.text = [[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, _items.count - 1] upperCase];
    [self.tableView endUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    [self setupApplyButtonView];
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
    [self setupApplyButtonView];
}

- (void)setupApplyButtonView
{
    BOOL hasSelection = _selectedItems.count != 0;
//    self.applyButton.backgroundColor = hasSelection ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_route_button_inactive);
//    [self.applyButton setTintColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
//    [self.applyButton setTitleColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
//    [self.applyButton setUserInteractionEnabled:hasSelection];
}

#pragma mark - OAMultiselectableHeaderDelegate

//-(void)headerCheckboxChanged:(id)sender value:(BOOL)value
//{
//    OAMultiselectableHeaderView *headerView = (OAMultiselectableHeaderView *)sender;
//    NSInteger section = headerView.section;
//    NSInteger rowsCount = [self.tableView numberOfRowsInSection:section];
//
//    [self.tableView beginUpdates];
//    if (value)
//    {
//        for (int i = 0; i < rowsCount; i++)
//            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES scrollPosition:UITableViewScrollPositionNone];
//    }
//    else
//    {
//        for (int i = 0; i < rowsCount; i++)
//            [self.tableView deselectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:section] animated:YES];
//    }
//    [self.tableView endUpdates];
//}

#pragma mark - UITableViewDataSource

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForFooter];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 46.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return _headerView;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSObject *item = _items[indexPath.row];
    NSString *cellType = NSStringFromClass(item.class);
    if ([cellType isEqualToString:kCellTypeSelectionButton])
    {
        static NSString * const identifierCell = kCellTypeSelectionButton;
        OACustomSelectionButtonCell *cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., 65., 0., 0.);
        }
        if (cell)
        {
            NSString *selectionText = _selectedItems.count > 0 ? OALocalizedString(@"shared_string_deselect_all") : OALocalizedString(@"select_all");
            [cell.selectDeselectButton setTitle:selectionText forState:UIControlStateNormal];
            [cell.selectDeselectButton addTarget:self action:@selector(selectDeselectGroup:) forControlEvents:UIControlEventTouchUpInside];
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
    else if ([cellType isEqualToString:kDataTypePoi])
    {
        static NSString * const identifierCell = kCellTypeTitle;
        OAMenuSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:identifierCell owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0., 65., 0., 0.);
            cell.tintColor = UIColorFromRGB(color_primary_purple);
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.05];
            [cell setSelectedBackgroundView:bgColorView];
        }
        if (cell)
        {
            OAPOIType *filter = (OAPOIType *) item;
            UIImage *poiIcon = [UIImage templateImageNamed:filter.iconName];
            cell.imgView.image = poiIcon ? poiIcon : [UIImage templateImageNamed:@"ic_custom_user"];
            cell.textView.text = filter.nameLocalized ? filter.nameLocalized : @"";
            cell.descriptionView.hidden = true;
            BOOL selected = [_selectedItems containsObject:filter];
            UIColor *selectedColor = selected ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_tint_gray);
            cell.imgView.tintColor = selectedColor;
            if ([cell needsUpdateConstraints])
                [cell updateConstraints];
            return cell;
        }
    }
    return nil;
}

@end
