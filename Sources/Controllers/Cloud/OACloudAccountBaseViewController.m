//
//  OACloudAccountBaseViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 17.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudAccountBaseViewController.h"
#import "Localization.h"
#import "OAColors.h"
#import "OATableViewCustomHeaderView.h"
#import "OADescrTitleCell.h"
#import "OAInputCellWithTitle.h"
#import "OAFilledButtonCell.h"
#import "OADividerCell.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface OACloudAccountBaseViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MFMailComposeViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *footerTitleLabel;

@end

@implementation OACloudAccountBaseViewController
{
    NSString *_inputText;
    NSString *_footerFullText;
    NSString *_footerColoredText;
}

- (instancetype) init
{
    self = [super initWithNibName:@"OACloudAccountBaseViewController" bundle:nil];
    if (self) {
        _inputText = @"";
        _errorMessage = @"";
        [self generateData];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTableHeaderView];
    [self setupTableFooterView];
    [self applyLocalization];
    _inputText = [OAAppSettings.sharedManager.backupUserEmail get];
    [self generateData];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.backButton.hidden = YES;
    self.backImageButton.hidden = NO;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self setupTableHeaderView];
        [self generateData];
        [self.tableView reloadData];
    } completion:nil];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleDefault;
}

- (void) setupTableHeaderView
{
    self.tableView.tableHeaderView = [OAUtilities setupTableHeaderViewWithText:[self getTableHeaderTitle] font:[UIFont systemFontOfSize:34.0 weight:UIFontWeightBold] textColor:UIColor.blackColor lineSpacing:0 isTitle:YES];
}

- (void) setupTableFooterView
{
    NSString *fullText = _footerFullText;
    NSString *coloredPart = _footerColoredText;
    NSRange fullRange = NSMakeRange(0, fullText.length);
    NSRange coloredRange = [fullText rangeOfString:coloredPart];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:fullText];
    UIFont *font = [UIFont systemFontOfSize:15];
    [attributedString addAttribute:NSFontAttributeName value:font range:fullRange];
    [attributedString addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_text_footer) range:fullRange];
    [attributedString addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_primary_purple) range:coloredRange];
    self.footerTitleLabel.attributedText = attributedString;
}

#pragma mark - Data section

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"user_login");
}

- (NSString *) getTextFieldValue
{
    return _inputText;
}

- (void) applyLocalization
{
    _footerFullText = OALocalizedString(@"login_footer_full_text");
    _footerColoredText = OALocalizedString(@"login_footer_email_part");
    self.titleLabel.text = [self getTableHeaderTitle];
}

- (void) generateData
{
    //override
}

- (NSArray<NSArray<NSDictionary *> *> *) getData
{
    return nil; //override
}

- (NSDictionary *) getItem:(NSIndexPath *)indexPath
{
    return [self getData][indexPath.section][indexPath.row];
}

- (void) updateScreen
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self generateData];
        [self.tableView reloadData];
    });
}

#pragma mark - Actions

- (void) textFieldDoneButtonPressed
{
    //override
}

- (void) continueButtonPressed
{
    //override
}

- (IBAction)footerButtonPressed:(id)sender
{
    [self sendEmail];
}

