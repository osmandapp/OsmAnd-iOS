//
//  OAUsernameFilterViewController.m
//  OsmAnd
//
//  Created by Paul on 2/23/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAUsernameFilterViewController.h"
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

#define DOWNLOAD_URL @"https://a.mapillary.com/v3/users?usernames=%@&client_id=%s"
#define CLIENT_ID "LXJVNHlDOGdMSVgxZG5mVzlHQ3ZqQTo0NjE5OWRiN2EzNTFkNDg4"

@interface OAUsernameFilterViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UIButton *backButton;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UITextField *searchField;
@property (weak, nonatomic) IBOutlet UIButton *doneButton;

@end

@implementation OAUsernameFilterViewController
{
    
    NSMutableArray *_data;
    NSArray *_filteredData;
    NSMutableArray *_userKeys;
    
    BOOL _isFiltered;
    
    NSString *_userNamesStr;
    NSString *_userKeysStr;
    
}

- (id) initWithData:(NSArray<NSString *> *)data
{
    self = [super init];
    if (self) {
        _userNamesStr = data[0];
        _userKeysStr = data[1];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupView];
}

-(void) applyLocalization
{
    _titleView.text = OALocalizedString(@"mapil_select_user");
    _searchField.placeholder = OALocalizedString(@"shared_string_search");
    [_doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
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
    if (_userNamesStr && _userNamesStr.length > 0)
        _data = [NSMutableArray arrayWithArray:[_userNamesStr componentsSeparatedByString:@"$$$"]];
    else
        _data = [NSMutableArray new];
    
    if (_userKeysStr && _userKeysStr.length > 0)
        _userKeys = [NSMutableArray arrayWithArray:[_userKeysStr componentsSeparatedByString:@"$$$"]];
    else
        _userKeys = [NSMutableArray new];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _isFiltered ? _filteredData.count : _data.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString* const identifierCell = @"OASettingsTitleTableViewCell";
    OASettingsTitleTableViewCell* cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASettingsTitleCell" owner:self options:nil];
        cell = (OASettingsTitleTableViewCell *)[nib objectAtIndex:0];
    }
    
    if (cell)
    {
        NSString *username = _isFiltered ? _filteredData[indexPath.row][@"username"] : _data[indexPath.row];
        [cell.textView setText:username];
        if (!_isFiltered || [_data containsObject:username])
            [cell.iconView setImage:[UIImage imageNamed:@"menu_cell_selected.png"]];
        else
            [cell.iconView setImage:nil];
    }
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_isFiltered)
    {
        NSDictionary *user = _filteredData[indexPath.row];
        NSString *username = user[@"username"];
        NSInteger index = [_data indexOfObject:username];
        if (index == NSNotFound)
        {
            [_data addObject:username];
            [_userKeys addObject:user[@"key"]];
        }
        else
        {
            [_userKeys removeObjectAtIndex:index];
            [_data removeObjectAtIndex:index];
        }
    }
    else
    {
        [_userKeys removeObjectAtIndex:indexPath.row];
        [_data removeObjectAtIndex:indexPath.row];
    }
    [_tableView reloadData];
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextViewDelegate

-(void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length == 0)
    {
        _isFiltered = NO;
    }
    else
    {
        _isFiltered = YES;
        _filteredData = [NSArray new];
        NSString *urlStr = [NSString stringWithFormat:DOWNLOAD_URL, textView.text, CLIENT_ID];
        NSURL *url = [NSURL URLWithString:urlStr];
        NSURLSession *aSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
        [[aSession dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            if (((NSHTTPURLResponse *)response).statusCode == 200) {
                if (data)
                {
                    NSError *error;
                    NSArray *jsonArr = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                    if (!error)
                    {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            _filteredData = [NSArray arrayWithArray:jsonArr];
                            [_tableView reloadData];
                        });
                    }
                }
            }
        }] resume];
        
    }
    [_tableView reloadData];
}

- (IBAction)backButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)doneButtonPressed:(id)sender
{
    NSString *usernames = [self buildFilterString:_data];
    NSString *userKeys = [self buildFilterString:_userKeys];
    if (_delegate)
        [_delegate setData:@[usernames, userKeys]];
    [self.navigationController popViewControllerAnimated:YES];
}

- (NSString *) buildFilterString:(NSArray *)data
{
    NSMutableString *res = [NSMutableString new];
    NSInteger size = data.count;
    for (NSInteger i = 0; i < size; i++)
    {
        [res appendString:data[i]];
        if (i < size - 1)
            [res appendString:@"$$$"];
    }
    return [NSString stringWithString:res];
}

@end
