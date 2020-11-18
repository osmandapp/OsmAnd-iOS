//
//  OALabelCardView.m
//  OsmAnd
//
//  Created by Max Kojin on 17.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OALabelCardView.h"
#import "OAUtilities.h"

@implementation OALabelCardView

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OALabelCardView class]])
        {
            self = (OALabelCardView *)v;
            break;
        }
    
    if (self)
        self.frame = CGRectMake(0, 0, 200, 100);
    
    [self commonInit];
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OALabelCardView class]])
        {
            self = (OALabelCardView *)v;
            break;
        }
    
    if (self)
        self.frame = frame;
    
    [self commonInit];
    return self;
}

- (void) commonInit
{
}

- (CGFloat) updateLayout:(CGFloat)width
{
    return [OAUtilities calculateTextBounds:self.textLabel.text width:width font:self.textLabel.font].height;
}

@end
