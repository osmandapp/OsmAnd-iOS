//
//  OAUserInteractionPassThroughView.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAUserInteractionPassThroughView.h"
#import "OAObservable.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAUserInteractionPassThroughView

@synthesize didLayoutObservable = _didLayoutObservable;

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        _didLayoutObservable = [[OAObservable alloc] init];
        _isScreenClickable = YES;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [_didLayoutObservable notifyEvent];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (LockHelper.shared.isScreenLocked || !_isScreenClickable)
    {
        if ([self.delegate respondsToSelector:@selector(isTouchEventAllowedForView:)])
        {
            // Quick-action buttons are siblings of this view in the map HUD container.
            UIView *findView = [self findView:self.superview ?: self atPoint:point withEvent:event];
            return findView ?: self;
        }
        return [super hitTest:point withEvent:event];
    }
    
    UIView *view = [super hitTest:point withEvent:event];
    return view == self ? nil : view;
}

- (UIView *)findView:(UIView *)view atPoint:(CGPoint)point withEvent:(UIEvent *)event
{
    if (view.hidden || view.alpha <= 0.01 || !view.userInteractionEnabled)
        return nil;

    if ([self.delegate isTouchEventAllowedForView:view])
    {
        CGPoint convertedPoint = [view convertPoint:point fromView:self];
        if ([view pointInside:convertedPoint withEvent:event])
            return view;
    }
    
    for (UIView *subview in view.subviews)
    {
        UIView *foundView = [self findView:subview atPoint:point withEvent:event];
        if (foundView)
        {
            return foundView;
        }
    }
    return nil;
}

@end
