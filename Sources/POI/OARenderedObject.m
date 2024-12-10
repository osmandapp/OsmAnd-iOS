//
//  OARenderedObject.m
//  OsmAnd
//
//  Created by Max Kojin on 09/12/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OARenderedObject.h"

@implementation OARenderedObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        _x = [NSMutableArray new];
        _y = [NSMutableArray new];
    }
    return self;
}

- (BOOL) isText
{
    return self.name && self.name.length > 0;
}

- (void) addLocation:(int)x y:(int)y
{
    [_x addObject:@(x)];
    [_y addObject:@(y)];
}

@end
