//
//  OAOsmAccountSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 06.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAOsmAccountSettingsViewController.h"
#import "OAOsmEditingSettingsViewController.h"
#import "OAInputCellWithTitle.h"
#import "OAFilledButtonCell.h"
#import "OADividerCell.h"
#import "OAAppSettings.h"
#import "OAOsmBugsRemoteUtil.h"
#import "OAOsmEditingPlugin.h"
#import "OAOsmBugResult.h"
#import "OAOsmNotePoint.h"
#import "OAColors.h"
#import "Localization.h"

@interface OAOsmAccountSettingsViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@end

@implementation OAOsmAccountSettingsViewController
{
    NSArray<NSArray *> *_data;
    NSIndexPath *_loginIndexPath;

    OAAppSettings *_settings;
    BOOL _isLogged;

    NSString *_newUserName;
    NSString *_newPassword;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OABaseSettingsViewController" bundle:nil];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    _settings = [OAAppSettings sharedManager];
    _newUserName = [_settings.osmUserName get];
    _newPassword = [_settings.osmUserPassword get];
    _isLogged = _newUserName.length > 0 && _newPassword.length > 0;

    [self generateData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

    self.subtitleLabel.text = @"";
    self.subtitleLabel.hidden = YES;

    self.separatorNavbarView.hidden = YES;

    if (!_isLogged)
    {
        self.tableView.tableHeaderView =
                [OAUtilities setupTableHeaderViewWithText:OALocalizedString(@"use_login_and_password_description")
                                                     font:[UIFont systemFontOfSize:13.]
                                                textColor:UIColorFromRGB(color_text_footer)
                                              lineSpacing:0
                                                  isTitle:NO];
    }

    self.backButton.hidden = YES;
    self.cancelButton.hidden = NO;
    [self.cancelButton setImage:[UIImage imageNamed:@"ic_navbar_chevron"] forState:UIControlStateNormal];
    self.cancelButton.tintColor = UIColorFromRGB(color_primary_purple);
    UIEdgeInsets titleInsets = self.cancelButton.titleEdgeInsets;
    titleInsets.left = -10.;
    self.cancelButton.titleEdgeInsets = titleInsets;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self showKeyboardForCellForIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.tableView reloadData];
    } completion:nil];
}

- (void)applyLocalization
{
    self.titleLabel.text = _isLogged ? OALocalizedString(@"shared_string_account") : OALocalizedString(@"shared_string_account_add");
    [self.cancelButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void)generateData
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray new];

    [data addObject:@[
            @{ @"type" : [OADividerCell getCellIdentifier] },
            @{
                    @"key" : @"email_input_cell",
                    @"type" : [OAInputCellWithTitle getCellIdentifier]
            },
            @{ @"type" : [OADividerCell getCellIdentifier] },
            @{
                    @"key" : @"password_input_cell",
                    @"type" : [OAInputCellWithTitle getCellIdentifier]
            },
            @{ @"type" : [OADividerCell getCellIdentifier] },
    ]];

    [data addObject:@[
            @{
                    @"key" : @"login_logout_cell",
                    @"type" : [OAFilledButtonCell getCellIdentifier],
            }
    ]];
    _loginIndexPath = [NSIndexPath indexPathForRow:data[data.count - 1].count - 1 inSection:data.count - 1];

    _data = data;
}

- (NSDictionary *)getItem:(NSIndexPath *)indexPath
{
    return _data[indexPath.section][indexPath.row];
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
        if ([type isEqualToString:[OAInputCellWithTitle getCellIdentifier]])
            return 48.;
        else if ([type isEqualToString:[OAFilledButtonCell getCellIdentifier]])
            return 42.;
    }

    return UITableViewAutomaticDimension;
}

#pragma mark - Selectors

- (void)loginLogoutButtonPressed
{
    if (!_isLogged)
    {
        [_settings.osmUserName set:_newUserName];
        [_settings.osmUserPassword set:_newPassword];

        OAOsmBugsRemoteUtil *util = (OAOsmBugsRemoteUtil *) [(OAOsmEditingPlugin *) [OAPlugin getPlugin:OAOsmEditingPlugin.class] getOsmNotesRemoteUtil];
        OAOsmBugResult *result = [util validateLoginDetails];
        NSString *warning = result.warning;
        if (warning)
        {
            [_settings.osmUserName resetToDefault];
            [_settings.osmUserPassword resetToDefault];
            [OAUtilities showToast:warning.length > 0 ? warning : OALocalizedString(@"auth_error") details:nil duration:4 inView:self.view];
        }
        else
        {
            [_settings.osmUserDisplayName set:result.userName];

            [self dismissViewControllerAnimated:YES completion:^{
                if (self.accountDelegate)
                    [self.accountDelegate onAccountInformationUpdated];
            }];
        }
    }
    else
    {
        [_settings.osmUserName resetToDefault];
        [_settings.osmUserPassword resetToDefault];
        [_settings.osmUserDisplayName resetToDefault];
        [_settings.mapperLiveUpdatesExpireTime resetToDefault];

        [self dismissViewControllerAnimated:YES completion:^{
            if (self.accountDelegate)
                [self.accountDelegate onAccountInformationUpdated];
        }];
    }
}

