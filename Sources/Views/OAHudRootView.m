//
//  OAHudRootView.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 8/21/13.
//  Copyright (c) 2013 OsmAnd. All rights reserved.
//

#import "OAHudRootView.h"

@implementation OAHudRootView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    for(UIView* view in [self subviews])
    {
        if(view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event])
            return YES;
    }
    
    return NO;
}

@end
