//
//  OACollapsableLabelView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACollapsableLabelView.h"
#import "OAUtilities.h"

@implementation OACollapsableLabelView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UIFont *font = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
        CGFloat viewWidth = frame.size.width;
        _label = [[UILabel alloc] initWithFrame:CGRectMake(50.0, 12.0, viewWidth - 10.0, 21.0)];
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _label.font = font;
        _label.textColor = [UIColor blackColor];
        [self addSubview:_label];
    }
    return self;
}

- (void)adjustHeightForWidth:(CGFloat)width
{
    CGSize bounds = [OAUtilities calculateTextBounds:_label.text width:width - 60.0 font:_label.font];
    CGFloat viewHeight = MAX(bounds.height, 21.0) + 0.0 + 11.0;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, viewHeight);
    _label.frame = CGRectMake(50.0, 0.0, width - 10.0, viewHeight - 0.0 - 11.0);
}

@end
