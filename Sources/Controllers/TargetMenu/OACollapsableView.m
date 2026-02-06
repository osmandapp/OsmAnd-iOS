//
//  OACollapsableView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACollapsableView.h"

CGFloat const kMarginLeft = 60.0;
CGFloat const kMarginRight = 15.0;
CGFloat const kMarginTop = 10.0;
CGFloat const kCollapsableTitleMarginRight = 95.0;

@implementation OACollapsableView

- (instancetype) initWithDefaultParameters:(BOOL)collapsed
{
    //Default values from our previous code
    self = [self initWithFrame:CGRectMake(0, 0, 320, 100)];
    if (self)
    {
        self.collapsed = collapsed;
    }
    return self;
}

- (void) adjustHeightForWidth:(CGFloat)width
{
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
}

- (void) setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
}

@end
