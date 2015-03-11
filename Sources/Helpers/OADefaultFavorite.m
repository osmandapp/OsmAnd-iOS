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

@implementation OAFavoriteColor

-(instancetype)initWithName:(NSString *)name color:(UIColor *)color iconName:(NSString *)iconName
{
    self = [super init];
    if (self) {
        self.name = name;
        self.color = color;
        self.iconName = iconName;
        self.icon = [UIImage imageNamed:iconName];
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
                   [[OAFavoriteColor alloc] initWithName:@"Purple" color:[UIColor colorWithRed:0.251f green:0.329f blue:0.698f alpha:1.00f] iconName:@"ic_favorite_1"],
                   
                   [[OAFavoriteColor alloc] initWithName:@"Green" color:[UIColor colorWithRed:0.278f green:0.624f blue:0.294f alpha:1.00f] iconName:@"ic_favorite_2"],
                   
                   [[OAFavoriteColor alloc] initWithName:@"Yellow" color:[UIColor colorWithRed:0.992f green:0.698f blue:0.169f alpha:1.00f] iconName:@"ic_favorite_3"],
                   
                   [[OAFavoriteColor alloc] initWithName:@"Orange" color:[UIColor colorWithRed:0.988f green:0.345f blue:0.188f alpha:1.00f] iconName:@"ic_favorite_4"],
                   
                   [[OAFavoriteColor alloc] initWithName:@"Gray" color:[UIColor colorWithRed:0.380f green:0.490f blue:0.541f alpha:1.00f] iconName:@"ic_favorite_5"],
                   
                   [[OAFavoriteColor alloc] initWithName:@"Red" color:[UIColor colorWithRed:0.902f green:0.145f blue:0.396f alpha:1.00f] iconName:@"ic_favorite_6"],
                   
                   [[OAFavoriteColor alloc] initWithName:@"Blue" color:[UIColor colorWithRed:0.169f green:0.596f blue:0.941f alpha:1.00f] iconName:@"ic_favorite_7"],
                   
                   [[OAFavoriteColor alloc] initWithName:@"Magenta" color:[UIColor colorWithRed:0.608f green:0.184f blue:0.682f alpha:1.00f] iconName:@"ic_favorite_8"]
                   ];
    
    return colors;
}

+ (NSArray*)builtinGroupNames
{
    return @[OALocalizedString(@"My places")];
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

@end
