//
//  OAPurchaseDialogCardView.m
//  OsmAnd
//
//  Created by Alexey on 20/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAPurchaseDialogItemView.h"

@implementation OAPurchaseDialogItemView

- (void) layoutSubviews
{
    //[self updateLayout:self.frame.size.width];
}

- (CGFloat) updateLayout:(CGFloat)width
{
    return 0;
}

- (CGRect) updateFrame:(CGFloat)width
{
    CGFloat h = [self updateLayout:width];
    CGRect f = self.frame;
    f.size.width = width;
    f.size.height = h;
    self.frame = f;
    return f;
}

@end
