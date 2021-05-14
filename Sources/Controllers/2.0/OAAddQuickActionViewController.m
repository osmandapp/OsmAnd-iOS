//
//  OAAddQuickActionViewController.m
//  OsmAnd
//
//  Created by Paul on 8/15/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAAddQuickActionViewController.h"
#import "OAActionConfigurationViewController.h"
#import "Localization.h"
#import "OAQuickActionRegistry.h"
#import "OAQuickAction.h"
#import "OrderedDictionary.h"
#import "OAIconTitleButtonCell.h"
#import "OASizes.h"
#import "OAQuickActionType.h"

#define kHeaderViewFont [UIFont systemFontOfSize:15.0]

@interface OAAddQuickActionViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *navBarView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UIButton *backBtn;
@property (weak, nonatomic) IBOutlet UIButton *searchBtn;

@end

@implementation OAAddQuickActionViewController
{
    OrderedDictionary<NSString *, NSArray<OAQuickActionType *> *> *_actions;
    
    NSMutableArray<OAQuickActionType *> *_filteredData;
    BOOL _isFiltered;
    BOOL _searchIsActive;
    
    UITextField *_searchField;
    UIView *_searchFieldContainer;
    
    UIView *_tableHeaderView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self commonInit];
    [self setupSearchView];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.tableHeaderView = _tableHeaderView;
    [self.backBtn setImage:[UIImage templateImageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
    [self.backBtn setTintColor:UIColor.whiteColor];
    [self.searchBtn setImage:[UIImage templateImageNamed:@"ic_navbar_search"] forState:UIControlStateNormal];
    [self.searchBtn setTintColor:UIColor.whiteColor];
    
    _searchFieldContainer = [[UIView alloc] initWithFrame:CGRectMake(0., defaultNavBarHeight + OAUtilities.getStatusBarHeight, DeviceScreenWidth, 0.1)];
    _searchFieldContainer.backgroundColor = _navBarView.backgroundColor;
    [_searchFieldContainer addSubview:_searchField];
    _searchField.hidden = YES;
    _searchFieldContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self applySafeAreaMargins];
    
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
    NSArray<OAQuickActionType *> *all = [[OAQuickActionRegistry sharedInstance] produceTypeActionsListWithHeaders];
    NSMutableArray<OAQuickActionType *> *actionsInSection = nil;
    MutableOrderedDictionary<NSString *, NSArray<OAQuickActionType *> *> *mapping = [[MutableOrderedDictionary alloc] init];
    NSString *currSectionName = @"";
    for (OAQuickActionType *action in all)
    {
        if (action.identifier == 0)
        {
            if (actionsInSection && actionsInSection.count > 0)
                [mapping setObject:[NSArray arrayWithArray:actionsInSection] forKey:currSectionName];
            
            currSectionName = action.name;
            actionsInSection = [NSMutableArray new];
        }
        else if (actionsInSection)
        {
            [actionsInSection addObject:action];
        }
    }
    if (currSectionName && actionsInSection && actionsInSection.count > 0)
        [mapping setObject:[NSArray arrayWithArray:actionsInSection] forKey:currSectionName];

    _actions = [OrderedDictionary dictionaryWithDictionary:mapping];
    
    _tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"quick_action_add_actions_descr") font:kHeaderViewFont textColor:UIColor.blackColor lineSpacing:0.0 isTitle:NO];
}

-(void) setupSearchView
{
    _searchField = [[UITextField alloc] initWithFrame:CGRectMake(16. + OAUtilities.getLeftMargin, 10., DeviceScreenWidth - 32.0 - OAUtilities.getLeftMargin * 2, 30.0)];
    _searchField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _searchField.placeholder = OALocalizedString(@"shared_string_search");
    _searchField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.44];
    _searchField.layer.cornerRadius = 10.0;
    _searchField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_searchField.placeholder attributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
    _searchField.leftView = [[UIView alloc] initWithFrame:CGRectMake(4.0, 0.0, 34.0, _searchField.bounds.size.height)];
    _searchField.leftViewMode = UITextFieldViewModeAlways;
    _searchField.textColor = [UIColor whiteColor];
    _searchField.delegate = self;
    [_searchField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    UIImageView *leftImageView = [[UIImageView alloc] initWithImage:[UIImage templateImageNamed:@"search_icon"]];
    leftImageView.contentMode = UIViewContentModeCenter;
    leftImageView.frame = _searchField.leftView.frame;
    leftImageView.tintColor = [UIColor whiteColor];
    
    [_searchField.leftView addSubview:leftImageView];
}

- (void)applyLocalization
{
    _titleView.text = OALocalizedString(@"add_action");
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        CGRect searchBarFrame = _searchFieldContainer.frame;
        searchBarFrame.origin.y = CGRectGetMaxY(_navBarView.frame);
        _searchFieldContainer.frame = searchBarFrame;
        
        CGFloat textWidth = DeviceScreenWidth - 32.0 - OAUtilities.getLeftMargin * 2;
        UIFont *labelFont = [UIFont systemFontOfSize:15.0];
        CGSize labelSize = [OAUtilities calculateTextBounds:OALocalizedString(@"quick_action_add_actions_descr") width:textWidth font:labelFont];
        _tableHeaderView.frame = CGRectMake(0.0, 0.0, DeviceScreenWidth, labelSize.height + 30.0);
        _tableHeaderView.subviews.firstObject.frame = CGRectMake(16.0 + OAUtilities.getLeftMargin, 20.0, textWidth, labelSize.height);
    } completion:nil];
}

