//
//  OACreateUploadOsmNoteViewController.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 22.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OACreateUploadOsmNoteViewController.h"
#import "Localization.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAInputTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAOsmNotePoint.h"
#import "OAMapPanelViewController.h"
#import "OARootViewController.h"
#import "OAOsmEditingPlugin.h"
#import "OAMapLayers.h"
#import "OAUploadOsmPointsAsyncTask.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAMappersViewController.h"

@interface OACreateUploadOsmNoteViewController () <UITextFieldDelegate, OAAccountSettingDelegate>

@end

@implementation OACreateUploadOsmNoteViewController
{
    OATableDataModel *_data;
    NSArray *_bugPoints;
    
    OAOsmEditingPlugin *_plugin;
    EOAOSMNoteScreenType _screenType;
    
    NSString *_messageText;
    
    BOOL _isNoteTextChanged;
    BOOL _uploadAnonymously;
    BOOL _isAuthorised;
}

#pragma mark - Initialization

- (instancetype)initWithEditingPlugin:(OAOsmEditingPlugin *)plugin points:(NSArray *)points type:(EOAOSMNoteScreenType)type
{
    self = [super init];

    if (self)
    {
        _bugPoints = points;
        _plugin = plugin;
        _screenType = type;
    }
    
    return self;
}

- (void)commonInit
{
    _isAuthorised = [OAOsmOAuthHelper isAuthorised];
}

- (void)registerNotifications
{
    [self addNotification:UIKeyboardWillShowNotification selector:@selector(keyboardWillShow:)];
    [self addNotification:UIKeyboardWillHideNotification selector:@selector(keyboardWillHide:)];
    [self addNotification:OAOsmOAuthHelper.notificationKey selector:@selector(onAccountInformationUpdated)];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    if (_screenType == EOAOsmNoteViewConrollerModeCreate)
        return OALocalizedString(@"context_menu_item_open_note");
    else if (_screenType == EOAOsmNoteViewConrollerModeUpload)
        return OALocalizedString(@"upload_osm_note");
    else if (_screenType == EOAOsmNoteViewConrollerModeReopen)
        return OALocalizedString(@"osm_note_reopen_title");
    else if (_screenType == EOAOsmNoteViewConrollerModeModify)
        return OALocalizedString(@"osm_edit_comment_note");
    return @"";
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSString *)getBottomButtonTitle
{
    return _screenType != EOAOsmNoteViewConrollerModeCreate ? OALocalizedString(@"shared_string_upload") : OALocalizedString(@"osn_add_dialog_title");
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    if (_screenType == EOAOsmNoteViewConrollerModeCreate)
        return _isNoteTextChanged ? EOABaseButtonColorSchemePurple : EOABaseButtonColorSchemeInactive;
    else
        return _isAuthorised || _uploadAnonymously ? EOABaseButtonColorSchemePurple : EOABaseButtonColorSchemeInactive;
}

- (BOOL)isNavbarSeparatorVisible
{
    return _screenType == EOAOsmNoteViewConrollerModeCreate ? NO : YES;
}

#pragma mark - Table data

- (void)generateData
{
    _data = [[OATableDataModel alloc] init];
    _messageText = ((OAOsmNotePoint *)_bugPoints.firstObject).getText;
    __weak OACreateUploadOsmNoteViewController *weakSelf = self;
    
    OATableSectionData *textSection = [_data createNewSection];
    textSection.headerText = OALocalizedString(@"osn_bug_name");
    OATableRowData *textInputCell = [textSection createNewRow];
    [textInputCell setCellType:[OAInputTableViewCell getCellIdentifier]];
    [textInputCell setTitle:_messageText];
    
    if (_screenType != EOAOsmNoteViewConrollerModeCreate)
    {
        OATableSectionData *accountSection = [_data createNewSection];
        accountSection.headerText = OALocalizedString(@"login_account");
        accountSection.footerText = OALocalizedString(@"osm_note_upload_info");
        
        OATableRowData *uploadAnonymouslyCell = [accountSection createNewRow];
        [uploadAnonymouslyCell setCellType:[OASwitchTableViewCell getCellIdentifier]];
        [uploadAnonymouslyCell setKey:@"upload_anonymously"];
        [uploadAnonymouslyCell setTitle:OALocalizedString(@"upload_anonymously")];
        [uploadAnonymouslyCell setObj:@(_uploadAnonymously) forKey:@"value"];
        
        if (!_uploadAnonymously)
        {
            OATableRowData *accountCell = [accountSection createNewRow];
            [accountCell setCellType:[OASimpleTableViewCell getCellIdentifier]];
            [accountCell setTitle: _isAuthorised ? [OAOsmOAuthHelper getUserDisplayName] : OALocalizedString(@"login_open_street_map_org")];
            [accountCell setIconName:@"ic_custom_user_profile"];
            [accountCell setObj:(_isAuthorised ? UIColor.blackColor : UIColorFromRGB(color_primary_purple)) forKey:@"title_color"];
            [accountCell setObj:([UIFont systemFontOfSize:17. weight:_isAuthorised ? UIFontWeightRegular : UIFontWeightMedium]) forKey:@"title_font"];
            [accountCell setObj:(_isAuthorised ? @(UITableViewCellAccessoryDisclosureIndicator) : @(UITableViewCellAccessoryNone)) forKey:@"accessory_type"];
            [accountCell setObj: (^void(){ [weakSelf onAccountButtonPressed]; }) forKey:@"actionBlock"];
        }
    }
}

