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
#import "OAMappersViewController.h"
#import "OASimpleTableViewCell.h"
#import "OARightIconTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OASizes.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OAIAPHelper.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define kAccountSectionIndex 0
#define kOfflineEditingSectionIndex 1

@interface OAOsmEditingSettingsViewController () <OAAccountSettingDelegate>

@end

@implementation OAOsmEditingSettingsViewController
{
    OATableDataModel *_data;
    BOOL _isAuthorised;
    NSIndexPath *_credentialIndexPath;
    NSIndexPath *_mappersIndexPath;

    OAAppSettings *_settings;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _isAuthorised = [OAOsmOAuthHelper isAuthorised];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onAccountInformationUpdated) name:OAOsmOAuthHelper.notificationKey object:nil];
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

- (NSArray<UIBarButtonItem *> *)getRightNavbarButtons
{
    UIBarButtonItem *rightButton = [self createRightNavbarButton:nil iconName:@"ic_navbar_reset" action:@selector(onRightNavbarButtonPressed) menu:nil];
    rightButton.accessibilityLabel = OALocalizedString(@"reset_to_default");
    return @[rightButton];
}

- (void)onRightNavbarButtonPressed
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:OALocalizedString(@"reset_to_default") message:OALocalizedString(@"reset_plugin_to_default") preferredStyle:UIAlertControllerStyleActionSheet];
    UIPopoverPresentationController *popPresenter = [alert popoverPresentationController];
    popPresenter.sourceView = self.view;
    popPresenter.barButtonItem = self.navigationItem.rightBarButtonItem;
    popPresenter.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil];

    UIAlertAction *resetAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_reset") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action)
    {
        [OAOsmOAuthHelper logOut];
        [_settings.offlineEditing resetToDefault];
        [self generateData];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kAccountSectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kOfflineEditingSectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
    }];

    [alert addAction:resetAction];
    [alert addAction:cancelAction];
    alert.preferredAction = resetAction;

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - Table data

