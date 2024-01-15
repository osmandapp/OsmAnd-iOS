//
//  OACustomPOIViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACustomPOIViewController.h"
#import "OAPOIHelper.h"
#import "OAPOICategory.h"
#import "OASelectSubcategoryViewController.h"
#import "OAPOIFiltersHelper.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "OASimpleTableViewCell.h"
#import "OASearchUICore.h"
#import "OAQuickSearchHelper.h"
#import "OASearchSettings.h"
#import "OAPOIType.h"
#import "OAPOIFilterViewController.h"
#import "GeneratedAssetSymbols.h"

@interface OACustomPOIViewController () <OASelectSubcategoryDelegate, UISearchBarDelegate>

@end

@implementation OACustomPOIViewController
{
    OASearchUICore *_core;
    OAPOIFiltersHelper *_filterHelper;
    OAPOIUIFilter *_filter;
    NSArray<OAPOICategory *> *_categories;
    NSMutableArray<OAPOIType *> *_searchResult;
    NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *_searchResultSelected;
    NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *_acceptedTypes;
    BOOL _editMode;
    BOOL _searchMode;
    NSInteger _countShowCategories;
    UISearchController *_searchController;
}

#pragma mark - Initialization

- (instancetype)initWithFilter:(OAPOIUIFilter *)filter
{
    self = [super init];
    if (self)
    {
        _filter = filter;
        _editMode = _filter != [_filterHelper getCustomPOIFilter];
    }
    return self;
}

- (void)commonInit
{
    _core = [[OAQuickSearchHelper instance] getCore];
    _filterHelper = [OAPOIFiltersHelper sharedInstance];
    _searchResultSelected = [NSMapTable weakToStrongObjectsMapTable];
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
    [self updateBottomButtons];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _editMode ? _filter.name : OALocalizedString(@"create_custom_poi");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    return @[[self createRightNavbarButton:OALocalizedString(@"shared_string_save")
                                  iconName:nil
                                    action:@selector(onRightNavbarButtonPressed)
                                      menu:nil]];
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

- (BOOL)hideFirstHeader
{
    return YES;
}

- (NSAttributedString *)getBottomButtonTitleAttr
{
    if (!_searchMode)
    {
        [self showCategoriesCount];
        
        NSString *textShow = OALocalizedString(@"recording_context_menu_show");
        UIFont *fontShow = [UIFont scaledSystemFontOfSize:15 weight:UIFontWeightSemibold];
        UIColor *colorShow = _countShowCategories != 0 ? UIColor.whiteColor : [UIColor colorNamed:ACColorNameTextColorSecondary];
        NSMutableAttributedString *attrShow = [[NSMutableAttributedString alloc] initWithString:textShow attributes:@{NSFontAttributeName: fontShow, NSForegroundColorAttributeName: colorShow}];

        NSString *textCategories = [NSString stringWithFormat:@"\n%@: %li", OALocalizedString(@"search_categories"), _countShowCategories];
        UIFont *fontCategories = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
        UIColor *colorCategories = _countShowCategories != 0 ? [[UIColor alloc] initWithWhite:1 alpha:0.5] : [UIColor colorNamed:ACColorNameTextColorSecondary];
        NSMutableAttributedString *attrCategories = [[NSMutableAttributedString alloc] initWithString:textCategories attributes:@{NSFontAttributeName: fontCategories, NSForegroundColorAttributeName: colorCategories}];

        [attrShow appendAttributedString:attrCategories];

        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:2.0];
        [style setAlignment:NSTextAlignmentCenter];
        [attrShow addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, attrShow.string.length)];
        return attrShow;
    }
    else
    {
        NSString *textShow = OALocalizedString(@"shared_string_add");
        UIFont *fontShow = [UIFont scaledSystemFontOfSize:15 weight:UIFontWeightSemibold];
        UIColor *colorShow = UIColor.whiteColor;
        NSMutableAttributedString *attrAdd = [[NSMutableAttributedString alloc] initWithString:textShow attributes:@{NSFontAttributeName: fontShow, NSForegroundColorAttributeName: colorShow}];
        return attrAdd;
    }
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    [self showCategoriesCount];
    
    return _searchMode || _countShowCategories != 0 ? EOABaseButtonColorSchemePurple : EOABaseButtonColorSchemeInactive;
}

