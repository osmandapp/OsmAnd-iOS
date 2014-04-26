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
        andSubresource:(NSString*)subresourceId
{
    self = [super init];
    if (self) {
        [self ctor];
        _resourceId = [resourceId copy];
        _subresourceId = [subresourceId copy];

    }
    return self;
}

- (void)ctor
{
}

@synthesize resourceId = _resourceId;
@synthesize subresourceId = _subresourceId;

- (BOOL)isEqual:(id)object
{
    if(self == object)
        return YES;
    if(object == nil || ![object isKindOfClass:[OAMapSource class]])
        return NO;

    OAMapSource* other = (OAMapSource*)object;
    return [_resourceId isEqualToString:other.resourceId] && [_subresourceId isEqualToString:other.subresourceId];
}

#pragma mark - NSCoding

#define kResourceId @"resource"
#define kSubresourceId @"subresource"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_resourceId forKey:kResourceId];
    [aCoder encodeObject:_subresourceId forKey:kSubresourceId];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self ctor];
        _resourceId = [aDecoder decodeObjectForKey:kResourceId];
        _subresourceId = [aDecoder decodeObjectForKey:kSubresourceId];
    }
    return self;
}

#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone
{
    OAMapSource* clone = [[OAMapSource allocWithZone:zone] initWithResource:_resourceId
                                                             andSubresource:_subresourceId];

    return clone;
}

#pragma mark -

@end
