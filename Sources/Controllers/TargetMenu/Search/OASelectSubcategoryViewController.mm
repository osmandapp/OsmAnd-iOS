//
//  OASelectSubcategoryViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OASelectSubcategoryViewController.h"
#import "Localization.h"
#import "OAPOICategory.h"
#import "OAPOIType.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAPOIUIFilter.h"
#import "OASearchResult.h"
#import "OAResultMatcher.h"
#import "OASearchUICore.h"
#import "OASearchSettings.h"
#import "OAQuickSearchHelper.h"
#import "OATableViewCustomHeaderView.h"
#import "OACustomPOIViewController.h"
#import "GeneratedAssetSymbols.h"

@interface OASelectSubcategoryViewController () <UISearchBarDelegate, OATableViewCellDelegate>

@end

@implementation OASelectSubcategoryViewController
{
    OASearchUICore *_core;
    OAPOICategory *_category;
    OAPOIUIFilter *_filter;
    NSArray<OAPOIType *> *_items;
    NSMutableArray<OAPOIType *> *_selectedItems;
    NSMutableArray<OAPOIType *> *_searchResult;
    UISearchController *_searchController;
    BOOL _searchMode;
    BOOL _hasSelection;
}

#pragma mark - Initialization

- (instancetype)initWithCategory:(OAPOICategory *)category filter:(OAPOIUIFilter *)filter
{
    self = [super init];
    if (self)
    {
        _category = category;
        _filter = filter;
    }
    return self;
}

- (void)commonInit
{
    _core = [[OAQuickSearchHelper instance] getCore];
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
    
    self.tableView.editing = YES;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
    [self.tableView beginUpdates];
    for (NSInteger i = 0; i < _items.count; i++)
        if ([_selectedItems containsObject:_items[i]])
            [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0] animated:NO scrollPosition:UITableViewScrollPositionNone];
    [self.tableView endUpdates];
    
    _searchMode = NO;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    _searchController.searchBar.delegate = self;
    _searchController.obscuresBackgroundDuringPresentation = NO;
    self.navigationItem.searchController = _searchController;
    [self setupSearchControllerWithFilter:NO];
//    _hasSelection = NO;
    [self updateBottomButtons];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _category ? _category.nameLocalized : @"";
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

- (NSString *)getBottomButtonTitle
{
    return OALocalizedString(@"shared_string_apply");
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return _hasSelection ? EOABaseButtonColorSchemePurple : EOABaseButtonColorSchemeInactive;
}

#pragma mark - Table data

- (void)generateData
{
    if (_category)
    {
        NSSet<NSString *> *acceptedTypes = [[_filter getAcceptedTypes] objectForKey:_category];
        NSSet<NSString *> *acceptedSubtypes = [_filter getAcceptedSubtypes:_category];
        NSArray<OAPOIType *> *types = _category.poiTypes;

        _selectedItems = [NSMutableArray new];
        _items = [NSArray arrayWithArray:[types sortedArrayUsingComparator:^NSComparisonResult(OAPOIType * _Nonnull t1, OAPOIType * _Nonnull t2) {
            return [t1.nameLocalized localizedCaseInsensitiveCompare:t2.nameLocalized];
        }]];

        if (acceptedSubtypes == [OAPOIBaseType nullSet] || acceptedTypes.count == types.count)
        {
            _selectedItems = [NSMutableArray arrayWithArray:_items];
        }
        else
        {
            for (OAPOIType *poiType in _items)
            {
                if ([acceptedTypes containsObject:poiType.name])
                    [_selectedItems addObject:poiType];
            }
        }
    }
}

- (NSInteger)sectionsCount
{
    return 1;
}

- (UIView *)getCustomViewForHeader:(NSInteger)section
{
    if (section == 0)
    {
        OATableViewCustomHeaderView *customHeader = [self.tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
        [customHeader setYOffset:32];
        customHeader.label.text = [[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, (int)_items.count] upperCase];
        return customHeader;
    }
    return nil;
}
 
- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    if (section == 0)
    {
        return [OATableViewCustomHeaderView getHeight:[[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int)_selectedItems.count, (int)_items.count] upperCase] width:self.tableView.bounds.size.width] + 18;
    }
    return UITableViewAutomaticDimension;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _searchMode ? _searchResult.count : _items.count + 1;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0 && !_searchMode)
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            [cell leftEditButtonVisibility:YES];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
    else
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
            bgColorView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
            [cell setSelectedBackgroundView:bgColorView];
        }
        if (cell)
        {
            OAPOIType *poiType = _searchMode && _searchResult.count > indexPath.row ? _searchResult[indexPath.row] : _items[indexPath.row - 1];
            BOOL selected = [_selectedItems containsObject:poiType];
            
            UIColor *selectedColor = selected ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];
            cell.leftIconView.image = self.delegate ? [self.delegate getPoiIcon:poiType] : [UIImage templateImageNamed:@"ic_custom_search_categories"];
            cell.leftIconView.tintColor = selectedColor;
            if (cell.leftIconView.image.size.width < cell.leftIconView.frame.size.width && cell.leftIconView.image.size.height < cell.leftIconView.frame.size.height)
                cell.leftIconView.contentMode = UIViewContentModeCenter;
            else
                cell.leftIconView.contentMode = UIViewContentModeScaleAspectFit;
            
            cell.titleLabel.text = poiType.nameLocalized ? poiType.nameLocalized : @"";
            return cell;
        }
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (!_searchMode && indexPath.row == 0)
        [self selectDeselectGroup:nil];
    else
        [self selectDeselectItem:indexPath];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_searchMode || (!_searchMode &&  indexPath.row > 0))
    {
        OAPOIType *item = _searchMode && _searchResult.count > indexPath.row ? _searchResult[indexPath.row] : _items[indexPath.row - 1];
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
    if (_searchMode || (!_searchMode &&  indexPath.row > 0))
        [self selectDeselectItem:indexPath];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    return indexPath;
}

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _searchMode || (!_searchMode && indexPath.row != 0);
}

