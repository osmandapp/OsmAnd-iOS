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
#import "OASizes.h"
#import "OAColors.h"
#import "OAMenuSimpleCell.h"
#import "OASearchUICore.h"
#import "OAQuickSearchHelper.h"
#import "OASearchSettings.h"
#import "OAPOIType.h"
#import "OAPOIFilterViewController.h"
#import "OATableViewCustomHeaderView.h"

@interface OACustomPOIViewController () <UITableViewDataSource, UITableViewDelegate, OASelectSubcategoryDelegate, UISearchBarDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *showButton;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *showBottomViewHeightPrimaryConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *showBottomViewHeightSecondaryConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *showButtonHeightPrimaryConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *showButtonHeightSecondaryConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *addBottomViewHeightPrimaryConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *addBottomViewHeightSecondaryConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *addButtonHeightSecondaryConstraint;

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
    BOOL _keyboardVisible;
    NSInteger _countShowCategories;
}

- (instancetype)initWithFilter:(OAPOIUIFilter *)filter
{
    self = [super init];
    if (self)
    {
        _core = [[OAQuickSearchHelper instance] getCore];
        _filterHelper = [OAPOIFiltersHelper sharedInstance];
        _filter = filter;
        _editMode = _filter != [_filterHelper getCustomPOIFilter];
        _searchResultSelected = [NSMapTable weakToStrongObjectsMapTable];
        [self initData];
    }
    return self;
}

- (void)initData
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

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:OATableViewCustomHeaderView.class forHeaderFooterViewReuseIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];

    _searchMode = NO;
    self.searchBar.delegate = self;

    [self updateTextShowButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)applyLocalization
{
    [self updateScreenTitle];

    self.saveButton.titleLabel.text = OALocalizedString(@"shared_string_save");
    self.searchBar.placeholder = _searchMode ? @"" : OALocalizedString(@"shared_string_search");
}

- (void)updateScreenTitle
{
    if (_searchMode)
        self.titleLabel.text = OALocalizedString(@"shared_string_search");
    else if (_editMode)
        self.titleLabel.text = _filter.name;
    else
        self.titleLabel.text = OALocalizedString(@"create_custom_poi");
}

- (void)updateShowButton:(BOOL)hasSelection
{
    self.showButton.backgroundColor = hasSelection ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_route_button_inactive);
    [self.showButton setTintColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer)];
    [self.showButton setTitleColor:hasSelection ? UIColor.whiteColor : UIColorFromRGB(color_text_footer) forState:UIControlStateNormal];
    [self.showButton setUserInteractionEnabled:hasSelection];
}

- (void)updateTextShowButton
{
    if (!_searchMode)
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

        NSString *textShow = OALocalizedString(@"sett_show");
        UIFont *fontShow = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        UIColor *colorShow = _countShowCategories != 0 ? UIColor.whiteColor : UIColorFromRGB(color_text_footer);
        NSMutableAttributedString *attrShow = [[NSMutableAttributedString alloc] initWithString:textShow attributes:@{NSFontAttributeName: fontShow, NSForegroundColorAttributeName: colorShow}];

        NSString *textCategories = [NSString stringWithFormat:@"\n%@: %li", OALocalizedString(@"categories"), _countShowCategories];
        UIFont *fontCategories = [UIFont systemFontOfSize:13];
        UIColor *colorCategories = _countShowCategories != 0 ? [[UIColor alloc] initWithWhite:1 alpha:0.5] : UIColorFromRGB(color_text_footer);
        NSMutableAttributedString *attrCategories = [[NSMutableAttributedString alloc] initWithString:textCategories attributes:@{NSFontAttributeName: fontCategories, NSForegroundColorAttributeName: colorCategories}];

        [attrShow appendAttributedString:attrCategories];

        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:2.0];
        [style setAlignment:NSTextAlignmentCenter];
        [attrShow addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, attrShow.string.length)];

        [self.showButton setAttributedTitle:attrShow forState:UIControlStateNormal];
        [self updateShowButton:_countShowCategories != 0];

        self.showBottomViewHeightPrimaryConstraint.active = !_keyboardVisible;
        self.showBottomViewHeightSecondaryConstraint.active = _keyboardVisible;
        self.showButtonHeightPrimaryConstraint.active = !_keyboardVisible;
        self.showButtonHeightSecondaryConstraint.active = _keyboardVisible;
    }
    else
    {
        NSString *textShow = OALocalizedString(@"shared_string_add");
        UIFont *fontShow = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
        UIColor *colorShow = UIColor.whiteColor;
        NSMutableAttributedString *attrAdd = [[NSMutableAttributedString alloc] initWithString:textShow attributes:@{NSFontAttributeName: fontShow, NSForegroundColorAttributeName: colorShow}];

        [self.showButton setAttributedTitle:attrAdd forState:UIControlStateNormal];
        [self updateShowButton:YES];

        self.addBottomViewHeightPrimaryConstraint.active = !_keyboardVisible;
        self.addBottomViewHeightSecondaryConstraint.active = _keyboardVisible;
        self.showButtonHeightSecondaryConstraint.active = !_keyboardVisible;
        self.addButtonHeightSecondaryConstraint.active = _keyboardVisible;
        self.showBottomViewHeightSecondaryConstraint.active = NO;
    }
}

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

