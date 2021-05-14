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
#import "OAPOISearchHelper.h"
#import "OASelectSubcategoryViewController.h"
#import "OAPOIUIFilter.h"
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

#define kCellTypeTitleDescCollapse @"OAMenuSimpleCell"
#define kCellTypeTitle @"OAMenuSimpleCell"
#define kHeaderViewFont [UIFont systemFontOfSize:15.0]

@interface OACustomPOIViewController () <UITableViewDataSource, UITableViewDelegate, OASelectSubcategoryDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *showButton;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (weak, nonatomic) IBOutlet UIButton *cancelSearchButton;
@property (weak, nonatomic) IBOutlet UIView *bottomView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchFieldRightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableBottomConstraint;

@end

@implementation OACustomPOIViewController
{
    OASearchUICore *_core;
    OAPOIFiltersHelper *_filterHelper;
    OAPOIUIFilter *_filter;
    NSArray<OAPOICategory *> *_categories;
    NSMutableArray<OAPOIType *> *_searchResult;
    NSMapTable<OAPOICategory *, NSMutableSet<NSString *> *> *_acceptedTypes;
    BOOL _editMode;
    BOOL _searchMode;
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
                for (OAPOIType *poiType in category.poiTypes)
                    [types addObject:poiType.name];
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
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"search_poi_types_descr") font:kHeaderViewFont textColor:UIColorFromRGB(color_text_footer) lineSpacing:6.0 isTitle:NO];

    _searchMode = NO;
    self.searchField.delegate = self;
    [self.searchField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self updateSearchView:NO];
}

- (void)applyLocalization
{
    [self updateTextTitle];

    self.saveButton.titleLabel.text = OALocalizedString(@"shared_string_save");
    self.cancelSearchButton.titleLabel.text = OALocalizedString(@"shared_string_cancel");
    [self updateTextShowButton];

    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"search_poi_types_descr") font:kHeaderViewFont textColor:UIColorFromRGB(color_text_footer) lineSpacing:6.0 isTitle:NO];
}

- (void)updateTextTitle
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

    if (_searchMode) {
        self.bottomView.hidden = YES;
        self.showButton.hidden = YES;
        self.tableBottomConstraint.constant = 0;
    } else {
        self.bottomView.hidden = NO;
        self.showButton.hidden = NO;
        self.tableBottomConstraint.constant = 110;
    }
}

- (void)updateTextShowButton
{
    _countShowCategories = 0;
    for (OAPOICategory *category in _acceptedTypes.keyEnumerator)
        if ([_filter isTypeAccepted:category])
        {
            NSSet<NSString *> *acceptedSubtypes = [_acceptedTypes objectForKey:category];
            NSInteger count = acceptedSubtypes != [OAPOIBaseType nullSet] ? acceptedSubtypes.count : category.poiTypes.count;
            _countShowCategories += count;
        }

    NSString *textShow = OALocalizedString(@"sett_show");
    UIFont *fontShow = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    UIColor *colorShow = _countShowCategories != 0 ? UIColor.whiteColor : UIColorFromRGB(color_text_footer);
    NSMutableAttributedString *attrShow = [[NSMutableAttributedString alloc] initWithString:textShow attributes:@{NSFontAttributeName: fontShow, NSForegroundColorAttributeName: colorShow}];

    NSString *textCategories = [NSString stringWithFormat:@"\n%@: %li", OALocalizedString(@"categories"), _countShowCategories];
    UIFont *fontCategories = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    UIColor *colorCategories = _countShowCategories != 0 ? [[UIColor alloc] initWithWhite:1 alpha:0.5] : UIColorFromRGB(color_text_footer);
    NSMutableAttributedString *attrCategories = [[NSMutableAttributedString alloc] initWithString:textCategories attributes:@{NSFontAttributeName: fontCategories, NSForegroundColorAttributeName: colorCategories}];

    [attrShow appendAttributedString:attrCategories];

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:2.0];
    [style setAlignment:NSTextAlignmentCenter];
    [attrShow addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, attrShow.string.length)];

    [self.showButton setAttributedTitle:attrShow forState:UIControlStateNormal];
    [self updateShowButton:_countShowCategories != 0];
}

