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
#import "OAInputTableViewCell.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

#define VERIFICATION_CODE_EXPIRATION_TIME_MIN (10 * 60)

@interface OACloudAccountVerificationViewController () <OAOnRegisterUserListener, OAOnRegisterDeviceListener, OAOnCheckCodeListener>

@end

@implementation OACloudAccountVerificationViewController
{
    NSArray<NSArray<NSDictionary *> *> *_data;
    NSString *_email;
    BOOL _isUnfoldPressed;
    
    long _lastTimeCodeSent;
    
    OABackupHelper *_backupHelper;
    EOACloudScreenSourceType _sourceType;
}

- (instancetype) initWithEmail:(NSString *)email sourceType:(EOACloudScreenSourceType)type
{
    self = [super init];
    if (self)
    {
        _email = email;
        _lastTimeCodeSent = 0;
        _sourceType = type;
        _backupHelper = OABackupHelper.sharedInstance;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = OALocalizedString(@"verification");
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_backupHelper.backupListeners addRegisterUserListener:self];
    [_backupHelper.backupListeners addRegisterDeviceListener:self];
    [_backupHelper.backupListeners addCheckCodeListener:self];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_backupHelper.backupListeners removeRegisterUserListener:self];
    [_backupHelper.backupListeners removeRegisterDeviceListener:self];
    [_backupHelper.backupListeners removeCheckCodeListener:self];
}

#pragma mark - Data section

- (void) generateData
{
    NSMutableArray<NSArray<NSDictionary *> *> *data = [NSMutableArray new];
    
    BOOL isTextFieldValidData = [self isValidInputValue:[self getTextFieldValue]];
    
    [data addObject:@[@{
        @"type" : [OASimpleTableViewCell getCellIdentifier],
        @"title" : [NSString stringWithFormat:OALocalizedString(@"verify_email_address_descr"), _email],
        @"boldPart" : _email ? _email : @"",
        @"color" : [UIColor colorNamed:ACColorNameTextColorSecondary],
        @"spacing" : @6
    },
    @{ @"type" : [OADividerCell getCellIdentifier] },
    @{
        @"type" : [OAInputTableViewCell getCellIdentifier],
        @"title" : @"",
        @"placeholder" : OALocalizedString(@"verification_code_placeholder"),
        @"numbersKeyboard" : @(YES)
    },
    @{ @"type" : [OADividerCell getCellIdentifier] } ]];
    
    NSMutableArray<NSDictionary *> *otherCells = [NSMutableArray array];
    
    if (self.errorMessage.length > 0)
    {
        [otherCells addObject:@{
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : self.errorMessage,
            @"color" : [UIColor colorNamed:ACColorNameButtonBgColorDisruptive],
            @"spacing" : @1
        }];
    }
    
    [otherCells addObject:@{
        @"type" : [OAButtonTableViewCell getCellIdentifier],
        @"title" : OALocalizedString(@"verification_code_missing"),
        @"color" : [UIColor colorNamed:ACColorNameIconColorActive],
        @"action" : @"unfoldButtonPressed",
    }];
    
    if (_isUnfoldPressed)
    {
        [otherCells addObject:@{
            @"type" : [OASimpleTableViewCell getCellIdentifier],
            @"title" : OALocalizedString(@"verification_code_missing_description"),
            @"color" : [UIColor colorNamed:ACColorNameTextColorSecondary],
            @"spacing" : @1
        }];

        [otherCells addObject: @{
            @"type" : [OAFilledButtonCell getCellIdentifier],
            @"title" : OALocalizedString(@"resend_verification_code"),
            @"buttonColor" : [UIColor colorNamed:ACColorNameButtonBgColorSecondary],
            @"textColor" : [UIColor colorNamed:ACColorNameButtonTextColorSecondary],
            @"action": @"resendButtonPressed",
            @"inteactive" : @YES,
            @"topMargin" : @0
        }];
    }
    
    NSNumber *continueButtonTopMargin = _isUnfoldPressed ? @20 : @8;
    if (isTextFieldValidData)
    {
        [otherCells addObject: @{
            @"type" : [OAFilledButtonCell getCellIdentifier],
            @"title" : OALocalizedString(@"shared_string_continue"),
            @"buttonColor" : [UIColor colorNamed:ACColorNameButtonBgColorPrimary],
            @"textColor" : [UIColor colorNamed:ACColorNameButtonTextColorPrimary],
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
            @"buttonColor" : [UIColor colorNamed:ACColorNameButtonBgColorSecondary],
            @"textColor" : [UIColor colorNamed:ACColorNameTextColorSecondary],
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
    if ([BackupUtils isTokenValid:token])
    {
        if (_sourceType == EOACloudScreenSourceDeleteAccount)
            [_backupHelper checkCode:[[OAAppSettings sharedManager].backupUserEmail get] token:token];
        else
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

- (BOOL) needEmailValidation
{
    return NO;
}

- (void)checkStatus:(NSInteger)status message:(NSString *)message error:(OABackupError *)error token:(NSString *)token
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (status == STATUS_SUCCESS)
        {
            if (_sourceType == EOACloudScreenSourceDeleteAccount)
                [self showViewController:[[OADeleteAccountViewController alloc] initWithToken:token]];
            else
                [self showViewController:[[OACloudBackupViewController alloc] initWithSourceType:_sourceType]];
            [self.navigationController.transitionCoordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
                if (viewControllers.count > 3)
                {
                    // remove previous login controllers
                    [viewControllers removeObjectsInRange:NSMakeRange(viewControllers.count - 4, 3)];
                }
                self.navigationController.viewControllers = viewControllers;
            }];
        }
        else {
            self.errorMessage = error != nil ? error.getLocalizedError : message;
            [self updateScreen];
        }
    });
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
    [self checkStatus:status message:message error:error token:nil];
}

// MARK: OAOnCheckCodeListener

- (void)onCheckCode:(NSString *)token status:(NSInteger)status message:(NSString *)message error:(OABackupError *)error
{
    [self checkStatus:status message:message error:error token:token];
}

@end
