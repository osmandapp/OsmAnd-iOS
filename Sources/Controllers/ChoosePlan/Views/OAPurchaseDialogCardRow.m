//
//  OAPurchaseDialogCardRow.m
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAPurchaseDialogCardRow.h"
#import "OAUtilities.h"
#import "OAColors.h"

#define kMinHeight 44
#define kTextMargin 8
#define kDivH 0.5

@implementation OAPurchaseDialogCardRow
{
    CALayer *_div;
}

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
    _imageView.tintColor = UIColorFromRGB(color_dialog_buttons_dark);
    _div = [[CALayer alloc] init];
    _div.backgroundColor = UIColorFromRGB(color_tint_gray).CGColor;
    [self.layer addSublayer:_div];
}

- (void) setText:(NSString *)text textColor:(UIColor *)color image:(UIImage *)image selected:(BOOL)selected showDivider:(BOOL)showDivider
{
    self.imageView.image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.lbTitle.font = [UIFont systemFontOfSize:17.0 weight:UIFontWeightRegular];
    self.lbTitle.textColor = color;
    self.lbTitle.text = text;
    _div.hidden = !showDivider;
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
    
    _div.frame = CGRectMake(tfx, 0, width - tfx, kDivH);
    
    return h;
}

@end