- (void)updateSearchView:(BOOL)searchMode
{
    UIView *searchLeftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 30, 20)];
    UIImageView *searchLeftImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];
    UIImage *searchIcon = [[UIImage imageNamed:@"ic_custom_search"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    searchLeftImageView.image = searchIcon;
    searchLeftImageView.tintColor = searchMode ? UIColorFromRGB(profile_icon_color_outdated_light) : [UIColor colorWithWhite:1 alpha:0.5];
    searchLeftImageView.center = searchLeftView.center;
    [searchLeftView addSubview:searchLeftImageView];
    self.searchField.leftViewMode = UITextFieldViewModeAlways;
    self.searchField.leftView = searchLeftView;
    self.searchField.borderStyle = UITextBorderStyleNone;
    self.searchField.layer.cornerRadius = 10;
    UIFont *searchTextFont = [UIFont systemFontOfSize:17 weight:UIFontWeightRegular];
    UIColor *searchTextColor = [UIColor colorWithWhite:1 alpha:0.5];
    self.searchField.placeholder = searchMode ? @"" : OALocalizedString(@"shared_string_search");
    self.searchField.text = @"";
    self.searchField.font = searchTextFont;
    self.searchField.tintColor = UIColorFromRGB(color_footer_icon_gray);
    self.searchField.backgroundColor = searchMode ? [UIColor colorWithWhite:1 alpha:1] : [UIColor colorWithWhite:1 alpha:0.24];
    self.searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:self.searchField.placeholder attributes:@{NSFontAttributeName:searchTextFont, NSForegroundColorAttributeName: searchTextColor}];
    [self.searchField endEditing:YES];
    self.cancelSearchButton.hidden = !searchMode;
    self.searchFieldRightConstraint.constant = searchMode ? 76 : 16;
}

- (void)selectDeselectItem:(NSIndexPath *)indexPath
{
    if (_searchMode)
    {
        OAPOIType *searchType = _searchResult[indexPath.row];
        OAPOICategory *searchCategory = searchType.category;
        BOOL containsCategory = [_acceptedTypes.keyEnumerator.allObjects containsObject:searchCategory];
        NSMutableSet<NSString *> *types = [_acceptedTypes objectForKey:searchCategory];
        BOOL containsType = [types containsObject:searchType.name];

        if (containsCategory) {
            if (containsType)
                [types removeObject:searchType.name];
            else
                [types addObject:searchType.name];
        } else {
            types = [NSMutableSet setWithObject:searchType.name];
            [_acceptedTypes setObject:types forKey:searchCategory];
        }

        if (types.count == searchCategory.poiTypes.count)
            [_filter selectSubTypesToAccept:searchCategory accept:[OAPOIBaseType nullSet]];
        else if (types.count == 0)
            [_filter setTypeToAccept:searchCategory b:NO];
        else
            [_filter selectSubTypesToAccept:searchCategory accept:types];
        [_filterHelper editPoiFilter:_filter];

        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:indexPath.section], indexPath] withRowAnimation:UITableViewRowAnimationNone];
    }
}

- (IBAction)onBackButtonClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];

    if (_editMode && self.refreshDelegate)
        [self.refreshDelegate refreshList];
}

- (IBAction)onSaveButtonClicked:(id)sender
{
    if (self.delegate) {
        UIAlertController *saveDialog = [self.delegate createSaveFilterDialog:_filter customSaveAction:YES];
        UIAlertAction *actionSave = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_save") style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
            [self.delegate searchByUIFilter:_filter newName:saveDialog.textFields[0].text willSaved:YES];
            [self.navigationController popViewControllerAnimated:YES];
        }];
        [saveDialog addAction:actionSave];
        [self presentViewController:saveDialog animated:YES completion:nil];
    }
}