- (void)showKeyboardForCellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell && [cell isKindOfClass:OAInputCellWithTitle.class])
    {
        OAInputCellWithTitle *resCell = (OAInputCellWithTitle *) cell;
        [resCell.inputField becomeFirstResponder];
    }
}

- (void)textViewDidChange:(UITextField *)textField
{
    NSIndexPath *indexPath =[NSIndexPath indexPathForRow:textField.tag & 0x3FF inSection:textField.tag >> 10];
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] isEqualToString:@"email_input_cell"])
        _newUserName = textField.text;
    else if ([item[@"key"] isEqualToString:@"password_input_cell"])
        _newPassword = textField.text;

    [self.tableView reloadRowsAtIndexPaths:@[_loginIndexPath] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return _data.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _data[section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    UITableViewCell *outCell = nil;

    NSString *type = item[@"type"];
    if ([type isEqualToString:[OAInputCellWithTitle getCellIdentifier]])
    {
        OAInputCellWithTitle *cell = [tableView dequeueReusableCellWithIdentifier:[OAInputCellWithTitle getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputCellWithTitle getCellIdentifier] owner:self options:nil];
            cell = (OAInputCellWithTitle *) [nib objectAtIndex:0];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.delegate = self;
            cell.inputField.textAlignment = NSTextAlignmentRight;
        }
        if (cell)
        {
            BOOL isEmail = [item[@"key"] isEqualToString:@"email_input_cell"];
            BOOL isPassword = [item[@"key"] isEqualToString:@"password_input_cell"];

            cell.titleLabel.text = isEmail ? OALocalizedString(@"shared_string_email") : OALocalizedString(@"shared_string_password");
            cell.titleLabel.textColor = [UIColor blackColor];

            cell.inputField.text = isEmail ? _settings.osmUserName.get : _settings.osmUserPassword.get;
            cell.inputField.placeholder = isEmail ? OALocalizedString(@"email_example_hint") : OALocalizedString(@"shared_string_required");
            cell.inputField.textContentType = isEmail ? UITextContentTypeUsername : UITextContentTypePassword;
            cell.inputField.secureTextEntry = isPassword;
            cell.inputField.tag = indexPath.section << 10 | indexPath.row;;
            cell.inputField.returnKeyType = UIReturnKeyDone;
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
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            cell.button.layer.cornerRadius = 9;
            cell.topMarginConstraint.constant = 0.;
            cell.bottomMarginConstraint.constant = 0.;
            cell.heightConstraint.constant = 42.;
        }
        if (cell)
        {
            cell.button.backgroundColor = _isLogged || _newUserName.length == 0 || _newPassword.length == 0
                    ? UIColorFromRGB(color_route_button_inactive)
                    : UIColorFromRGB(color_primary_purple);
            [cell.button setTitleColor:_isLogged
                            ? UIColorFromRGB(color_primary_purple)
                            : _newUserName.length == 0 || _newPassword.length == 0
                                    ? UIColorFromRGB(color_text_footer) : UIColor.whiteColor
                              forState:UIControlStateNormal];
            [cell.button setTitle:_isLogged > 0 ? OALocalizedString(@"shared_string_logout") : OALocalizedString(@"user_login")
                         forState:UIControlStateNormal];
            cell.button.userInteractionEnabled = _isLogged ? YES : _newUserName.length > 0 && _newPassword.length > 0;
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self action:@selector(loginLogoutButtonPressed) forControlEvents:UIControlEventTouchUpInside];
        }
        outCell = cell;
    }
    else if ([type isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell *cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *) nib[0];
            cell.backgroundColor = UIColor.whiteColor;
            cell.dividerColor = UIColorFromRGB(color_tint_gray);
        }
        if (cell)
        {
            cell.dividerHight = 1. / [UIScreen mainScreen].scale;

            if (indexPath.row == 0 || indexPath.row == [self.tableView numberOfRowsInSection:indexPath.section] - 1)
                cell.dividerInsets = UIEdgeInsetsZero;
            else
                cell.dividerInsets = UIEdgeInsetsMake(0., 20. + [OAUtilities getLeftMargin], 0., 0.);
        }
        outCell = cell;
    }

    if ([outCell needsUpdateConstraints])
        [outCell updateConstraints];

    return outCell;
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return UITableViewAutomaticDimension;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"key"] hasSuffix:@"_input_cell"])
        [self showKeyboardForCellForIndexPath:indexPath];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

- (BOOL) textFieldShouldClear:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
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
