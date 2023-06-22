//
//  OAPoiTypeSelectionViewController.m
//  OsmAnd
//
//  Created by Paul on 2/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAPoiTypeSelectionViewController.h"
#import "OAEditPOIData.h"
#import "OAPOIHelper.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"
#import "OAPOIBaseType.h"
#import "OARightIconTableViewCell.h"
#import "OASizes.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAPoiTypeSelectionViewController () <UISearchBarDelegate>

@end

@implementation OAPoiTypeSelectionViewController
{
    EOASelectionType _screenType;
    OAEditPOIData *_poiData;
    OAPOIHelper *_poiHelper;
    
    NSArray *_data;
    NSMutableArray *_filteredData;
    
    UISearchController *_searchController;
    
    BOOL _isFiltered;
    BOOL _searchIsActive;
}

#pragma mark - Initialization

- (instancetype)initWithType:(EOASelectionType)type
{
    self = [super init];
    if (self)
        _screenType = type;
    return self;
}

- (void)commonInit
{
    _poiHelper = [OAPOIHelper sharedInstance];
}

- (void)registerNotifications
{
    [self addNotification:UIKeyboardWillShowNotification selector:@selector(keyboardWillShow:)];
    [self addNotification:UIKeyboardWillHideNotification selector:@selector(keyboardWillHide:)];
}

#pragma mark - UIViewController

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchBar.delegate = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    self.navigationItem.searchController = _searchController;
    [self setupSearchControllerWithFilter:NO];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _screenType == CATEGORY_SCREEN ? OALocalizedString(@"poi_select_category") : OALocalizedString(@"poi_select_type");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
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

#pragma mark - Table data

- (void)generateData
{
    _isFiltered = NO;
    if (!_poiData && self.dataProvider)
        _poiData = self.dataProvider.getData;
    
    if (_screenType == CATEGORY_SCREEN)
    {
        NSMutableArray *dataArr = [NSMutableArray new];
        for (OAPOICategory *c in _poiHelper.poiCategories)
        {
            if (!c.nonEditableOsm)
                [dataArr addObject:c];
        }
        _data = [NSArray arrayWithArray:dataArr];
    }
    else
    {
        [self generateTypesList];
    }
    
    _data = [_data sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [((OAPOIBaseType *)obj1).nameLocalized caseInsensitiveCompare:((OAPOIBaseType *)obj2).nameLocalized];
    }];
}

- (void)generateTypesList
{
    NSMutableOrderedSet *dataSet = [NSMutableOrderedSet new];
    OAPOICategory *filter = _searchIsActive || !_poiData ? _poiHelper.otherPoiCategory : _poiData.getPoiCategory;
    NSString *categoryName = filter.name;
    
    for (OAPOIType *type in _poiHelper.poiTypes)
    {
        if (((categoryName && [type.category.name isEqualToString:categoryName]) || [categoryName isEqualToString:@"user_defined_other"]) && !type.nonEditableOsm)
            [dataSet addObject:type];
    }
    _data = dataSet.array;
}

- (NSInteger)sectionsCount
{
    return 1;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _isFiltered ? _filteredData.count : _data.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OARightIconTableViewCell* cell = nil;
    cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OARightIconTableViewCell *)[nib objectAtIndex:0];
        [cell descriptionVisibility:NO];
    }
    if (cell)
    {
        OAPOIBaseType *item = _isFiltered ? (OAPOIBaseType *)_filteredData[indexPath.row] : (OAPOIBaseType *)_data[indexPath.row];
        cell.titleLabel.text = item.nameLocalized;
        UIImage *icon = [item.icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [cell.leftIconView setImage:icon];
        [cell.leftIconView setTintColor:UIColorFromRGB(color_poi_orange)];
        if ((_screenType == CATEGORY_SCREEN && [item isEqual:_poiData.getPoiCategory]) || [item isEqual:_poiData.getCurrentPoiType])
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        else
            cell.accessoryType = UITableViewCellAccessoryNone;
    }
    return cell;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (_screenType == CATEGORY_SCREEN)
    {
        [_poiData updateType:_isFiltered ? _filteredData[indexPath.row] : _data[indexPath.row]];
    }
    else
    {
        NSString *selectedTypeName = _isFiltered ? ((OAPOIBaseType *)_filteredData[indexPath.row]).nameLocalized : ((OAPOIBaseType *)_data[indexPath.row]).nameLocalized;
        NSString *selectedType = _isFiltered ? ((OAPOIBaseType *)_filteredData[indexPath.row]).name : ((OAPOIBaseType *)_data[indexPath.row]).name;
        selectedType = [selectedType stringByReplacingOccurrencesOfString:@"_" withString:@" "];
        if (_delegate)
            [_delegate onPoiTypeSelected:selectedTypeName];
        if (_poiData)
            [_poiData updateTypeTag:selectedType userChanges:YES];
    }
        
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    _searchIsActive = NO;
    _isFiltered = NO;
    [self setupSearchControllerWithFilter:NO];
    [self.tableView reloadData];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    _searchIsActive = YES;
    [self generateData];
    return YES;
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
        for (OAPOIBaseType *type in _data)
        {
            NSRange nameRange = [type.nameLocalized rangeOfString:searchText options:NSCaseInsensitiveSearch];
            NSRange nameTagRange = [type.name rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if (nameRange.location != NSNotFound || nameTagRange.location != NSNotFound)
                [_filteredData addObject:type];
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
