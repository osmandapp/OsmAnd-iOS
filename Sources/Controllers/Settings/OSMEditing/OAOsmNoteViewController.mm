//
//  OAOsmNoteViewController.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 22.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAOsmNoteViewController.h"
#import "OAUploadOsmPOINoteViewProgressController.h"
#import "Localization.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OATextMultilineTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OAOsmNotePoint.h"
#import "OAMapPanelViewController.h"
#import "OAMapViewController.h"
#import "OARootViewController.h"
#import "OAOsmEditingPlugin.h"
#import "OAMapLayers.h"
#import "OAUploadOsmPointsAsyncTask.h"
#import "OAOsmBugsUtilsProtocol.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAMappersViewController.h"
#import "GeneratedAssetSymbols.h"

@interface OAOsmNoteViewController () <UITextViewDelegate, OAAccountSettingDelegate, OAUploadTaskDelegate>

@end

@implementation OAOsmNoteViewController
{
    OATableDataModel *_data;
    NSArray *_bugPoints;
    
    OAOsmEditingPlugin *_plugin;
    EOAOSMNoteScreenType _screenType;
    OAUploadOsmPOINoteViewProgressController *_progressController;
    
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
        _messageText = ((OAOsmNotePoint *)_bugPoints.firstObject).getText;
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
    if (_screenType == EOAOsmNoteViewConrollerModeCreate && _messageText.length > 0)
        return OALocalizedString(@"edit_osm_note");
    else if (_screenType == EOAOsmNoteViewConrollerModeCreate)
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
    __weak OAOsmNoteViewController *weakSelf = self;
    
    OATableSectionData *textSection = [_data createNewSection];
    textSection.headerText = OALocalizedString(@"osn_bug_name");
    OATableRowData *textInputCell = [textSection createNewRow];
    [textInputCell setCellType:[OATextMultilineTableViewCell getCellIdentifier]];
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
            [accountCell setObj:(_isAuthorised ? [UIColor colorNamed:ACColorNameTextColorPrimary] : [UIColor colorNamed:ACColorNameIconColorActive]) forKey:@"title_color"];
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
    
    if ([cellType isEqualToString:[OATextMultilineTableViewCell getCellIdentifier]])
    {
        OATextMultilineTableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:[OATextMultilineTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OATextMultilineTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OATextMultilineTableViewCell *) nib[0];
            [cell leftIconVisibility:NO];
            [cell clearButtonVisibility:NO];
            cell.textView.userInteractionEnabled = YES;
            cell.textView.editable = YES;
            cell.textView.delegate = self;
            cell.textView.returnKeyType = UIReturnKeyDefault;
            cell.textView.enablesReturnKeyAutomatically = YES;
            cell.textView.autocapitalizationType = UITextAutocapitalizationTypeNone;
            cell.textView.autocorrectionType = UITextAutocorrectionTypeNo;
            cell.textView.spellCheckingType = UITextSpellCheckingTypeNo;
            cell.textView.textAlignment = NSTextAlignmentNatural;
            cell.textView.accessibilityLabel = OALocalizedString(@"osn_bug_name");
        }
        if (cell)
        {
            cell.textView.text = item.title;
            if (_screenType != EOAOsmNoteViewConrollerModeUpload)
                [cell.textView becomeFirstResponder];
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
            cell.leftIconView.tintColor = [UIColor colorNamed:ACColorNameIconColorActive];
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

- (void)showActionSheet
{
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *destructiveAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_discard_changes") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [super onLeftNavbarButtonPressed];
    }];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:OALocalizedString(@"shared_string_cancel") style:UIAlertActionStyleCancel handler:nil];
    
    [actionSheet addAction:destructiveAction];
    [actionSheet addAction:cancelAction];
    
    UIPopoverPresentationController *popover = actionSheet.popoverPresentationController;
    popover.barButtonItem = self.navigationItem.leftBarButtonItem;
    popover.permittedArrowDirections = UIPopoverArrowDirectionAny;
    
    [self presentViewController:actionSheet animated:YES completion:nil];
}

#pragma mark - Selectors

- (void)onLeftNavbarButtonPressed
{
    if (_isNoteTextChanged)
        [self showActionSheet];
    else
        [super onLeftNavbarButtonPressed];
}

- (void)onBottomButtonPressed
{
    [self.view endEditing:YES];
    
    [(OAOsmNotePoint *) _bugPoints.firstObject setText:_messageText];
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
        OAUploadOsmPointsAsyncTask *task = [[OAUploadOsmPointsAsyncTask alloc] initWithPlugin:_plugin points:_bugPoints closeChangeset:NO anonymous:_uploadAnonymously comment:nil];
        _progressController = [[OAUploadOsmPOINoteViewProgressController alloc] initWithParam:task];
        _progressController.delegate = self.delegate;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:_progressController];
        navigationController.modalPresentationStyle = UIModalPresentationCustom;
        [self presentViewController:navigationController animated:YES completion:^{
            task.delegate = self;
            [task uploadPoints];
        }];
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

#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    [textView resignFirstResponder];
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    _messageText = textView.text;
    _isNoteTextChanged = YES;
    [self setupBottomButtons];
    [textView sizeToFit];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
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

#pragma mark - OAUploadTaskDelegate

- (void)uploadDidProgress:(float)progress
{
    [_progressController setProgress:progress];
}

- (void)uploadDidFinishWithFailedPoints:(NSArray<OAOsmPoint *> *)points successfulUploads:(NSInteger)successfulUploads
{
    [_progressController setUploadResultWithFailedPoints:points successfulUploads:successfulUploads];
}

- (void)uploadDidCompleteWithSuccess:(BOOL)success
{
    [self dismissViewController];
    if ([self.delegate respondsToSelector:@selector(uploadFinished:)])
        [self.delegate uploadFinished:!success];
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
