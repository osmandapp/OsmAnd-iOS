//
//  OAOsmEditingSettingsViewController.m
//  OsmAnd
//
//  Created by Paul on 8/29/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAOsmEditingSettingsViewController.h"
#import "OASettingsTableViewCell.h"
#import "OASettingsTitleTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAAppSettings.h"
#import "Localization.h"
#import "OAUtilities.h"
#import "OsmAndApp.h"
#import "PXAlertView.h"
#import "OASettingsViewController.h"
#import "OATextInputCell.h"
#import "OAButtonCell.h"
#import "OAColors.h"


#define kCellTypeSwitch @"switch"
#define kCellTypeSingleSelectionList @"single_selection_list"
#define kCellTypeMultiSelectionList @"multi_selection_list"
#define kCellTypeButton @"button"
#define kCellTypeTextInput @"text_input_cell"

@interface OAOsmEditingSettingsViewController () <UITextFieldDelegate>

@end

@implementation OAOsmEditingSettingsViewController
{
    NSArray *_credentialsSectionData;
    NSArray *_offlineModeSectionData;
    
    OATextInputCell *_passwordCell;
    OATextInputCell *_userNameCell;
    OAButtonCell *_buttonCell;
    
    UITextField *_textFieldBeingEdited;
    BOOL _isInEditingMode;
    
    OAAppSettings *_settings;
}

static const NSInteger credentialsSectionIndex = 0;
static const NSInteger offlineSectionIndex = 1;
static const NSInteger sectionCount = 2;

-(void) applyLocalization
{
    _titleView.text = OALocalizedString(@"product_title_osm_editing");
    [_backButton setTitle:OALocalizedString(@"shared_string_back") forState:UIControlStateNormal];
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    _settings = [OAAppSettings sharedManager];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputCell" owner:self options:nil];
    _userNameCell = (OATextInputCell *)[nib objectAtIndex:0];
    _userNameCell.inputField.text = _settings.osmUserName;
    _userNameCell.inputField.textColor = UIColorFromRGB(color_dialog_text_description_color);
    _userNameCell.inputField.placeholder = OALocalizedString(@"osm_name");
    _userNameCell.inputField.delegate = self;
    _userNameCell.userInteractionEnabled = NO;
    
    nib = [[NSBundle mainBundle] loadNibNamed:@"OATextInputCell" owner:self options:nil];
    _passwordCell = (OATextInputCell *)[nib objectAtIndex:0];
    _passwordCell.inputField.text = _settings.osmUserPassword;
    _passwordCell.inputField.textColor = UIColorFromRGB(color_dialog_text_description_color);
    _passwordCell.inputField.placeholder = OALocalizedString(@"shared_string_password");
    _passwordCell.inputField.delegate = self;
    _passwordCell.inputField.secureTextEntry = YES;
    _passwordCell.userInteractionEnabled = NO;
    
    _buttonCell = [self getButtonCell];
}

- (OAButtonCell *) getButtonCell
{
    static NSString* const identifierCell = @"OAButtonCell";
    OAButtonCell* cell = nil;
    
    cell = [self.tableView dequeueReusableCellWithIdentifier:identifierCell];
    if (cell == nil)
    {
        NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OAButtonCell" owner:self options:nil];
        cell = (OAButtonCell *)[nib objectAtIndex:0];
    }
    if (cell)
    {
        [cell.button setTitle:OALocalizedString(@"shared_string_edit") forState:UIControlStateNormal];
        [cell.button addTarget:self action:@selector(editPressed) forControlEvents:UIControlEventTouchDown];
    }
    return cell;
}

- (void) didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewWillAppear:(BOOL)animated
{
    [self setupView];
}

-(UIView *) getTopView
{
    return _navBarView;
}

-(UIView *) getMiddleView
{
    return _tableView;
}

