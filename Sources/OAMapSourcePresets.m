//
//  OAMapSourcePresets.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/20/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAMapSourcePresets.h"

@implementation OAMapSourcePresets
{
}

- (id)initEmpty
{
    self = [super init];
    if (self) {
        [self ctor];
        _presets = [[NSDictionary alloc] init];
        _order = [[NSArray alloc] init];
    }
    return self;
}

- (id)initWithPresets:(NSDictionary*)presets andOrder:(NSArray*)order
{
    self = [super init];
    if (self) {
        [self ctor];
        _presets = [NSDictionary dictionaryWithDictionary:presets];
        _order = [NSArray arrayWithArray:order];
    }
    return self;
}

- (void)ctor
{
}

@synthesize presets = _presets;
@synthesize order = _order;

@end
