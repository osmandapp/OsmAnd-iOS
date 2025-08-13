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

#import "OsmAnd_Maps-Swift.h"

@interface OALocationIcon()

@property (nonatomic) NSString *name;
@property (nonatomic) NSString *iconName;
@property (nonatomic) NSString *headingIconName;
@property (nonatomic) NSString *modelName;

@end


@implementation OALocationIcon
{
    NSString *_name;
    NSString *_iconName;
    NSString *_headingIconName;
    NSString *_modelName;
}

static OALocationIcon *_DEFAULT;
static OALocationIcon *_CAR;
static OALocationIcon *_BICYCLE;
static OALocationIcon *_MOVEMENT_DEFAULT;
static OALocationIcon *_MOVEMENT_NAUTICAL;
static OALocationIcon *_MOVEMENT_CAR;

+ (instancetype) withName:(NSString *)name iconName:(NSString *)iconName headingIconName:(NSString *)headingIconName modelName:(NSString *)modelName
{
    OALocationIcon *obj = [[OALocationIcon alloc] init];
    if (obj)
    {
        obj.name = name;
        obj.iconName = iconName;
        obj.headingIconName = headingIconName;
        obj.modelName = modelName;
    }

    return obj;
}

+ (instancetype) withModelName:(NSString *)modelName
{
    OALocationIcon *obj = [[OALocationIcon alloc] init];
    if (obj)
    {
        obj.name = modelName;
        obj.headingIconName = @"map_location_default_view_angle";
        obj.modelName = modelName;
    }
    return obj;
}

+ (void) initialize
{
    _DEFAULT = [OALocationIcon withName:@"DEFAULT" iconName:@"map_location_default" headingIconName:@"map_location_default_view_angle" modelName:@"model_map_default_location"];
    _CAR = [OALocationIcon withName:@"CAR" iconName:@"map_location_car" headingIconName:@"map_location_car_view_angle" modelName:@"model_map_car_location"];
    _BICYCLE = [OALocationIcon withName:@"BICYCLE" iconName:@"map_location_bicycle" headingIconName:@"map_location_bicycle_view_angle" modelName:@"model_map_bicycle_location"];
    _MOVEMENT_DEFAULT = [OALocationIcon withName:@"MOVEMENT_DEFAULT" iconName:@"map_navigation_default" headingIconName:@"map_location_default_view_angle" modelName:@"model_map_car_bearing"];
    _MOVEMENT_NAUTICAL = [OALocationIcon withName:@"MOVEMENT_NAUTICAL" iconName:@"map_navigation_nautical" headingIconName:@"map_location_default_view_angle" modelName:@"model_map_navigation_nautical"];
    _MOVEMENT_CAR = [OALocationIcon withName:@"MOVEMENT_CAR" iconName:@"map_navigation_car" headingIconName:@"map_location_default_view_angle" modelName:@"model_map_navigation_car"];
}

+ (OALocationIcon *) locationIconWithName:(NSString *)name
{
    // Temporary fix to prevent possible crash due to old numeric setting
    if ([name isKindOfClass:NSNumber.class]) {
        return _DEFAULT;
    }
    for (OALocationIcon *icon in [self defaultIcons])
    {
        if ([name isEqualToString:icon.name] ||
            [name isEqualToString:icon.iconName] ||
            [name isEqualToString:icon.modelName])
        {
            return icon;
        }
    }
    return _DEFAULT;
}

+ (OALocationIcon *) DEFAULT
{
    return _DEFAULT;
}

+ (OALocationIcon *) CAR
{
    return _CAR;
}

+ (OALocationIcon *) BICYCLE
{
    return _BICYCLE;
}

+ (OALocationIcon *) MOVEMENT_DEFAULT
{
    return _MOVEMENT_DEFAULT;
}

+ (OALocationIcon *) MOVEMENT_NAUTICAL
{
    return _MOVEMENT_NAUTICAL;
}

+ (OALocationIcon *) MOVEMENT_CAR
{
    return _MOVEMENT_CAR;
}

