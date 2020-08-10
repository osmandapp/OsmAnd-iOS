//
//  OAMapSource.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSource.h"

@implementation OAMapSource

@synthesize resourceId = _resourceId;
@synthesize variant = _variant;
@synthesize name = _name;
@synthesize type = _type;

+ (OAMapSource *)fromDictionary:(NSDictionary<NSString *,NSString *> *)dictionary
{
    NSString *resId = dictionary[@"resourceId"];
    NSString *var = dictionary[@"variant"];
    NSString *name = dictionary[@"name"];
    NSString *type = dictionary[@"type"];
    return [[OAMapSource alloc] initWithResource:resId andVariant:var name:name type:type];
}

- (instancetype) init
{
    self = [super init];
    if (self)
        [self commonInit];
   
    return self;
}

- (instancetype) initWithResource:(NSString *)resourceId
{
    self = [super init];
    if (self) {
        [self commonInit];
        _resourceId = [resourceId copy];
        _variant = nil;
        _name = @"OsmAnd";
        _type = nil;

    }
    return self;
}

- (instancetype) initWithResource:(NSString *)resourceId
                       andVariant:(NSString *)variant
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _resourceId = [resourceId copy];
        _variant = [variant copy];
        _name = @"OsmAnd";
        _type = nil;
    }
    return self;
}

- (instancetype) initWithResource:(NSString *)resourceId
                       andVariant:(NSString *)variant
                             name:(NSString *)name
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _resourceId = [resourceId copy];
        _variant = [variant copy];
        _name = [name copy];
        _type = nil;
    }
    return self;
}

- (instancetype) initWithResource:(NSString *)resourceId
                       andVariant:(NSString *)variant
                             name:(NSString *)name
                             type:(NSString *)type
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _resourceId = [resourceId copy];
        _variant = [variant copy];
        _name = [name copy];
        _type = [type copy];
    }
    return self;
}

- (void) commonInit
{
}

- (NSDictionary<NSString *,NSString *> *)toDictionary
{
    NSMutableDictionary<NSString *, NSString *> *result = [NSMutableDictionary new];
    if (_resourceId)
        [result setObject:_resourceId forKey:@"resourceId"];
    if (_variant)
        [result setObject:_variant forKey:@"variant"];
    if (_name)
        [result setObject:_name forKey:@"name"];
    if (_type)
        [result setObject:_type forKey:@"type"];
    return result;
}

- (BOOL) isEqual:(id)object
{
    if (self == object)
        return YES;
    if (object == nil || ![object isKindOfClass:[OAMapSource class]])
        return NO;

    OAMapSource* other = (OAMapSource*)object;
    return [_resourceId isEqualToString:other.resourceId]
           && ([_variant isEqualToString:other.variant] || (_variant == other.variant)) ;
}

- (NSUInteger) hash
{
    return [_resourceId hash] + [_variant hash];
}

+ (OAMapSource *) getOsmAndOnlineTilesMapSource
{
    return [[OAMapSource alloc] initWithResource:@"online_tiles" andVariant:@"OsmAnd (online tiles)" name:@"OsmAnd (online tiles)"];
}

#pragma mark - NSCoding

#define kResourceId @"resource"
#define kVariantId @"variant"
#define kNameId @"name"
#define kTypeId @"type"

- (void) encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_resourceId forKey:kResourceId];
    [aCoder encodeObject:_variant forKey:kVariantId];
    [aCoder encodeObject:_name forKey:kNameId];
    [aCoder encodeObject:_type forKey:kTypeId];
}

- (instancetype) initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        [self commonInit];
        _resourceId = [aDecoder decodeObjectForKey:kResourceId];
        _variant = [aDecoder decodeObjectForKey:kVariantId];
        _name = [aDecoder decodeObjectForKey:kNameId];
        _type = [aDecoder decodeObjectForKey:kTypeId];

        if (_variant == (id)[NSNull null])
            _variant = nil;
        if (_name == nil)
            _name = @"OsmAnd";
        if (_type == (id)[NSNull null])
            _type = nil;
        
        if ([_name isEqualToString:@"sqlitedb"])
        {
            _name = [[_resourceId stringByDeletingPathExtension] stringByReplacingOccurrencesOfString:@"_" withString:@" "];
            _type = @"sqlitedb";
        }
    }
    return self;
}

#pragma mark NSCopying

- (id) copyWithZone:(NSZone *)zone
{
    OAMapSource *clone = [[OAMapSource allocWithZone:zone] initWithResource:_resourceId
                                                                 andVariant:_variant
                                                                       name:_name
                                                                       type:_type];
    return clone;
}

@end
