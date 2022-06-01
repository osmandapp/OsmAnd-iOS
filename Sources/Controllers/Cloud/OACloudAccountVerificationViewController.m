//
//  OACloudAccountVerificationViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 23.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudAccountVerificationViewController.h"
#import "OABackupHelper.h"
#import "OAAppSettings.h"
#import "OABackupListeners.h"
#import "OABackupError.h"
#import "OACloudBackupViewController.h"

#define VERIFICATION_CODE_EXPIRATION_TIME_MIN (10 * 60)

@interface OACloudAccountVerificationViewController () <OAOnRegisterUserListener, OAOnRegisterDeviceListener>

@end

@implementation OACloudAccountVerificationViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSString *_email;
    BOOL _isUnfoldPressed;
    
    long _lastTimeCodeSent;
    
    OABackupHelper *_backupHelper;
}

- (instancetype) initWithEmail:(NSString *)email
{
    self = [super init];
    if (self)
    {
        _email = email;
        _lastTimeCodeSent = 0;
        _backupHelper = OABackupHelper.sharedInstance;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_backupHelper.backupListeners addRegisterUserListener:self];
    [_backupHelper.backupListeners addRegisterDeviceListener:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_backupHelper.backupListeners removeRegisterUserListener:self];
    [_backupHelper.backupListeners removeRegisterDeviceListener:self];
}

#pragma mark - Data section

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"verification");
}

- (void) generateData
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray new];
    
    BOOL isTextFieldValidData = [self isValidInputValue:[self getTextFieldValue]];
    
    [data addObject:@[@{
        @"type" : [OADescrTitleCell getCellIdentifier],
        @"title" : [NSString stringWithFormat:OALocalizedString(@"verify_email_address_descr"), _email],
        @"boldPart" : _email ? _email : @"",
        @"color" : UIColorFromRGB(color_text_footer),
        @"spacing" : @6,
        @"topMargin" : @20,
        @"bottomMargin" : @14
    },
    @{ @"type" : [OADividerCell getCellIdentifier] },
    @{
        @"type" : [OAInputCellWithTitle getCellIdentifier],
        @"title" : @"",
        @"placeholder" : OALocalizedString(@"verification_code_placeholder"),
        @"numbersKeyboard" : @(YES)
    },
    @{ @"type" : [OADividerCell getCellIdentifier] } ]];
    
    NSMutableArray<NSDictionary *> *otherCells = [NSMutableArray array];
    
    if (self.errorMessage.length > 0)
    {
        [otherCells addObject:@{
            @"type" : [OADescrTitleCell getCellIdentifier],
            @"title" : self.errorMessage,
            @"color" : UIColorFromRGB(color_support_red),
            @"spacing" : @1,
            @"topMargin" : @14,
            @"bottomMargin" : @0
        }];
    }
    
    [otherCells addObject:@{
        @"type" : [OAButtonCell getCellIdentifier],
        @"title" : OALocalizedString(@"verification_code_missing"),
        @"color" : UIColorFromRGB(color_primary_purple),
        @"action" : @"unfoldButtonPressed",
    }];
    
    if (_isUnfoldPressed)
    {
        [otherCells addObject:@{
            @"type" : [OADescrTitleCell getCellIdentifier],
            @"title" : OALocalizedString(@"verification_code_missing_description"),
            @"color" : UIColorFromRGB(color_text_footer),
            @"spacing" : @1,
            @"topMargin" : @0,
            @"bottomMargin" : @0
        }];

        [otherCells addObject: @{
            @"type" : [OAFilledButtonCell getCellIdentifier],
            @"title" : OALocalizedString(@"resend_verification_code"),
            @"buttonColor" : UIColorFromRGB(color_bottom_sheet_secondary),
            @"textColor" : UIColorFromRGB(color_primary_purple),
            @"action": @"resendButtonPressed",
            @"inteactive" : @YES,
        }];
    }
    
    NSNumber *continueButtonTopMargin = _isUnfoldPressed ? @20 : @8;
    if (isTextFieldValidData)
    {
        [otherCells addObject: @{
            @"type" : [OAFilledButtonCell getCellIdentifier],
            @"title" : OALocalizedString(@"shared_string_continue"),
            @"buttonColor" : UIColorFromRGB(color_primary_purple),
            @"textColor" : UIColor.whiteColor,
            @"action" : @"continueButtonPressed",
            @"inteactive" : @YES,
            @"topMargin" : continueButtonTopMargin,
        }];
    }
    else
    {
        [otherCells addObject: @{
            @"type" : [OAFilledButtonCell getCellIdentifier],
            @"title" : OALocalizedString(@"shared_string_continue"),
            @"buttonColor" : UIColorFromRGB(color_bottom_sheet_secondary),
            @"textColor" : UIColorFromRGB(color_text_footer),
            @"action": @"continueButtonPressed",
            @"inteactive" : @NO,
            @"topMargin" : continueButtonTopMargin,
        }];
    }
    [data addObject:otherCells];
    _data = data;
}

- (NSArray<NSArray<NSDictionary *> *> *) getData
{
    return _data;
}

#pragma mark - Actions

- (void)toggleResendButton
{
    _isUnfoldPressed = !_isUnfoldPressed;
    int errorOffset = self.errorMessage.length > 0 ? 1 : 0;
    [self generateData];
    [self.tableView performBatchUpdates:^{
        if (_isUnfoldPressed)
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 + errorOffset inSection:1], [NSIndexPath indexPathForRow:2 + errorOffset inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
        else
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 + errorOffset inSection:1], [NSIndexPath indexPathForRow:2 + errorOffset inSection:1]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    } completion:nil];
}

- (void) unfoldButtonPressed
{
    if (_lastTimeCodeSent > 0 && NSDate.date.timeIntervalSince1970 - _lastTimeCodeSent >= VERIFICATION_CODE_EXPIRATION_TIME_MIN)
        [_backupHelper registerUser:[OAAppSettings.sharedManager.backupUserEmail get] promoCode:@"" login:YES];
    else
        [self toggleResendButton];
}

- (void) continueButtonPressed
{
    NSString *token = [self getTextFieldValue];
    if ([OABackupHelper isTokenValid:token])
    {
        [_backupHelper registerDevice:token];
    }
    else
    {
        self.errorMessage = OALocalizedString(@"backup_error_invalid_token");
        [self updateScreen];
        NSLog(@"Token is not valid");
    }
}

- (void) resendButtonPressed
{
    [_backupHelper registerUser:[OAAppSettings.sharedManager.backupUserEmail get] promoCode:@"" login:YES];
    [self toggleResendButton];
}

- (void) textFieldDoneButtonPressed
{
    [self continueButtonPressed];
}

- (BOOL) isValidInputValue:(NSString *)value
{
    return value.length > 0;
}

// MARK: OAOnRegisterUserListener

- (void)onRegisterUser:(NSInteger)status message:(NSString *)message error:(OABackupError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        _lastTimeCodeSent = NSDate.date.timeIntervalSince1970;
        if (status == STATUS_SUCCESS)
            [self.tableView reloadData];
    });
}

// MARK: OAOnRegisterDeviceListener

- (void)onRegisterDevice:(NSInteger)status message:(NSString *)message error:(OABackupError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (status == STATUS_SUCCESS)
        {
            OACloudBackupViewController *vc = [[OACloudBackupViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else {
            self.errorMessage = error != nil ? error.getLocalizedError : message;
            [self updateScreen];
        }
    });
}

@end
