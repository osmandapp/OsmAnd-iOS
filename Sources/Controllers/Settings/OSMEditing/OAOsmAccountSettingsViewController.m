//
//  OAOsmAccountSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 06.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAOsmAccountSettingsViewController.h"
#import "OAOsmEditingSettingsViewController.h"
#import "OAInputTableViewCell.h"
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

@interface OAOsmAccountSettingsViewController () <UITextFieldDelegate, UIGestureRecognizerDelegate>

@end

@implementation OAOsmAccountSettingsViewController
{
    NSArray<NSArray *> *_data;
    NSIndexPath *_loginIndexPath;
    NSIndexPath *_userNameIndexPath;
    NSIndexPath *_passwordIndexPath;
    NSIndexPath *_errorEmptySpaceIndexPath;

    OAAppSettings *_settings;
    BOOL _isAuthorised;
    NSString *_errorMessage;

    NSString *_newUserName;
    NSString *_newPassword;
}

#pragma mark - Initialization

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _newUserName = [_settings.osmUserName get];
    _newPassword = [_settings.osmUserPassword get];
    _isAuthorised = [OAOsmOAuthHelper isAuthorised];
}

- (void)registerNotifications
{
    [self addNotification:UIKeyboardWillShowNotification selector:@selector(keyboardWillShow:)];
    [self addNotification:UIKeyboardWillHideNotification selector:@selector(keyboardWillHide:)];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    if (!_isAuthorised)
    {
        self.tableView.tableHeaderView =
                [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"use_login_and_password_description")
                                                     font:kHeaderDescriptionFont
                                                textColor:[UIColor colorNamed:ACColorNameTextColorSecondary]
                                               isBigTitle:NO
                                          parentViewWidth:self.view.frame.size.width];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (!_isAuthorised && _userNameIndexPath)
        [self showKeyboardForCellForIndexPath:_userNameIndexPath];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return _isAuthorised ? OALocalizedString(@"login_account") : OALocalizedString(@"shared_string_account_add");
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
        @"key" : @"email_input_cell",
        @"type" : [OAInputTableViewCell getCellIdentifier]
    }];
    _userNameIndexPath = [NSIndexPath indexPathForRow:loginLogoutSection.count - 1 inSection:data.count - 1];

    if (!_isAuthorised)
    {
        [loginLogoutSection addObject:@{
            @"type" : [OADividerCell getCellIdentifier],
            @"left_inset" : @([OAUtilities getLeftMargin] + kPaddingOnSideOfContent)
        }];
        [loginLogoutSection addObject:@{
            @"key" : @"password_input_cell",
            @"type" : [OAInputTableViewCell getCellIdentifier]
        }];
        _passwordIndexPath = [NSIndexPath indexPathForRow:loginLogoutSection.count - 1 inSection:data.count - 1];
    }

    [loginLogoutSection addObject:@{
        @"type" : [OADividerCell getCellIdentifier],
        @"left_inset" : @(0.)
    }];

    if (_errorMessage)
    {
        [loginLogoutSection addObject:@{
            @"key" : @"error_cell",
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : _errorMessage,
            @"title_color" : [UIColor colorNamed:ACColorNameButtonBgColorDisruptive]
        }];
    }
    else
    {
        [loginLogoutSection addObject:@{
            @"key" : @"empty_cell",
            @"type" : [OADividerCell getCellIdentifier]
        }];
    }
    _errorEmptySpaceIndexPath = [NSIndexPath indexPathForRow:loginLogoutSection.count - 1 inSection:data.count - 1];

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
    if ([type isEqualToString:[OAInputTableViewCell getCellIdentifier]])
    {
        OAInputTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAInputTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAInputTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell clearButtonVisibility:NO];
            [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.delegate = self;
        }
        if (cell)
        {
            BOOL isEmail = [item[@"key"] isEqualToString:@"email_input_cell"];
            BOOL isPassword = [item[@"key"] isEqualToString:@"password_input_cell"];
            
            if (isEmail)
            {
                cell.titleLabel.text = [OAOsmOAuthHelper isOAuthAuthorised] ? OALocalizedString(@"user_name") : OALocalizedString(@"shared_string_email");
                cell.inputField.text = [OAOsmOAuthHelper isOAuthAuthorised] ? _settings.osmUserDisplayName.get : _settings.osmUserName.get;
                cell.inputField.placeholder = OALocalizedString(@"email_example_hint");
                cell.inputField.textContentType = UITextContentTypeUsername;
                cell.inputField.secureTextEntry = NO;
            }
            else
            {
                cell.titleLabel.text = OALocalizedString(@"user_password");
                cell.inputField.text = _settings.osmUserPassword.get;
                cell.inputField.placeholder = OALocalizedString(@"shared_string_required");
                cell.inputField.textContentType = UITextContentTypePassword;
                cell.inputField.secureTextEntry = YES;
            }
            cell.titleLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
            cell.inputField.userInteractionEnabled = !_isAuthorised;
            cell.inputField.tag = indexPath.section << 10 | indexPath.row;;
            cell.inputField.returnKeyType = UIReturnKeyDone;
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
            cell.button.backgroundColor = _isAuthorised || _newUserName.length == 0 || _newPassword.length == 0 || _errorMessage != nil
                    ? [UIColor colorNamed:ACColorNameButtonBgColorSecondary]
            : [UIColor colorNamed:ACColorNameButtonBgColorPrimary];
            [cell.button setTitleColor:_isAuthorised
             ? [UIColor colorNamed:ACColorNameButtonTextColorSecondary]
                            : _newUserName.length == 0 || _newPassword.length == 0 || _errorMessage != nil
             ? [UIColor colorNamed:ACColorNameTextColorSecondary] : [UIColor colorNamed:ACColorNameButtonTextColorPrimary]
                              forState:UIControlStateNormal];
            [cell.button setTitle:_isAuthorised > 0 ? OALocalizedString(@"shared_string_logout") : OALocalizedString(@"user_login")
                         forState:UIControlStateNormal];
            cell.button.userInteractionEnabled = _isAuthorised ? YES : _newUserName.length > 0 && _newPassword.length > 0 && _errorMessage == nil;
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

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] hasSuffix:@"_input_cell"])
        [self showKeyboardForCellForIndexPath:indexPath];
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
        if ([type isEqualToString:[OAInputTableViewCell getCellIdentifier]])
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
    if (_userNameIndexPath)
    {
        OAInputTableViewCell *cell = [self.tableView cellForRowAtIndexPath:_userNameIndexPath];
        [cell.inputField resignFirstResponder];
    }
    if (_passwordIndexPath)
    {
        OAInputTableViewCell *cell = [self.tableView cellForRowAtIndexPath:_passwordIndexPath];
        [cell.inputField resignFirstResponder];
    }

    if (!_isAuthorised)
    {
        [_settings.osmUserName set:_newUserName];
        [_settings.osmUserPassword set:_newPassword];

        OAOsmBugsRemoteUtil *util = (OAOsmBugsRemoteUtil *) [(OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class] getOsmNotesRemoteUtil];
        OAOsmBugResult *result = [util validateLoginDetails];
        NSString *warning = result.warning;
        if (warning)
        {
            [OAOsmOAuthHelper logOut];
            _errorMessage = OALocalizedString(@"auth_failed");

            [self generateData];
            [self.tableView performBatchUpdates:^{
                if (_errorEmptySpaceIndexPath && _loginIndexPath)
                {
                    [self.tableView reloadRowsAtIndexPaths:@[_errorEmptySpaceIndexPath, _loginIndexPath]
                                          withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            } completion:nil];
        }
        else
        {
            [_settings.osmUserDisplayName set:result.userName];

            [self dismissViewControllerAnimated:YES completion:^{
                if (self.accountDelegate)
                    [self.accountDelegate onAccountInformationUpdated];

                [OAOsmOAuthHelper sendNotifications];
            }];
        }
    }
    else
    {
        [OAOsmOAuthHelper logOut];
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.accountDelegate)
                [self.accountDelegate onAccountInformationUpdated];
        }];
    }
}

