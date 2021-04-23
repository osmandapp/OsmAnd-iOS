//
//  OACollectionViewCellState.m
//  OsmAnd Maps
//
//  Created by nnngrach on 20.04.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OACollectionViewCellState.h"

@implementation OACollectionViewCellState
{
    NSMutableDictionary<NSIndexPath *, NSValue *> *_values;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _values = [NSMutableDictionary new];
    }
    return self;
}

- (BOOL) containsValueForIndex:(NSIndexPath *)index
{
    return _values[index] != nil;
}

- (CGPoint) getOffsetForIndex:(NSIndexPath *)index
{
    return _values[index].CGPointValue;
}

- (void) setOffset:(CGPoint)offset forIndex:(NSIndexPath *)index
{
    _values[index] = [NSValue valueWithCGPoint:offset];
}

@end
