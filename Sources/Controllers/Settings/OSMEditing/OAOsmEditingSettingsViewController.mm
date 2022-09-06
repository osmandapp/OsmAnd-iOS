//
//  OAOsmEditingSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAOsmEditingSettingsViewController.h"
#import "OAOsmAccountSettingsViewController.h"
#import "OAOsmEditsListViewController.h"
#import "OAOsmLoginMainViewController.h"
#import "OABenefitsOsmContributorsViewController.h"
#import "OAMappersViewController.h"
#import "OASwitchTableViewCell.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAMenuSimpleCellNoIcon.h"
#import "OATitleDescrRightIconTableViewCell.h"
#import "OAIconTitleValueCell.h"
#import "OAAppSettings.h"

@interface OAOsmEditingSettingsViewController () <OAAccountSettingDelegate>

@end

@implementation OAOsmEditingSettingsViewController
{
    NSArray<NSArray *> *_data;
    NSMapTable<NSNumber *, NSString *> *_headers;
    NSMapTable<NSNumber *, NSString *> *_footers;
    BOOL _isLogged;

    OAAppSettings *_settings;
}

- (void) applyLocalization
{
    _titleView.text = OALocalizedString(@"product_title_osm_editing");
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    _settings = [OAAppSettings sharedManager];
    _isLogged = [_settings.osmUserName get].length > 0 && [_settings.osmUserPassword get].length > 0;
    _headers = [NSMapTable new];
    _footers = [NSMapTable new];
    [self generateData];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    [self updateTableHeaderView];

    self.backButton.imageView.image = [self.backButton.imageView.image imageFlippedForRightToLeftLayoutDirection];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self updateTableHeaderView];
    } completion:nil];
}

- (void)updateTableHeaderView
{
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"osm_editing_settings_descr")
                                                                          font:[UIFont systemFontOfSize:15.]
                                                                     textColor:UIColorFromRGB(color_text_footer)
                                                                   lineSpacing:0.0
                                                                       isTitle:NO];
}

- (void)generateData
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray new];

    [data addObject:@[
            @{
                    @"key" : @"edit_credentials",
                    @"type" : [OAIconTitleValueCell getCellIdentifier],
                    @"title": _isLogged ? [_settings.osmUserName get] : OALocalizedString(@"login_open_street_map_org"),
                    @"title_color": _isLogged ? UIColor.blackColor : UIColorFromRGB(color_primary_purple),
                    @"left_icon" : @"ic_custom_user_profile",
                    @"right_icon" : @"menu_cell_pointer",
                    @"font" : [UIFont systemFontOfSize:17. weight:_isLogged ? UIFontWeightRegular : UIFontWeightMedium]
            }
    ]];
    [_headers setObject:OALocalizedString(@"shared_string_account") forKey:@(data.count - 1)];

    [data addObject:@[
            @{
                    @"key" : @"offline_editing",
                    @"type" : [OASwitchTableViewCell getCellIdentifier],
                    @"title" : OALocalizedString(@"osm_editing_offline"),
            }
    ]];
    [_footers setObject:OALocalizedString(@"offline_edition_descr") forKey:@(data.count - 1)];

    [data addObject:@[
            @{
                    @"key" : @"updates_for_mappers",
                    @"type" : [OATitleDescrRightIconTableViewCell getCellIdentifier],
                    @"title" : OALocalizedString(@"map_updates_for_mappers"),
                    @"description" : _isLogged ? OALocalizedString(@"shared_string_learn_more") : OALocalizedString(@"shared_string_unavailable"),
                    @"right_icon" : @"menu_cell_pointer"
            }
    ]];

    NSString *menuPath = [NSString stringWithFormat:@"%@ — %@ — %@", OALocalizedString(@"menu"), OALocalizedString(@"menu_my_places"), OALocalizedString(@"osm_edits_title")];
    NSString *actionsDescr = [NSString stringWithFormat:OALocalizedString(@"osm_editing_access_descr"), menuPath];
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:actionsDescr attributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15], NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer)}];
    [str addAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold]} range:[actionsDescr rangeOfString:menuPath]];

    [data addObject:@[
            @{
                    @"type" : [OAMenuSimpleCellNoIcon getCellIdentifier],
                    @"title" : str
            },
            @{
                    @"key" : @"open_edits",
                    @"type" : [OAIconTitleValueCell getCellIdentifier],
                    @"title": OALocalizedString(@"osm_edits_title"),
                    @"title_color": UIColorFromRGB(color_primary_purple),
                    @"right_icon" : @"ic_custom_folder",
                    @"right_icon_color" : UIColorFromRGB(color_primary_purple),
                    @"font" : [UIFont systemFontOfSize:17. weight:UIFontWeightMedium]
            }
    ]];
    [_headers setObject:OALocalizedString(@"actions") forKey:@(data.count - 1)];

    _data = data;
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (BOOL)isEnabled:(NSString *)key
{
    if ([key isEqualToString:@"offline_editing"])
        return [_settings.offlineEditing get];

    return NO;
}

#pragma mark - Selectors

