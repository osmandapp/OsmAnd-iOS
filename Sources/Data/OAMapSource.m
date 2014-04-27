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

- (id)init
{
    self = [super init];
    if (self) {
        [self ctor];
    }
    return self;
}

- (id)initWithResource:(NSString*)resourceId
{
    self = [super init];
    if (self) {
        [self ctor];
        _resourceId = [resourceId copy];
        _variant = nil;

    }
    return self;
}

- (id)initWithResource:(NSString*)resourceId
            andVariant:(NSString*)variant
{
    self = [super init];
    if (self) {
        [self ctor];
        _resourceId = [resourceId copy];
        _variant = [variant copy];

    }
    return self;
}

- (void)ctor
{
}

@synthesize resourceId = _resourceId;
@synthesize variant = _variant;

- (BOOL)isEqual:(id)object
{
    if(self == object)
        return YES;
    if(object == nil || ![object isKindOfClass:[OAMapSource class]])
        return NO;

    OAMapSource* other = (OAMapSource*)object;
    return [_resourceId isEqualToString:other.resourceId] && [_variant isEqualToString:other.variant];
}

#pragma mark - NSCoding

#define kResourceId @"resource"
#define kVariantId @"variant"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_resourceId forKey:kResourceId];
    [aCoder encodeObject:_variant forKey:kVariantId];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self ctor];
        _resourceId = [aDecoder decodeObjectForKey:kResourceId];
        _variant = [aDecoder decodeObjectForKey:kVariantId];
    }
    return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OAMapSource* clone = [[OAMapSource allocWithZone:zone] initWithResource:_resourceId
                                                             andVariant:_variant];

    return clone;
}

#pragma mark -

@end