- (void) setupView
{
    [self applySafeAreaMargins];
    NSMutableArray *dataArr = [NSMutableArray array];
    
    [dataArr addObject:
     @{
       @"name" : @"username_input",
       @"type" : kCellTypeTextInput }];
    
    [dataArr addObject:
     @{
       @"name" : @"password_input",
       @"type" : kCellTypeTextInput }];
    
    [dataArr addObject:
     @{
       @"name" : @"edit_credentials",
       @"type" : kCellTypeButton
       }];
    
    _credentialsSectionData = [NSArray arrayWithArray:dataArr];
    
    [dataArr removeAllObjects];
    
    [dataArr addObject:
     @{
       @"name" : @"offline_editing",
       @"type" : kCellTypeSwitch,
       @"title" : OALocalizedString(@"osm_offline_editing"),
       @"value" : @(_settings.offlineEditing)
       }];
    
    _offlineModeSectionData = [NSArray arrayWithArray:dataArr];
    
    [self.tableView reloadData];
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    if (indexPath.section == credentialsSectionIndex)
        return _credentialsSectionData[indexPath.row];
    else if (indexPath.section == offlineSectionIndex)
        return _offlineModeSectionData[indexPath.row];
    
    return nil;
}

- (void) applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        NSDictionary *item = [self getItem:indexPath];

        BOOL isChecked = ((UISwitch *) sender).on;
        NSString *name = item[@"name"];
        
        if ([name isEqualToString:@"offline_editing"])
            [_settings setOfflineEditing:isChecked];
    }
}

- (void) editPressed
{
    if (_isInEditingMode)
    {
        NSLog(@"%@ %@", _userNameCell.textLabel.text, _passwordCell.textLabel.text);
        if (_textFieldBeingEdited)
            [_textFieldBeingEdited resignFirstResponder];
        [_buttonCell.button setTitle:OALocalizedString(@"shared_string_edit") forState:UIControlStateNormal];
        [_settings setOsmUserName:_userNameCell.inputField.text];
        [_settings setOsmUserPassword:_passwordCell.inputField.text];
        _passwordCell.inputField.textColor = UIColorFromRGB(color_dialog_text_description_color);
        _userNameCell.inputField.textColor = UIColorFromRGB(color_dialog_text_description_color);
    }
    else
    {
        [_buttonCell.button setTitle:OALocalizedString(@"shared_string_save") forState:UIControlStateNormal];
        [_userNameCell.inputField becomeFirstResponder];
        _passwordCell.inputField.textColor = [UIColor blackColor];
        _userNameCell.inputField.textColor = [UIColor blackColor];
    }
    _isInEditingMode = !_isInEditingMode;
    _userNameCell.userInteractionEnabled = _isInEditingMode;
    _passwordCell.userInteractionEnabled = _isInEditingMode;
    
}

#pragma mark - UITableViewDataSource

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView
{
    return sectionCount;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == credentialsSectionIndex)
        return _credentialsSectionData.count;
    else if (section == offlineSectionIndex)
        return _offlineModeSectionData.count;
    else
        return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:kCellTypeSwitch])
    {
        static NSString* const identifierCell = @"OASwitchTableViewCell";
        OASwitchTableViewCell* cell = nil;
        
        cell = [tableView dequeueReusableCellWithIdentifier:identifierCell];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:@"OASwitchCell" owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            cell.textView.numberOfLines = 0;
        }
        
        if (cell)
        {
            [cell.textView setText: item[@"title"]];
            id v = item[@"value"];
            
            cell.switchView.on = [v boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([type isEqualToString:kCellTypeTextInput])
    {
        if ([item[@"name"] isEqualToString:@"username_input"])
            return _userNameCell;
        if ([item[@"name"] isEqualToString:@"password_input"])
            return _passwordCell;
    }
    else if ([type isEqualToString:kCellTypeButton])
    {
        return _buttonCell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    NSString *type = item[@"type"];
    
    if ([type isEqualToString:kCellTypeSwitch])
    {
        return [OASwitchTableViewCell getHeight:item[@"title"] cellWidth:tableView.bounds.size.width];
    }
    else
    {
        return 44.0;
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == credentialsSectionIndex)
        return OALocalizedString(@"osm_editing_login_and_pass");
    else if (section == offlineSectionIndex)
        return OALocalizedString(@"osm_editing_offline");
    else
        return @"";
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

#pragma mark - UITextFieldDelegate

- (void) textFieldDidBeginEditing:(UITextField *)textField
{
    _textFieldBeingEdited = textField;
}

- (void) textFieldDidEndEditing:(UITextField *)textField
{
    _textFieldBeingEdited = nil;
}

- (BOOL) textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

@end
