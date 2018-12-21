//
//  OAPurchaseDialogCardRow.m
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAPurchaseDialogCardRow.h"
#import "OAUtilities.h"

#define kMinHeight 48
#define kTextMargin 8

@implementation OAPurchaseDialogCardRow

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OAPurchaseDialogCardRow class]])
        {
            self = (OAPurchaseDialogCardRow *)v;
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
        if ([v isKindOfClass:[OAPurchaseDialogCardRow class]])
        {
            self = (OAPurchaseDialogCardRow *)v;
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

- (void) setText:(NSString *)text image:(UIImage *)image selected:(BOOL)selected
{
    self.imageView.image = image;
    self.lbTitle.font = [UIFont systemFontOfSize:16.0 weight:selected ? UIFontWeightMedium : UIFontWeightRegular];
    self.lbTitle.text = text;
}

- (CGFloat) updateLayout:(CGFloat)width
{
    CGFloat tfx = self.lbTitle.frame.origin.x;
    CGFloat tw = width - tfx - kTextMargin;
    CGFloat th = [OAUtilities calculateTextBounds:self.lbTitle.text width:tw font:self.lbTitle.font].height;
    CGFloat h = th + kTextMargin * 2;
    if (h < kMinHeight)
    {
        h = kMinHeight;
        self.lbTitle.frame = CGRectMake(tfx, h / 2 - th / 2, tw, th);
    }
    else
    {
        self.lbTitle.frame = CGRectMake(tfx, kTextMargin, tw, th);
    }
    
    return h;
}

@end
