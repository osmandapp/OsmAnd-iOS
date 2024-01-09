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
#import "OAChoosePlanHelper.h"
#import "OAInputTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@interface OACloudAccountLoginViewController () <OAOnRegisterUserListener, OAOnRegisterDeviceListener>

@end

@implementation OACloudAccountLoginViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    
    OABackupHelper *_backupHelper;
    
    BOOL _isEmailRegistered;
    BOOL _hasValidSub;
    BOOL _continuePressed;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _hasValidSub = YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = OALocalizedString(@"user_login");
    self.lastTimeCodeSent = 0;
    
    _backupHelper = [OABackupHelper sharedInstance];
    _continuePressed = NO;
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

- (void) generateData
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray new];
    
    BOOL isTextFieldValidData = [self isValidInputValue:[self getTextFieldValue]] && !_continuePressed;
    _isEmailRegistered = ![self.errorMessage isEqualToString:OALocalizedString(@"cloud_email_not_registered")];
    
    [data addObject:@[@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"osmand_cloud_login_descr"),
        @"color" : [UIColor colorNamed:ACColorNameIconColorSecondary],
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
    if (_isEmailRegistered)
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
                @"topMargin" : !_hasValidSub ? @0 : @20
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
                @"topMargin" : !_hasValidSub ? @0 : @20
            }];
        }
        if (!_hasValidSub)
        {
            [otherCells addObject: @{
                @"type" : [OAFilledButtonCell getCellIdentifier],
                @"title" : OALocalizedString(@"shared_string_get"),
                @"buttonColor" : [UIColor colorNamed:ACColorNameButtonBgColorPrimary],
                @"textColor" : [UIColor colorNamed:ACColorNameTextColorPrimary],
                @"action" : @"getButtonPressed",
                @"inteactive" : @YES,
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
            @"title" : OALocalizedString(@"register_opr_create_new_account"),
            @"buttonColor" : [UIColor colorNamed:ACColorNameButtonBgColorSecondary],
            @"textColor" : [UIColor colorNamed:ACColorNameTextColorActive],
            @"action": @"createAccountButtonPressed",
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

- (void) registerUser
{
//    [OAAppSettings.sharedManager.backupPromocode set:_promoCode];
    [_backupHelper registerUser:[OAAppSettings.sharedManager.backupUserEmail get] promoCode:@"" login:YES];
}

// MARK: - Actions

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

- (void) getButtonPressed
{
    [OAChoosePlanHelper showChoosePlanScreenWithFeature:OAFeature.OSMAND_CLOUD navController:self.navigationController];
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
        else if (errorCode == SERVER_ERROR_CODE_NO_VALID_SUBSCRIPTION)
        {
            _hasValidSub = NO;
            self.errorMessage = error.getLocalizedError;
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
            OACloudAccountVerificationViewController *verificationVc = [[OACloudAccountVerificationViewController alloc] initWithEmail:self.getTextFieldValue sourceType:EOACloudScreenSourceTypeSignIn];
            [self.navigationController pushViewController:verificationVc animated:YES];
        }
        else
        {
            self.errorMessage = error != nil ? error.getLocalizedError : message;
            _continuePressed = NO;
            [self updateScreen];
        }
    });
}

@end
