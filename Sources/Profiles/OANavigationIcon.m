//
//  OANavigationIcon.m
//  OsmAnd
//
//  Created by Alexey on 29.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavigationIcon.h"
#import "OAUtilities.h"

@interface OANavigationIcon()

@property (nonatomic) EOANavigationIcon navigationIcon;

@end

@implementation OANavigationIcon

+ (instancetype) withNavigationIcon:(EOANavigationIcon)navigationIcon
{
    OANavigationIcon *obj = [[OANavigationIcon alloc] init];
    if (obj)
        obj.navigationIcon = navigationIcon;

    return obj;
}

- (UIImage *) iconWithColor:(UIColor *)color scaleFactor:(CGFloat)currentScaleFactor
{
    return [self.class getIcon:_navigationIcon color:color scaleFactor:currentScaleFactor];
}

+ (NSArray<OANavigationIcon *> *) values
{
    return @[ [OANavigationIcon withNavigationIcon:NAVIGATION_ICON_DEFAULT],
              [OANavigationIcon withNavigationIcon:NAVIGATION_ICON_NAUTICAL],
              [OANavigationIcon withNavigationIcon:NAVIGATION_ICON_CAR] ];
}

+ (UIImage *)getIcon:(EOANavigationIcon)navigationIcon color:(UIColor *)color scaleFactor:(CGFloat)currentScaleFactor
{
    UIImage *bottomImage;
    UIImage *centerImage;
    UIImage *topImage;
    switch (navigationIcon)
    {
        case NAVIGATION_ICON_DEFAULT:
            bottomImage = [UIImage imageNamed:@"map_navigation_default_bottom"];
            centerImage = [UIImage imageNamed:@"map_navigation_default_center"];
            topImage = [UIImage imageNamed:@"map_navigation_default_top"];
            break;
        case NAVIGATION_ICON_NAUTICAL:
            bottomImage = [UIImage imageNamed:@"map_navigation_nautical_bottom"];
            centerImage = [UIImage imageNamed:@"map_navigation_nautical_center"];
            topImage = [UIImage imageNamed:@"map_navigation_nautical_top"];
            break;
        case NAVIGATION_ICON_CAR:
            bottomImage = [UIImage imageNamed:@"map_navigation_car_bottom"];
            centerImage = [UIImage imageNamed:@"map_navigation_car_center"];
            topImage = [UIImage imageNamed:@"map_navigation_car_top"];
            break;
        default:
            return nil;
    }
    return [OAUtilities layeredImageWithColor:color bottom:bottomImage center:centerImage top:topImage scaleFactor:currentScaleFactor];
}

@end
