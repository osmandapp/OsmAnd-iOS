//
//  OAFingerRulerDelegate.m
//  OsmAnd
//
//  Created by Paul on 11/16/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAFingerRulerDelegate.h"

@implementation OAFingerRulerDelegate

- (id) initWithRulerLayer:(OARulerByTapView *)rulerLayer
{
    self = [super init];
    if (self)
    {
        [self commonInit:rulerLayer];
    }
    return self;
}

- (void) commonInit:(OARulerByTapView *)layer
{
    _rulerByTapControl = layer;
}

- (void) drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    [_rulerByTapControl drawFingerRulerLayer:layer inContext:ctx];
}

@end
