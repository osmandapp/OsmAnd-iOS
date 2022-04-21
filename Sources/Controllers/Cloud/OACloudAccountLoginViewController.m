//
//  OACloudAccountLoginViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 22.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudAccountLoginViewController.h"
#import "OAAppSettings.h"
#import "OABackupHelper.h"
#import "OABackupListeners.h"
#import "OABackupError.h"
#import "OACloudAccountVerificationViewController.h"
#import "OACloudAccountCreateViewController.h"

@interface OACloudAccountLoginViewController () <OAOnRegisterUserListener, OAOnRegisterDeviceListener>

@end

@implementation OACloudAccountLoginViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    
    OABackupHelper *_backupHelper;
    
    BOOL _isEmailRegistered;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.lastTimeCodeSent = 0;
    
    _backupHelper = [OABackupHelper sharedInstance];
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
    return OALocalizedString(@"user_login");
}

- (void) generateData
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray new];
    
    BOOL isTextFieldValidData = [self isValidInputValue:[self getTextFieldValue]];
    _isEmailRegistered = ![self.errorMessage isEqualToString:OALocalizedString(@"cloud_email_not_registered")];
    
    [data addObject:@[@{
        @"type" : [OADescrTitleCell getCellIdentifier],
        @"title" : OALocalizedString(@"osmand_cloud_login_descr"),
        @"color" : UIColorFromRGB(color_text_footer),
        @"spacing" : @6,
        @"topMargin" : @20,
        @"bottomMargin" : @14
    },
    @{ @"type" : [OADividerCell getCellIdentifier] },
    @{
        @"type" : [OAInputCellWithTitle getCellIdentifier],
        @"title" : [self getTextFieldValue],
        @"placeholder" : OALocalizedString(@"shared_string_email")
    },
    @{ @"type" : [OADividerCell getCellIdentifier] } ]];
    
    NSMutableArray<NSDictionary *> *otherCells = [NSMutableArray array];
    if (_isEmailRegistered)
    {
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
        if (isTextFieldValidData)
        {
            [otherCells addObject: @{
                @"type" : [OAFilledButtonCell getCellIdentifier],
                @"title" : OALocalizedString(@"shared_string_continue"),
                @"buttonColor" : UIColorFromRGB(color_primary_purple),
                @"textColor" : UIColor.whiteColor,
                @"action" : @"continueButtonPressed",
                @"inteactive" : @YES,
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
            }];
        }
    }
    else
    {
        [otherCells addObject:@{
            @"type" : [OADescrTitleCell getCellIdentifier],
            @"title" : self.errorMessage,
            @"color" : UIColorFromRGB(color_support_red),
            @"spacing" : @1,
            @"topMargin" : @14,
            @"bottomMargin" : @0
        }];
        
        [otherCells addObject: @{
            @"type" : [OAFilledButtonCell getCellIdentifier],
            @"title" : OALocalizedString(@"register_opr_create_new_account"),
            @"buttonColor" : UIColorFromRGB(color_bottom_sheet_secondary),
            @"textColor" : UIColorFromRGB(color_primary_purple),
            @"action": @"createAccountButtonPressed",
            @"inteactive" : @YES,
        }];
        
        [otherCells addObject: @{
            @"type" : [OAFilledButtonCell getCellIdentifier],
            @"title" : OALocalizedString(@"shared_string_continue"),
            @"buttonColor" : UIColorFromRGB(color_bottom_sheet_secondary),
            @"textColor" : UIColorFromRGB(color_text_footer),
            @"action": @"continueButtonPressed",
            @"inteactive" : @NO,
        }];
    }
    [data addObject:otherCells];
    _data = data;
}

- (NSArray<NSArray<NSDictionary *> *> *) getData
{
    return _data;
}

- (void) registerUser
{
//    [OAAppSettings.sharedManager.backupPromocode set:_promoCode];
    [_backupHelper registerUser:[OAAppSettings.sharedManager.backupUserEmail get] promoCode:@"" login:YES];
}

// MARK: - Actions

- (void) continueButtonPressed
{
    NSString *email = self.getTextFieldValue;
    if ([email isValidEmail])
    {
        [OAAppSettings.sharedManager.backupUserEmail set:email];
        [_backupHelper registerDevice:@""];
    }
    else
    {
        self.errorMessage = OALocalizedString(@"login_error_email_invalid");
        [self updateScreen];
    }
}

- (void) createAccountButtonPressed
{
    OACloudAccountCreateViewController *vc = [[OACloudAccountCreateViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) textFieldDoneButtonPressed
{
    [self continueButtonPressed];
}

// MARK: OAOnRegisterDeviceListener

- (void)onRegisterDevice:(NSInteger)status message:(NSString *)message error:(OABackupError *)error
{
    NSInteger errorCode = error != nil ? error.code : -1;
    
    if (errorCode == SERVER_ERROR_CODE_TOKEN_IS_NOT_VALID_OR_EXPIRED)
    {
        [self registerUser];
    }
    else if (errorCode != -1)
    {
        if (errorCode == SERVER_ERROR_CODE_USER_IS_NOT_REGISTERED)
        {
            _isEmailRegistered = NO;
            self.errorMessage = OALocalizedString(@"cloud_email_not_registered");
        }
        else
        {
            self.errorMessage = error.getLocalizedError;
        }
        [self updateScreen];
        NSLog(@"Backup error: %@", error.getLocalizedError);
    }
}

// MARK: OAOnRegisterUserListener

- (void)onRegisterUser:(NSInteger)status message:(NSString *)message error:(OABackupError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (status == STATUS_SUCCESS) {
            self.lastTimeCodeSent = NSDate.date.timeIntervalSince1970;
            OACloudAccountVerificationViewController *verificationVc = [[OACloudAccountVerificationViewController alloc] initWithEmail:self.getTextFieldValue];
            [self.navigationController pushViewController:verificationVc animated:YES];
        }
        else
        {
            self.errorMessage = error != nil ? error.getLocalizedError : message;
            [self updateScreen];
        }
    });
}

@end
