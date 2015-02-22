//
//  OAMapSource.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 4/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSource.h"

@implementation OAMapSource
{
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithResource:(NSString*)resourceId
{
    self = [super init];
    if (self) {
        [self commonInit];
        _resourceId = [resourceId copy];
        _variant = nil;
        _name = @"OsmAnd";

    }
    return self;
}

- (instancetype)initWithResource:(NSString*)resourceId
                      andVariant:(NSString*)variant
{
    self = [super init];
    if (self) {
        [self commonInit];
        _resourceId = [resourceId copy];
        _variant = [variant copy];
        _name = @"OsmAnd";

    }
    return self;
}

- (instancetype)initWithResource:(NSString*)resourceId
                      andVariant:(NSString*)variant
                            name:(NSString*)name
{
    self = [super init];
    if (self) {
        [self commonInit];
        _resourceId = [resourceId copy];
        _variant = [variant copy];
        _name = [name copy];
        
    }
    return self;
}

- (void)commonInit
{
}

@synthesize resourceId = _resourceId;
@synthesize variant = _variant;
@synthesize name = _name;

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    if (object == nil || ![object isKindOfClass:[OAMapSource class]])
        return NO;

    OAMapSource* other = (OAMapSource*)object;
    return [_resourceId isEqualToString:other.resourceId]
           && ([_variant isEqualToString:other.variant] || (_variant == other.variant)) ;
}

#pragma mark - NSCoding

#define kResourceId @"resource"
#define kVariantId @"variant"
#define kNameId @"name"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_resourceId forKey:kResourceId];
    [aCoder encodeObject:_variant forKey:kVariantId];
    [aCoder encodeObject:_name forKey:kNameId];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self commonInit];
        _resourceId = [aDecoder decodeObjectForKey:kResourceId];
        _variant = [aDecoder decodeObjectForKey:kVariantId];
        _name = [aDecoder decodeObjectForKey:kNameId];

        if (_variant == (id)[NSNull null])
            _variant = nil;
        if (_name == nil)
            _name = @"OsmAnd";
    }
    return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OAMapSource* clone = [[OAMapSource allocWithZone:zone] initWithResource:_resourceId
                                                                 andVariant:_variant
                                                                       name:_name];

    return clone;
}

#pragma mark -

@end