- (void)generateData
{
    _data = [OATableDataModel model];

    OATableSectionData *credentialSection = [_data createNewSection];
    credentialSection.headerText = OALocalizedString(@"login_account");
    
    if ([OAOsmOAuthHelper isOAuthAllowed])
    {
        _isAuthorised = [OAOsmOAuthHelper isAuthorised];
        [credentialSection addRowFromDictionary:@{
            kCellKeyKey : @"edit_credentials",
            kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
            kCellTitleKey : _isAuthorised ? [_settings.osmUserDisplayName get] : OALocalizedString(@"login_open_street_map_org"),
            kCellIconNameKey : @"ic_custom_user_profile",
            kCellAccessoryType : _isAuthorised ? @(UITableViewCellAccessoryDisclosureIndicator) : @(UITableViewCellAccessoryNone),
            @"titleColor" : _isAuthorised ? [UIColor colorNamed:ACColorNameTextColorPrimary] : [UIColor colorNamed:ACColorNameTextColorActive],
            @"titleFont" : [UIFont scaledSystemFontOfSize:17. weight:_isAuthorised ? UIFontWeightRegular : UIFontWeightMedium]
        }];
    }
    else
    {
        [credentialSection addRowFromDictionary:@{
            kCellKeyKey : @"edit_credentials",
            kCellTypeKey : [OASimpleTableViewCell getCellIdentifier],
            kCellTitleKey : OALocalizedString(@"shared_string_update_required"),
            kCellDescrKey : OALocalizedString(@"osm_login_needs_ios_16_4"),
            kCellIconNameKey : @"ic_custom_alert",
            kCellIconTintColor : [UIColor colorNamed:ACColorNameIconColorSelected],
            kCellAccessoryType : @(UITableViewCellAccessoryNone),
            @"titleColor" : [UIColor colorNamed:ACColorNameTextColorPrimary],
            @"titleFont" : [UIFont scaledSystemFontOfSize:17. weight:UIFontWeightRegular]
        }];
    }
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
        @"titleColor" : [UIColor colorNamed:ACColorNameTextColorPrimary],
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
                                                                 NSForegroundColorAttributeName : [UIColor colorNamed:ACColorNameTextColorSecondary] }];
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
        @"titleColor" : [UIColor colorNamed:ACColorNameTextColorPrimary],
        @"titleFont" : [UIFont preferredFontForTextStyle:UIFontTextStyleBody]
    }];

    [actionsSection addRowFromDictionary:@{
        kCellKeyKey : @"open_edits",
        kCellTypeKey : [OARightIconTableViewCell getCellIdentifier],
        kCellTitleKey : OALocalizedString(@"osm_edits_title"),
        kCellSecondaryIconName : @"ic_custom_folder",
        kCellIconTintColor : [UIColor colorNamed:ACColorNameIconColorActive],
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
        }
        if (cell)
        {
            NSString *title = item.title;
            [cell titleVisibility:title];
            cell.titleLabel.text = title;

            cell.titleLabel.textColor = [item objForKey:@"titleColor"];
            cell.titleLabel.font = [item objForKey:@"titleFont"];

            BOOL hasLeftIcon = item.iconName && item.iconName.length > 0;
            [cell leftIconVisibility:hasLeftIcon];
            cell.leftIconView.image = hasLeftIcon ? [UIImage templateImageNamed:item.iconName] : nil;
            
            UIColor *iconColor = [item objForKey:kCellIconTintColor];
            if (iconColor)
                cell.leftIconView.tintColor = iconColor;
            else
                cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];

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
            cell.titleLabel.textColor = item.iconTintColor;
            cell.titleLabel.font = [item objForKey:@"titleFont"];
            cell.rightIconView.image = [UIImage templateImageNamed:item.secondaryIconName];
            cell.rightIconView.tintColor = item.iconTintColor;
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
        if ([OAOsmOAuthHelper isOAuthAllowed])
        {
            if (_isAuthorised)
            {
                OAOsmAccountSettingsViewController *accountSettings = [[OAOsmAccountSettingsViewController alloc] init];
                accountSettings.accountDelegate = self;
                [self showModalViewController:accountSettings];
            }
            else
            {
                [OAOsmOAuthHelper showOAuthScreenWithHostVC:self];
            }
        }
    }
    else if ([item.key isEqualToString:@"updates_for_mappers"])
    {
        if (_isAuthorised)
        {
            OAMappersViewController *benefitsViewController = [[OAMappersViewController alloc] init];
            [self showModalViewController:benefitsViewController];
        }
        else
        {
            [OAOsmOAuthHelper showBenefitsIntroScreenWithHostVC:self];
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

    return !_isAuthorised ? OALocalizedString(@"shared_string_learn_more")
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
        _isAuthorised = [OAOsmOAuthHelper isAuthorised];
        if (_credentialIndexPath && _mappersIndexPath)
        {
            OATableRowData *credentialRow = [_data itemForIndexPath:_credentialIndexPath];
            credentialRow.title = _isAuthorised ? [_settings.osmUserDisplayName get] : OALocalizedString(@"login_open_street_map_org");
            credentialRow.accessoryType = _isAuthorised ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
            [credentialRow setObj:_isAuthorised ? [UIColor colorNamed:ACColorNameTextColorPrimary] : [UIColor colorNamed:ACColorNameTextColorActive] forKey:@"titleColor"];
            [credentialRow setObj:[UIFont scaledSystemFontOfSize:17. weight:_isAuthorised ? UIFontWeightRegular : UIFontWeightMedium] forKey:@"titleFont"];
            
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
    if (_isAuthorised)
    {
        OAMappersViewController *benefitsViewController = [[OAMappersViewController alloc] init];
        [self showModalViewController:benefitsViewController];
    }
}

@end