#pragma mark - Additions

- (void)hasSelection
{
    NSSet<NSString *> *acceptedSubtypes = [_filter getAcceptedSubtypes:_category];
    NSArray<OAPOIType *> *types = _category.poiTypes;
    if ((![[self getSelectedKeys] isEqualToSet:acceptedSubtypes] && acceptedSubtypes != [OAPOIBaseType nullSet]) || (acceptedSubtypes == [OAPOIBaseType nullSet] && _selectedItems.count != types.count))
        _hasSelection = YES;
    else
        _hasSelection = NO;
}

- (NSMutableSet<NSString *> *)getSelectedKeys
{
    NSMutableSet<NSString *> *selectedKeys = [NSMutableSet set];
    for (OAPOIType *poiType in _selectedItems)
        [selectedKeys addObject:poiType.name];
    return selectedKeys;
}

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    if (_searchMode || (!_searchMode && indexPath.row > 0))
    {
        [self.tableView beginUpdates];
        OAPOIType *type = _searchMode && _searchResult.count > indexPath.row ? _searchResult[indexPath.row] : _items[indexPath.row - 1];
        if ([_selectedItems containsObject:type])
            [_selectedItems removeObject:type];
        else
            [_selectedItems addObject:type];
        [self.tableView headerViewForSection:indexPath.section].textLabel.text = [[NSString stringWithFormat:OALocalizedString(@"selected_of"), (int) _selectedItems.count, _items.count] upperCase];
        [self.tableView endUpdates];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];

        [self hasSelection];
        [self updateBottomButtons];
    }
}

- (void)resetSearchTypes
{
    [_core updateSettings:[[_core getSearchSettings] resetSearchTypes]];
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    if (self.delegate)
        [self.delegate selectSubcategoryCancel];
    
    [self resetSearchTypes];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)onBottomButtonPressed
{
    if (self.delegate)
        [self.delegate selectSubcategoryDone:_category keys:[self getSelectedKeys] allSelected:_selectedItems.count == _items.count];

    [self resetSearchTypes];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)selectDeselectGroup:(UIButton *)sender
{
    [self onLeftEditButtonPressed:sender.tag];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    _searchMode = NO;
    [self setupSearchControllerWithFilter:NO];
    _searchResult = [NSMutableArray new];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchBar.text.length == 0)
    {
        _searchMode = NO;
        [self setupSearchControllerWithFilter:NO];
        [_core updateSettings:_core.getSearchSettings.resetSearchTypes];
        [self resetSearchTypes];
    }
    else
    {
        _searchMode = YES;
        [self setupSearchControllerWithFilter:YES];
        _searchResult = [NSMutableArray new];
        OASearchSettings *searchSettings = [[_core getSearchSettings] setSearchTypes:@[[OAObjectType withType:POI_TYPE]]];
        [_core updateSettings:searchSettings];
        [_core search:searchBar.text delayedExecution:YES matcher:[[OAResultMatcher<OASearchResult *> alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *object) {
            OASearchResult *obj = *object;
            if (obj.objectType == SEARCH_FINISHED)
            {
                OASearchResultCollection *currentSearchResult = [_core getCurrentSearchResult];
                NSMutableArray<OAPOIType *> *results = [NSMutableArray new];
                for (OASearchResult *result in currentSearchResult.getCurrentSearchResults)
                {
                    NSObject *poiObject = result.object;
                    if ([poiObject isKindOfClass:[OAPOIType class]])
                    {
                        OAPOIType *poiType = (OAPOIType *) poiObject;
                        if (!poiType.isAdditional)
                        {
                            if (poiType.category == _category || [_items containsObject:poiType])
                            {
                                [results addObject:poiType];
                            }
                            else
                            {
                                for (OAPOIType *item in _items)
                                {
                                    if ([item.name isEqualToString:poiType.name])
                                        [results addObject:item];
                                }
                            }
                        }
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    _searchResult = [NSMutableArray arrayWithArray:results];
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                    [self hasSelection];
                    [self updateBottomButtons];
                });
            }
            return YES;
        } cancelledFunc:^BOOL {
            return !_searchMode;
        }]];
    }
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self hasSelection];
    [self updateBottomButtons];
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;
    
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.buttonsBottomOffsetConstraint.constant = keyboardHeight - [OAUtilities getBottomMargin];
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.buttonsBottomOffsetConstraint.constant = 0;
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
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

    [self hasSelection];
    [self updateBottomButtons];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [_searchController.searchBar resignFirstResponder];
}

@end
