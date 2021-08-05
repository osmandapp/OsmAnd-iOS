//
//  OAUserInteractionPassThroughView.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAUserInteractionPassThroughView.h"

@implementation OAUserInteractionPassThroughView

@synthesize didLayoutObservable = _didLayoutObservable;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _didLayoutObservable = [[OAObservable alloc] init];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [_didLayoutObservable notifyEvent];
}

- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    for (UIView* view in [self subviews])
    {
        if (view.userInteractionEnabled && !view.hidden && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
            return YES;
    }
    
    return NO;
}

@end
