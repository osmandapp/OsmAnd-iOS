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
#import "OACloudBackupViewController.h"

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
        
        [_backupHelper.backupListeners addRegisterUserListener:self];
        [_backupHelper.backupListeners addRegisterDeviceListener:self];
    }
    return self;
}

- (void)dealloc
{
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
    BOOL isUnfolded = YES;
    
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
        @"placeholder" : OALocalizedString(@"verification_code_placeholder")
    },
    @{ @"type" : [OADividerCell getCellIdentifier] } ]];
    
    NSMutableArray<NSDictionary *> *otherCells = [NSMutableArray array];
    
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

- (void) unfoldButtonPressed
{
    _isUnfoldPressed = !_isUnfoldPressed;
    [self generateData];
    [self.tableView beginUpdates];
    if (_isUnfoldPressed)
        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:5 inSection:0], [NSIndexPath indexPathForRow:6 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    else
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:5 inSection:0], [NSIndexPath indexPathForRow:6 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

- (void) continueButtonPressed
{
    NSString *token = [self getTextFieldValue];
    if ([OABackupHelper isTokenValid:token])
    {
//        progressBar.setVisibility(View.VISIBLE);
        [_backupHelper registerDevice:token];
    }
    else
    {
//        editText.requestFocus();
//        editText.setError("Token is not valid");
        NSLog(@"Token is not valid");
    }
}

- (void) resendButtonPressed
{
    [_backupHelper registerUser:[OAAppSettings.sharedManager.backupUserEmail get] promoCode:@"" login:YES];
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
        if (status == STATUS_SUCCESS)
        {
            _lastTimeCodeSent = NSDate.date.timeIntervalSince1970;
            [self.tableView reloadData];
        }
    });
}

// MARK: OAOnRegisterDeviceListener

- (void)onRegisterDevice:(NSInteger)status message:(NSString *)message error:(OABackupError *)error
{
    dispatch_async(dispatch_get_main_queue(), ^{
        //    progressBar.setVisibility(View.INVISIBLE);
        if (status == STATUS_SUCCESS)
        {
    //        FragmentManager fragmentManager = activity.getSupportFragmentManager();
    //        if (!fragmentManager.isStateSaved()) {
    //            fragmentManager.popBackStack(BaseSettingsFragment.SettingsScreenType.BACKUP_AUTHORIZATION.name(), FragmentManager.POP_BACK_STACK_INCLUSIVE);
    //        }
            OACloudBackupViewController *vc = [[OACloudBackupViewController alloc] init];
            [self.navigationController pushViewController:vc animated:YES];
        }
        else {
    //        errorText.setText(error != null ? error.getLocalizedError(app) : message);
    //        buttonContinue.setEnabled(false);
    //        AndroidUiHelper.updateVisibility(errorText, true);
        }
    });
}

@end
