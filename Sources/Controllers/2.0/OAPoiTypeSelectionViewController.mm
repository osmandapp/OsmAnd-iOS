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
#import "OASettingsTitleTableViewCell.h"
#import "OASizes.h"
#import "OAColors.h"
#import "Localization.h"
#import "MaterialTextFields.h"

@interface OAPoiTypeSelectionViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;

@end

@implementation OAPoiTypeSelectionViewController
{
    EOASelectionType _screenType;
    OAEditPOIData *_poiData;
    OAPOIHelper *_poiHelper;
    
    NSArray *_data;
    
    NSMutableArray *_filteredData;
    BOOL _isFiltered;
    BOOL _searchIsActive;
}

-(id)initWithType:(EOASelectionType)type
{
    self = [super init];
    if (self) {
        _screenType = type;
        _poiHelper = [OAPOIHelper sharedInstance];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
}

- (void) viewWillAppear:(BOOL)animated
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

-(void) applyLocalization
{
    _titleView.text = _screenType == CATEGORY_SCREEN ? OALocalizedString(@"poi_select_category") : OALocalizedString(@"poi_select_type");
    _searchField.placeholder = OALocalizedString(@"shared_string_search");
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

-(CGFloat)getNavBarHeight
{
    return navBarWithSearchFieldHeight;
}

-(void)setupView
{
    _isFiltered = NO;
    [self setupSearchView];
    [self applySafeAreaMargins];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    if (!_poiData && self.dataProvider)
        _poiData = self.dataProvider.getData;
    
    if (_screenType == CATEGORY_SCREEN)
    {
        NSMutableArray *dataArr = [NSMutableArray new];
        for (OAPOICategory *c in _poiHelper.poiCategories) {
            if (!c.nonEditableOsm)
                [dataArr addObject:c];
        }
        _data = [NSArray arrayWithArray:dataArr];
    }
    else
        [self generateTypesList];
    
    _data = [_data sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [((OAPOIBaseType *)obj1).nameLocalized caseInsensitiveCompare:((OAPOIBaseType *)obj2).nameLocalized];
    }];
}

-(void) setupSearchView
{
    _searchField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.44];
    _searchField.layer.cornerRadius = 10.0;
    _searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_searchField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    _searchField.leftView = [[UIView alloc] initWithFrame:CGRectMake(4.0, 0.0, 34.0, _searchField.bounds.size.height)];
    _searchField.leftViewMode = UITextFieldViewModeAlways;
    _searchField.textColor = [UIColor whiteColor];
    _searchField.delegate = self;
    [_searchField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    UIImageView *leftImageView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"search_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    leftImageView.contentMode = UIViewContentModeCenter;
    leftImageView.frame = _searchField.leftView.frame;
    leftImageView.tintColor = [UIColor whiteColor];
    
    [_searchField.leftView addSubview:leftImageView];
}

-(void)generateTypesList
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _isFiltered ? _filteredData.count : _data.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OASettingsTitleTableViewCell* cell = nil;
    cell = [tableView dequeueReusableCellWithIdentifier:[OASettingsTitleTableViewCell getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASettingsTitleTableViewCell getCellIdentifier] owner:self options:nil];
        cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        OAPOIBaseType *item = _isFiltered ? (OAPOIBaseType *)_filteredData[indexPath.row] : (OAPOIBaseType *)_data[indexPath.row];
        [cell.textView setText:item.nameLocalized];
        if ((_screenType == CATEGORY_SCREEN && [item isEqual:_poiData.getPoiCategory]) || [item isEqual:_poiData.getCurrentPoiType])
            [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
        else
            [cell.iconView setImage:nil];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
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

#pragma mark - UITextViewDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    _searchIsActive = YES;
    [self setupView];
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length == 0)
    {
        _isFiltered = NO;
    }
    else
    {
        _isFiltered = YES;
        _filteredData = [NSMutableArray new];
        for (OAPOIBaseType *type in _data)
        {
            NSRange nameRange = [type.nameLocalized rangeOfString:textView.text options:NSCaseInsensitiveSearch];
            NSRange nameTagRange = [type.name rangeOfString:textView.text options:NSCaseInsensitiveSearch];
            if (nameRange.location != NSNotFound || nameTagRange.location != NSNotFound)
                [_filteredData addObject:type];
        }
    }
    [_tableView reloadData];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
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

- (void) keyboardWillHide:(NSNotification *)notification;
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
