//
//  OADefaultFavorite.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/12/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADefaultFavorite.h"

#import <UIKit/UIKit.h>

#include "Localization.h"

@implementation OADefaultFavorite

+ (NSArray*)builtinColors
{
    return @[
             @[@"Black", [UIColor blackColor]],
             @[@"White", [UIColor whiteColor]],
             @[@"Blue",  [UIColor blueColor]],
             @[@"Red",  [UIColor redColor]],
             @[@"Green", [UIColor greenColor]],
             @[@"Yellow", [UIColor yellowColor]],
             @[@"Purple", [UIColor purpleColor]],
             @[@"Magenta", [UIColor magentaColor]]
             ];
}

+ (NSArray*)builtinGroupNames
{
    return @[OALocalizedString(@"My places")];
}

@end
