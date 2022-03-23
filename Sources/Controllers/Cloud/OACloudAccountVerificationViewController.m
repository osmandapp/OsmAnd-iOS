//
//  OACloudAccountVerificationViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 23.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudAccountVerificationViewController.h"

@implementation OACloudAccountVerificationViewController
{
    NSString *_email;
    BOOL _isUnfoldPressed;
}

- (instancetype) initWithEmail:(NSString *)email
{
    self = [super init];
    if (self)
    {
        _email = email;
    }
    return self;
}

#pragma mark - Data section

- (void) applyLocalization
{
    [super applyLocalization];
    self.titleLabel.text = OALocalizedString(@"verification");
    self.headerText = OALocalizedString(@"verification");
}

- (void) generateData
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray new];
    
    BOOL isTextFieldValidData = [self isValidInputedValue:self.inputedText];
    BOOL isUnfolded = YES;
    
    [data addObject:@{
        @"type" : [OADescrTitleCell getCellIdentifier],
        @"title" : [NSString stringWithFormat:OALocalizedString(@"verify_email_address_descr"), _email],
        @"boldPart" : _email ? _email : @"",
        @"color" : UIColorFromRGB(color_text_footer),
        @"spacing" : @6,
        @"topMargin" : @20,
        @"bottomMargin" : @14
    }];
    
    [data addObject:@{ @"type" : [OADividerCell getCellIdentifier] } ];
    [data addObject:@{
        @"type" : [OAInputCellWithTitle getCellIdentifier],
        @"title" : self.inputedText,
        @"placeholder" : OALocalizedString(@"verification_code_placeholder")
    }];
    [data addObject:@{ @"type" : [OADividerCell getCellIdentifier] } ];
    
    [data addObject:@{
        @"type" : [OAButtonCell getCellIdentifier],
        @"title" : OALocalizedString(@"verification_code_missing"),
        @"color" : UIColorFromRGB(color_primary_purple),
        @"action" : @"unfoldButtonPressed",
    }];
    
    if (_isUnfoldPressed)
    {
        [data addObject:@{
            @"type" : [OADescrTitleCell getCellIdentifier],
            @"title" : OALocalizedString(@"verification_code_missing_description"),
            @"color" : UIColorFromRGB(color_text_footer),
            @"spacing" : @1,
            @"topMargin" : @0,
            @"bottomMargin" : @0
        }];

        [data addObject: @{
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
        [data addObject: @{
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
        [data addObject: @{
            @"type" : [OAFilledButtonCell getCellIdentifier],
            @"title" : OALocalizedString(@"shared_string_continue"),
            @"buttonColor" : UIColorFromRGB(color_bottom_sheet_secondary),
            @"textColor" : UIColorFromRGB(color_text_footer),
            @"action": @"continueButtonPressed",
            @"inteactive" : @NO,
            @"topMargin" : continueButtonTopMargin,
        }];
    }
    
    self.data = data;
}

#pragma mark - Actions

- (void) unfoldButtonPressed
{
    _isUnfoldPressed = !_isUnfoldPressed;
    [self generateData];
    [self reloadAllCells];
}

- (void) continueButtonPressed
{
}

- (void) resendButtonPressed
{
}

- (void) textFieldDoneButtonPressed
{
    [self continueButtonPressed];
}

- (BOOL) isValidInputedValue:(NSString *)value
{
    return value.length > 0;
}

@end
