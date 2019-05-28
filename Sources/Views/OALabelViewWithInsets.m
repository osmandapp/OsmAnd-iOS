//
//  OALabelViewWithInsets.m
//  OsmAnd
//
//  Created by Paul on 5/28/19.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OALabelViewWithInsets.h"

@implementation OALabelViewWithInsets

@synthesize topInset, leftInset, bottomInset, rightInset;

- (void) drawTextInRect:(CGRect) rect
{
    UIEdgeInsets insets = {self.topInset, self.leftInset,
        self.bottomInset, self.rightInset};
    
    return [super drawTextInRect:UIEdgeInsetsInsetRect(rect, insets)];
}


@end
