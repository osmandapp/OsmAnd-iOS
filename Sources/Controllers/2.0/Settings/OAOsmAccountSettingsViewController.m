//
//  OAOsmAccountSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 06.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAOsmAccountSettingsViewController.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OAInputCellWithTitle.h"
#import "OAColors.h"

@interface OAOsmAccountSettingsViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@end

@implementation OAOsmAccountSettingsViewController
{
    OAAppSettings *_settings;
    
    NSString *_newUserName;
    NSString *_newPassword;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _settings = OAAppSettings.sharedManager;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _newUserName = _settings.osmUserName.get;
    _newPassword = _settings.osmUserPassword.get;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorColor = UIColorFromRGB(color_tint_gray);
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

- (void)applyLocalization
{
    self.titleView.text = _settings.osmUserName.get.length > 0 ? OALocalizedString(@"shared_string_account") : OALocalizedString(@"shared_string_account_add");
    [self.backButton setTitle:OALocalizedString(@"shared_string_cancel") forState:UIControlStateNormal];
    [self.doneButton setTitle:OALocalizedString(@"shared_string_done") forState:UIControlStateNormal];
}

- (NSString *) getTitleForIndex:(NSInteger)index
{
    return index == 0 ? OALocalizedString(@"shared_string_email") : OALocalizedString(@"shared_string_password");
}

- (NSString *) getTextForIndex:(NSInteger)index
{
    return index == 0 ? _settings.osmUserName.get : _settings.osmUserPassword.get;
}

- (NSString *) getHintForIndex:(NSInteger)index
{
    return index == 0 ? OALocalizedString(@"email_example_hint") : OALocalizedString(@"shared_string_required");
}

- (void)doneButtonPressed
{
    [_settings.osmUserName set:_newUserName];
    [_settings.osmUserPassword set:_newPassword];
    if (self.delegate)
        [self.delegate onAccountInformationUpdated];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) showKeyboardForCellForIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell && [cell isKindOfClass:OAInputCellWithTitle.class])
    {
        OAInputCellWithTitle *resCell = (OAInputCellWithTitle *) cell;
        [resCell.inputField becomeFirstResponder];
    }
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    OAInputCellWithTitle* cell = [tableView dequeueReusableCellWithIdentifier:[OAInputCellWithTitle getCellIdentifier]];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputCellWithTitle getCellIdentifier] owner:self options:nil];
        cell = (OAInputCellWithTitle *)[nib objectAtIndex:0];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
        cell.inputField.delegate = self;
    }
    if (cell)
    {
        cell.titleLabel.text = [self getTitleForIndex:indexPath.row];
        cell.titleLabel.textColor = [UIColor blackColor];
        NSString *text = [self getTextForIndex:indexPath.row];
        cell.inputField.text = text;
        cell.inputField.placeholder = [self getHintForIndex:indexPath.row];
        cell.inputField.textContentType = indexPath.row == 0 ? UITextContentTypeUsername : UITextContentTypePassword;
        cell.inputField.secureTextEntry = indexPath.row != 0;
        cell.inputField.tag = indexPath.row;
        cell.inputField.returnKeyType = UIReturnKeyDone;
        
        if (indexPath.row != 0)
        {
            if (@available(iOS 13.0, *))
                cell.inputField.font = [UIFont monospacedSystemFontOfSize:17 weight:UIFontWeightRegular];
            else
                cell.inputField.font = [UIFont monospacedDigitSystemFontOfSize:16 weight:UIFontWeightRegular];
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self showKeyboardForCellForIndexPath:indexPath];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

- (void) textViewDidChange:(UITextField *)textField
{
    if (textField.tag == 0)
        _newUserName = textField.text;
    else
        _newPassword = textField.text;
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
