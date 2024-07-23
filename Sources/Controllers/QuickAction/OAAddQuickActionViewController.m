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
#import "OAMapButtonsHelper.h"
#import "OAQuickAction.h"
#import "OrderedDictionary.h"
#import "OAButtonTableViewCell.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OAAddQuickActionViewController () <UISearchBarDelegate>

@end

@implementation OAAddQuickActionViewController
{
    OATableDataModel *_data;
    NSString *_selectedGroup;
    
    OrderedDictionary<NSString *, NSArray<QuickActionType *> *> *_actions;
    NSMutableArray<QuickActionType *> *_filteredData;
    
    UISearchController *_searchController;
    BOOL _isFiltered;
    NSString *_query;

    OAMapButtonsHelper *_mapButtonsHelper;
    QuickActionButtonState *_buttonState;
}

static NSString *_kActionObjectKey = @"actionObjectKey";

#pragma mark - Initialization

- (instancetype)initWithButtonState:(QuickActionButtonState *)buttonState
{
    self = [super init];
    if (self)
    {
        _buttonState = buttonState;
    }
    return self;
}

- (instancetype)initWithButtonState:(QuickActionButtonState *)buttonState selectedGroup:(NSString *)selectedGroup actions:(OrderedDictionary<NSString *, NSArray<QuickActionType *> *> *)actions
{
    self = [super init];
    if (self)
    {
        _buttonState = buttonState;
        _selectedGroup = selectedGroup;
        _actions = actions;
    }
    return self;
}

