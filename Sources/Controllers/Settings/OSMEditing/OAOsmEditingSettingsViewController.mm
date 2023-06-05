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
#import "OABenefitsOsmContributorsViewController.h"
#import "OAMappersViewController.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OASizes.h"
#import "Localization.h"
#import "OAColors.h"
#import "OAAppSettings.h"
#import "OAIAPHelper.h"
#import "OsmAnd_Maps-Swift.h"

@interface OAOsmEditingSettingsViewController () <OAAccountSettingDelegate>

@end

@implementation OAOsmEditingSettingsViewController
{
    OATableDataModel *_data;
    BOOL _isLogged;
    NSIndexPath *_credentialIndexPath;
    NSIndexPath *_mappersIndexPath;

    OAAppSettings *_settings;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _isLogged = [OsmOAuthHelper isLogged];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAccountInformationUpdated) name:OsmOAuthHelper.notificationKey object:nil];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"osm_editing_plugin_name");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeOrange;
}

- (NSString *)getTableHeaderDescription
{
    return OALocalizedString(@"osm_editing_settings_descr");
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];

    OATableSectionData *credentialSection = [_data createNewSection];
    credentialSection.headerText = OALocalizedString(@"login_account");

    [credentialSection addRowFromDictionary:@{
        kCellKeyKey : @"edit_credentials",
        kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
        kCellTitleKey : _isLogged ? [_settings.osmUserName get] : OALocalizedString(@"login_open_street_map_org"),
        kCellIconNameKey : @"ic_custom_user_profile",
        kCellAccessoryType : _isLogged ? @(UITableViewCellAccessoryDisclosureIndicator) : @(UITableViewCellAccessoryNone),
        @"titleColor" : _isLogged ? UIColor.blackColor : UIColorFromRGB(color_primary_purple),
        @"titleFont" : [UIFont scaledSystemFontOfSize:17. weight:_isLogged ? UIFontWeightRegular : UIFontWeightMedium]
    }];
    _credentialIndexPath = [NSIndexPath indexPathForRow:[credentialSection rowCount] - 1 inSection:[_data sectionCount] - 1];

    OATableSectionData *offlieneEditingSection = [_data createNewSection];
    offlieneEditingSection.footerText = OALocalizedString(@"offline_edition_descr");

    [offlieneEditingSection addRowFromDictionary:@{
        kCellKeyKey : @"offline_editing",
        kCellTypeKey : [OASwitchTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"offline_edition"),
        @"isOn" : @([_settings.offlineEditing get])
    }];

    OATableSectionData *mappersSection = [_data createNewSection];
    [mappersSection addRowFromDictionary:@{
        kCellKeyKey : @"updates_for_mappers",
        kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"map_updates_for_mappers"),
        kCellDescrKey : [self getMappersDescription],
        kCellAccessoryType : @(UITableViewCellAccessoryDisclosureIndicator),
        @"titleColor" : UIColor.blackColor,
        @"titleFont" : [UIFont preferredFontForTextStyle:UIFontTextStyleBody]
    }];
    _mappersIndexPath = [NSIndexPath indexPathForRow:[mappersSection rowCount] - 1 inSection:[_data sectionCount] - 1];

    OATableSectionData *actionsSection = [_data createNewSection];
    actionsSection.headerText = OALocalizedString(@"shared_string_actions");

    NSString *menuPath = [NSString stringWithFormat:@"%@ — %@ — %@",
                          OALocalizedString(@"shared_string_menu"), OALocalizedString(@"shared_string_my_places"), OALocalizedString(@"osm_edits_title")];
    NSString *actionsDescr = [NSString stringWithFormat:OALocalizedString(@"osm_editing_access_descr"), menuPath];
    NSMutableAttributedString *actionsDescrAttr =
            [[NSMutableAttributedString alloc] initWithString:actionsDescr
                                                   attributes:@{ NSFontAttributeName : [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline],
                                                                 NSForegroundColorAttributeName : UIColorFromRGB(color_text_footer) }];
    [actionsDescrAttr addAttributes:@{ NSFontAttributeName : [UIFont scaledSystemFontOfSize:15 weight:UIFontWeightSemibold] }
                              range:[actionsDescr rangeOfString:menuPath]];
    
    NSMutableParagraphStyle *actionsDescrParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    actionsDescrParagraphStyle.minimumLineHeight = 20.;
    [actionsDescrAttr addAttribute:NSParagraphStyleAttributeName
                             value:actionsDescrParagraphStyle
                             range:NSMakeRange(0, actionsDescrAttr.length)];

    [actionsSection addRowFromDictionary:@{
        kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
        kCellAccessoryType : @(UITableViewCellAccessoryNone),
        @"descriptionAttributed" : actionsDescrAttr,
        @"titleColor" : UIColor.blackColor,
        @"titleFont" : [UIFont preferredFontForTextStyle:UIFontTextStyleBody]
    }];

    [actionsSection addRowFromDictionary:@{
        kCellKeyKey : @"open_edits",
        kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"osm_edits_title"),
        kCellSecondaryIconName : @"ic_custom_folder",
        kCellIconTint : @(color_primary_purple),
        @"titleFont" : [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightMedium]
    }];
}

