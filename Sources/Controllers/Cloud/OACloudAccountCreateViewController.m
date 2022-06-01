//
//  OACloudAccountCreateViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 23.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudAccountCreateViewController.h"
#import "OAAppSettings.h"
#import "OABackupHelper.h"
#import "OABackupError.h"
#import "OABackupListeners.h"
#import "OACloudAccountVerificationViewController.h"
#import "OACloudAccountLoginViewController.h"

@interface OACloudAccountCreateViewController () <OAOnRegisterUserListener, OAOnRegisterDeviceListener>

@end

@implementation OACloudAccountCreateViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    
    OABackupHelper *_backupHelper;
}

#pragma mark - Data section

- (void)viewDidLoad
{
    [super viewDidLoad];
    _backupHelper = OABackupHelper.sharedInstance;
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

- (NSString *) getTableHeaderTitle
{
    return OALocalizedString(@"register_opr_create_new_account");
}

- (void) generateData
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray new];
    
    BOOL isTextFieldValidData = [self isValidInputValue:[self getTextFieldValue]];
    BOOL isEmailRegistred = [self.errorMessage isEqualToString:OALocalizedString(@"cloud_email_already_registered")];
    
    [data addObject:@[@{
        @"type" : [OADescrTitleCell getCellIdentifier],
        @"title" : OALocalizedString(@"osmand_cloud_create_account_descr"),
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
    if (!isEmailRegistred)
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
            @"title" : OALocalizedString(@"user_login"),
            @"buttonColor" : UIColorFromRGB(color_bottom_sheet_secondary),
            @"textColor" : UIColorFromRGB(color_primary_purple),
            @"action": @"loginButtonPressed",
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

#pragma mark - Actions

- (void) continueButtonPressed
{
    NSString *email = self.getTextFieldValue;
    if ([email isValidEmail])
    {
        [OAAppSettings.sharedManager.backupUserEmail set:email];
        [_backupHelper registerDevice:@""];
    }
}

- (void) loginButtonPressed
{
    OACloudAccountLoginViewController *vc = [[OACloudAccountLoginViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void) textFieldDoneButtonPressed
{
    [self continueButtonPressed];
}

- (void) registerUser
{
//    [OAAppSettings.sharedManager.backupPromocode set:_promoCode];
    [_backupHelper registerUser:[OAAppSettings.sharedManager.backupUserEmail get] promoCode:@"" login:NO];
}

// MARK: OAOnRegisterDeviceListener

- (void)onRegisterDevice:(NSInteger)status message:(NSString *)message error:(OABackupError *)error
{
    NSInteger errorCode = error != nil ? error.code : -1;
    
    if (errorCode == SERVER_ERROR_CODE_USER_IS_NOT_REGISTERED)
    {
        [self registerUser];
    }
    else if (errorCode != -1)
    {
        if (errorCode == SERVER_ERROR_CODE_TOKEN_IS_NOT_VALID_OR_EXPIRED)
        {
            self.errorMessage = OALocalizedString(@"cloud_email_already_registered");
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