- (NSString *)getTableHeaderDescription
{
    return !_searchMode ? OALocalizedString(@"search_poi_types_descr") : nil;
}

#pragma mark - Table data

- (void)generateData
{
    NSArray<OAPOICategory *> *poiCategoriesNoOther = [OAPOIHelper sharedInstance].poiCategoriesNoOther;
    _categories = [poiCategoriesNoOther sortedArrayUsingComparator:^NSComparisonResult(OAPOICategory * _Nonnull c1, OAPOICategory * _Nonnull c2) {
        return [c1.nameLocalized localizedCaseInsensitiveCompare:c2.nameLocalized];
    }];
    if (_editMode)
    {
        _acceptedTypes = [_filter getAcceptedTypes];
        for (OAPOICategory *category in _acceptedTypes.keyEnumerator)
        {
            NSMutableSet *types = [_acceptedTypes objectForKey:category];
            if (types == [OAPOIBaseType nullSet])
            {
                for (OAPOIType *poiType in category.poiTypes)
                    [types addObject:poiType.name];
            }
        }
    }
    else
    {
        _acceptedTypes = [NSMapTable new];
    }
}

- (UIImage *)getPoiIcon:(OAPOIType *)poiType
{
    UIImage *img = [UIImage mapSvgImageNamed:[NSString stringWithFormat:@"mx_%@", poiType.name]];
    if (!img)
        img = [UIImage mapSvgImageNamed:[NSString stringWithFormat:@"mx_%@_%@", [poiType getOsmTag], [poiType getOsmValue]]];
    if (img)
        return [img imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    else
        return [UIImage templateImageNamed:@"ic_custom_search_categories"];
}

- (NSInteger)sectionsCount
{
    return 1;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _searchMode ? _searchResult.count : _categories.count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OASimpleTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASimpleTableViewCell *) nib[0];
        if (_searchMode)
        {
            cell.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
            [cell setSelectedBackgroundView:bgColorView];
        }
    }
    if (cell)
    {
        if (!_searchMode)
        {
            OAPOICategory *category = _categories[indexPath.row];
            NSSet<NSString *> *subtypes = [_acceptedTypes objectForKey:category];
            NSInteger countAcceptedTypes = subtypes.count;
            NSInteger countAllTypes = category.poiTypes.count;
            BOOL isSelected = [_filter isTypeAccepted:category] && subtypes.count > 0;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            cell.titleLabel.text = category.nameLocalized;
            
            UIImage *categoryIcon = [[category icon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.leftIconView.image = categoryIcon;
            cell.leftIconView.tintColor = isSelected ? [UIColor colorNamed:ACColorNameIconColorActive] : [UIColor colorNamed:ACColorNameIconColorDisabled];
            cell.leftIconView.contentMode = UIViewContentModeCenter;
            
            NSString *descText;
            if (subtypes == [OAPOIBaseType nullSet] || countAllTypes == countAcceptedTypes)
                descText = [NSString stringWithFormat:@"%@ - %lu", OALocalizedString(@"shared_string_all"), countAllTypes];
            else
                descText = [NSString stringWithFormat:@"%lu/%lu", countAcceptedTypes, countAllTypes];
            [cell descriptionVisibility:YES];
            cell.descriptionLabel.text = descText;
            cell.descriptionLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
        }
        else
        {
            OAPOIType *poiType = _searchResult[indexPath.row];
            BOOL accepted = [[_searchResultSelected objectForKey:poiType.category] containsObject:poiType.name];
            cell.accessoryType = UITableViewCellAccessoryNone;
            
            cell.titleLabel.text = poiType.nameLocalized ? poiType.nameLocalized : @"";
            
            UIColor *selectedColor = accepted ? [UIColor colorNamed:ACColorNameIconColorSelected] : [UIColor colorNamed:ACColorNameIconColorDisabled];
            cell.leftIconView.image = [self getPoiIcon:poiType];
            cell.leftIconView.tintColor = selectedColor;
            if (cell.leftIconView.image.size.width < cell.leftIconView.frame.size.width && cell.leftIconView.image.size.height < cell.leftIconView.frame.size.height)
                cell.leftIconView.contentMode = UIViewContentModeCenter;
            else
                cell.leftIconView.contentMode = UIViewContentModeScaleAspectFit;
            
            cell.descriptionLabel.text = nil;
            [cell descriptionVisibility:NO];
        }
        return cell;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    if (_searchMode)
    {
        [self selectDeselectItem:indexPath];
    }
    else
    {
        OAPOICategory* item = _categories[indexPath.row];
        OASelectSubcategoryViewController *subcategoryScreen = [[OASelectSubcategoryViewController alloc] initWithCategory:item filter:_filter];
        subcategoryScreen.delegate = self;
        [self.navigationController pushViewController:subcategoryScreen animated:YES];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_searchMode)
    {
        OAPOIType *poiType = _searchResult[indexPath.row];
        BOOL accepted = [[_searchResultSelected objectForKey:poiType.category] containsObject:poiType.name];
        [cell setSelected:accepted animated:NO];
        if (accepted)
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        else
            [tableView deselectRowAtIndexPath:indexPath animated:NO];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_searchMode)
        [self selectDeselectItem:indexPath];
}

#pragma mark - UITableViewDataSource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _searchMode;
}

#pragma mark - Additions

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    if (_searchMode)
    {
        OAPOIType *searchType = _searchResult[indexPath.row];
        NSString *searchTypeName = searchType.name;
        OAPOICategory *searchTypeCategory = searchType.category;

        if ([_searchResultSelected.keyEnumerator.allObjects containsObject:searchTypeCategory])
        {
            NSMutableSet<NSString *> *searchTypes = [_searchResultSelected objectForKey:searchTypeCategory];
            if ([searchTypes containsObject:searchTypeName])
                [searchTypes removeObject:searchTypeName];
            else
                [searchTypes addObject:searchTypeName];
        }
        else
        {
            [_searchResultSelected setObject:[NSMutableSet setWithObject:searchTypeName] forKey:searchTypeCategory];
        }

        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (void)resetSearchTypes
{
    [_core updateSettings:[[_core getSearchSettings] resetSearchTypes]];
}

- (void)showCategoriesCount
{
    _countShowCategories = 0;
    for (OAPOICategory *category in _acceptedTypes.keyEnumerator)
    {
        if ([_filter isTypeAccepted:category])
        {
            NSSet<NSString *> *acceptedSubtypes = [_acceptedTypes objectForKey:category];
            NSInteger count = acceptedSubtypes != [OAPOIBaseType nullSet] ? acceptedSubtypes.count : category.poiTypes.count;
            _countShowCategories += count;
        }
    }
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    [self resetSearchTypes];
    [OAQuickSearchHelper.instance refreshCustomPoiFilters];
    [self.navigationController popViewControllerAnimated:YES];
    
    if (_editMode && self.refreshDelegate)
        [self.refreshDelegate refreshList];
}

- (void)onRightNavbarButtonPressed
{
    if (self.delegate)
    {
        UIAlertController *saveDialog = [self.delegate createSaveFilterDialog:_filter customSaveAction:YES];
        UIAlertAction *actionSave = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_save") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [self.delegate searchByUIFilter:_filter newName:saveDialog.textFields[0].text willSaved:YES];
            [self resetSearchTypes];
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [saveDialog addAction:actionSave];
        [self presentViewController:saveDialog animated:YES completion:nil];
    }
}

- (void)onBottomButtonPressed
{
    if (!_searchMode)
    {
        [_filterHelper editPoiFilter:_filter];
        if (self.delegate)
            [self.delegate searchByUIFilter:_filter newName:nil willSaved:NO];

        if (_editMode && self.refreshDelegate)
            [self.refreshDelegate refreshList];

        [self resetSearchTypes];
        [OAQuickSearchHelper.instance refreshCustomPoiFilters];
        [self.navigationController popViewControllerAnimated:YES];
    }
    else
    {
        for (OAPOICategory *poiCategory in _searchResultSelected)
        {
            NSMutableSet *selectedSubtypes = [_searchResultSelected objectForKey:poiCategory];
            if (![[_acceptedTypes objectForKey:poiCategory] isEqualToSet:selectedSubtypes])
            {
                if (selectedSubtypes.count == poiCategory.poiTypes.count)
                    [_filter selectSubTypesToAccept:poiCategory accept:[OAPOIBaseType nullSet]];
                else if (selectedSubtypes.count == 0)
                    [_filter setTypeToAccept:poiCategory b:NO];
                else
                    [_filter selectSubTypesToAccept:poiCategory accept:selectedSubtypes];
            }
        }

        [_filterHelper editPoiFilter:_filter];
        _acceptedTypes = _filter.getAcceptedTypes;
        [self searchBarCancelButtonClicked:_searchController.searchBar];
        _searchController.active = NO;
        [self resetSearchTypes];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    _searchMode = NO;
    [self setupSearchControllerWithFilter:NO];
    [_searchResult removeAllObjects];
    [_searchResultSelected removeAllObjects];
    [self updateBottomButtons];
    [self.tableView setEditing:NO];
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [_searchResult removeAllObjects];
    [_searchResultSelected removeAllObjects];
    if (searchBar.text.length == 0)
    {
        _searchMode = NO;
        [self setupSearchControllerWithFilter:NO];
        [self.tableView setEditing:NO];
        self.tableView.allowsMultipleSelectionDuringEditing = NO;
        [self resetSearchTypes];
    }
    else
    {
        _searchMode = YES;
        [self setupSearchControllerWithFilter:YES];
        [self.tableView setEditing:YES];
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        self.tableView.tableHeaderView = nil;
        OASearchSettings *searchSettings = [[_core getSearchSettings] setSearchTypes:@[[OAObjectType withType:POI_TYPE]]];
        [_core updateSettings:searchSettings];
        [_core search:searchBar.text delayedExecution:YES matcher:[[OAResultMatcher<OASearchResult *> alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *object) {
            OASearchResult *obj = *object;
            if (obj.objectType == SEARCH_FINISHED)
            {
                OASearchResultCollection *currentSearchResult = [_core getCurrentSearchResult];
                NSMutableArray<OAPOIType *> *results = [NSMutableArray new];
                NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *resultsSelected = [NSMapTable new];
                for (OASearchResult *result in currentSearchResult.getCurrentSearchResults)
                {
                    NSObject *poiObject = result.object;
                    if ([poiObject isKindOfClass:[OAPOIType class]])
                    {
                        OAPOIType *poiType = (OAPOIType *) poiObject;
                        NSString *poiTypeName = poiType.name;
                        OAPOICategory *poiTypeCategory = poiType.category;
                        if (!poiType.isAdditional)
                            [results addObject:poiType];
                        if ([[_acceptedTypes objectForKey:poiTypeCategory] containsObject:poiTypeName])
                        {
                            if ([resultsSelected objectForKey:poiTypeCategory])
                                [[resultsSelected objectForKey:poiTypeCategory] addObject:poiTypeName];
                            else
                                [resultsSelected setObject:[NSMutableSet setWithObject:poiTypeName] forKey:poiTypeCategory];
                        }
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    _searchResult = [NSMutableArray arrayWithArray:results];
                    for (OAPOICategory *category in resultsSelected)
                        [_searchResultSelected setObject:[resultsSelected objectForKey:category] forKey:category];
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
                });
            }
            return YES;
        } cancelledFunc:^BOOL {
            return !_searchMode;
        }]];
    }
    [self updateBottomButtons];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - OASelectSubcategoryDelegate

- (void)selectSubcategoryCancel
{
    [self.tableView reloadData];
}

- (void)selectSubcategoryDone:(OAPOICategory *)category keys:(NSMutableSet<NSString *> *)keys allSelected:(BOOL)allSelected;
{
    if (allSelected)
        [_filter selectSubTypesToAccept:category accept:[OAPOIBaseType nullSet]];
    else if (keys.count == 0)
        [_filter setTypeToAccept:category b:NO];
    else
        [_filter selectSubTypesToAccept:category accept:keys];

    [_filterHelper editPoiFilter:_filter];
    [_acceptedTypes setObject:keys forKey:category];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
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

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [_searchController.searchBar resignFirstResponder];
}

@end
