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
#import "OACustomBasicTableCell.h"
#import "OASizes.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAAppSettings.h"
#import "OAIAPHelper.h"

@interface OAOsmEditingSettingsViewController () <OAAccountSettingDelegate>

@end

@implementation OAOsmEditingSettingsViewController
{
    NSMutableArray<NSMutableArray<NSMutableDictionary *> *> *_data;
    NSMutableDictionary<NSNumber *, NSString *> *_headers;
    NSMutableDictionary<NSNumber *, NSString *> *_footers;
    BOOL _isLogged;
    NSIndexPath *_credentialIndexPath;
    NSIndexPath *_mappersIndexPath;

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
    _headers = [NSMutableDictionary dictionary];
    _footers = [NSMutableDictionary dictionary];
    [self generateData];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.estimatedRowHeight = kEstimatedRowHeight;
    self.tableView.sectionFooterHeight = 0.001;
    self.tableView.sectionHeaderHeight = kHeaderHeightDefault;
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
    NSMutableArray<NSMutableArray<NSMutableDictionary *> *> *data = [NSMutableArray new];

    NSMutableArray<NSMutableDictionary *> *credentialCells = [NSMutableArray array];
    [data addObject:credentialCells];
    _headers[@(data.count - 1)] = OALocalizedString(@"shared_string_account");

    NSMutableDictionary *credentialData = [NSMutableDictionary dictionary];
    credentialData[@"key"] = @"edit_credentials";
    credentialData[@"type"] = [OACustomBasicTableCell getCellIdentifier];
    credentialData[@"title"] = _isLogged ? [_settings.osmUserName get] : OALocalizedString(@"login_open_street_map_org");
    credentialData[@"title_color"] = _isLogged ? UIColor.blackColor : UIColorFromRGB(color_primary_purple);
    credentialData[@"title_font"] = [UIFont systemFontOfSize:17. weight:_isLogged ? UIFontWeightRegular : UIFontWeightMedium];
    credentialData[@"left_icon"] = @"ic_custom_user_profile";
    credentialData[@"right_icon"] = @"ic_custom_arrow_right";
    credentialData[@"right_icon_color"] = UIColorFromRGB(color_tint_gray);
    [credentialCells addObject:credentialData];
    _credentialIndexPath = [NSIndexPath indexPathForRow:credentialCells.count - 1 inSection:data.count - 1];

    NSMutableArray<NSMutableDictionary *> *offlieneEditingCells = [NSMutableArray array];
    [data addObject:offlieneEditingCells];
    _footers[@(data.count - 1)] = OALocalizedString(@"offline_edition_descr");

    NSMutableDictionary *offlieneEditingData = [NSMutableDictionary dictionary];
    offlieneEditingData[@"key"] = @"offline_editing";
    offlieneEditingData[@"type"] = [OACustomBasicTableCell getCellIdentifier];
    offlieneEditingData[@"title"] = OALocalizedString(@"osm_editing_offline");
    offlieneEditingData[@"switch_cell"] = @(YES);
    [offlieneEditingCells addObject:offlieneEditingData];

    NSMutableArray<NSMutableDictionary *> *mappersCells = [NSMutableArray array];
    [data addObject:mappersCells];

    NSMutableDictionary *mappersData = [NSMutableDictionary dictionary];
    mappersData[@"key"] = @"updates_for_mappers";
    mappersData[@"type"] = [OACustomBasicTableCell getCellIdentifier];
    mappersData[@"title"] = OALocalizedString(@"map_updates_for_mappers");
    mappersData[@"description"] = [self getMappersDescription];
    mappersData[@"right_icon"] = @"ic_custom_arrow_right";
    mappersData[@"right_icon_color"] = UIColorFromRGB(color_tint_gray);
    [mappersCells addObject:mappersData];
    _mappersIndexPath = [NSIndexPath indexPathForRow:mappersCells.count - 1 inSection:data.count - 1];

    NSMutableArray<NSMutableDictionary *> *actionsCells = [NSMutableArray array];
    [data addObject:actionsCells];
    _headers[@(data.count - 1)] = OALocalizedString(@"actions");

    NSString *menuPath = [NSString stringWithFormat:@"%@ — %@ — %@",
                          OALocalizedString(@"menu"), OALocalizedString(@"menu_my_places"), OALocalizedString(@"osm_edits_title")];
    NSString *actionsDescr = [NSString stringWithFormat:OALocalizedString(@"osm_editing_access_descr"), menuPath];
    NSMutableAttributedString *actionsDescrAttr =
            [[NSMutableAttributedString alloc] initWithString:actionsDescr
                                                   attributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:15],
                                                                 NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer) }];
    [actionsDescrAttr addAttributes:@{ NSFontAttributeName : [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold] }
                              range:[actionsDescr rangeOfString:menuPath]];
    
    NSMutableParagraphStyle *actionsDescrParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    actionsDescrParagraphStyle.minimumLineHeight = 20.;
    [actionsDescrAttr addAttribute:NSParagraphStyleAttributeName
                             value:actionsDescrParagraphStyle
                             range:NSMakeRange(0, actionsDescrAttr.length)];

    NSMutableDictionary *descriptionData = [NSMutableDictionary dictionary];
    descriptionData[@"type"] = [OACustomBasicTableCell getCellIdentifier];
    descriptionData[@"description_attributed"] = actionsDescrAttr;
    [actionsCells addObject:descriptionData];

    NSMutableDictionary *editsData = [NSMutableDictionary dictionary];
    editsData[@"key"] = @"open_edits";
    editsData[@"type"] = [OACustomBasicTableCell getCellIdentifier];
    editsData[@"title"] = OALocalizedString(@"osm_edits_title");
    editsData[@"title_color"] = UIColorFromRGB(color_primary_purple);
    editsData[@"title_font"] = [UIFont systemFontOfSize:17. weight:UIFontWeightMedium];
    editsData[@"right_icon"] = @"ic_custom_folder";
    editsData[@"right_icon_color"] = UIColorFromRGB(color_primary_purple);
    [actionsCells addObject:editsData];

    _data = data;
}

