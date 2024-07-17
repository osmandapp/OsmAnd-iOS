//
//  OAOsmAccountSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 06.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAOsmAccountSettingsViewController.h"
#import "OAOsmEditingSettingsViewController.h"
#import "OAValueTableViewCell.h"
#import "OAFilledButtonCell.h"
#import "OADividerCell.h"
#import "OASimpleTableViewCell.h"
#import "OAAppSettings.h"
#import "OAOsmBugsRemoteUtil.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmBugResult.h"
#import "OAOsmNotePoint.h"
#import "OASizes.h"
#import "Localization.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OAPluginsHelper.h"

@interface OAOsmAccountSettingsViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@end

@implementation OAOsmAccountSettingsViewController
{
    NSArray<NSArray *> *_data;
    NSIndexPath *_loginIndexPath;
    NSIndexPath *_userNameIndexPath;
    OAAppSettings *_settings;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"login_account");
}

- (BOOL)isNavbarSeparatorVisible
{
    return NO;
}

#pragma mark - Table data

- (void)generateData
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray new];

    NSMutableArray<NSDictionary *> *loginLogoutSection = [NSMutableArray new];
    [data addObject:loginLogoutSection];

    [loginLogoutSection addObject:@{
        @"type" : [OADividerCell getCellIdentifier],
        @"left_inset" : @(0.)
    }];
    [loginLogoutSection addObject:@{
        @"key" : @"user_name",
        @"type" : [OAValueTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"user_name"),
        @"value" : _settings.osmUserDisplayName.get
    }];
    _userNameIndexPath = [NSIndexPath indexPathForRow:loginLogoutSection.count - 1 inSection:data.count - 1];

    [loginLogoutSection addObject:@{
        @"type" : [OADividerCell getCellIdentifier],
        @"left_inset" : @(0.)
    }];

    [loginLogoutSection addObject:@{
        @"key" : @"empty_cell",
        @"type" : [OADividerCell getCellIdentifier]
    }];

    [loginLogoutSection addObject:@{
            @"key" : @"login_logout_cell",
            @"type" : [OAFilledButtonCell getCellIdentifier]
    }];
    _loginIndexPath = [NSIndexPath indexPathForRow:loginLogoutSection.count - 1 inSection:data.count - 1];

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
    if ([type isEqualToString:[OAValueTableViewCell getCellIdentifier]])
    {
        OAValueTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAValueTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAValueTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAValueTableViewCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.valueLabel.text = item[@"value"];
        }
        return cell;
    }
    else if ([type isEqualToString:[OAFilledButtonCell getCellIdentifier]])
    {
        OAFilledButtonCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAFilledButtonCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *) nib[0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.button.layer.cornerRadius = 9;
            cell.topMarginConstraint.constant = 0.;
            cell.bottomMarginConstraint.constant = 0.;
            cell.heightConstraint.constant = 42.;
        }
        if (cell)
        {
            cell.button.backgroundColor = [UIColor colorNamed:ACColorNameButtonBgColorSecondary];
            [cell.button setTitleColor:[UIColor colorNamed:ACColorNameButtonTextColorSecondary] forState:(UIControlState)UIControlStateNormal];
            [cell.button setTitle:OALocalizedString(@"shared_string_logout") forState:UIControlStateNormal];
            cell.button.userInteractionEnabled = YES;
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self action:@selector(loginLogoutButtonPressed) forControlEvents:UIControlEventTouchUpInside];
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
            cell.dividerColor = [UIColor colorNamed:ACColorNameCustomSeparator];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        if (cell)
        {
            BOOL isErrorEmptyCell = [item[@"key"] isEqualToString:@"empty_cell"];
            cell.backgroundColor = isErrorEmptyCell ? UIColor.clearColor : [UIColor colorNamed:ACColorNameGroupBg];
            cell.dividerHight = isErrorEmptyCell ? 30. : (1. / [UIScreen mainScreen].scale);
            cell.dividerInsets = UIEdgeInsetsMake(0., isErrorEmptyCell ? CGFLOAT_MAX : [item[@"left_inset"] floatValue], 0., 0.);
        }
        outCell = cell;
    }
    else if ([type isEqualToString:[OASimpleTableViewCell getCellIdentifier]])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline];
            cell.backgroundColor = UIColor.clearColor;
        }
        if (cell)
        {
            cell.titleLabel.text = item[@"title"];
            cell.titleLabel.textColor = [item.allKeys containsObject:@"title_color"] ? item[@"title_color"] : [UIColor colorNamed:ACColorNameTextColorPrimary];
        }
        return cell;
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
    return section == _userNameIndexPath.section ? 14. : UITableViewAutomaticDimension;
}

- (CGFloat)heightForRow:(NSIndexPath *)indexPath estimated:(BOOL)estimated
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    if ([type isEqualToString:[OADividerCell getCellIdentifier]])
    {
        return [item[@"key"] isEqualToString:@"empty_cell"] ? 30. : (1. / [UIScreen mainScreen].scale);
    }
    else if (estimated)
    {
        if ([type isEqualToString:[OAValueTableViewCell getCellIdentifier]])
            return 48.;
        else if ([type isEqualToString:[OAFilledButtonCell getCellIdentifier]])
            return 42.;
    }

    return UITableViewAutomaticDimension;
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

#pragma mark - Selectors

- (void)loginLogoutButtonPressed
{
    [OAOsmOAuthHelper logOut];
    [self dismissViewControllerAnimated:YES completion:^{
        if (self.accountDelegate)
            [self.accountDelegate onAccountInformationUpdated];
    }];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
        shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