- (void)onSwitchPressed:(id)sender
{
    UISwitch *switchView = (UISwitch *) sender;
    if (switchView)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:switchView.tag & 0x3FF inSection:switchView.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];

        if ([item[@"key"] isEqualToString:@"offline_editing"])
            [_settings.offlineEditing set:switchView.on];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    UITableViewCell *outCell = nil;

    NSString *type = item[@"type"];
    if ([type isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell* cell = nil;
        cell = [tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            cell.switchView.on = [self isEnabled:item[@"key"]];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        outCell = cell;
    }
    else if ([type isEqualToString:[OAMenuSimpleCellNoIcon getCellIdentifier]])
    {
        OAMenuSimpleCellNoIcon* cell = [tableView dequeueReusableCellWithIdentifier:[OAMenuSimpleCellNoIcon getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAMenuSimpleCellNoIcon getCellIdentifier] owner:self options:nil];
            cell = (OAMenuSimpleCellNoIcon *)[nib objectAtIndex:0];
            cell.descriptionView.hidden = YES;
        }
        if (cell)
        {
            self.tableView.separatorInset = UIEdgeInsetsMake(0., 20. + [OAUtilities getLeftMargin], 0., 0.);

            cell.textView.attributedText = item[@"title"];
        }
        outCell = cell;
    }
    else if ([type isEqualToString:[OATitleDescrRightIconTableViewCell getCellIdentifier]])
    {
        OATitleDescrRightIconTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[OATitleDescrRightIconTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescrRightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleDescrRightIconTableViewCell *) nib[0];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.descriptionLabel.text = item[@"description"];
            cell.iconView.image = [UIImage imageNamed:item[@"right_icon"]];
        }

        outCell = cell;
    }
    else if ([type isEqualToString:[OAIconTitleValueCell getCellIdentifier]])
    {
        OAIconTitleValueCell *cell = [tableView dequeueReusableCellWithIdentifier:[OAIconTitleValueCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAIconTitleValueCell getCellIdentifier] owner:self options:nil];
            cell = (OAIconTitleValueCell *) nib[0];
            cell.descriptionView.text = @"";
        }
        if (cell)
        {
            NSString *leftIcon = item[@"left_icon"];
            NSString *rightIcon = item[@"right_icon"];
            UIColor *rightIconColor = item[@"right_icon_color"];

            [cell showLeftIcon:leftIcon != nil];
            cell.leftIconView.image = [UIImage templateImageNamed:leftIcon];
            cell.leftIconView.tintColor = UIColorFromRGB(color_primary_purple);

            [cell showRightIcon:rightIcon != nil];
            cell.rightIconView.image = rightIconColor ? [UIImage templateImageNamed:rightIcon] : [UIImage imageNamed:rightIcon];
            cell.rightIconView.tintColor = rightIconColor;

            cell.textView.text = item[@"title"];
            cell.textView.textColor = item[@"title_color"];
            cell.textView.font = item[@"font"];
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [_headers objectForKey:@(section)];
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return [_footers objectForKey:@(section)];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    
    if ([item[@"key"] isEqualToString:@"open_edits"])
    {
        UITabBarController *myPlacesViewController = [[UIStoryboard storyboardWithName:@"MyPlaces" bundle:nil] instantiateInitialViewController];
        [myPlacesViewController setSelectedIndex:kOSMEditsTabIndex];
        if (myPlacesViewController.viewControllers.count > kOSMEditsTabIndex)
        {
            OAOsmEditsListViewController *osmEdits = myPlacesViewController.viewControllers[kOSMEditsTabIndex];
            [osmEdits setShouldPopToParent:YES];
            [self.navigationController pushViewController:myPlacesViewController animated:YES];
        }
    }
    else if ([item[@"key"] isEqualToString:@"edit_credentials"])
    {
        if (_isLogged)
        {
            OAOsmAccountSettingsViewController *accountSettings = [[OAOsmAccountSettingsViewController alloc] init];
            accountSettings.accountDelegate = self;
            [self presentViewController:accountSettings animated:YES completion:nil];
        }
        else
        {
            OAOsmLoginMainViewController *loginMainViewController = [[OAOsmLoginMainViewController alloc] init];
            loginMainViewController.delegate = self;
            [self presentViewController:loginMainViewController animated:YES completion:nil];
        }
    }
    else if ([item[@"key"] isEqualToString:@"updates_for_mappers"])
    {
        if (_isLogged)
        {
            OAMappersViewController *benefitsViewController = [[OAMappersViewController alloc] init];
            [self presentViewController:benefitsViewController animated:YES completion:nil];
        }
        else
        {
            OABenefitsOsmContributorsViewController *benefitsViewController = [[OABenefitsOsmContributorsViewController alloc] init];
            benefitsViewController.accountDelegate = self;
            [self presentViewController:benefitsViewController animated:YES completion:nil];
        }
    }
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - OAAccontSettingDelegate

- (void)onAccountInformationUpdated
{
    _isLogged = [_settings.osmUserName get].length > 0 && [_settings.osmUserPassword get].length > 0;
    [self generateData];
    [self.tableView reloadData];
}

@end
