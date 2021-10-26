//
//  OADefaultFavorite.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/12/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OADefaultFavorite.h"
#import "OAUtilities.h"
#import <UIKit/UIKit.h>
#include "Localization.h"

@implementation OAFavoriteColor

-(instancetype)initWithName:(NSString *)name color:(UIColor *)color
{
    self = [super init];
    if (self) {
        self.name = name;
        self.color = color;
    }
    return self;
}

-(BOOL)isEqual:(id)object
{
    OAFavoriteColor *obj = object;
    return [obj.name isEqualToString:self.name];
}

@end


@implementation OADefaultFavorite

static NSArray *colors;


+ (NSArray*)builtinColors
{
    if (!colors)
        colors = @[
                   [[OAFavoriteColor alloc] initWithName:OALocalizedString(@"col_purple") color:UIColorFromRGB(0x3F51B5)],
                   
                   [[OAFavoriteColor alloc] initWithName:OALocalizedString(@"col_green") color:UIColorFromRGB(0x43A047)],
                   
                   [[OAFavoriteColor alloc] initWithName:OALocalizedString(@"col_yellow") color:UIColorFromRGB(0xffb300)],
                   
                   [[OAFavoriteColor alloc] initWithName:OALocalizedString(@"col_orange") color:UIColorFromRGB(0xff5722)],
                   
                   [[OAFavoriteColor alloc] initWithName:OALocalizedString(@"col_gray") color:UIColorFromRGB(0x607d8b)],
                   
                   [[OAFavoriteColor alloc] initWithName:OALocalizedString(@"col_red") color:UIColorFromRGB(0xe91e63)],
                   
                   [[OAFavoriteColor alloc] initWithName:OALocalizedString(@"col_blue") color:UIColorFromRGB(0x2196f3)],
                   
                   [[OAFavoriteColor alloc] initWithName:OALocalizedString(@"col_magenta") color:UIColorFromRGB(0x9c27b0)]
                   ];
    
    return colors;
}

+ (UIColor *) getDefaultColor
{
    return ((OAFavoriteColor *) [self.class builtinColors][0]).color;
}

+ (OAFavoriteColor *)getFavoriteColor:(UIColor *)color
{
    NSArray *favoriteColors = [OADefaultFavorite builtinColors];
    for (OAFavoriteColor *favoriteColor in favoriteColors)
    {
        if ([favoriteColor.color isEqual:color])
            return favoriteColor;
    }
    return favoriteColors[0];
}

+ (OAFavoriteColor *)nearestFavColor:(UIColor *)sourceColor
{
    CGFloat distance = FLT_MAX;
    
    NSInteger index = 0;
    for (int i = 0; i < [OADefaultFavorite builtinColors].count; i++) {
        OAFavoriteColor *col = colors[i];
        CGFloat newDistance = [OADefaultFavorite distanceBetweenColor:col.color secondColor:sourceColor];
        if (newDistance < distance) {
            index = i;
            distance = newDistance;
        }
    }
    
    return colors[index];
}

+ (CGFloat)distanceBetweenColor:(UIColor *)col1 secondColor:(UIColor *)col2
{
    CGFloat distance;
    CGFloat r1,g1,b1,a1,r2,g2,b2,a2;
    
    [col1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [col2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    
    distance = sqrtf( powf(r1 - r2, 2) + powf(g1 - g2, 2) + powf(b1 - b2, 2) );
    
    if (distance == 0)
        distance = sqrtf( powf(a1 - a2,2));
    
    return distance;
}

+ (NSInteger) getValidBuiltInColorNumber:(NSInteger)number
{
    if (number < 0 || number >= [OADefaultFavorite builtinColors].count)
        return 0;
    return number;
}

@end
