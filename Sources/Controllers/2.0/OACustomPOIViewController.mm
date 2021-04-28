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
#import "OATitleDescrDraggableCell.h"

#define kCellTypeTitleDescCollapse @"OATitleDescrDraggableCell"
#define kHeaderViewFont [UIFont systemFontOfSize:15.0]

@interface OACustomPOIViewController () <UITableViewDataSource, UITableViewDelegate, OASelectSubcategoryDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBar;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UIButton *saveButton;
@property (weak, nonatomic) IBOutlet UIButton *showButton;

@end

@implementation OACustomPOIViewController
{
    OAPOIFiltersHelper *_filterHelper;
    OAPOIUIFilter *_filter;
    NSArray<OAPOICategory *> *_categories;
    BOOL _editMode;
    NSInteger _countShowCategories;
}

- (instancetype)initWithFilter:(OAPOIUIFilter *)filter
{
    self = [super init];
    if (self)
    {
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
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 66.0;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    _tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"search_poi_types_descr") font:kHeaderViewFont textColor:UIColorFromRGB(color_text_footer) lineSpacing:6.0 isTitle:NO];
}

- (void)applyLocalization
{
    if (_editMode)
        self.titleLabel.text = _filter.name;
    else
        self.titleLabel.text = OALocalizedString(@"create_custom_poi");

    self.saveButton.titleLabel.text = OALocalizedString(@"shared_string_save");
    [self updateTextShowButton];
}

- (void)updateTextShowButton
{
    _countShowCategories = 0;
    for (OAPOICategory* item in _categories)
        if ([_filter isTypeAccepted:item])
            _countShowCategories += 1;

    NSString *textShow = OALocalizedString(@"sett_show");
    UIFont *fontShow = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    UIColor *colorShow = [[UIColor alloc] initWithWhite:1 alpha:1];
    NSMutableAttributedString *attrShow = [[NSMutableAttributedString alloc] initWithString:textShow attributes:@{NSFontAttributeName:fontShow, NSForegroundColorAttributeName:colorShow}];

    NSString *textCategories = [NSString stringWithFormat:@"\n%@: %li", OALocalizedString(@"categories"), _countShowCategories];
    UIFont *fontCategories = [UIFont systemFontOfSize:13 weight:UIFontWeightRegular];
    UIColor *colorCategories = [[UIColor alloc] initWithWhite:1 alpha:0.5];
    NSMutableAttributedString *attrCategories = [[NSMutableAttributedString alloc] initWithString:textCategories attributes:@{NSFontAttributeName:fontCategories, NSForegroundColorAttributeName:colorCategories}];

    [attrShow appendAttributedString:attrCategories];

    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:2.0];
    [style setAlignment:NSTextAlignmentCenter];
    [attrShow addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange(0, attrShow.string.length)];

    [_showButton setAttributedTitle:attrShow forState:UIControlStateNormal];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self applySafeAreaMargins];
}

- (CGFloat)getToolBarHeight
{
    return customSearchToolBarHeight;
}

- (IBAction)onBackButtonClicked:(id)sender
{
    [self dismissViewController];
}

- (IBAction)onSaveButtonClicked:(id)sender
{
    if (self.delegate)
        [self.delegate saveFilter:_filter alertDelegate:self];
}

- (IBAction)onShowButtonClicked:(id)sender
{
    if (self.delegate)
        [self.delegate searchByUIFilter:_filter wasSaved:NO];

    [self dismissViewController];
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
    [self.tableView reloadData];
    [self updateTextShowButton];
}


#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OATitleDescrDraggableCell* cell = [tableView dequeueReusableCellWithIdentifier:kCellTypeTitleDescCollapse];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:kCellTypeTitleDescCollapse owner:self options:nil];
        cell = (OATitleDescrDraggableCell *) nib[0];
    }
    
    if (cell)
    {
        OAPOICategory* item = _categories[indexPath.row];
        BOOL isSelected = [_filter isTypeAccepted:item];
        NSInteger countAllTypes = item.poiTypes.count;
        NSInteger countAcceptedTypes = [[_filter getAcceptedTypes] objectForKey:item].count;
        NSSet<NSString *> *subtypes = [_filter getAcceptedSubtypes:item];

        cell.contentView.backgroundColor = [UIColor whiteColor];
        cell.separatorInset = UIEdgeInsetsMake(0.0, 66.0, 0.0, 0.0);

        cell.textView.text = item.nameLocalized;
        cell.textView.textColor = [UIColor blackColor];

        cell.overflowButton.enabled = NO;
        cell.overflowButton.imageView.contentMode = UIViewContentModeCenter;
        [cell.overflowButton setImage:[[UIImage imageNamed:@"ic_custom_arrow_right"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        cell.overflowButton.tintColor = UIColorFromRGB(color_tint_gray);

        UIImage *img = [[item icon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.iconView.image = img;
        cell.iconView.tintColor = isSelected ? UIColorFromRGB(color_primary_purple) : UIColorFromRGB(color_tint_gray);

        NSString *descText;
        if (subtypes == [OAPOIBaseType nullSet] || countAllTypes == countAcceptedTypes)
            descText = [NSString stringWithFormat:@"%@ - %lu", OALocalizedString(@"shared_string_all"), countAllTypes];
        else
            descText = [NSString stringWithFormat:@"%lu/%lu", countAcceptedTypes, countAllTypes];
        cell.descView.text = descText;
        cell.descView.textColor = UIColorFromRGB(color_text_footer);

        [cell updateConstraintsIfNeeded];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    OAPOICategory* item = _categories[indexPath.row];
    OASelectSubcategoryViewController *subcategoryScreen = [[OASelectSubcategoryViewController alloc] initWithCategory:item filter:_filter];
    subcategoryScreen.delegate = self;
    subcategoryScreen.modalPresentationStyle = UIModalPresentationFullScreen;
    [self showViewController:subcategoryScreen];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _categories.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;
{
    return 66.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForFooter];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [OAPOISearchHelper getHeightForHeader];
}

#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        if (self.delegate)
        {
            [self.delegate searchByUIFilter:_filter wasSaved:YES];
            [self.delegate updateRootScreen:alertView];
        }

        [self dismissViewController];
    }
}

@end
