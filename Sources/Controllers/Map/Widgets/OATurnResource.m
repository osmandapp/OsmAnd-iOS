//
//  OATurnResource.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/11/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATurnResource.h"

@implementation OATurnResource

- (instancetype) initWithTurnType:(int)turnType noOverlap:(BOOL)noOverlap leftSide:(BOOL)leftSide
{
    self = [super init];
    if (self)
    {
        _turnType = turnType == 0 ? 1 : turnType;
        _noOverlap = noOverlap;
        _shortArrow = NO;
        _leftSide = leftSide;
    }
    return self;
}

- (instancetype) initWithTurnTypeShort:(int)turnType leftSide:(BOOL)leftSide
{
    self = [super init];
    if (self)
    {
        _turnType = turnType == 0 ? 1 : turnType;
        _shortArrow = YES;
        _noOverlap = NO;
        _leftSide = leftSide;
    }
    return self;
}

- (BOOL) isEqual:(id)object
{
    if (self == object)
        return YES;
    if (!object|| ![self isKindOfClass:[object class]])
        return NO;
    
    OATurnResource *turnResource = (OATurnResource *) object;
    return turnResource.turnType == _turnType && turnResource.shortArrow == _shortArrow && turnResource.noOverlap == _noOverlap && turnResource.leftSide == _leftSide;
}

- (NSUInteger) hash
{
    return (_turnType + (_noOverlap ? 100 : 1) + (_shortArrow ? 1000 : 1)) * (_leftSide ? -1 : 1);
}

@end
