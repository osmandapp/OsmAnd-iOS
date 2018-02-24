//
//  OAScrollView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/02/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAScrollView.h"

@implementation OAScrollView

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.oaDelegate)
        return [self.oaDelegate isScrollAllowed];
    
    return YES;
}

- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    for (UIView *view in self.subviews)
    {
        if (!view.hidden && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL) isSliding
{
    return self.dragging || self.decelerating;
}

- (void) setContentOffset:(CGPoint)contentOffset
{
    [super setContentOffset:contentOffset];

    if (self.oaDelegate)
        [self.oaDelegate onContentOffsetChanged:contentOffset];
}

@end