- (IBAction)onBackButtonClicked:(id)sender
{
    [self resetSearchTypes];
    [OAQuickSearchHelper.instance refreshCustomPoiFilters];
    [self dismissViewController];

    if (_editMode && self.refreshDelegate)
        [self.refreshDelegate refreshList];
}

- (IBAction)onSaveButtonClicked:(id)sender
{
    if (self.delegate)
    {
        UIAlertController *saveDialog = [self.delegate createSaveFilterDialog:_filter customSaveAction:YES];
        UIAlertAction *actionSave = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_save") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [self.delegate searchByUIFilter:_filter newName:saveDialog.textFields[0].text willSaved:YES];
            [self resetSearchTypes];
            [self dismissViewController];
        }];
        [saveDialog addAction:actionSave];
        [self presentViewController:saveDialog animated:YES completion:nil];
    }
}

- (IBAction)onShowButtonClicked:(id)sender
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
        [self dismissViewController];
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
        [self searchBarCancelButtonClicked:self.searchBar];
        [self resetSearchTypes];
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searchBar.text = @"";
    _searchMode = NO;
    [_searchResult removeAllObjects];
    [_searchResultSelected removeAllObjects];
    self.searchBar.placeholder = OALocalizedString(@"shared_string_search");
    [self updateScreenTitle];
    [self updateTextShowButton];
    self.saveButton.hidden = NO;
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
        self.saveButton.hidden = NO;
        [self.tableView setEditing:NO];
        self.tableView.allowsMultipleSelectionDuringEditing = NO;
        [self resetSearchTypes];
    }
    else
    {
        _searchMode = YES;
        self.saveButton.hidden = YES;
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
                    [self updateTextShowButton];
                });
            }
            return YES;
        } cancelledFunc:^BOOL {
            return !_searchMode;
        }]];
    }
    self.searchBar.placeholder = _searchMode ? @"" : OALocalizedString(@"shared_string_search");
    [self updateScreenTitle];
    [self updateTextShowButton];
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
    [self updateTextShowButton];
}

