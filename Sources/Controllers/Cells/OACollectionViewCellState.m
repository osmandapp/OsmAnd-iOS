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
    NSMutableDictionary<NSString *, NSValue *> *_values;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _values = [NSMutableDictionary new];
    }
    return self;
}

- (BOOL) containsValueForKey:(NSString *)key
{
    return _values[key] != nil;
}

- (CGPoint) getOffsetForKey:(NSString *)key
{
    return _values[key].CGPointValue;
}

- (void) setOffset:(CGPoint)offset forKey:(NSString *)key
{
    _values[key] = [NSValue valueWithCGPoint:offset];
}

@end