- (IBAction)backPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)searchPressed:(id)sender
{
    _isFiltered = NO;
    [_filteredData removeAllObjects];
    _searchIsActive = !_searchIsActive;
    if (_searchFieldContainer.superview)
    {
        _tableView.contentInset = UIEdgeInsetsMake(0., _tableView.contentInset.left, _tableView.contentInset.bottom, _tableView.contentInset.right);
        [UIView animateWithDuration:.3 animations:^{
            _searchField.hidden = YES;
            _searchFieldContainer.frame = CGRectMake(0., CGRectGetMaxY(_navBarView.frame), DeviceScreenWidth, 0.01);
        } completion:^(BOOL finished) {
            [_searchFieldContainer removeFromSuperview];
        }];
    }
    else
    {
        [UIView animateWithDuration:.3 animations:^{
            [self.view addSubview:_searchFieldContainer];
            _searchFieldContainer.frame = CGRectMake(0., CGRectGetMaxY(_navBarView.frame), DeviceScreenWidth, 50.0);
        } completion:^(BOOL finished) {
            _searchField.hidden = NO;
            
        }];
        _tableView.contentInset = UIEdgeInsetsMake(_searchFieldContainer.frame.size.height, _tableView.contentInset.left, _tableView.contentInset.bottom, _tableView.contentInset.right);
    }
    [_tableView reloadData];
    
    if (_searchIsActive)
        [_searchField becomeFirstResponder];
}

-(OAQuickActionType *)getItem:(NSIndexPath *)indexPath
{
    if (_isFiltered)
        return _filteredData[indexPath.row];
    
    NSString *sectionKey = _actions.allKeys[indexPath.section];
    return _actions[sectionKey][indexPath.row];
}

- (void) addAction:(id)sender
{
    if ([sender isKindOfClass:UIButton.class])
    {
        UIButton *button = (UIButton *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
        [self openQuickActionSetupFor:indexPath];
    }
}

- (void) openQuickActionSetupFor:(NSIndexPath *)indexPath
{
    OAQuickActionType *item = [self getItem:indexPath];
    OAActionConfigurationViewController *actionScreen = [[OAActionConfigurationViewController alloc] initWithAction:[item createNew] isNew:YES];
    [self.navigationController pushViewController:actionScreen animated:YES];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self openQuickActionSetupFor:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAQuickActionType *action = [self getItem:indexPath];
    if (action)
    {
        static NSString* const identifierCell = @"OAIconTitleButtonCell";
        OAIconTitleButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAIconTitleButtonCell" owner:self options:nil];
            cell = (OAIconTitleButtonCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., 62., 0., 0.);
            cell.titleView.text = action.name;
            cell.iconView.image = [UIImage imageNamed:action.iconName];
            if (cell.iconView.subviews.count > 0)
                [[cell.iconView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            
            if (action.hasSecondaryIcon)
            {
                OAQuickAction *act = [action createNew];
                CGRect frame = CGRectMake(0., 0., cell.iconView.frame.size.width, cell.iconView.frame.size.height);
                UIImage *imgBackground = [UIImage templateImageNamed:@"ic_custom_compound_action_background"];
                UIImageView *background = [[UIImageView alloc] initWithImage:imgBackground];
                [background setTintColor:UIColor.whiteColor];
                [cell.iconView addSubview:background];
                UIImage *img = [UIImage imageNamed:act.getSecondaryIconName];
                UIImageView *view = [[UIImageView alloc] initWithImage:img];
                view.frame = frame;
                [cell.iconView addSubview:view];
            }
            [cell setButtonText:nil];
            cell.buttonView.tag = indexPath.section << 10 | indexPath.row;
            [cell.buttonView setImage:[UIImage templateImageNamed:@"ic_custom_plus"] forState:UIControlStateNormal];
            [cell.buttonView addTarget:self action:@selector(addAction:) forControlEvents:UIControlEventTouchUpInside];
            cell.buttonView.imageEdgeInsets = UIEdgeInsetsMake(0., cell.buttonView.frame.size.width - 30, 0, 0);
        }
        return cell;
    }
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _isFiltered ? 1 : _actions.allKeys.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_isFiltered)
        return _filteredData.count;
    
    NSString *key = _actions.allKeys[section];
    return _actions[key].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _isFiltered ? OALocalizedString(@"search_results") : _actions.allKeys[section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 38.5;
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
        for (NSArray *actionGroup in _actions.allValues)
        {
            for (OAQuickActionType *actionType in actionGroup)
            {
                NSRange nameRange = [actionType.name rangeOfString:textView.text options:NSCaseInsensitiveSearch];
                if (nameRange.location != NSNotFound)
                    [_filteredData addObject:actionType];
            }
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
