//
//  OAPOIAdapter.m
//  OsmAnd Maps
//
//  Created by nnngrach on 11.08.2023.
//  Copyright © 2023 OsmAnd. All rights reserved.
//

#import "OAPOIAdapter.h"
#import "OAPOI.h"

@implementation OAPOIAdapter

- (instancetype)init
{
    self = [super init];
    if (self)
        _object = [[OAPOI alloc] init];
    return self;
}

- (instancetype) initWithPOI:(id)poi
{
    self = [super init];
    if (self)
        _object = poi;
    return self;
}

- (OAPOI *)getObject
{
    if (_object && [_object isKindOfClass:OAPOI.class])
        return (OAPOI *)_object;
    return nil;
}

- (NSString *) name
{
    OAPOI *obj = [self getObject];
    return obj ? obj.name : nil;
}

- (void) setName:(NSString *)name
{
    OAPOI *obj = [self getObject];
    if (obj)
        obj.name = name;
}

- (NSString *) getDescription:(NSString *)lang
{
    OAPOI *obj = [self getObject];
    if (obj)
    {
        NSString *info = [obj getTagContent:@"description" lang:lang];
        if (!info || info.length == 0)
        {
            return [obj getTagContent:@"content" lang:lang];
        }
        else
        {
            return info;
        }
    }
    return nil;
}

- (NSString *) subtype
{
    OAPOI *obj = [self getObject];
    return obj ? obj.subType : nil;
}

- (double) latitude
{
    OAPOI *obj = [self getObject];
    return obj ? obj.latitude : NAN;
}

- (void) setLatitude:(double)latitude
{
    OAPOI *obj = [self getObject];
    if (obj)
        obj.latitude = latitude;
}

- (double) longitude
{
    OAPOI *obj = [self getObject];
    return obj ? obj.longitude : NAN;
}

- (void) setLongitude:(double)longitude
{
    OAPOI *obj = [self getObject];
    if (obj)
        obj.longitude = longitude;
}

- (NSDictionary<NSString *, NSString *> *)getAdditionalInfo
{
    OAPOI *obj = [self getObject];
    return obj ? [obj getAdditionalInfo] : nil;
}

- (NSString *)getRef
{
    OAPOI *obj = [self getObject];
    return obj ? [obj getRef] : nil;
}

- (NSString *) getRouteId
{
    OAPOI *obj = [self getObject];
    return obj ? [obj getRouteId] : nil;
}

- (NSString *)getName:(NSString *)lang transliterate:(BOOL)transliterate
{
    OAPOI *obj = [self getObject];
    return obj ? [obj getName:lang transliterate:transliterate] : nil;
}

- (NSArray<NSString *> *)getNames:(NSString *)tag defTag:(NSString *)defTag
{
    OAPOI *obj = [self getObject];
    
    if (obj)
    {
        NSString *name =  obj.localizedNames[tag] ? obj.localizedNames[tag] : obj.localizedNames[defTag];
        return name ? @[name] : @[@""];
    }
    return @[@""];
}

- (NSDictionary<NSString *, NSString *> *)getNamesMap:(BOOL)includeEn
{
    OAPOI *obj = [self getObject];
    return obj ? [obj getNamesMap:includeEn] : nil;
}

- (NSString *)getStrictTagContent:(NSString *)tag lang:(NSString *)lang
{
    OAPOI *obj = [self getObject];
    return obj ? [obj getStrictTagContent:tag lang:lang] : nil;
}

- (NSString *)getTagContent:(NSString *)tag
{
    OAPOI *obj = [self getObject];
    return obj ? [obj getTagContent:tag] : nil;
}

- (NSString *)getTagContent:(NSString *)tag lang:(NSString *)lang
{
    OAPOI *obj = [self getObject];
    return obj ? [obj getTagContent:tag lang:lang] : nil;
}

- (NSString *)getTagSuffix:(NSString *)tagPrefix
{
    OAPOI *obj = [self getObject];
    return obj ? [obj getTagSuffix:tagPrefix] : nil;
}

- (NSString *)getLocalizedContent:(NSString *)tag lang:(NSString *)lang
{
    OAPOI *obj = [self getObject];
    return obj ? [obj getLocalizedContent:tag lang:lang] : nil;
}

@end
