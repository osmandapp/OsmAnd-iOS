//
//  OAPurchaseDialogCardView.m
//  OsmAnd
//
//  Created by Alexey on 20/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABaseFeatureCardView.h"

@implementation OABaseFeatureCardView

- (void) layoutSubviews
{
    //[self updateLayout:self.frame.size.width];
}

- (CGFloat) updateLayout:(CGFloat)y
{
    return 0;
}

- (CGFloat)updateFrame:(CGFloat)y
{
    return [self updateLayout:y];
}

@end
