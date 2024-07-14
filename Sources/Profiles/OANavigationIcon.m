//
//  OANavigationIcon.m
//  OsmAnd
//
//  Created by Alexey on 29.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavigationIcon.h"
#import "OAUtilities.h"
#import "OAAppSettings.h"
#import "OAIndexConstants.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

static NSString *NAVIGATION_MODEL_ICON_DEFAULT = @"model_map_car_bearing";
static NSString *NAVIGATION_MODEL_ICON_NAUTICAL = @"model_map_navigation_nautical";
static NSString *NAVIGATION_MODEL_ICON_CAR = @"model_map_navigation_car";

@interface OANavigationIcon()

@property (nonatomic) NSString *iconName;

@end

@implementation OANavigationIcon

+ (instancetype) withIconName:(NSString *)iconName
{
    OANavigationIcon *obj = [[OANavigationIcon alloc] init];
    if (obj)
        obj.iconName = iconName;

    return obj;
}

+ (BOOL) isStandardIcon:(NSString *)iconName
{
    return [iconName isEqualToString:NAVIGATION_ICON_DEFAULT]
        || [iconName isEqualToString:NAVIGATION_ICON_NAUTICAL]
        || [iconName isEqualToString:NAVIGATION_ICON_CAR];
}

+ (NSString *) getStandardIconModelName:(NSString *)iconName
{
    if ([iconName isEqualToString:NAVIGATION_ICON_DEFAULT])
        return NAVIGATION_MODEL_ICON_DEFAULT;
    if ([iconName isEqualToString:NAVIGATION_ICON_NAUTICAL])
        return NAVIGATION_MODEL_ICON_NAUTICAL;
    if ([iconName isEqualToString:NAVIGATION_ICON_CAR])
        return NAVIGATION_MODEL_ICON_CAR;

    return iconName;
}

+ (NSString *) getIconName:(NSString *)iconName
{
    return OAAppSettings.sharedManager.use3dIconsByDefault.get && [self.class isStandardIcon:iconName]
    	? [self.class getStandardIconModelName:iconName]
        : iconName;
}

+ (NSArray<NSString *> *) getIconNames
{
    NSMutableArray<NSString *> *iconNames = [NSMutableArray array];
    [iconNames addObject:[self.class getIconName:NAVIGATION_ICON_DEFAULT]];
    [iconNames addObject:[self.class getIconName:NAVIGATION_ICON_NAUTICAL]];
    [iconNames addObject:[self.class getIconName:NAVIGATION_ICON_CAR]];
    return iconNames;
}

- (NSString *) iconName
{
    return [self.class getIconName:_iconName];
}

- (UIImage *) iconWithColor:(UIColor *)color
{
    return [self.class getIcon:self.iconName color:color];
}

- (UIImage *) getMapIcon:(UIColor *)color
{
    return [self.class getIcon:self.iconName color:color scaleFactor:[[OAAppSettings sharedManager].textSize get]];
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
    if ([iconName isEqualToString:NAVIGATION_ICON_DEFAULT])
    {
        bottomImage = [UIImage imageNamed:@"map_navigation_default_bottom"];
        centerImage = [UIImage imageNamed:@"map_navigation_default_center"];
        topImage = [UIImage imageNamed:@"map_navigation_default_top"];
    }
    else if ([iconName isEqualToString:NAVIGATION_ICON_NAUTICAL])
    {
        bottomImage = [UIImage imageNamed:@"map_navigation_nautical_bottom"];
        centerImage = [UIImage imageNamed:@"map_navigation_nautical_center"];
        topImage = [UIImage imageNamed:@"map_navigation_nautical_top"];
    }
    else if ([iconName isEqualToString:NAVIGATION_ICON_CAR])
    {
        bottomImage = [UIImage imageNamed:@"map_navigation_car_bottom"];
        centerImage = [UIImage imageNamed:@"map_navigation_car_center"];
        topImage = [UIImage imageNamed:@"map_navigation_car_top"];
    }
    else if ([self isModel:iconName])
    {
        bottomImage = [UIImage imageNamed:@"map_navigation_default_bottom"];
        centerImage = [UIImage imageNamed:@"map_navigation_default_center"];
        topImage = [UIImage imageNamed:@"map_navigation_default_top"];
    }
    else
    {
        bottomImage = [UIImage imageNamed:@"map_navigation_default_bottom"];
        centerImage = [UIImage imageNamed:@"map_navigation_default_center"];
        topImage = [UIImage imageNamed:@"map_navigation_default_top"];
    }
    return [OAUtilities layeredImageWithColor:color bottom:bottomImage center:centerImage top:topImage scaleFactor:currentScaleFactor];
}

+ (UIImage *) getPreviewIcon:(NSString *)iconName color:(UIColor *)color
{
    UIImage *modelPreview = [self getModelPreviewDrawable:iconName];
    if (modelPreview)
        return modelPreview;
    return [self getIcon:iconName color:color scaleFactor:1];
}

+ (UIImage *) getModelPreviewDrawable:(NSString *)iconName
{
    if ([self isModel:iconName])
    {        
        NSString *shortIconName = [iconName substringFromIndex:MODEL_NAME_PREFIX.length];
        NSString *modelDirPath = [Model3dHelper getModelPathWithModelName:shortIconName];
        NSString *iconFilePath = [Model3dHelper getModelIconFilePathWithDirPath:modelDirPath];
        if ([NSFileManager.defaultManager fileExistsAtPath:iconFilePath])
        {
            return [UIImage imageNamed:iconFilePath];
        }
    }
    return nil;
}

+ (BOOL) isModel:(NSString *)iconName
{
    return [iconName hasPrefix:MODEL_NAME_PREFIX];
}

- (BOOL) isModel
{
    return [self.class isModel:self.iconName];
}

@end
