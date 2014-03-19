//
//  OAMapSourcePreset.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/19/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, OAMapSourcePresetType)
{
    OAMapSourcePresetTypeUndefined = -1,
    OAMapSourcePresetTypeGeneral,
    OAMapSourcePresetTypeCar,
    OAMapSourcePresetTypeBicycle,
    OAMapSourcePresetTypePedestrian
};

@interface OAMapSourcePreset : NSObject <NSCoding>

- (id)init;
- (id)initWithLocalizedNameKey:(NSString*)localizedNameKey andType:(OAMapSourcePresetType)type andValues:(NSDictionary*)values;

@property(getter = getName, setter = setName:) NSString* name;
@property NSString* localizedNameKey;
@property NSString* iconImageName;
@property OAMapSourcePresetType type;
@property NSMutableDictionary* values;

@end
