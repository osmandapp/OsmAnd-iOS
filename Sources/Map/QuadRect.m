//
//  QuadRect.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "QuadRect.h"

@implementation QuadRect

- (instancetype)initWithLeft:(double)left top:(double)top right:(double)right bottom:(double)bottom
{
    self = [super init];
    if (self)
    {
        _left = left;
        _top = top;
        _right = right;
        _bottom = bottom;
    }
    return self;
}

- (instancetype)initWithRect:(QuadRect *)rect
{
    self = [super init];
    if (self)
    {
        _left = rect.left;
        _top = rect.top;
        _right = rect.right;
        _bottom = rect.bottom;
    }
    return self;
}


- (double)width
{
    return _right - _left;
}

- (double)height
{
    return _bottom - _top;
}

- (BOOL)contains:(double)left top:(double)top right:(double)right bottom:(double)bottom
{
    return MIN(_left, _right) <= MIN(left, right)
            && MAX(_left, _right) >= MAX(left, right)
            && MIN(_top, _bottom) <= MIN(top, bottom)
            && MAX(_top, _bottom) >= MAX(top, bottom);
}

- (BOOL)contains:(QuadRect *)box
{
    return [self contains:box.left top:box.top right:box.right bottom:box.bottom];
}

+ (BOOL)intersects:(QuadRect *)a b:(QuadRect *)b
{
    return a.left < b.right && b.left < a.right && a.top < b.bottom && b.top < a.bottom;
}

- (double)centerX
{
    return (_left + _right) / 2;
}

- (double) centerY
{
    return (_top + _bottom) / 2;
}

- (void)offset:(double)dx dy:(double)dy
{
    _left += dx;
    _top += dy;
    _right += dx;
    _bottom += dy;
}

- (void)inset:(double)dx dy:(double)dy
{
    _left += dx;
    _top += dy;
    _right -= dx;
    _bottom -= dy;
}

@end