- (void)showKeyboardForCellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell && [cell isKindOfClass:OAInputTableViewCell.class])
    {
        OAInputTableViewCell *resCell = (OAInputTableViewCell *) cell;
        [resCell.inputField becomeFirstResponder];
    }
}

- (void)textViewDidChange:(UITextField *)textField
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:textField.tag & 0x3FF inSection:textField.tag >> 10];
    NSDictionary *item = [self getItem:indexPath];

    BOOL needToReloadCells = NO;
    if (_errorMessage)
    {
        _errorMessage = nil;
        [self generateData];
        needToReloadCells = YES;
    }
    if ([item[@"key"] isEqualToString:@"email_input_cell"])
        _newUserName = textField.text;
    else if ([item[@"key"] isEqualToString:@"password_input_cell"])
    {
        if (((_newUserName.length == 0 || _newPassword.length == 0) && textField.text.length > 0) || textField.text.length == 0)
        {
            needToReloadCells = YES;
        }
        _newPassword = textField.text;
    }
    [self.tableView performBatchUpdates:^{
        if (needToReloadCells && _errorEmptySpaceIndexPath && _loginIndexPath)
        {
            [self.tableView reloadRowsAtIndexPaths:@[_errorEmptySpaceIndexPath, _loginIndexPath]
                                  withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    } completion:nil];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (_userNameIndexPath)
    {
        OAInputTableViewCell *cell = [self.tableView cellForRowAtIndexPath:_userNameIndexPath];
        [cell.inputField resignFirstResponder];
    }
    if (_passwordIndexPath)
    {
        OAInputTableViewCell *cell = [self.tableView cellForRowAtIndexPath:_passwordIndexPath];
        [cell.inputField resignFirstResponder];
    }
}
#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    if (!_isAuthorised && _passwordIndexPath && _userNameIndexPath)
    {
        if (_newPassword.length > 0 && _newUserName.length > 0)
        {
            [self loginLogoutButtonPressed];
            [textField resignFirstResponder];
        }
        else
        {
            [self showKeyboardForCellForIndexPath:_newPassword.length == 0 ? _passwordIndexPath : _userNameIndexPath];
        }
    }
    else
    {
        [textField resignFirstResponder];
    }

    return YES;
}

- (BOOL) textFieldShouldClear:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
        shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

#pragma mark - Keyboard Notifications

- (void) keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;
    
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void) keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [[userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

@end
