//
//  OAUserInteractionInterceptorView.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/29/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAUserInteractionInterceptorView.h"
#import "OAUserInteractionInterceptorProtocol.h"

@implementation OAUserInteractionInterceptorView

@synthesize delegate = _delegate;

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    if (_delegate != nil)
    {
        if ([_delegate shouldInterceptInteration:point withEvent:event inView:self])
            return NO;
    }

    for(UIView* view in [self subviews])
    {
        if (view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
            return YES;
    }

    return NO;
}

@end
