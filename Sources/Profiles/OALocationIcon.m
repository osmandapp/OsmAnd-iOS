//
//  OALocationIcon.m
//  OsmAnd
//
//  Created by Alexey on 28.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OALocationIcon.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAIndexConstants.h"

@interface OALocationIcon()

@property (nonatomic) NSString *iconName;

@end


@implementation OALocationIcon

+ (instancetype) withIconName:(NSString *)iconName
{
    OALocationIcon *obj = [[OALocationIcon alloc] init];
    if (obj)
    {
        NSString *migratedOldValue = [self getMigratedValue:iconName];
        if (migratedOldValue)
            obj.iconName = migratedOldValue;
        else
            obj.iconName = iconName;
    }

    return obj;
}

+ (NSString *) getMigratedValue:(id)value
{
    if ([value isKindOfClass:NSNumber.class])
    {
        NSNumber *oldEnumValue = value;
        if (oldEnumValue.intValue == 0)
            return LOCATION_ICON_DEFAULT;
        else if (oldEnumValue.intValue == 1)
            return LOCATION_ICON_CAR;
        else if (oldEnumValue.intValue == 2)
            return LOCATION_ICON_BICYCLE;
    }
    return nil;
}

- (UIImage *) iconWithColor:(UIColor *)color
{
    return [self.class getIcon:_iconName color:color];
}

- (UIImage *) getMapIcon:(UIColor *)color
{
    return [self.class getIcon:_iconName color:color scaleFactor:[[OAAppSettings sharedManager].textSize get]];
}

- (UIImage *) headingIconWithColor:(UIColor *)color
{
    return [self.class getHeadingIcon:_iconName color:color];
}

+ (UIImage *) getIcon:(NSString *)iconName color:(UIColor *)color
{
    return [self getIcon:iconName color:color scaleFactor:1.0];
}

+ (UIImage *) getIcon:(NSString *)iconName color:(UIColor *)color scaleFactor:(CGFloat)currentScaleFactor
{
    UIImage *bottomImage;
    UIImage *centerImage;
    UIImage *topImage;
    if ([iconName isEqualToString:LOCATION_ICON_DEFAULT])
    {
        bottomImage = [UIImage imageNamed:@"map_location_default_bottom"];
        centerImage = [UIImage imageNamed:@"map_location_default_center"];
        topImage = [UIImage imageNamed:@"map_location_default_top"];
    }
    else if ([iconName isEqualToString:LOCATION_ICON_CAR])
    {
        bottomImage = [UIImage imageNamed:@"map_location_car_bottom"];
        centerImage = [UIImage imageNamed:@"map_location_car_center"];
        topImage = [UIImage imageNamed:@"map_location_car_top"];
    }
    else if ([iconName isEqualToString:LOCATION_ICON_BICYCLE])
    {
        bottomImage = [UIImage imageNamed:@"map_location_bicycle_bottom"];
        centerImage = [UIImage imageNamed:@"map_location_bicycle_center"];
        topImage = [UIImage imageNamed:@"map_location_bicycle_top"];
    }
    return [OAUtilities layeredImageWithColor:color bottom:bottomImage center:centerImage top:topImage scaleFactor:currentScaleFactor];
}

+ (UIImage *) getHeadingIcon:(NSString *)iconName color:(UIColor *)color
{
    if ([iconName isEqualToString:LOCATION_ICON_DEFAULT])
        return [OAUtilities tintImageWithColor:[UIImage imageNamed:@"map_default_location_view_angle"] color:color];
    else if ([iconName isEqualToString:LOCATION_ICON_CAR])
        return [OAUtilities tintImageWithColor:[UIImage imageNamed:@"map_car_location_view_angle"] color:color];
    else if ([iconName isEqualToString:LOCATION_ICON_BICYCLE])
        return [OAUtilities tintImageWithColor:[UIImage imageNamed:@"map_bicycle_location_view_angle"] color:color];
    else if ([self isModel:iconName])
        return [OAUtilities tintImageWithColor:[UIImage imageNamed:@"map_car_location_view_angle"] color:color];
    return nil;
}

+ (UIImage *) getPreviewIcon:(NSString *)iconName color:(UIColor *)color
{
    UIImage *modelPreview = [OANavigationIcon getModelPreviewDrawable:iconName];
    if (modelPreview)
        return modelPreview;
    return [self getIcon:iconName color:color scaleFactor:1];
}

+ (BOOL) isModel:(NSString *)iconName
{
    return [iconName hasPrefix:MODEL_NAME_PREFIX];
}

- (BOOL) isModel
{
    return [self.class isModel:_iconName];
}

@end
