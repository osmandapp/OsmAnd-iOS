//
//  OACollectionViewCellState.m
//  OsmAnd Maps
//
//  Created by nnngrach on 20.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACollectionViewCellState.h"

@implementation OACollectionViewCellState

- (instancetype)init
{
    self = [super init];
    if (self) {
        _values = [NSMutableDictionary new];
    }
    return self;
}

@end
