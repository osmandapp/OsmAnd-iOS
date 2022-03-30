//
//  OACloudAccountCreateViewController.m
//  OsmAnd Maps
//
//  Created by nnngrach on 23.03.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACloudAccountCreateViewController.h"

@implementation OACloudAccountCreateViewController
{
    NSArray<NSDictionary *> *_data;
}

#pragma mark - Data section

- (void) applyLocalization
{
    [super applyLocalization];
    [self setHeaderTitle:OALocalizedString(@"register_opr_create_new_account")];
}

- (void) generateData
{
    NSMutableArray<NSDictionary *> *data = [NSMutableArray new];
    
    BOOL isTextFieldValidData = [self isValidInputedValue:[self getTextFieldValue]];
    BOOL isIntialLaunch = YES;
    BOOL isEmailValid = YES;
    BOOL isEmailRegistred = YES;
    
    [data addObject:@{
        @"type" : [OADescrTitleCell getCellIdentifier],
        @"title" : OALocalizedString(@"osmand_cloud_create_account_descr"),
        @"color" : UIColorFromRGB(color_text_footer),
        @"spacing" : @6,
        @"topMargin" : @20,
        @"bottomMargin" : @14
    }];
    
    [data addObject:@{ @"type" : [OADividerCell getCellIdentifier] } ];
    [data addObject:@{
        @"type" : [OAInputCellWithTitle getCellIdentifier],
        @"title" : [self getTextFieldValue],
        @"placeholder" : OALocalizedString(@"shared_string_email")
    }];
    [data addObject:@{ @"type" : [OADividerCell getCellIdentifier] } ];
    
    if (isIntialLaunch)
    {
        if (isTextFieldValidData)
        {
            [data addObject: @{
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
            [data addObject: @{
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
            [data addObject:@{
                @"type" : [OADescrTitleCell getCellIdentifier],
                @"title" : OALocalizedString(@"login_error_email_invalid"),
                @"color" : UIColorFromRGB(color_support_red),
                @"spacing" : @1,
                @"topMargin" : @14,
                @"bottomMargin" : @0
            }];
            
            if (isTextFieldValidData)
            {
                [data addObject: @{
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
                [data addObject: @{
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
            [data addObject:@{
                @"type" : [OADescrTitleCell getCellIdentifier],
                @"title" : OALocalizedString(@"cloud_email_already_registered"),
                @"color" : UIColorFromRGB(color_support_red),
                @"spacing" : @1,
                @"topMargin" : @14,
                @"bottomMargin" : @0
            }];
            
            [data addObject: @{
                @"type" : [OAFilledButtonCell getCellIdentifier],
                @"title" : OALocalizedString(@"user_login"),
                @"buttonColor" : UIColorFromRGB(color_bottom_sheet_secondary),
                @"textColor" : UIColorFromRGB(color_primary_purple),
                @"action": @"loginButtonPressed",
                @"inteactive" : @YES,
            }];
            
            [data addObject: @{
                @"type" : [OAFilledButtonCell getCellIdentifier],
                @"title" : OALocalizedString(@"shared_string_continue"),
                @"buttonColor" : UIColorFromRGB(color_bottom_sheet_secondary),
                @"textColor" : UIColorFromRGB(color_text_footer),
                @"action": @"continueButtonPressed",
                @"inteactive" : @NO,
            }];
        }
    }
    
    _data = data;
}

- (NSArray<NSDictionary *> *) getData
{
    return _data;
}

#pragma mark - Actions

- (void) continueButtonPressed
{
}

- (void) loginButtonPressed
{
}

- (void) textFieldDoneButtonPressed
{
    [self continueButtonPressed];
}

@end
