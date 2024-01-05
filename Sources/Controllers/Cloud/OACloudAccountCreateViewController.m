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
#import "OAInputTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OACloudAccountCreateViewController () <OAOnRegisterUserListener, OAOnRegisterDeviceListener>

@end

@implementation OACloudAccountCreateViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    
    OABackupHelper *_backupHelper;
    
    BOOL _continuePressed;
}

#pragma mark - Data section

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = OALocalizedString(@"register_opr_create_new_account");
    _continuePressed = NO;
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

- (void) generateData
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray new];
    
    BOOL isTextFieldValidData = [self isValidInputValue:[self getTextFieldValue]] && !_continuePressed;
    BOOL isEmailRegistred = [self.errorMessage isEqualToString:OALocalizedString(@"cloud_email_already_registered")];
    
    [data addObject:@[@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"osmand_cloud_create_account_descr"),
        @"color" : [UIColor colorNamed:ACColorNameTextColorSecondary],
        @"spacing" : @6
    },
    @{ @"type" : [OADividerCell getCellIdentifier] },
    @{
        @"type" : [OAInputTableViewCell getCellIdentifier],
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
                @"type" : [OASimpleTableViewCell getCellIdentifier],
                @"title" : self.errorMessage,
                @"color" : [UIColor colorNamed:ACColorNameButtonBgColorDisruptive],
                @"spacing" : @1
            }];
        }
        if (isTextFieldValidData)
        {
            [otherCells addObject: @{
                @"type" : [OAFilledButtonCell getCellIdentifier],
                @"title" : OALocalizedString(@"shared_string_continue"),
                @"buttonColor" : [UIColor colorNamed:ACColorNameButtonBgColorPrimary],
                @"textColor" : [UIColor colorNamed:ACColorNameButtonTextColorPrimary],
                @"action" : @"continueButtonPressed",
                @"inteactive" : @YES,
            }];
        }
        else
        {
            [otherCells addObject: @{
                @"type" : [OAFilledButtonCell getCellIdentifier],
                @"title" : OALocalizedString(@"shared_string_continue"),
                @"buttonColor" : [UIColor colorNamed:ACColorNameButtonBgColorSecondary],
                @"textColor" : [UIColor colorNamed:ACColorNameTextColorSecondary],
                @"action": @"continueButtonPressed",
                @"inteactive" : @NO,
            }];
        }
    }
    else
    {
        [otherCells addObject:@{
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : self.errorMessage,
            @"color" : [UIColor colorNamed:ACColorNameButtonBgColorDisruptive],
            @"spacing" : @1
        }];
        
        [otherCells addObject: @{
            @"type" : [OAFilledButtonCell getCellIdentifier],
            @"title" : OALocalizedString(@"user_login"),
            @"buttonColor" : [UIColor colorNamed:ACColorNameButtonBgColorSecondary],
            @"textColor" : [UIColor colorNamed:ACColorNameButtonTextColorSecondary],
            @"action": @"loginButtonPressed",
            @"inteactive" : @YES,
            @"topMargin" : @0
        }];
        
        [otherCells addObject: @{
            @"type" : [OAFilledButtonCell getCellIdentifier],
            @"title" : OALocalizedString(@"shared_string_continue"),
            @"buttonColor" : [UIColor colorNamed:ACColorNameButtonBgColorSecondary],
            @"textColor" : [UIColor colorNamed:ACColorNameTextColorSecondary],
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
    if (!_continuePressed)
    {
        NSString *email = self.getTextFieldValue;
        if ([email isValidEmail])
        {
            [OAAppSettings.sharedManager.backupUserEmail set:email];
            [_backupHelper registerDevice:@""];
            _continuePressed = YES;
            [self updateScreen];
        }
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
        _continuePressed = NO;
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
            OACloudAccountVerificationViewController *verificationVc = [[OACloudAccountVerificationViewController alloc] initWithEmail:self.getTextFieldValue sourceType:EOACloudScreenSourceTypeSignUp];
            [self.navigationController pushViewController:verificationVc animated:YES];
        }
        else
        {
            self.errorMessage = error != nil ? error.getLocalizedError : message;
            NSLog(@"%@", message);
            _continuePressed = NO;
            [self updateScreen];
        }
    });
}

@end
