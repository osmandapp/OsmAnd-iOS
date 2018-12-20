//
//  OAPurchaseDialogCardButtonEx.m
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAPurchaseDialogCardButton.h"
#import "OAUtilities.h"

#define kMarginVert 8.0
#define kMarginHor 12.0
#define kMarginBtn 16.0
#define kMarginLabel 4.0

#define kMinBtnTxtWidth 72.0
#define kMaxBtnTxtWidth 120.0
#define kBtnHeight 36.0
#define kMinHeight 60

@implementation OAPurchaseDialogCardButton
{
    OAPurchaseDialogCardButtonClickHandler _buttonClickHandler;
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OAPurchaseDialogCardButton class]])
        {
            self = (OAPurchaseDialogCardButton *)v;
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
        if ([v isKindOfClass:[OAPurchaseDialogCardButton class]])
        {
            self = (OAPurchaseDialogCardButton *)v;
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

- (void) setupButton:(BOOL)purchased active:(BOOL)active cancel:(BOOL)cancel title:(NSAttributedString *)title description:(NSAttributedString *)description discountDescr:(NSString *)discountDescr showDiscount:(BOOL)showDiscount highDiscount:(BOOL)highDiscount buttonClickHandler:(nullable OAPurchaseDialogCardButtonClickHandler)buttonClickHandler
{
    _buttonClickHandler = buttonClickHandler;
    
    self.backgroundColor = active ? UIColorFromRGB(0xf3edae) : UIColorFromRGB(0xffffff);
    self.lbTitle.attributedText = title;
    self.lbDescription.attributedText = description;
    if (active)
    {
        self.btnRegular.hidden = YES;
        self.btnExtended.hidden = !cancel;
        self.btnDisabled.hidden = cancel;
    }
    else
    {
        self.btnRegular.hidden = !purchased;
        self.btnExtended.hidden = purchased;
        self.btnDisabled.hidden = YES;
    }
    self.lbSaveLess.text = discountDescr;
    self.lbSaveMore.text = discountDescr;
    self.lbSaveLess.hidden = showDiscount && highDiscount;
    self.lbSaveMore.hidden = showDiscount && !highDiscount;
    
    UIButton *activeButton = [self getActiveButton];
    if (activeButton)
        [activeButton addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
}

- (UIButton *) getActiveButton
{
    if (!self.btnRegular.hidden)
        return self.btnRegular;
    else if (!self.btnExtended.hidden)
        return self.btnExtended;
    else
        return self.btnDisabled;
}

- (void) buttonPressed
{
    if (_buttonClickHandler)
        _buttonClickHandler();
}

- (CGFloat) updateLayout:(CGFloat)width
{
    CGFloat w = width;
    CGFloat h = kMinHeight;
    UIButton *activeButton = [self getActiveButton];

    CGFloat btnWidth = [OAUtilities calculateTextBounds:activeButton.titleLabel.text width:kMaxBtnTxtWidth font:activeButton.titleLabel.font].width + kMarginVert * 2;
    CGFloat btnHeight = kBtnHeight;
    activeButton.frame = CGRectMake(w - btnWidth - kMarginHor, h / 2 - btnHeight / 2, btnWidth, btnHeight);
    CGRect bf = activeButton.frame;
    
    CGFloat tw = bf.origin.x - kMarginBtn;
    CGFloat th = [OAUtilities calculateTextBounds:self.lbTitle.text width:tw font:self.lbTitle.font].height;
    self.lbTitle.frame = CGRectMake(kMarginHor, kMarginVert, tw, th);
    CGRect tf = self.lbTitle.frame;

    UILabel *activeDiscount = nil;
    if (!self.lbSaveLess.hidden)
        activeDiscount = self.lbSaveLess;
    else if (!self.lbSaveMore.hidden)
        activeDiscount = self.lbSaveMore;

    CGRect af = CGRectNull;
    CGFloat dw;
    if (activeDiscount)
    {
        CGSize s = [OAUtilities calculateTextBounds:activeDiscount.text width:1000.0 font:activeDiscount.font];
        activeDiscount.frame = CGRectMake(bf.origin.x - kMarginBtn - s.width - 2 * 2, 0, s.width + 2 * 2, s.height + 2 * 2);
        af = activeDiscount.frame;
        dw = af.origin.x - kMarginLabel - kMarginHor;
    }
    else
    {
        dw = tw;
    }
    
    CGFloat dh = [OAUtilities calculateTextBounds:self.lbDescription.text width:dw font:self.lbDescription.font].height;
    self.lbDescription.frame = CGRectMake(kMarginHor, tf.origin.y + tf.size.height + 4.0, dw, dh);
    CGRect df = self.lbDescription.frame;
    if (activeDiscount)
    {
        af.origin.y = df.origin.y + df.size.height - af.size.height;
        activeDiscount.frame = af;
    }

    h = df.origin.y + df.size.height + kMarginVert;
    bf.origin.y = h / 2 - bf.size.height / 2;
    activeButton.frame = bf;
    
    return h;
}

@end