- (NSString *)getTitleForHeader:(NSInteger)section
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [[_data sectionDataForIndex:section] rowCount];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.cellType isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            cell.leftIconView.tintColor = UIColorFromRGB(color_primary_purple);
        }
        if (cell)
        {
            NSString *title = item.title;
            [cell titleVisibility:title && title.length > 0];
            cell.titleLabel.text = title;

            cell.titleLabel.textColor = [item objForKey:@"titleColor"];
            cell.titleLabel.font = [item objForKey:@"titleFont"];

            BOOL hasLeftIcon = item.iconName && item.iconName.length > 0;
            [cell leftIconVisibility:hasLeftIcon];
            cell.leftIconView.image = hasLeftIcon ? [UIImage templateImageNamed:item.iconName] : nil;

            NSString *description = item.descr;
            NSAttributedString *descriptionAttributed = [item objForKey:@"descriptionAttributed"];
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

            cell.selectionStyle = cell.titleLabel.hidden ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleDefault;
            cell.accessoryType = item.accessoryType;
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OARightIconTableViewCell getCellIdentifier]])
    {
        OARightIconTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OARightIconTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OARightIconTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OARightIconTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.titleLabel.textColor = UIColorFromRGB(item.iconTint);
            cell.titleLabel.font = [item objForKey:@"titleFont"];
            cell.rightIconView.image = [UIImage templateImageNamed:item.secondaryIconName];
            cell.rightIconView.tintColor = UIColorFromRGB(item.iconTint);
        }
        return cell;
    }
    else if ([item.cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.switchView.on = [item boolForKey:@"isOn"];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:self action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(onSwitchPressed:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }

    return nil;
}

- (NSInteger)sectionsCount
{
    return [_data sectionCount];
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    
    if ([item.key isEqualToString:@"open_edits"])
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
    else if ([item.key isEqualToString:@"edit_credentials"])
    {
        if (_isLogged)
        {
            OAOsmAccountSettingsViewController *accountSettings = [[OAOsmAccountSettingsViewController alloc] init];
            accountSettings.accountDelegate = self;
            [self showModalViewController:accountSettings];
        }
        else
        {
            [OsmOAuthHelper showAuthIntroScreenWithHostVC:self];
        }
    }
    else if ([item.key isEqualToString:@"updates_for_mappers"])
    {
        if (_isLogged)
        {
            OAMappersViewController *benefitsViewController = [[OAMappersViewController alloc] init];
            [self showModalViewController:benefitsViewController];
        }
        else
        {
            OABenefitsOsmContributorsViewController *benefitsViewController = [[OABenefitsOsmContributorsViewController alloc] init];
            benefitsViewController.accountDelegate = self;
            [self showModalViewController:benefitsViewController];
        }
    }
}

#pragma mark - Selectors

- (void)onSwitchPressed:(UISwitch *)sender
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sender.tag & 0x3FF inSection:sender.tag >> 10];
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    if ([item.key isEqualToString:@"offline_editing"])
    {
        [_settings.offlineEditing set:sender.on];
        [item setObj:@(sender.on) forKey:@"isOn"];
    }
}

#pragma mark - Additions

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

#pragma mark - OAAccontSettingDelegate

- (void)onAccountInformationUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _isLogged = [OsmOAuthHelper isLogged];
        if (_credentialIndexPath && _mappersIndexPath)
        {
            OATableRowData *credentialRow = [_data itemForIndexPath:_credentialIndexPath];
            credentialRow.title = _isLogged ? [_settings.osmUserName get] : OALocalizedString(@"login_open_street_map_org");
            credentialRow.accessoryType = _isLogged ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
            [credentialRow setObj:_isLogged ? UIColor.blackColor : UIColorFromRGB(color_primary_purple) forKey:@"titleColor"];
            [credentialRow setObj:[UIFont scaledSystemFontOfSize:17. weight:_isLogged ? UIFontWeightRegular : UIFontWeightMedium] forKey:@"titleFont"];
            
            OATableRowData *mappersRow = [_data itemForIndexPath:_mappersIndexPath];
            mappersRow.descr = [self getMappersDescription];
            
            [self.tableView reloadRowsAtIndexPaths:@[_credentialIndexPath, _mappersIndexPath]
                                  withRowAnimation:UITableViewRowAnimationNone];
        }
    });
}

-(void)onAccountInformationUpdatedFromBenefits
{
    [self onAccountInformationUpdated];
    if (_isLogged)
    {
        OAMappersViewController *benefitsViewController = [[OAMappersViewController alloc] init];
        [self showModalViewController:benefitsViewController];
    }
}

@end
