//
//  OAMapSourcePreset.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/19/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OAObservable.h"
#import "OAMapSourcePresetValues.h"

typedef NS_ENUM(NSInteger, OAMapSourcePresetType)
{
    OAMapSourcePresetTypeUndefined = -1,
    OAMapSourcePresetTypeGeneral,
    OAMapSourcePresetTypeCar,
    OAMapSourcePresetTypeBicycle,
    OAMapSourcePresetTypePedestrian
};

@class OAMapSourcePresetsCollection;

@interface OAMapSourcePreset : NSObject <NSCoding>

- (id)initWithLocalizedNameKey:(NSString*)localizedNameKey andType:(OAMapSourcePresetType)type andValues:(NSDictionary*)values;

- (void)registerAs:(NSUUID*)uniqueId in:(OAMapSourcePresetsCollection*)owner;

@property(readonly) OAObservable* changeObservable;

@property(readonly) NSUUID* uniqueId;

@property(copy) NSString* name;
@property(readonly) OAObservable* nameChangeObservable;

@property(readonly, copy) NSString* localizedNameKey;

@property(copy) NSString* iconImageName;
@property(readonly) OAObservable* iconImageNameChangeObservable;

@property OAMapSourcePresetType type;
@property(readonly) OAObservable* typeChangeObservable;

@property(readonly) OAMapSourcePresetValues* values;

@end
