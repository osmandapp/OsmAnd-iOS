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
        _optionalLabel = @"";

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
        _optionalLabel = @"";

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
        _optionalLabel = @"";
        
    }
    return self;
}

- (instancetype)initWithResource:(NSString*)resourceId
                      andVariant:(NSString*)variant
                            name:(NSString*)name
                   optionalLabel:(NSString*)optionalLabel
{
    self = [super init];
    if (self) {
        [self commonInit];
        _resourceId = [resourceId copy];
        _variant = [variant copy];
        _name = [name copy];
        _optionalLabel = [optionalLabel copy];
        
    }
    return self;
}

- (void)commonInit
{
}

@synthesize resourceId = _resourceId;
@synthesize variant = _variant;
@synthesize name = _name;
@synthesize optionalLabel = _optionalLabel;

- (BOOL)isEqual:(id)object
{
    if (self == object)
        return YES;
    if (object == nil || ![object isKindOfClass:[OAMapSource class]])
        return NO;

    OAMapSource* other = (OAMapSource*)object;
    return [_resourceId isEqualToString:other.resourceId]
           && ([_variant isEqualToString:other.variant] || (_variant == other.variant) || (_optionalLabel == other.optionalLabel)) ;
}

-(NSUInteger)hash
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
#define kOptionalLabelId @"optionalLabel"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:_resourceId forKey:kResourceId];
    [aCoder encodeObject:_variant forKey:kVariantId];
    [aCoder encodeObject:_name forKey:kNameId];
    [aCoder encodeObject:_optionalLabel forKey:kOptionalLabelId];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self commonInit];
        _resourceId = [aDecoder decodeObjectForKey:kResourceId];
        _variant = [aDecoder decodeObjectForKey:kVariantId];
        _name = [aDecoder decodeObjectForKey:kNameId];
        _optionalLabel = [aDecoder decodeObjectForKey:kOptionalLabelId];

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
                                                                       name:_name
                                                              optionalLabel:_optionalLabel];

    return clone;
}

#pragma mark -

@end