- (NSString *)getTitleForHeader:(NSInteger)section;
{
    return [_data sectionDataForIndex:section].headerText;
}

- (NSString *)getTitleForFooter:(NSInteger)section
{
    return [_data sectionDataForIndex:section].footerText;
}

- (NSInteger)sectionsCount
{
    return _data.sectionCount;
}

- (NSInteger)rowsCount:(NSInteger)section
{
    return [_data rowCount:section];
}

- (UITableViewCell *)getRow:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    NSString *cellType = item.cellType;
    
    if ([cellType isEqualToString:[OAInputTableViewCell getCellIdentifier]])
    {
        OAInputTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OAInputTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAInputTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OAInputTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell titleVisibility:NO];
            [cell clearButtonVisibility:NO];
            [cell.inputField removeTarget:self action:NULL forControlEvents:UIControlEventEditingChanged];
            [cell.inputField addTarget:self action:@selector(textViewDidChange:) forControlEvents:UIControlEventEditingChanged];
            cell.inputField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            cell.inputField.autocorrectionType = UITextAutocorrectionTypeNo;
            cell.inputField.spellCheckingType = UITextSpellCheckingTypeNo;
            cell.inputField.textAlignment = NSTextAlignmentNatural;
        }
        if (cell)
        {
            cell.inputField.text = item.title;
            cell.inputField.delegate = self;
            cell.inputField.placeholder = OALocalizedString(@"rendering_attr_hideText_name");
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            cell.titleLabel.text = item.title;
            cell.switchView.on = [[item objForKey:@"value"] boolValue];
            cell.switchView.tag = indexPath.section << 10 | indexPath.row;
            [cell.switchView removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
            [cell.switchView addTarget:self action:@selector(applyParameter:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    }
    else if ([cellType isEqualToString:OASimpleTableViewCell.getCellIdentifier])
    {
        OASimpleTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OASimpleTableViewCell getCellIdentifier]];
        if (!cell)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASimpleTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASimpleTableViewCell *) nib[0];
            [cell leftIconVisibility:YES];
            [cell descriptionVisibility:NO];
        }
        if (cell)
        {
            NSString *title = item.title;
            [cell titleVisibility:title != nil];
            cell.titleLabel.text = title;
            cell.titleLabel.textColor = [item objForKey:@"title_color"];
            cell.titleLabel.font = [item objForKey:@"title_font"];
            cell.leftIconView.image = [UIImage templateImageNamed:item.iconName];
            cell.leftIconView.tintColor = UIColorFromRGB(color_primary_purple);
            cell.accessoryType = (UITableViewCellAccessoryType) [item integerForKey:@"accessory_type"];
            cell.accessibilityTraits = UIAccessibilityTraitButton;
        }
        return cell;
    }
    return nil;
}

- (void)onRowSelected:(NSIndexPath *)indexPath
{
    OATableRowData *item = [_data itemForIndexPath:indexPath];
    void (^actionBlock)() = [item objForKey:@"actionBlock"];
    if (actionBlock)
        actionBlock();
    [self setupBottomButtons];
}

#pragma mark - Aditions

