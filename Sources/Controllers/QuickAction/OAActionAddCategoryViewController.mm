//
//  OAActionAddCategoryViewController.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAActionAddCategoryViewController.h"
#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OASearchUICore.h"
#import "OAQuickSearchHelper.h"
#import "OAQuickSearchListItem.h"
#import "OASimpleTableViewCell.h"
#import "OAPOIUIFilter.h"
#import "OAPOIBaseType.h"
#import "OAPOIHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OAActionAddCategoryViewController () <UITextFieldDelegate, UISearchBarDelegate>

@end

@implementation OAActionAddCategoryViewController
{
    NSArray *_data;
    NSMutableArray *_filteredData;
    NSMutableArray<NSString *> *_initialValues;
    
    UIView *_tableHeaderView;
    UISearchController *_searchController;
    
    BOOL _isFiltered;
}

#pragma mark - Initialization

- (instancetype)initWithNames:(NSMutableArray<NSString *> *)names
{
    self = [super init];
    if (self)
        _initialValues = names;
    return self;
}

- (void)registerNotifications
{
    [self addNotification:UIKeyboardWillShowNotification selector:@selector(keyboardWillShow:)];
    [self addNotification:UIKeyboardWillHideNotification selector:@selector(keyboardWillHide:)];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self.tableView setEditing:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchBar.delegate = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    _searchController.hidesNavigationBarDuringPresentation = NO;
    self.navigationItem.searchController = _searchController;
    [self setupSearchControllerWithFilter:NO];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"quick_action_new_action");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (NSString *)getTableHeaderDescription
{
    return OALocalizedString(@"quick_action_add_category_descr");
}

- (BOOL)hideFirstHeader
{
    return YES;
}

- (void)setupSearchControllerWithFilter:(BOOL)isFiltered
{
    if (isFiltered)
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_search") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.5]}];
        _searchController.searchBar.searchTextField.backgroundColor = UIColor.whiteColor;
        _searchController.searchBar.searchTextField.leftView.tintColor = UIColor.grayColor;
    }
    else
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_search") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.5]}];
        _searchController.searchBar.searchTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        _searchController.searchBar.searchTextField.leftView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        _searchController.searchBar.searchTextField.tintColor = UIColor.grayColor;
    }
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return @[[self createRightNavbarButton:OALocalizedString(@"shared_string_done")
                                  iconName:nil
                                    action:@selector(onRightNavbarButtonPressed)
                                      menu:nil]];
}

#pragma mark - Table data

- (void)generateData
{
    OASearchResultCollection *res = [[[OAQuickSearchHelper instance] getCore] shallowSearch:[OASearchAmenityTypesAPI class] text:@"" matcher:nil];
    NSMutableArray *rows = [NSMutableArray array];
    if (res)
    {
        for (OASearchResult *sr in [res getCurrentSearchResults])
            [rows addObject:sr.object];
    }
    _data = [NSArray arrayWithArray:rows];
}

- (id)getItem:(NSIndexPath *)indexPath
{
    if (_isFiltered)
        return _filteredData[indexPath.row];
    return _data[indexPath.row];
}

- (NSInteger)sectionsCount
{
    return 1;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (_isFiltered)
        return _filteredData.count;
    return _data.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    id category = [self getItem:indexPath];
    OASimpleTableViewCell* cell;
    cell = (OASimpleTableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
        [cell descriptionVisibility:NO];
    }
    if (cell)
    {
        NSString *name = [self getNameFromCategory:category];
        cell.titleLabel.text = name;
        if ([category isKindOfClass:OAPOIBaseType.class])
            cell.leftIconView.image = ((OAPOIBaseType *)category).icon;
        else if ([category isKindOfClass:OAPOIUIFilter.class])
            cell.leftIconView.image = [OAPOIHelper getCustomFilterIcon:(OAPOIUIFilter *)category];
        cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorSelected];
        if ([_initialValues containsObject:name])
        {
            [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            [_initialValues removeObject:name];
        }
    }
    return cell;
}

#pragma mark - Additions

- (NSString *)getNameFromCategory:(id)category
{
    if ([category isKindOfClass:OAPOIUIFilter.class])
    {
        OAPOIUIFilter *filter = (OAPOIUIFilter *)category;
        return filter.getName;
    }
    else if ([category isKindOfClass:OAPOIBaseType.class])
    {
        OAPOIBaseType *filter = (OAPOIBaseType *)category;
        return filter.nameLocalized;
    }
    else
    {
        return nil;
    }
}

- (NSString *)getName:(id)item
{
    NSString *name = @"";
    if ([item isKindOfClass:OAPOIUIFilter.class])
    {
        OAPOIUIFilter *filter = (OAPOIUIFilter *)item;
        name = filter.getName;
    }
    else if ([item isKindOfClass:OAPOIBaseType.class])
    {
        OAPOIBaseType *filter = (OAPOIBaseType *)item;
        name = filter.nameLocalized;
    }
    return name;
}

#pragma mark - Selectors

- (void)onRightNavbarButtonPressed
{
    NSArray *selectedItems = [self.tableView indexPathsForSelectedRows];
    NSMutableArray *arr = [NSMutableArray new];
    for (NSIndexPath *path in selectedItems)
        [arr addObject:[self getItem:path]];
    
    if (self.delegate)
        [self.delegate onCategoriesSelected:[NSArray arrayWithArray:arr]];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    _isFiltered = NO;
    [self setupSearchControllerWithFilter:NO];
    [self.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchText.length == 0)
    {
        _isFiltered = NO;
        [self setupSearchControllerWithFilter:NO];
    }
    else
    {
        _isFiltered = YES;
        [self setupSearchControllerWithFilter:YES];
        _filteredData = [NSMutableArray new];
        for (id item in _data)
        {
            NSString * name = [self getName:item];
            NSRange nameRange = [name rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if (nameRange.location != NSNotFound)
                [_filteredData addObject:item];
        }
    }
    [self.tableView reloadData];
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGRect keyboardBounds;
    [[userInfo valueForKey:UIKeyboardFrameEndUserInfoKey] getValue: &keyboardBounds];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        UIEdgeInsets insets = [self.tableView contentInset];
        [self.tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardBounds.size.height, insets.right)];
        [self.tableView setScrollIndicatorInsets:self.tableView.contentInset];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        UIEdgeInsets insets = [self.tableView contentInset];
        [self.tableView setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0.0, insets.right)];
        [self.tableView setScrollIndicatorInsets:self.tableView.contentInset];
    } completion:nil];
}

@end