- (void)commonInit
{
    _mapButtonsHelper = [OAMapButtonsHelper sharedInstance];
    _buttonState = [_mapButtonsHelper getButtonStateById:@""];
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
    
    if (!_selectedGroup)
    {
        _searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        _searchController.searchBar.delegate = self;
        _searchController.obscuresBackgroundDuringPresentation = NO;
        self.navigationItem.searchController = _searchController;
        [self setupSearchControllerWithFilter:_isFiltered];
        if (_query)
            _searchController.searchBar.searchTextField.text = _query;
    }
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
    if (_selectedGroup)
        return _selectedGroup;
    else
        return _isFiltered ? OALocalizedString(@"search_results") : OALocalizedString(@"quick_action_new_action");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeGray;
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

- (void)buildData
{
    NSArray<QuickActionType *> *all = [_mapButtonsHelper produceTypeActionsListWithHeaders:_buttonState];
    NSMutableArray<QuickActionType *> *actionsInSection = nil;
    MutableOrderedDictionary<NSString *, NSArray<QuickActionType *> *> *mapping = [[MutableOrderedDictionary alloc] init];
    NSString *currSectionName = @"";
    for (QuickActionType *action in all)
    {
        if (action.id == 0)
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

- (void)generateData
{
    if (!_actions || _actions.count == 0)
        [self buildData];
    
    _data = [[OATableDataModel alloc] init];
    OATableSectionData *section = [_data createNewSection];
    
    if (!_selectedGroup)
    {
        // Main screen - groups list
        if (!_isFiltered)
        {
            /*
            OATableRowData *mapInteractionsRow = [section createNewRow];
            mapInteractionsRow.cellType = [OASimpleTableViewCell getCellIdentifier];
            mapInteractionsRow.title = OALocalizedString(@"key_event_category_map_interactions");
            mapInteractionsRow.iconName = @"ic_custom_show_on_map";
            mapInteractionsRow.key = [OAMapButtonsHelper TYPE_MAP_INTERACTIONS].name;
            */
            
            OATableRowData *configureMapRow = [section createNewRow];
            configureMapRow.cellType = [OASimpleTableViewCell getCellIdentifier];
            configureMapRow.title = OALocalizedString(@"configure_map");
            configureMapRow.iconName = @"ic_custom_overlay_map";
            configureMapRow.key = [OAMapButtonsHelper TYPE_CONFIGURE_MAP].name;
            
            OATableRowData *myPlacesRow = [section createNewRow];
            myPlacesRow.cellType = [OASimpleTableViewCell getCellIdentifier];
            myPlacesRow.title = OALocalizedString(@"shared_string_my_places");
            myPlacesRow.iconName = @"ic_custom_favorites";
            myPlacesRow.key = [OAMapButtonsHelper TYPE_MY_PLACES].name;
            
            OATableRowData *navigationRow = [section createNewRow];
            navigationRow.cellType = [OASimpleTableViewCell getCellIdentifier];
            navigationRow.title = OALocalizedString(@"shared_string_navigation");
            navigationRow.iconName = @"ic_custom_navigation";
            navigationRow.key = [OAMapButtonsHelper TYPE_NAVIGATION].name;
            
            OATableRowData *settingsRow = [section createNewRow];
            settingsRow.cellType = [OASimpleTableViewCell getCellIdentifier];
            settingsRow.title = OALocalizedString(@"shared_string_settings");
            settingsRow.iconName = @"ic_custom_settings";
            settingsRow.key = [OAMapButtonsHelper TYPE_SETTINGS].name;
        }
        else
        {
            NSArray<QuickActionType *> *selectedGroupActions = _actions[_selectedGroup];
            for (QuickActionType *action in _filteredData)
            {
                OATableRowData *row = [section createNewRow];
                row.cellType = [OAButtonTableViewCell getCellIdentifier];
                row.title = action.nameAction;
                row.descr = action.name;
                row.iconName = action.iconName;
                row.secondaryIconName = action.secondaryIconName;
                [row setObj:action forKey:_kActionObjectKey];
            }
        }
    }
    else
    {
        NSArray<QuickActionType *> *selectedGroupActions = _actions[_selectedGroup];
        for (QuickActionType *action in selectedGroupActions)
        {
            OATableRowData *row = [section createNewRow];
            row.cellType = [OAButtonTableViewCell getCellIdentifier];
            row.title = action.nameAction;
            row.descr = action.name;
            row.iconName = action.iconName;
            row.secondaryIconName = action.secondaryIconName;
            [row setObj:action forKey:_kActionObjectKey];
        }
    }
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell* cell = nil;
        cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:YES];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            if (item.iconName)
            {
                cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
                cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
                
                BOOL leftIconVisible = YES;
                cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + (leftIconVisible ? kPaddingToLeftOfContentWithIcon : kPaddingOnSideOfContent), 0., 0.);
            }
        }
        return cell;
    }
    if ([item.cellType isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
    {
        OAButtonTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAButtonTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAButtonTableViewCell *) nib[0];
            [cell descriptionVisibility:YES];
            [cell.button setTitle:nil forState:UIControlStateNormal];
        }
        if (cell)
        {
            cell.separatorInset = UIEdgeInsetsMake(0., [OAUtilities getLeftMargin] + kPaddingToLeftOfContentWithIcon, 0., 0.);
            cell.titleLabel.text = item.title;
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
            
            cell.descriptionLabel.text = item.descr;
            cell.descriptionLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            cell.descriptionLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
            
            cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
            if (cell.leftIconView.subviews.count > 0)
                [[cell.leftIconView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

            if (item.secondaryIconName != nil)
            {
                CGRect frame = CGRectMake(0., 0., cell.leftIconView.frame.size.width, cell.leftIconView.frame.size.height);
                UIImage *imgBackground = [UIImage templateImageNamed:@"ic_custom_compound_action_background"];
                UIImageView *background = [[UIImageView alloc] initWithImage:imgBackground];
                [background setTintColor:[UIColor colorNamed:ACColorNameGroupBg]];
                [cell.leftIconView addSubview:background];
                UIImage *img = [UIImage imageNamed:item.secondaryIconName];
                UIImageView *view = [[UIImageView alloc] initWithImage:img];
                view.frame = frame;
                [cell.leftIconView addSubview:view];
            }
        }
        return cell;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OAActionConfigurationViewController *groupContentVC = [[OAAddQuickActionViewController alloc] initWithButtonState:_buttonState selectedGroup:item.key actions:_actions];
        groupContentVC.delegate = self.delegate;
        [self.navigationController pushViewController:groupContentVC animated:YES];
    }
    else if ([item.cellType isEqualToString:[OAButtonTableViewCell getCellIdentifier]])
    {
        QuickActionType *action = [item objForKey:_kActionObjectKey];
        if (action)
        {
            OAActionConfigurationViewController *actionSetupVC = [[OAActionConfigurationViewController alloc] initWithButtonState:_buttonState typeId:action.id];
            actionSetupVC.delegate = self.delegate;
            [self.navigationController pushViewController:actionSetupVC animated:YES];
        }
    }
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
        _query = searchText;
        _filteredData = [NSMutableArray new];
        for (NSArray *actionGroup in _actions.allValues)
        {
            for (QuickActionType *actionType in actionGroup)
            {
                NSRange nameRange = [[actionType getFullName] rangeOfString:searchText options:NSCaseInsensitiveSearch];
                if (nameRange.location != NSNotFound)
                    [_filteredData addObject:actionType];
            }
        }
    }
    else
    {
        _isFiltered = NO;
        _query = nil;
        [self setupSearchControllerWithFilter:NO];
    }
    self.title = [self getTitle];
    [self generateData];
    [self.tableView reloadData];
}

@end
