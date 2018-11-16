//
//  OAFingerRulerDelegate.m
//  OsmAnd
//
//  Created by Paul on 11/16/18.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAFingerRulerDelegate.h"

@implementation OAFingerRulerDelegate

-(id) initWithRulerWidget:(OARulerWidget *)widget
{
    self = [super init];
    if (self)
    {
        [self commonInit:widget];
    }
    return self;
}

-(void) commonInit:(OARulerWidget *)widget
{
    _rulerWidget = widget;
}

- (void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx
{
    [_rulerWidget drawFingerRulerLayer:layer inContext:ctx];
}

@end