- (UIImage *)getPoiIcon:(OAPOIType *)poiType
{
    UIImage *img = [UIImage imageNamed:[OAUtilities drawablePath:[NSString stringWithFormat:@"mx_%@", poiType.name]]];
    if (!img)
        img = [UIImage imageNamed:[OAUtilities drawablePath:[NSString stringWithFormat:@"mx_%@_%@", [poiType getOsmTag], [poiType getOsmValue]]]];
    if (img)
        return [[OAUtilities applyScaleFactorToImage:img] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    else
        return [UIImage templateImageNamed:@"ic_custom_search_categories"];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAMenuSimpleCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCell getCellIdentifier] owner:self options:nil];
        cell = (OAMenuSimpleCell *) nib[0];
        if (_searchMode)
        {
            cell.tintColor = UIColorFromRGB(color_primary_purple);
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
            [cell setSelectedBackgroundView:bgColorView];
        }
    }
    if (cell)
    {
        if (!_searchMode)
        {
            [cell changeHeight:YES];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 70.0, 0.0, 0.0);

            OAPOICategory *category = _categories[indexPath.row];
            NSSet<NSString *> *subtypes = [_acceptedTypes objectForKey:category];
            NSInteger countAcceptedTypes = subtypes.count;
            NSInteger countAllTypes = category.poiTypes.count;
            BOOL isSelected = [_filter isTypeAccepted:category] && subtypes.count > 0;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            cell.textView.text = category.nameLocalized;

            UIImage *categoryIcon = [[category icon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imgView.image = categoryIcon;
            cell.imgView.tintColor = isSelected ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_tint_gray);
            cell.imgView.contentMode = UIViewContentModeCenter;

            NSString *descText;
            if (subtypes == [OAPOIBaseType nullSet] || countAllTypes == countAcceptedTypes)
                descText = [NSString stringWithFormat:@"%@ - %lu", OALocalizedString(@"shared_string_all"), countAllTypes];
            else
                descText = [NSString stringWithFormat:@"%lu/%lu", countAcceptedTypes, countAllTypes];
            cell.descriptionView.hidden = NO;
            cell.descriptionView.text = descText;
            cell.descriptionView.textColor = UIColorFromRGB(color_text_footer);
        }
        else
        {
            [cell changeHeight:NO];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 62.0, 0.0, 0.0);

            OAPOIType *poiType = _searchResult[indexPath.row];
            BOOL accepted = [[_searchResultSelected objectForKey:poiType.category] containsObject:poiType.name];
            cell.accessoryType = UITableViewCellAccessoryNone;

            cell.textView.text = poiType.nameLocalized ? poiType.nameLocalized : @"";

            UIColor *selectedColor = accepted ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
            cell.imgView.image = [self getPoiIcon:poiType];
            cell.imgView.tintColor = selectedColor;
            if (cell.imgView.image.size.width < cell.imgView.frame.size.width && cell.imgView.image.size.height < cell.imgView.frame.size.height)
                cell.imgView.contentMode = UIViewContentModeCenter;
            else
                cell.imgView.contentMode = UIViewContentModeScaleAspectFit;

            cell.descriptionView.hidden = YES;
        }

        [cell updateConstraints];
        return cell;
    }
    return nil;
}

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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_searchMode)
    {
        [self selectDeselectItem:indexPath];
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        OAPOICategory* item = _categories[indexPath.row];
        OASelectSubcategoryViewController *subcategoryScreen = [[OASelectSubcategoryViewController alloc] initWithCategory:item filter:_filter];
        subcategoryScreen.delegate = self;
        [self.navigationController pushViewController:subcategoryScreen animated:YES];
        [self.searchBar resignFirstResponder];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_searchMode)
        [self selectDeselectItem:indexPath];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _searchMode ? _searchResult.count : _categories.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _searchMode;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0 && !_searchMode)
    {
        OATableViewCustomHeaderView *customHeader = [tableView dequeueReusableHeaderFooterViewWithIdentifier:[OATableViewCustomHeaderView getCellIdentifier]];
        customHeader.label.text = OALocalizedString(@"search_poi_types_descr");
        customHeader.label.font = [UIFont systemFontOfSize:15];
        [customHeader setYOffset:10];
        return customHeader;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return section == 0 && !_searchMode ? [OATableViewCustomHeaderView getHeight:OALocalizedString(@"search_poi_types_descr") width:tableView.bounds.size.width] + 2 : 0.01;
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification;
{
    _keyboardVisible = YES;
    NSDictionary* userInfo = [notification userInfo];
    CGRect keyboardRect = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    CGFloat keyboardHeight = keyboardRect.size.height;
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    CGRect viewFrame = self.view.frame;
    viewFrame.size.height = DeviceScreenHeight - keyboardHeight;

    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.view.frame = viewFrame;

        if (!_searchMode)
        {
            self.showBottomViewHeightPrimaryConstraint.active = NO;
            self.showBottomViewHeightSecondaryConstraint.active = YES;
            self.showButtonHeightPrimaryConstraint.active = NO;
            self.showButtonHeightSecondaryConstraint.active = YES;
        }
        else
        {
            self.addBottomViewHeightPrimaryConstraint.active = NO;
            self.addBottomViewHeightSecondaryConstraint.active = YES;
            self.showButtonHeightSecondaryConstraint.active = NO;
            self.addButtonHeightSecondaryConstraint.active = YES;
        }
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification;
{
    _keyboardVisible = NO;
    NSDictionary* userInfo = [notification userInfo];
    CGRect keyboardRect = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    keyboardRect = [self.view convertRect:keyboardRect fromView:nil];
    CGFloat keyboardHeight = keyboardRect.size.height;
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];

    CGRect viewFrame = self.view.frame;
    viewFrame.size.height = DeviceScreenHeight;

    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.view.frame = viewFrame;

        if (!_searchMode)
        {
            self.showBottomViewHeightPrimaryConstraint.active = YES;
            self.showBottomViewHeightSecondaryConstraint.active = NO;
            self.showButtonHeightPrimaryConstraint.active = YES;
            self.showButtonHeightSecondaryConstraint.active = NO;
        }
        else
        {
            self.addBottomViewHeightPrimaryConstraint.active = YES;
            self.addBottomViewHeightSecondaryConstraint.active = NO;
            self.showButtonHeightSecondaryConstraint.active = YES;
            self.addButtonHeightSecondaryConstraint.active = NO;
        }
    } completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

@end
