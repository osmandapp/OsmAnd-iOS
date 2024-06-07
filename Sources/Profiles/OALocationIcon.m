//
//  OALocationIcon.m
//  OsmAnd
//
//  Created by Alexey on 28.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OALocationIcon.h"
#import "OAUtilities.h"

@interface OALocationIcon()

@property (nonatomic) EOALocationIcon locationIcon;

@end


@implementation OALocationIcon

+ (instancetype) withLocationIcon:(EOALocationIcon)locationIcon
{
    OALocationIcon *obj = [[OALocationIcon alloc] init];
    if (obj)
        obj.locationIcon = locationIcon;

    return obj;
}

- (UIImage *) iconWithColor:(UIColor *)color
{
    return [self.class getIcon:_locationIcon color:color];
}

- (UIImage *) iconWithColor:(UIColor *)color scaleFactor:(CGFloat)currentScaleFactor
{
    return [self.class getMapIcon:_locationIcon color:color scaleFactor:currentScaleFactor];
}

- (UIImage *) headingIconWithColor:(UIColor *)color
{
    return [self.class getHeadingIcon:_locationIcon color:color];
}

+ (NSArray<OALocationIcon *> *) values
{
    return @[ [OALocationIcon withLocationIcon:LOCATION_ICON_DEFAULT],
              [OALocationIcon withLocationIcon:LOCATION_ICON_CAR],
              [OALocationIcon withLocationIcon:LOCATION_ICON_BICYCLE] ];
}

+ (UIImage *) getIcon:(EOALocationIcon)locationIcon color:(UIColor *)color
{
    UIImage *bottomImage;
    UIImage *centerImage;
    UIImage *topImage;
    switch (locationIcon)
    {
        case LOCATION_ICON_DEFAULT:
            bottomImage = [UIImage imageNamed:@"map_location_default_bottom"];
            centerImage = [UIImage imageNamed:@"map_location_default_center"];
            topImage = [UIImage imageNamed:@"map_location_default_top"];
            break;
        case LOCATION_ICON_CAR:
            bottomImage = [UIImage imageNamed:@"map_location_car_bottom"];
            centerImage = [UIImage imageNamed:@"map_location_car_center"];
            topImage = [UIImage imageNamed:@"map_location_car_top"];
            break;
        case LOCATION_ICON_BICYCLE:
            bottomImage = [UIImage imageNamed:@"map_location_bicycle_bottom"];
            centerImage = [UIImage imageNamed:@"map_location_bicycle_center"];
            topImage = [UIImage imageNamed:@"map_location_bicycle_top"];
            break;
        default:
            return nil;
    }
    return [OAUtilities layeredImageWithColor:color bottom:bottomImage center:centerImage top:topImage scaleFactor:1.0];
}

+ (UIImage *) getMapIcon:(EOALocationIcon)locationIcon color:(UIColor *)color scaleFactor:(CGFloat)currentScaleFactor
{
    UIImage *bottomImage;
    UIImage *centerImage;
    UIImage *topImage;
    switch (locationIcon)
    {
        case LOCATION_ICON_DEFAULT:
            bottomImage = [UIImage imageNamed:@"map_location_default_bottom"];
            centerImage = [UIImage imageNamed:@"map_location_default_center"];
            topImage = [UIImage imageNamed:@"map_location_default_top"];
            break;
        case LOCATION_ICON_CAR:
            bottomImage = [UIImage imageNamed:@"map_location_car_bottom"];
            centerImage = [UIImage imageNamed:@"map_location_car_center"];
            topImage = [UIImage imageNamed:@"map_location_car_top"];
            break;
        case LOCATION_ICON_BICYCLE:
            bottomImage = [UIImage imageNamed:@"map_location_bicycle_bottom"];
            centerImage = [UIImage imageNamed:@"map_location_bicycle_center"];
            topImage = [UIImage imageNamed:@"map_location_bicycle_top"];
            break;
        default:
            return nil;
    }
    return [OAUtilities layeredImageWithColor:color bottom:bottomImage center:centerImage top:topImage scaleFactor:currentScaleFactor];
}

+ (UIImage *) getHeadingIcon:(EOALocationIcon)locationIcon color:(UIColor *)color
{
    switch (locationIcon)
    {
        case LOCATION_ICON_DEFAULT:
            return [OAUtilities tintImageWithColor:[UIImage imageNamed:@"map_default_location_view_angle"] color:color];
        case LOCATION_ICON_CAR:
            return [OAUtilities tintImageWithColor:[UIImage imageNamed:@"map_car_location_view_angle"] color:color];
        case LOCATION_ICON_BICYCLE:
            return [OAUtilities tintImageWithColor:[UIImage imageNamed:@"map_bicycle_location_view_angle"] color:color];
        default:
            return nil;
    }
}

@end
