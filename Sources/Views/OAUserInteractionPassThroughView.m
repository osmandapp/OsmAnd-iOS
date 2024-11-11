//
//  OAUserInteractionPassThroughView.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAUserInteractionPassThroughView.h"
#import "OAObservable.h"
#import "OAHudButton.h"
#import "OsmAnd_Maps-Swift.h"

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

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    if (LockHelper.shared.isScreenLocked)
    {
        if ([self.delegate respondsToSelector:@selector(isTouchEventAllowedForView:)])
        {
            UIView *findView = [self findView:self];
            if (findView)
            {
                CGPoint convertedPoint = [findView convertPoint:point fromView:self];
                if ([findView pointInside:convertedPoint withEvent:event])
                    return findView;
                else
                    return self;
            }
        }
        return [super hitTest:point withEvent:event];
    }
    
    UIView *view = [super hitTest:point withEvent:event];
    return view == self ? nil : view;
}

- (UIView *)findView:(UIView *)view
{
    BOOL isTouchEventAllowed = [self.delegate isTouchEventAllowedForView:view];
    if (isTouchEventAllowed)
        return view;
    
    for (UIView *subview in view.subviews)
    {
        UIView *foundView = [self findView:subview];
        if (foundView)
        {
            return foundView;
        }
    }
    return nil;
}

@end