- (BOOL) isValidInputValue:(NSString *)value
{
    return value.length > 0 && self.errorMessage.length == 0;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self getData].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self getData][section].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OADescrTitleCell getCellIdentifier]])
    {
        OADescrTitleCell* cell;
        cell = (OADescrTitleCell *)[tableView dequeueReusableCellWithIdentifier:[OADescrTitleCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADescrTitleCell getCellIdentifier] owner:self options:nil];
            cell = (OADescrTitleCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.contentView.backgroundColor = UIColor.clearColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.descriptionView.backgroundColor = UIColor.clearColor;
            cell.textViewZeroHeightConstraint.priority = 1000;
            cell.textView.hidden = YES;
        }
        if (cell)
        {
            NSString *text = item[@"title"];
            NSRange range = NSMakeRange(0, text.length);
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text];
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.lineSpacing = [item[@"spacing"] intValue];
            [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
            
            int fontSize = item[@"fontSize"] ? [item[@"fontSize"] intValue] : 15;
            [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:fontSize] range:range];
            [attributedString addAttribute:NSForegroundColorAttributeName value:item[@"color"] range:range];
            
            NSString *boldPart = item[@"boldPart"];
            if (boldPart && boldPart.length > 0)
            {
                NSRange boldRange = [text rangeOfString:boldPart];
                [attributedString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold] range:boldRange];
                [attributedString addAttribute:NSForegroundColorAttributeName value:UIColor.blackColor range:boldRange];
            }
            
            cell.descriptionView.attributedText = attributedString;
            cell.topConstraint.constant = [item[@"topMargin"] intValue];
            cell.bottomConstraint.constant = [item[@"bottomMargin"] intValue];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAInputCellWithTitle getCellIdentifier]])
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
            cell.titleLabel.text = item[@"placeholder"];
            cell.titleLabel.textColor = UIColorFromRGB(color_text_footer);
            NSString *text =  item[@"title"];
            cell.inputField.text = text;
            cell.inputField.textContentType = UITextContentTypeEmailAddress;
            if ([item[@"numbersKeyboard"] boolValue])
                cell.inputField.keyboardType = UIKeyboardTypePhonePad;
            else
                cell.inputField.keyboardType = UIKeyboardTypeEmailAddress;
            cell.inputField.returnKeyType = UIReturnKeyGo;
            cell.inputField.textAlignment = NSTextAlignmentRight;
            cell.inputField.autocorrectionType = UITextAutocorrectionTypeNo;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAFilledButtonCell getCellIdentifier]])
    {
        OAFilledButtonCell* cell;
        cell = (OAFilledButtonCell *)[self.tableView dequeueReusableCellWithIdentifier:[OAFilledButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAFilledButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAFilledButtonCell *)[nib objectAtIndex:0];
        }
        if (cell)
        {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.backgroundColor = UIColor.clearColor;
            [cell.button setBackgroundColor:item[@"buttonColor"]];
            [cell.button setTitleColor:item[@"textColor"] forState:UIControlStateNormal];
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            cell.button.userInteractionEnabled = [item[@"inteactive"] boolValue];
            cell.button.layer.cornerRadius = 9;
            cell.topMarginConstraint.constant = item[@"topMargin"] ? [item[@"topMargin"] intValue] : 20;
            cell.bottomMarginConstraint.constant = 0;
            cell.heightConstraint.constant = 42;
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self action:NSSelectorFromString(item[@"action"]) forControlEvents:UIControlEventTouchUpInside];
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        OADividerCell* cell = [tableView dequeueReusableCellWithIdentifier:[OADividerCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OADividerCell getCellIdentifier] owner:self options:nil];
            cell = (OADividerCell *)[nib objectAtIndex:0];
            cell.backgroundColor = UIColor.clearColor;
            cell.dividerColor = UIColorFromRGB(color_divider_blur);
            cell.dividerInsets = UIEdgeInsetsZero;
            cell.dividerHight = 1.0 / [UIScreen mainScreen].scale;
        }
        return cell;
    }
    else if ([item[@"type"] isEqualToString:[OAButtonCell getCellIdentifier]])
    {
        OAButtonCell* cell = [tableView dequeueReusableCellWithIdentifier:[OAButtonCell getCellIdentifier]];
        if (cell == nil)
        {
            NSArray *nib = [[NSBundle mainBundle] loadNibNamed:[OAButtonCell getCellIdentifier] owner:self options:nil];
            cell = (OAButtonCell *)[nib objectAtIndex:0];
            [cell showImage:NO];
        }
        if (cell)
        {
            [cell.button setTitle:item[@"title"] forState:UIControlStateNormal];
            [cell.button setTitleColor:item[@"color"] forState:UIControlStateNormal];
            [cell.button removeTarget:nil action:NULL forControlEvents:UIControlEventAllEvents];
            [cell.button addTarget:self action:NSSelectorFromString(item[@"action"]) forControlEvents:UIControlEventTouchUpInside];
            cell.backgroundColor = UIColor.clearColor;
        }
        return cell;
    }

    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary *item = [self getItem:indexPath];
    if ([item[@"type"] isEqualToString:[OADividerCell getCellIdentifier]])
    {
        return 1.0 / [UIScreen mainScreen].scale;
    }
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.001;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.001;
}


#pragma mark - UITextFieldDelegate

- (BOOL) textFieldShouldReturn:(UITextField *)sender
{
    [sender resignFirstResponder];
    [self textFieldDoneButtonPressed];
    return YES;
}

- (void)updateAllSections
{
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (NSInteger i = 1; i < self.tableView.numberOfSections; i++)
        [indexSet addIndex:i];
    [self.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void) textViewDidChange:(UITextField *)textField
{
    BOOL needFullReload = (_inputText.length == 0 && textField.text.length > 0) || (_inputText.length > 0 && textField.text.length == 0);
    _inputText = textField.text;
    BOOL hadError = _errorMessage.length > 0;
    self.errorMessage = @"";
    [self generateData];
    if (hadError)
    {
        [self.tableView performBatchUpdates:^{
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self updateAllSections];
        } completion:nil];
    }
    else if (needFullReload)
    {
        [self updateAllSections];
    }
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

#pragma mark - MFMailComposeViewControllerDelegate

- (void)sendEmail
{
    if([MFMailComposeViewController canSendMail])
    {
        MFMailComposeViewController *mailCont = [[MFMailComposeViewController alloc] init];
        mailCont.mailComposeDelegate = self;
        [mailCont setSubject:OALocalizedString(@"login_help_email_title")];
        [mailCont setToRecipients:[NSArray arrayWithObject:OALocalizedString(@"login_footer_email_part")]];
        [mailCont setMessageBody:@"" isHTML:NO];
        [self presentViewController:mailCont animated:YES completion:nil];
    }
}

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
