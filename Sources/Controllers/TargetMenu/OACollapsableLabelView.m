//
//  OACollapsableLabelView.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OACollapsableLabelView.h"
#import "OACustomLabel.h"

@implementation OACollapsableLabelView

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        UIFont *font = [UIFont systemFontOfSize:15.0];
        CGFloat viewWidth = frame.size.width;
        _label = [[OACustomLabel alloc] initWithFrame:CGRectMake(kMarginLeft, 12.0, viewWidth - kMarginLeft - kMarginRight, 21.0)
                                            tapToCopy:YES
                                      longPressToCopy:YES];
        _label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        _label.font = font;
        _label.textColor = UIColorFromRGB(0x212121);
        _label.numberOfLines = 0;
        [_label bringSubviewToFront:self];
        [self addSubview:_label];
    }
    return self;
}

- (void) adjustHeightForWidth:(CGFloat)width
{
    CGSize bounds = [OAUtilities calculateTextBounds:_label.text width:width - kMarginLeft - kMarginRight font:_label.font];
    CGFloat viewHeight = MAX(bounds.height, 21.0) + 0.0 + 11.0;
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, viewHeight);
    _label.frame = CGRectMake(kMarginLeft, 0.0, width - kMarginLeft - kMarginRight, viewHeight - 0.0 - 11.0);
}

@end
