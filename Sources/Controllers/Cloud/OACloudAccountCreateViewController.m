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
    
    [_backupHelper.backupListeners addRegisterUserListener:self];
    [_backupHelper.backupListeners addRegisterDeviceListener:self];
}

- (void)dealloc
{
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
    BOOL isIntialLaunch = YES;
    BOOL isEmailValid = YES;
    BOOL isEmailRegistred = YES;
    
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
    if (isIntialLaunch)
    {
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
        if (!isEmailValid)
        {
            [otherCells addObject:@{
                @"type" : [OADescrTitleCell getCellIdentifier],
                @"title" : OALocalizedString(@"login_error_email_invalid"),
                @"color" : UIColorFromRGB(color_support_red),
                @"spacing" : @1,
                @"topMargin" : @14,
                @"bottomMargin" : @0
            }];
            
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
        else if (isEmailRegistred)
        {
            [otherCells addObject:@{
                @"type" : [OADescrTitleCell getCellIdentifier],
                @"title" : OALocalizedString(@"cloud_email_already_registered"),
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
    
    if (errorCode == SERVER_ERROR_CODE_TOKEN_IS_NOT_VALID_OR_EXPIRED)
    {
        [self registerUser];
    }
    else if (errorCode != -1)
    {
//        progressBar.setVisibility(View.INVISIBLE);
        if (errorCode == SERVER_ERROR_CODE_USER_IS_NOT_REGISTERED)
        {
//            errorText.setText(dialogType.warningId);
//            AndroidUiHelper.updateVisibility(buttonAuthorize, !promoCodeSupported());
        }
        else
        {
//            errorText.setText(error.getLocalizedError(app));
        }
        NSLog(@"Backup error: %@", error.getLocalizedError);
//        buttonContinue.setEnabled(false);
//        AndroidUiHelper.updateVisibility(errorText, true);
    }
//    AndroidUiHelper.updateVisibility(buttonChoosePlan, false);
}

// MARK: OAOnRegisterUserListener

- (void)onRegisterUser:(NSInteger)status message:(NSString *)message error:(OABackupError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //    progressBar.setVisibility(View.INVISIBLE);
        if (status == STATUS_SUCCESS) {
            self.lastTimeCodeSent = NSDate.date.timeIntervalSince1970;
            OACloudAccountVerificationViewController *verificationVc = [[OACloudAccountVerificationViewController alloc] initWithEmail:self.getTextFieldValue];
            [self.navigationController pushViewController:verificationVc animated:YES];
        }
        else
        {
            //        boolean choosePlanVisible = false;
            //        if (error != null) {
            //            int code = error.getCode();
            //            choosePlanVisible = !promoCodeSupported()
            //            && (code == SERVER_ERROR_CODE_NO_VALID_SUBSCRIPTION
            //                || code == SERVER_ERROR_CODE_USER_IS_NOT_REGISTERED
            //                || code == SERVER_ERROR_CODE_SUBSCRIPTION_WAS_EXPIRED_OR_NOT_PRESENT);
            //        }
            //        errorText.setText(error != null ? error.getLocalizedError(app) : message);
            //        buttonContinue.setEnabled(false);
            //        AndroidUiHelper.updateVisibility(errorText, true);
            //        AndroidUiHelper.updateVisibility(buttonChoosePlan, choosePlanVisible);
        }
    });
}

@end
