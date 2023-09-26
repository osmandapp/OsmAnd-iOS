//
//  OAOsmUploadPOIViewController.m
//  OsmAnd Maps
//
//  Created by Dmitry Svetlichny on 21.09.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAOsmUploadPOIViewController.h"
#import "OATableDataModel.h"
#import "OATableSectionData.h"
#import "OATableRowData.h"
#import "OAInputTableViewCell.h"
#import "OASwitchTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "OAMappersViewController.h"
#import "OAUploadOsmPointsAsyncTask.h"
#import "OAOsmEditingPlugin.h"
#import "OAOpenStreetMapPoint.h"
#import "OAEditPOIData.h"

@interface OAOsmUploadPOIViewController () <UITextFieldDelegate, OAAccountSettingDelegate>

@end

@implementation OAOsmUploadPOIViewController
{
    OATableDataModel *_data;
    NSArray *_osmPoints;
    
    NSString *_messageText;
    
    BOOL _closeChangeset;
    BOOL _isAuthorised;
}

#pragma mark - Initialization

- (instancetype)initWithPOIItems:(NSArray<OAOsmPoint *> *)points
{
    self = [super init];
    if (self)
    {
        _osmPoints = points;
        _closeChangeset = NO;
        
        for (OAOsmPoint *p in _osmPoints)
        {
            if (p.getGroup == POI)
            {
                _closeChangeset = YES;
                break;
            }
        }
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

#pragma mark - UIViewController

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (!_isAuthorised)
        [OAOsmOAuthHelper showAuthIntroScreenWithHostVC:self];
}

#pragma mark - Base UI

- (NSString *)getTitle
{
    return OALocalizedString(@"upload_poi");
}

- (NSString *)getLeftNavbarButtonTitle
{
    return OALocalizedString(@"shared_string_cancel");
}

- (NSString *)getBottomButtonTitle
{
    return OALocalizedString(@"shared_string_upload");
}

- (EOABaseButtonColorScheme)getBottomButtonColorScheme
{
    return _isAuthorised ? EOABaseButtonColorSchemePurple : EOABaseButtonColorSchemeInactive;
}

#pragma mark - Table data

- (void)generateData
{
    _data = [[OATableDataModel alloc] init];
    __weak OAOsmUploadPOIViewController *weakSelf = self;
    _messageText = !_messageText || _messageText.length == 0 ? [self generateMessage] : _messageText;
    
    OATableSectionData *messageSection = [_data createNewSection];
    messageSection.headerText = OALocalizedString(@"osb_comment_dialog_message");
    OATableRowData *messageTextInputCell = [messageSection createNewRow];
    [messageTextInputCell setCellType:[OAInputTableViewCell getCellIdentifier]];
    [messageTextInputCell setTitle:_messageText];
    
    OATableSectionData *closeChangesetSection = [_data createNewSection];
    OATableRowData *closeChangesetCell = [closeChangesetSection createNewRow];
    [closeChangesetCell setCellType:[OASwitchTableViewCell getCellIdentifier]];
    [closeChangesetCell setKey:@"close_changeset"];
    [closeChangesetCell setTitle:OALocalizedString(@"close_changeset")];
    [closeChangesetCell setObj:@(_closeChangeset) forKey:@"value"];
    
    OATableSectionData *accountSection = [_data createNewSection];
    accountSection.headerText = OALocalizedString(@"login_account");
    OATableRowData *accountCell = [accountSection createNewRow];
    [accountCell setCellType:[OASimpleTableViewCell getCellIdentifier]];
    [accountCell setTitle: _isAuthorised ? [OAOsmOAuthHelper getUserDisplayName] : OALocalizedString(@"login_open_street_map_org")];
    [accountCell setIconName:@"ic_custom_user_profile"];
    [accountCell setObj:(_isAuthorised ? UIColor.blackColor : UIColorFromRGB(color_primary_purple)) forKey:@"title_color"];
    [accountCell setObj:([UIFont systemFontOfSize:17. weight:_isAuthorised ? UIFontWeightRegular : UIFontWeightMedium]) forKey:@"title_font"];
    [accountCell setObj:(_isAuthorised ? @(UITableViewCellAccessoryDisclosureIndicator) : @(UITableViewCellAccessoryNone)) forKey:@"accessory_type"];
    [accountCell setObj: (^void(){ [weakSelf onAccountButtonPressed]; }) forKey:@"actionBlock"];
}

- (NSString *)generateMessage
{
    NSMutableDictionary<NSString *, NSNumber *> *addGroup = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, NSNumber *> *editGroup = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, NSNumber *> *deleteGroup = [NSMutableDictionary new];
    NSMutableString *comment = [NSMutableString new];
    for (NSInteger i = 0; i < _osmPoints.count; i++)
    {
        OAOpenStreetMapPoint *p = _osmPoints[i];
        NSString *type = [[OAEditPOIData alloc] initWithEntity:((OAOpenStreetMapPoint *) p).getEntity].getCurrentPoiType.nameLocalizedEN;
        if (!type || type.length == 0)
            continue;
        
        switch (p.getAction) {
            case CREATE:
            {
                if (!addGroup[type])
                    [addGroup setObject:@(1) forKey:type];
                else
                    [addGroup setObject:@(addGroup[type].integerValue + 1)  forKey:type];
                break;
            }
            case MODIFY:
            {
                if (!editGroup[type])
                    [editGroup setObject:@(1) forKey:type];
                else
                    [editGroup setObject:@(editGroup[type].integerValue + 1)  forKey:type];
                break;
            }
            case DELETE:
            {
                if (!deleteGroup[type])
                    [deleteGroup setObject:@(1) forKey:type];
                else
                    [deleteGroup setObject:@(deleteGroup[type].integerValue + 1)  forKey:type];
                break;
            }
            default:
                break;
        }
    }
    NSInteger modifiedItemsOutOfLimit = 0;
    for (NSInteger i = 0; i < 3; i++)
    {
        NSString *action;
        NSMutableDictionary<NSString *, NSNumber *> *group;
        switch (i) {
            case CREATE:
            {
                action = @"Add";
                group = addGroup;
                break;
            }
            case MODIFY:
            {
                action = @"Edit";
                group = editGroup;
                break;
            }
            case DELETE:
            {
                action = @"Delete";
                group = deleteGroup;
                break;
            }
            default:
            {
                action = @"";
                group = [NSMutableDictionary new];
                break;
            }
        }
        
        if (group.count > 0)
        {
            NSInteger pos = 0;
            for (NSString *key in group.allKeys)
            {
                NSInteger quantity = group[key].integerValue;
                if (comment.length > 200)
                    modifiedItemsOutOfLimit += quantity;
                else
                {
                    if (pos == 0)
                    {
                        [comment appendString:(comment.length == 0 ? @"" : @"; ")];
                        [comment appendString:action];
                        [comment appendString:@" "];
                        [comment appendString:(quantity == 1 ? @"" : [NSString stringWithFormat:@"%ld ", quantity])];
                        [comment appendString:key];
                    } else
                    {
                        [comment appendString:@", "];
                        [comment appendString:(quantity == 1 ? @"" : [NSString stringWithFormat:@"%ld ", quantity])];
                        [comment appendString:key];
                    }
                }
                pos++;
            }
        }
    }
    if (modifiedItemsOutOfLimit != 0)
    {
        [comment appendString:@"; "];
        [comment appendString:[NSString stringWithFormat:@"%ld ", modifiedItemsOutOfLimit]];
        [comment appendString:@"items modified."];
    }
    else if (comment.length > 0)
        [comment appendString:@"."];
    
    return [NSString stringWithString:comment];
}

- (NSString *)getTitleForHeader:(NSInteger)section;
{
    return [_data sectionDataForIndex:section].headerText;
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
            cell.inputField.tag = [item integerForKey:@"tag"];
        }
        return cell;
    }
    else if ([cellType isEqualToString:[OASwitchTableViewCell getCellIdentifier]])
    {
        OASwitchTableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:[OASwitchTableViewCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OASwitchTableViewCell getCellIdentifier] owner:self options:nil];
            cell = (OASwitchTableViewCell *)[nib objectAtIndex:0];
            [cell descriptionVisibility:NO];
            [cell leftIconVisibility:NO];
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
}

#pragma mark - Selectors

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
            BOOL isChecked = ((UISwitch *) sender).on;
            if ([key isEqualToString:@"close_changeset"])
                _closeChangeset = isChecked;
        }
    }
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

- (void)onBottomButtonPressed
{
    if (_isAuthorised)
    {
        OAUploadOsmPointsAsyncTask *uploadTask = [[OAUploadOsmPointsAsyncTask alloc] initWithPlugin:(OAOsmEditingPlugin *)[OAPlugin getPlugin:OAOsmEditingPlugin.class] points:_osmPoints closeChangeset:_closeChangeset anonymous:NO comment:_messageText bottomSheetDelegate:self.delegate controller:self];
        [uploadTask uploadPoints];
        
        if ([self.delegate respondsToSelector:@selector(dismissEditingScreen)])
            [self.delegate dismissEditingScreen];
    }
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    return YES;
}

- (void)textViewDidChange:(UITextView *)textView
{
    _messageText = textView.text;
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