- (void)saveNote
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        id<OAOsmBugsUtilsProtocol> util = [_plugin getLocalOsmNotesUtil];
        OAOsmNotePoint *p = _bugPoints.firstObject;
        if (!p)
            return;
        
        if (p.getAction == CREATE)
            [util commit:p text:p.getText action:p.getAction];
        else
            [util modify:p text:p.getText];
        
        OAOsmNotePoint *note = [[OAOsmNotePoint alloc] init];
        [note setLatitude:p.getLatitude];
        [note setLongitude:p.getLongitude];
        [note setId:p.getId];
        [note setText:p.getText];
        [note setAuthor:@""];
        [note setAction:p.getAction];
        dispatch_async(dispatch_get_main_queue(), ^{
            OAMapPanelViewController *mapPanel = [OARootViewController instance].mapPanel;
            OATargetPoint *newTarget = [mapPanel.mapViewController.mapLayers.osmEditsLayer getTargetPoint:note];
            [mapPanel showContextMenu:newTarget];
        });
    });
}

#pragma mark - Selectors

- (void)onBottomButtonPressed
{
    BOOL shouldWarn = _screenType != EOAOsmNoteViewConrollerModeUpload;
    BOOL shouldUpload = _screenType != EOAOsmNoteViewConrollerModeCreate;
    if (shouldWarn)
    {
        OAOsmNotePoint *p = _bugPoints.firstObject;
        NSString *comment = p.getText;
        if (!comment || comment.length == 0)
        {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:OALocalizedString(@"osm_note_empty_message") preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_ok") style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            _isNoteTextChanged = NO;
            return;
        }
    }
    if (shouldUpload)
    {
        OAUploadOsmPointsAsyncTask *task = [[OAUploadOsmPointsAsyncTask alloc] initWithPlugin:_plugin points:_bugPoints closeChangeset:NO anonymous:_uploadAnonymously comment:nil bottomSheetDelegate:self.delegate controller:self];
        [task uploadPoints];
    }
    else
    {
        [self saveNote];
    }
    
    [super onLeftNavbarButtonPressed];
    if ([self.delegate respondsToSelector:@selector(dismissEditingScreen)])
        [self.delegate dismissEditingScreen];
}

- (void)onAccountButtonPressed
{
    if (_isAuthorised)
    {
        OAOsmAccountSettingsViewController *accountSettings = [[OAOsmAccountSettingsViewController alloc] init];
        accountSettings.accountDelegate = self;
        [self showModalViewController:accountSettings];
    }
    else
    {
        [OAOsmOAuthHelper showAuthIntroScreenWithHostVC:self];
    }
}

- (void)applyParameter:(id)sender
{
    if ([sender isKindOfClass:[UISwitch class]])
    {
        UISwitch *sw = (UISwitch *) sender;
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:sw.tag & 0x3FF inSection:sw.tag >> 10];
        OATableRowData *item = [_data itemForIndexPath:indexPath];
        NSString *key = item.key;
        if (key)
        {
            BOOL isChecked = sw.on;
            if ([key isEqualToString:@"upload_anonymously"])
                _uploadAnonymously = isChecked;
        }
    }
    [self generateData];
    [self.tableView reloadData];
    [self setupBottomButtons];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    [(OAOsmNotePoint *) _bugPoints.firstObject setText:textView.text];
    _isNoteTextChanged = YES;
    [self setupBottomButtons];
}

#pragma mark - OAAccontSettingDelegate

- (void)onAccountInformationUpdated
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _isAuthorised = [OAOsmOAuthHelper isAuthorised];
        [self generateData];
        [self.tableView reloadData];
        [self setupBottomButtons];
    });
}

- (void)onAccountInformationUpdatedFromBenefits
{
    [self onAccountInformationUpdated];
    if (_isAuthorised)
    {
        OAMappersViewController *benefitsViewController = [[OAMappersViewController alloc] init];
        [self showModalViewController:benefitsViewController];
    }
}

#pragma mark - Keyboard Notifications

- (void)keyboardWillShow:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    NSValue *keyboardBoundsValue = userInfo[UIKeyboardFrameEndUserInfoKey];
    CGFloat keyboardHeight = [keyboardBoundsValue CGRectValue].size.height;
    
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.buttonsBottomOffsetConstraint.constant = keyboardHeight - [OAUtilities getBottomMargin];
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, keyboardHeight, insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification;
{
    NSDictionary *userInfo = [notification userInfo];
    CGFloat duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] floatValue];
    NSInteger animationCurve = [userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    UIEdgeInsets insets = [[self tableView] contentInset];
    [UIView animateWithDuration:duration delay:0. options:animationCurve animations:^{
        self.buttonsBottomOffsetConstraint.constant = 0;
        [[self tableView] setContentInset:UIEdgeInsetsMake(insets.top, insets.left, 0., insets.right)];
        [[self view] layoutIfNeeded];
    } completion:nil];
}

@end
