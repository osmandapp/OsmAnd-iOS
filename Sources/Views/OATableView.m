//
//  OATableView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 14/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATableView.h"

@implementation OATableView
{
    CGPoint _lastVelocity;
}

- (BOOL) gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.oaDelegate)
        return [self.oaDelegate tableViewScrollAllowed:self];
    
    return YES;
}

- (BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *headerView = self.tableHeaderView;
    if (headerView && [headerView pointInside:[self convertPoint:point toView:headerView] withEvent:event])
        return NO;
    else
        return YES;
}

- (BOOL) isSliding
{
    return self.dragging || self.decelerating;
}

- (void) setContentOffset:(CGPoint)contentOffset
{
    [super setContentOffset:contentOffset];
 
    CGPoint velocity = [self.panGestureRecognizer velocityInView:self];
    if (velocity.y != 0)
    {
        _lastVelocity = velocity;
    }
    else if (_lastVelocity.y != 0)
    {
        [self.oaDelegate tableViewWillEndDragging:self withVelocity:_lastVelocity];
        _lastVelocity = CGPointZero;
    }
    
    if (self.oaDelegate)
        [self.oaDelegate tableViewContentOffsetChanged:self contentOffset:contentOffset];
}

@end
