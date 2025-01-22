//
//  OAMapObject.mm
//  OsmAnd
//
//  Created by Max Kojin on 09/12/24.
//  Copyright © 2024 OsmAnd. All rights reserved.
//

#import "OAMapObject.h"

@implementation OAMapObject

- (instancetype)init
{
    self = [super init];
    if (self) {
        _x = [NSMutableArray new];
        _y = [NSMutableArray new];
    }
    return self;
}

- (void) addLocation:(int)x y:(int)y
{
    [_x addObject:@(x)];
    [_y addObject:@(y)];
}


@end