+ (NSArray<OALocationIcon *> *) defaultIcons
{
    return @[_DEFAULT, _CAR, _BICYCLE, _MOVEMENT_DEFAULT, _MOVEMENT_NAUTICAL, _MOVEMENT_CAR];
}

+ (NSArray<NSString *> *) defaultIconNames
{
    NSMutableArray<NSString *> *iconNames = [NSMutableArray array];
    for (OALocationIcon *icon in [self defaultIcons]){
        [iconNames addObject:[icon iconName]];
    }
    return iconNames;
}

+ (NSArray<NSString *> *) defaultIconModels
{
    NSMutableArray<NSString *> *iconNames = [NSMutableArray array];
    for (OALocationIcon *icon in [self defaultIcons]){
        [iconNames addObject:[icon modelName]];
    }
    return iconNames;
}

- (NSString *) name
{
    return _name;
}

- (NSString *) iconName
{
    return _iconName;
}

- (NSString *) headingIconName
{
    return _iconName;
}

- (NSString *) modelName
{
    return _modelName;
}

- (UIImage *) getMapIcon:(UIColor *)color
{
    return [self.class getIcon:self.iconName color:color scaleFactor:[[OAAppSettings sharedManager].textSize get]];
}

+ (UIImage *) getIcon:(NSString *)iconName color:(UIColor *)color scaleFactor:(CGFloat)currentScaleFactor
{
    UIImage *bottomImage;
    UIImage *centerImage;
    UIImage *topImage;
    if ([[self defaultIconNames] containsObject:iconName])
    {
        bottomImage = [UIImage imageNamed:[iconName stringByAppendingString:@"_bottom"]];
        centerImage = [UIImage imageNamed:[iconName stringByAppendingString:@"_center"]];
        topImage = [UIImage imageNamed:[iconName stringByAppendingString:@"_top"]];
    }
    else
    {
        bottomImage = [UIImage imageNamed:@"map_location_default_bottom"];
        centerImage = [UIImage imageNamed:@"map_location_default_center"];
        topImage = [UIImage imageNamed:@"map_location_default_top"];
    }
    return [OAUtilities layeredImageWithColor:color bottom:bottomImage center:centerImage top:topImage scaleFactor:currentScaleFactor];
}

- (UIImage *) getHeadingIconWithColor:(UIColor *)color
{
    return [OAUtilities tintImageWithColor:[UIImage imageNamed:_headingIconName] color:color];
}

- (UIImage *) getPreviewIconWithColor:(UIColor *)color
{
    if ([[self.class defaultIcons] containsObject:self])
    {
        // for embedded icons for 2D & 3D mode show 2D preview
        return [self.class getIcon:_iconName color:color scaleFactor:1];
    }
    else if ([self isModel])
    {
        // for models from 3D plugin show preview image from plugin folder
        return [self getModelPreviewDrawable];
    }
}

- (UIImage *) getModelPreviewDrawable
{
    NSString *shortIconName = [_modelName substringFromIndex:MODEL_NAME_PREFIX.length];
    NSString *modelDirPath = [Model3dHelper getModelPathWithModelName:shortIconName];
    NSString *iconFilePath = [Model3dHelper getModelIconFilePathWithDirPath:modelDirPath];
    if ([NSFileManager.defaultManager fileExistsAtPath:iconFilePath])
    {
        return [UIImage imageNamed:iconFilePath];
    }
    return nil;
}

+ (BOOL) isModel:(NSString *)modelName
{
    return modelName && [modelName hasPrefix:MODEL_NAME_PREFIX];
}

- (BOOL) isModel
{
    return _modelName && [_modelName hasPrefix:MODEL_NAME_PREFIX];
}

- (BOOL) shouldDisplayModel
{
    BOOL use3dIconsByDefault = [[OAAppSettings.sharedManager use3dIconsByDefault] get];
    BOOL hasModel = [self isModel];
    BOOL hasIcon = _iconName;
    return (use3dIconsByDefault && hasModel) || (!hasIcon && hasModel);
}

@end
