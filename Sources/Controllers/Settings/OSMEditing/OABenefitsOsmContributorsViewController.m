//
//  OABenefitsOsmContributorsViewController.m
//  OsmAnd
//
//  Created by Skalii on 05.09.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OABenefitsOsmContributorsViewController.h"
#import "OADividerCell.h"
#import "OAFilledButtonCell.h"
#import "OATitleDescriptionBigIconCell.h"
#import "OAValueTableViewCell.h"
#import "OAOsmAccountSettingsViewController.h"
#import "OASizes.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

@interface OABenefitsOsmContributorsViewController () <OAAccountSettingDelegate>

@end

@implementation OABenefitsOsmContributorsViewController
{
    NSArray<NSArray *> *_data;
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsSelection = NO;
}

#pragma mark - Base UI

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (EOABaseNavbarColorScheme)getNavbarColorScheme
{
    return EOABaseNavbarColorSchemeWhite;
}

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray new];

    NSMutableAttributedString *descriptionAttributed = [[NSMutableAttributedString alloc] initWithString:OALocalizedString(@"benefits_for_contributors_primary_descr")];
    NSMutableParagraphStyle *descriptionParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    descriptionParagraphStyle.minimumLineHeight = 25.5;
    [descriptionAttributed addAttribute:NSParagraphStyleAttributeName
                                             value:descriptionParagraphStyle
                                             range:NSMakeRange(0, descriptionAttributed.length)];
    [descriptionAttributed addAttribute:NSFontAttributeName
                                             value:[UIFont preferredFontForTextStyle:UIFontTextStyleBody]
                                             range:NSMakeRange(0, descriptionAttributed.length)];

    NSMutableAttributedString *signInAttributed = [[NSMutableAttributedString alloc] initWithString:
            [@"\n\n" stringByAppendingString:OALocalizedString(@"benefits_for_contributors_secondary_descr")]];
    NSMutableParagraphStyle *signInParagraphStyle = [[NSMutableParagraphStyle alloc] init];
    signInParagraphStyle.minimumLineHeight = 21.;
    [signInAttributed addAttribute:NSParagraphStyleAttributeName
                                  value:signInParagraphStyle
                                  range:NSMakeRange(0, signInAttributed.length)];
    [signInAttributed addAttribute:NSFontAttributeName
                                  value:[UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
                                  range:NSMakeRange(0, signInAttributed.length)];
    [signInAttributed addAttribute:NSForegroundColorAttributeName
                                  value:[UIColor colorNamed:ACColorNameTextColorSecondary]
                                  range:NSMakeRange(0, signInAttributed.length)];
    [descriptionAttributed appendAttributedString:signInAttributed];

    [data addObject:@[
            @{
                    @"type" : [OATitleDescriptionBigIconCell getCellIdentifier],
                    @"title" : OALocalizedString(@"benefits_for_contributors"),
                    @"icon": @"ic_custom_openstreetmap_logo_colored_day_big"
            },
            @{
                    @"type" : [OATitleDescriptionBigIconCell getCellIdentifier],
                    @"attributed_title" : descriptionAttributed
            },
            @{ @"type" : [OADividerCell getCellIdentifier] },
            @{
                    @"type" : [OAValueTableViewCell getCellIdentifier],
                    @"title" : OALocalizedString(@"daily_map_updates"),
                    @"left_icon": @"ic_custom_map_updates_colored",
                    @"right_icon": @"img_openstreetmap_logo"
            },
            @{
                    @"type" : [OADividerCell getCellIdentifier],
                    @"left_inset": @(66. + [OAUtilities getLeftMargin])
            },
            @{
                    @"type" : [OAValueTableViewCell getCellIdentifier],
                    @"title" : OALocalizedString(@"monthly_map_updates"),
                    @"left_icon": @"ic_custom_monthly_map_updates_colored",
                    @"right_icon": @"img_openstreetmap_logo"
            },
            @{
                    @"type" : [OADividerCell getCellIdentifier],
                    @"left_inset": @(66. + [OAUtilities getLeftMargin])
            },
            @{
                    @"type" : [OAValueTableViewCell getCellIdentifier],
                    @"title" : OALocalizedString(@"unlimited_map_downloads"),
                    @"left_icon": @"ic_custom_unlimited_downloads_colored",
                    @"right_icon": @"img_openstreetmap_logo"
            },
            /*@{
                    @"key" : @"oauth_login_button",
                    @"type" : [OAFilledButtonCell getCellIdentifier],
                    @"title" : OALocalizedString(@"sign_in_with_open_street_map"),
                    @"icon": @"ic_action_openstreetmap_logo",
                    @"background_color": UIColorFromRGB(color_primary_purple),
                    @"tint_color": UIColor.whiteColor,
                    @"top_margin": @(9.)
            },*/
            @{
                    @"key" : @"email_login_button",
                    @"type" : [OAFilledButtonCell getCellIdentifier],
                    @"title" : OALocalizedString(@"use_login_and_password"),
                    @"background_color": [UIColor colorNamed:ACColorNameButtonBgColorDisabled],
                    @"tint_color": [UIColor colorNamed:ACColorNameButtonTextColorSecondary],
                    @"top_margin": @(16.),
                    @"bottom_margin": @(20.)
            },
            @{ @"type" : [OADividerCell getCellIdentifier] }
    ]];

    _data = data;
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    UITableViewCell *outCell = nil;

    NSString *type = item[@"type"];
    if ([type isEqualToString:[OATitleDescriptionBigIconCell getCellIdentifier]])
    {
        OATitleDescriptionBigIconCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OATitleDescriptionBigIconCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATitleDescriptionBigIconCell getCellIdentifier] owner:self options:nil];
            cell = (OATitleDescriptionBigIconCell *) nib[0];
            [cell showDescription:NO];
            [cell showRightIcon:NO];
        }
        if (cell)
        {
            NSString *imageNamed = item[@"icon"];
            [cell showLeftIcon:imageNamed && imageNamed.length > 0];
            cell.leftIconView.image = [UIImage imageNamed:imageNamed];

            if ([item.allKeys containsObject:@"attributed_title"])
                cell.titleView.attributedText = item[@"attributed_title"];
            else
                cell.titleView.text = item[@"title"];
        }
        outCell = cell;
    }
    else if ([type isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            [cell descriptionVisibility:NO];
            [cell valueVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.leftIconView.image = [UIImage imageNamed:item[@"left_icon"]];
            cell.accessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:item[@"right_icon"]]];
        }
        outCell = cell;
    }
    else if ([type isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *) nib[0];
            cell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            cell.dividerColor = [UIColor colorNamed:ACColorNameCustomSeparator];
        }
        if (cell)
        {
            cell.dividerHight = 1. / [UIScreen mainScreen].scale;
            cell.dividerInsets = UIEdgeInsetsMake(0., [item.allKeys containsObject:@"left_inset"]
                    ? [item[@"left_inset"] floatValue] : 0., 0., 0.);
        }
        outCell = cell;
    }
    else if ([type isEqualToString:[OAFilledButtonCell getCellIdentifier]])
    {
        OAFilledButtonCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAFilledButtonCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *) nib[0];
            cell.backgroundColor = [UIColor colorNamed:ACColorNameGroupBg];
            cell.button.layer.cornerRadius = 9;
            cell.heightConstraint.constant = 42.;
        }
        if (cell)
        {
            cell.topMarginConstraint.constant = [item[@"top_margin"] floatValue];
            cell.bottomMarginConstraint.constant = [item.allKeys containsObject:@"bottom_margin"]
                    ? [item[@"bottom_margin"] floatValue] : 0.;

            cell.button.backgroundColor = item[@"background_color"];
            [cell.button setTitleColor:item[@"tint_color"] forState:UIControlStateNormal];
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            [cell.button setImage:[UIImage templateImageNamed:item[@"icon"]] forState:UIControlStateNormal];
            cell.button.tintColor = item[@"tint_color"];

            cell.button.tag = indexPath.section << 10 | indexPath.row;
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self action:@selector(onButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
}

- (NSInteger)sectionsCount
{
    return _data.count;
}

- (CGFloat)getCustomHeightForHeader:(NSInteger)section
{
    return 0.001;
}

- (CGFloat)getCustomHeightForFooter:(NSInteger)section
{
    return 0.001;
}

- (CGFloat)heightForRow:(NSIndexPath *)indexPath estimated:(BOOL)estimated
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    if ([type isEqualToString:[OADividerCell getCellIdentifier]])
    {
        return 1. / [UIScreen mainScreen].scale;
    }
    else if (estimated)
    {
        if ([type isEqualToString:[OATitleDescriptionBigIconCell getCellIdentifier]])
            return 66.;
        else if ([type isEqualToString:[OAValueTableViewCell getCellIdentifier]])
            return 48.;
        else if ([type isEqualToString:[OAFilledButtonCell getCellIdentifier]])
            return 42.;
    }

    return UITableViewAutomaticDimension;
}

#pragma mark - Selectors

- (void)onButtonPressed:(id)sender
{
    UIButton *button = (UIButton *) sender;
    if (button)
    {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:button.tag & 0x3FF inSection:button.tag >> 10];
        NSDictionary *item = _data[indexPath.section][indexPath.row];
        NSString *key = item[@"key"];
        if ([key isEqualToString:@"oauth_login_button"])
        {
        }
        else if ([key isEqualToString:@"email_login_button"])
        {
            OAOsmAccountSettingsViewController *accountSettings = [[OAOsmAccountSettingsViewController alloc] init];
            accountSettings.accountDelegate = self;
            [self showModalViewController:accountSettings];
        }
    }
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath estimated:NO];
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self heightForRow:indexPath estimated:YES];
}

#pragma mark - OAAccountSettingDelegate

- (void)onAccountInformationUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.accountDelegate)
                [self.accountDelegate onAccountInformationUpdatedFromBenefits];
        }];
    });
}

@end
