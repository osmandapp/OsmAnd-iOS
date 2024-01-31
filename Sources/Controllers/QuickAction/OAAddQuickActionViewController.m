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
#import "OAButtonTableViewCell.h"
#import "OASizes.h"
#import "OAQuickActionType.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OAAddQuickActionViewController () <UISearchBarDelegate>

@end

@implementation OAAddQuickActionViewController
{
    OrderedDictionary<NSString *, NSArray<OAQuickActionType *> *> *_actions;
    
    NSMutableArray<OAQuickActionType *> *_filteredData;
    UISearchController *_searchController;
    BOOL _isFiltered;
}

#pragma mark - Initialization

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
    _isFiltered = NO;
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.navigationItem.searchController = nil;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"quick_action_new_action");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (NSString *)getTableHeaderDescription
{
    return OALocalizedString(@"quick_action_add_actions_descr");
}

- (void)setupSearchControllerWithFilter:(BOOL)isFiltered
{
    if (isFiltered)
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_search") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.5]}];
        _searchController.searchBar.searchTextField.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
        _searchController.searchBar.searchTextField.leftView.tintColor = [UIColor colorNamed:ACColorNameTextColorTertiary];
    }
    else
    {
        _searchController.searchBar.searchTextField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:OALocalizedString(@"shared_string_search") attributes:@{NSForegroundColorAttributeName:[UIColor colorWithWhite:1.0 alpha:0.5]}];
        _searchController.searchBar.searchTextField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];
        _searchController.searchBar.searchTextField.leftView.tintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
        _searchController.searchBar.searchTextField.tintColor = [UIColor colorNamed:ACColorNameTextColorTertiary];
    }
}

#pragma mark - Table data

- (void)generateData
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
}

- (OAQuickActionType *)getItem:(NSIndexPath *)indexPath
{
    if (_isFiltered)
        return _filteredData[indexPath.row];
    
    NSString *sectionKey = _actions.allKeys[indexPath.section];
    return _actions[sectionKey][indexPath.row];
}

- (NSInteger)sectionsCount
{
    return _isFiltered ? 1 : _actions.allKeys.count;
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return _isFiltered ? OALocalizedString(@"search_results") : _actions.allKeys[section];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    if (_isFiltered)
        return _filteredData.count;
    
    NSString *key = _actions.allKeys[section];
    return _actions[key].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OAQuickActionType *action = [self getItem:indexPath];
    if (action)
    {
        OAButtonTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAButtonTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAButtonTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            [cell.button setTitle:nil forState:UIControlStateNormal];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingToLeftOfContentWithIcon, 0., 0.);
            cell.titleLabel.text = action.name;
            cell.leftIconView.image = [UIImage templateImageNamed:action.iconName];
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorSelected];
            if (cell.leftIconView.subviews.count > 0)
                [[cell.leftIconView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
            
            if (action.hasSecondaryIcon)
            {
                OAQuickAction *act = [action createNew];
                CGRect frame = CGRectMake(0., 0., cell.leftIconView.frame.size.width, cell.leftIconView.frame.size.height);
                UIImage *imgBackground = [UIImage templateImageNamed:@"ic_custom_compound_action_background"];
                UIImageView *background = [[UIImageView alloc] initWithImage:imgBackground];
                [background setTintColor:[UIColor colorNamed:ACColorNameGroupBg]];
                [cell.leftIconView addSubview:background];
                UIImage *img = [UIImage imageNamed:act.getSecondaryIconName];
                UIImageView *view = [[UIImageView alloc] initWithImage:img];
                view.frame = frame;
                [cell.leftIconView addSubview:view];
            }
            cell.button.tag = indexPath.section << 10 | indexPath.row;
            [cell.button setImage:[[UIImage imageNamed:@"ic_custom_plus"] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]
                         forState:UIControlStateNormal];
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
            [cell.button addTarget:self action:@selector(addAction:) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    [self openQuickActionSetupFor:indexPath];
}

#pragma mark - Selectors

- (void)addAction:(id)sender
{
    if ([sender isKindOfClass:UIButton.class])
    {
        UIButton *button = (UIButton *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
        [self openQuickActionSetupFor:indexPath];
    }
}

- (void)openQuickActionSetupFor:(NSIndexPath *)indexPath
{
    OAQuickActionType *item = [self getItem:indexPath];
    OAActionConfigurationViewController *actionScreen = [[OAActionConfigurationViewController alloc] initWithAction:[item createNew] isNew:YES];
    actionScreen.delegate = self.delegate;
    [self.navigationController pushViewController:actionScreen animated:YES];
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

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    _isFiltered = NO;
    [self setupSearchControllerWithFilter:NO];
    [self.tableView reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if (searchText.length > 0)
    {
        [self setupSearchControllerWithFilter:YES];
        _isFiltered = YES;
        _filteredData = [NSMutableArray new];
        for (NSArray *actionGroup in _actions.allValues)
        {
            for (OAQuickActionType *actionType in actionGroup)
            {
                NSRange nameRange = [actionType.name rangeOfString:searchText options:NSCaseInsensitiveSearch];
                if (nameRange.location != NSNotFound)
                    [_filteredData addObject:actionType];
            }
        }
    }
    else
    {
        _isFiltered = NO;
        [self setupSearchControllerWithFilter:NO];
    }
    [self.tableView reloadData];
}

@end
