//
//  OAMapViewState.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapViewState.h"

@implementation OAMapViewState
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

- (void)commonInit
{
}

@synthesize target31 = _target31;
@synthesize zoom = _zoom;
@synthesize azimuth = _azimuth;

#pragma mark - NSCoding

#define kTarget31x @"target31.x"
#define kTarget31y @"target31.y"
#define kZoom @"zoom"
#define kAzimuth @"azimuth"

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt32:_target31.x forKey:kTarget31x];
    [aCoder encodeInt32:_target31.y forKey:kTarget31y];
    [aCoder encodeFloat:_zoom forKey:kZoom];
    [aCoder encodeFloat:_azimuth forKey:kAzimuth];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self) {
        [self commonInit];
        _target31.x = [aDecoder decodeInt32ForKey:kTarget31x];
        _target31.y = [aDecoder decodeInt32ForKey:kTarget31y];
        _zoom = [aDecoder decodeFloatForKey:kZoom];
        _azimuth = [aDecoder decodeFloatForKey:kAzimuth];
    }
    return self;
}

#pragma mark -

@end
