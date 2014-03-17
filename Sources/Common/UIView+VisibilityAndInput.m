//
//  UIView+VisibilityAndInput.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 3/17/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "UIView+VisibilityAndInput.h"

@implementation UIView (VisibilityAndInput)

- (void)hideAndDisableInput
{
    self.hidden = YES;
    self.userInteractionEnabled = NO;
}

- (void)showAndEnableInput
{
    self.hidden = NO;
    self.userInteractionEnabled = YES;
}

- (BOOL)isGone
{
    return (self.hidden && !self.userInteractionEnabled);
}

@end
