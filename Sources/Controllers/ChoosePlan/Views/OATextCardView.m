//
//  OATextCardView.m
//  OsmAnd
//
//  Created by Max Kojin on 17.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATextCardView.h"
#import "OAUtilities.h"

@implementation OATextCardView

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OATextCardView class]])
        {
            self = (OATextCardView *)v;
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
        if ([v isKindOfClass:[OATextCardView class]])
        {
            self = (OATextCardView *)v;
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
