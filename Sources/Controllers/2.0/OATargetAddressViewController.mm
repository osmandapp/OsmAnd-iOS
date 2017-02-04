//
//  OATargetAddressViewController.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/02/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATargetAddressViewController.h"
#import "OAAddress.h"
#import "Localization.h"

@interface OATargetAddressViewController ()

@end

@implementation OATargetAddressViewController

- (id)initWithAddress:(OAAddress *)address
{
    self = [self init];
    if (self)
    {
        _address = address;
    }
    return self;
}

-(NSString *)getCommonTypeStr
{
    return @"";
}

@end