- (IBAction)onShowButtonClicked:(id)sender
{
    if (self.delegate)
        [self.delegate searchByUIFilter:_filter newName:nil willSaved:NO];

    if (_editMode && self.refreshDelegate)
        [self.refreshDelegate refreshList];

    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)onSearchCancelButtonClicked:(id)sender
{
    _searchMode = NO;
    _searchResult = [NSMutableArray new];
    [self updateTextTitle];
    [self updateSearchView:NO];
    [self updateTextShowButton];
    self.saveButton.hidden = NO;
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"search_poi_types_descr") font:kHeaderViewFont textColor:UIColorFromRGB(color_text_footer) lineSpacing:6.0 isTitle:NO];
    [self.tableView setEditing:NO];
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UITextViewDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    [self updateSearchView:YES];
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView
{
    _searchResult = [NSMutableArray new];
    if (textView.text.length == 0)
    {
        _searchMode = NO;
        self.saveButton.hidden = NO;
        [self.tableView setEditing:NO];
        self.tableView.allowsMultipleSelectionDuringEditing = NO;
        self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"search_poi_types_descr") font:kHeaderViewFont textColor:UIColorFromRGB(color_text_footer) lineSpacing:6.0 isTitle:NO];
        [_core updateSettings:_core.getSearchSettings.resetSearchTypes];
    }
    else {
        _searchMode = YES;
        self.saveButton.hidden = YES;
        [self.tableView setEditing:YES];
        self.tableView.allowsMultipleSelectionDuringEditing = YES;
        self.tableView.tableHeaderView = nil;
        OASearchSettings *searchSettings = [[_core getSearchSettings] setSearchTypes:@[[OAObjectType withType:POI_TYPE]]];
        [_core updateSettings:searchSettings];
        [_core search:textView.text delayedExecution:YES matcher:[[OAResultMatcher<OASearchResult *> alloc] initWithPublishFunc:^BOOL(OASearchResult *__autoreleasing *object) {
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
                            [results addObject:poiType];
                    }
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    _searchResult = [NSMutableArray arrayWithArray:results];
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
                });
            }
            return YES;
        } cancelledFunc:^BOOL {
            return !_searchMode;
        }]];
    }
    [self updateTextTitle];
    [self updateTextShowButton];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
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


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!_searchMode) {
        OAMenuSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellTypeTitleDescCollapse];
        if (cell == nil) {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kCellTypeTitleDescCollapse owner:self options:nil];
            cell = (OAMenuSimpleCell *) nib[0];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }

        if (cell) {
            OAPOICategory *category = _categories[indexPath.row];
            NSSet<NSString *> *subtypes = [_acceptedTypes objectForKey:category];
            NSInteger countAcceptedTypes = subtypes.count;
            NSInteger countAllTypes = category.poiTypes.count;
            BOOL isSelected = [_filter isTypeAccepted:category] && subtypes.count > 0;

            cell.contentView.backgroundColor = [UIColor whiteColor];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 66.0, 0.0, 0.0);

            cell.textView.text = category.nameLocalized;
            cell.textView.textColor = [UIColor blackColor];

            UIImage *img = [[category icon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            cell.imgView.image = img;
            cell.imgView.tintColor = isSelected ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_tint_gray);
            cell.imgView.contentMode = UIViewContentModeCenter;

            NSString *descText;
            if (subtypes == [OAPOIBaseType nullSet] || countAllTypes == countAcceptedTypes)
                descText = [NSString stringWithFormat:@"%@ - %lu", OALocalizedString(@"shared_string_all"), countAllTypes];
            else
                descText = [NSString stringWithFormat:@"%lu/%lu", countAcceptedTypes, countAllTypes];
            cell.descriptionView.hidden = false;
            cell.descriptionView.text = descText;
            cell.descriptionView.textColor = UIColorFromRGB(color_text_footer);

            [cell updateConstraints];
            return cell;
        }
    } else {
        OAMenuSimpleCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellTypeTitle];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kCellTypeTitle owner:self options:nil];
            cell = nib[0];
            cell.separatorInset = UIEdgeInsetsMake(0.0, 65.0, 0.0, 0.0);
            cell.tintColor = UIColorFromRGB(color_primary_purple);
            UIView *bgColorView = [[UIView alloc] init];
            bgColorView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.0];
            [cell setSelectedBackgroundView:bgColorView];
        }
        if (cell)
        {
            OAPOIType *poiType = _searchResult[indexPath.row];
            NSSet<NSString *> *acceptedSubtypes = [_acceptedTypes objectForKey:poiType.category];
            BOOL accepted = [acceptedSubtypes containsObject:poiType.name];

            UIColor *selectedColor = accepted ? UIColorFromRGB(color_chart_orange) : UIColorFromRGB(color_tint_gray);
            UIImage *poiIcon = [UIImage templateImageNamed:poiType.iconName];
            cell.imgView.image = poiIcon ? poiIcon : [UIImage templateImageNamed:@"ic_custom_search_categories"];
            cell.imgView.tintColor = selectedColor;

            if (poiIcon.size.width < cell.imgView.frame.size.width && poiIcon.size.height < cell.imgView.frame.size.height)
                cell.imgView.contentMode = UIViewContentModeCenter;
            else
                cell.imgView.contentMode = UIViewContentModeScaleAspectFit;

            cell.textView.text = poiType.nameLocalized ? poiType.nameLocalized : @"";
            cell.descriptionView.hidden = true;

            [cell updateConstraints];
            return cell;
        }
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_searchMode)
    {
        OAPOIType *poiType = _searchResult[indexPath.row];
        NSSet<NSString *> *acceptedSubtypes = [_acceptedTypes objectForKey:poiType.category];
        BOOL accepted = [acceptedSubtypes containsObject:poiType.name];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return _searchMode ? 48 : 66;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForFooter];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForHeader];
}

@end
