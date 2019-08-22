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
#import "OAIconTitleButtonCell.h"
#import "OASizes.h"
#import "OASearchUICore.h"
#import "OAQuickSearchHelper.h"
#import "OAQuickSearchListItem.h"
#import "OATextLineViewCell.h"
#import "OAPOIUIFilter.h"
#import "OAPOIBaseType.h"

@interface OAActionAddCategoryViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;
@property (weak, nonatomic) IBOutlet UITextField *searchField;

@end

@implementation OAActionAddCategoryViewController
{
    NSArray *_data;
    
    NSMutableArray *_filteredData;
    BOOL _isFiltered;
    
    NSMutableArray<NSString *> *_initialValues;
}

- (instancetype)initWithNames:(NSMutableArray<NSString *> *)names
{
    self = [super init];
    if (self) {
        _initialValues = names;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self commonInit];
    [self setupSearchView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.allowsMultipleSelectionDuringEditing = YES;
    self.tableView.separatorInset = UIEdgeInsetsMake(0.0, 55., 0.0, 0.0);
    [self.tableView setEditing:YES];
    [self.backBtn setImage:[[UIImage imageNamed:@"ic_navbar_chevron"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.backBtn setTintColor:UIColor.whiteColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self applySafeAreaMargins];
    [self setupSearchView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

-(void) commonInit
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

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"add_action");
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

- (IBAction)backPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneButtonPressed:(id)sender
{
    NSArray *selectedItems = [self.tableView indexPathsForSelectedRows];
    NSMutableArray *arr = [NSMutableArray new];
    for (NSIndexPath *path in selectedItems)
        [arr addObject:[self getItem:path]];
    
    if (self.delegate)
        [self.delegate onCategoriesSelected:[NSArray arrayWithArray:arr]];
    [self.navigationController popViewControllerAnimated:YES];
}

-(id)getItem:(NSIndexPath *)indexPath
{
    if (_isFiltered)
        return _filteredData[indexPath.row];
    return _data[indexPath.row];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id category = [self getItem:indexPath];
    OATextLineViewCell* cell;
    cell = (OATextLineViewCell *)[tableView dequeueReusableCellWithIdentifier:@"OATextLineViewCell"];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextLineViewCell" owner:self options:nil];
        cell = (OATextLineViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        cell.contentView.backgroundColor = [UIColor whiteColor];
        [cell.textView setTextColor:[UIColor blackColor]];
        NSString *name = @"";
        if ([category isKindOfClass:OAPOIUIFilter.class])
        {
            OAPOIUIFilter *filter = (OAPOIUIFilter *)category;
            name = filter.getName;
        }
        else if ([category isKindOfClass:OAPOIBaseType.class])
        {
            OAPOIBaseType *filter = (OAPOIBaseType *)category;
            name = filter.nameLocalized;
        }
        [cell.textView setText:name];
        if ([_initialValues containsObject:name])
        {
            [_tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
            [_initialValues removeObject:name];
        }
    }
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_isFiltered)
        return _filteredData.count;
    return _data.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    id object = _data[indexPath.row];
    if ([object isKindOfClass:OAPOIUIFilter.class])
    {
        OAPOIUIFilter *filter = (OAPOIUIFilter *)object;
        return [OATextLineViewCell getHeight:filter.getName cellWidth:tableView.bounds.size.width];
    }
    else if ([object isKindOfClass:OAPOIBaseType.class])
    {
        OAPOIBaseType *filter = (OAPOIBaseType *)object;
        return [OATextLineViewCell getHeight:filter.name cellWidth:tableView.bounds.size.width];
    }
    return 44.0;
}

- (NSString *)getName:(id)item {
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
        for (id item in _data)
        {
            NSString * name = [self getName:item];
            NSRange nameRange = [name rangeOfString:textView.text options:NSCaseInsensitiveSearch];
            if (nameRange.location != NSNotFound)
                [_filteredData addObject:item];
        }
    }
    [_tableView reloadData];
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