- (NSString *)getMappersDescription
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MMM d"];

    return !_isLogged ? OALocalizedString(@"shared_string_learn_more")
            : ![OAIAPHelper isSubscribedToMapperUpdates]
            ? OALocalizedString(@"shared_string_unavailable")
                : [NSString stringWithFormat:@"%@ %@",
                    OALocalizedString(@"shared_string_available_until"),
                    [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[_settings.mapperLiveUpdatesExpireTime get]]]];

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OACustomBasicTableCell getCellIdentifier]])
    {
        OACustomBasicTableCell *cell = [tableView dequeueReusableCellWithIdentifier:[OACustomBasicTableCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OACustomBasicTableCell getCellIdentifier] owner:self options:nil];
            cell = (OACustomBasicTableCell *) nib[0];
            [cell valueVisibility:NO];
        }
        if (cell)
        {
            NSString *title = item[@"title"];
            [cell titleVisibility:title != nil];
            cell.titleLabel.text = title;
            cell.titleLabel.textColor = [item.allKeys containsObject:@"title_color"] ? item[@"title_color"] : UIColor.blackColor;
            cell.titleLabel.font = [item.allKeys containsObject:@"title_font"] ? item[@"title_font"] : [UIFont systemFontOfSize:17.];

            BOOL isSwitchCell = item[@"switch_cell"];
            cell.selectionStyle = isSwitchCell || !title ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
            [cell switchVisibility:isSwitchCell];

            BOOL hasLeftIcon = [item.allKeys containsObject:@"left_icon"];
            [cell leftIconVisibility:hasLeftIcon];
            cell.leftIconView.image = [UIImage templateImageNamed:item[@"left_icon"]];
            cell.leftIconView.tintColor = UIColorFromRGB(color_primary_purple);

            NSString *description = item[@"description"];
            NSAttributedString *descriptionAttributed = item[@"description_attributed"];
            [cell descriptionVisibility:description != nil || descriptionAttributed != nil];
            if (descriptionAttributed)
            {
                cell.descriptionLabel.text = nil;
                cell.descriptionLabel.attributedText = descriptionAttributed;
            }
            else
            {
                cell.descriptionLabel.attributedText = nil;
                cell.descriptionLabel.text = description;
            }

            NSString *rightIcon = item[@"right_icon"];
            [cell rightIconVisibility:rightIcon != nil];
            cell.rightIconView.image = [UIImage templateImageNamed:rightIcon];
            cell.rightIconView.tintColor = item[@"right_icon_color"];
        }
        return cell;
    }

    return nil;
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return _headers[@(section)];
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return _footers[@(section)];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *header = _headers[@(section)];
    if (header)
    {
        UIFont *font = [UIFont systemFontOfSize:13.];
        CGFloat headerHeight = [OAUtilities calculateTextBounds:header
                                                          width:tableView.frame.size.width - (kPaddingOnSideOfContent + [OAUtilities getLeftMargin]) * 2
                                                           font:font].height + (section == _credentialIndexPath.section ? 20. : kPaddingOnSideOfHeaderWithText);
        return headerHeight;
    }
    return kHeaderHeightDefault;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    NSString *footer = _footers[@(section)];
    if (footer)
    {
        UIFont *font = [UIFont systemFontOfSize:13.];
        CGFloat footerHeight = [OAUtilities calculateTextBounds:[_footers objectForKey:@(section)]
                                                        width:tableView.frame.size.width - (kPaddingOnSideOfContent + [OAUtilities getLeftMargin]) * 2
                                                        font:font].height + kPaddingOnSideOfFooterWithText;
        return footerHeight;
    }
    return 0.001;
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
    if (_credentialIndexPath && _mappersIndexPath)
    {
        NSMutableDictionary *credentialData = _data[_credentialIndexPath.section][_credentialIndexPath.row];
        credentialData[@"title"] = _isLogged ? [_settings.osmUserName get] : OALocalizedString(@"login_open_street_map_org");
        credentialData[@"title_color"] = _isLogged ? UIColor.blackColor : UIColorFromRGB(color_primary_purple);
        credentialData[@"title_font"] = [UIFont systemFontOfSize:17. weight:_isLogged ? UIFontWeightRegular : UIFontWeightMedium];

        NSMutableDictionary *mappersData = _data[_mappersIndexPath.section][_mappersIndexPath.row];
        mappersData[@"description"] = [self getMappersDescription];

        [self.tableView reloadRowsAtIndexPaths:@[_credentialIndexPath, _mappersIndexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}

@end
