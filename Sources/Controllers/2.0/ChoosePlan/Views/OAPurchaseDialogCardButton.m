//
//  OAPurchaseDialogCardButtonEx.m
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAPurchaseDialogCardButton.h"
#import "OAUtilities.h"
#import "OAColors.h"

#define kMarginVert 8.0
#define kMarginHor 12.0
#define kMarginBtn 16.0
#define kMarginBtnHor 12.0
#define kMarginLabel 4.0
#define kSaveMargin 2.0

#define kMinBtnTxtWidth 72.0
#define kMaxBtnTxtWidth 120.0
#define kBtnHeight 36.0
#define kMinHeight 60
#define kDivH 1.0

@interface OAPurchaseDialogCardButton()

@property (nonatomic) BOOL active;

@end

@implementation OAPurchaseDialogCardButton
{
    CALayer *_topDiv;
    CALayer *_bottomDiv;
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
    self.btnRegular.layer.cornerRadius = 3;
    self.btnExtended.layer.cornerRadius = 3;
    self.btnDisabled.layer.cornerRadius = 3;
    
    self.lbSaveLess.backgroundColor = UIColorFromRGB(color_card_divider_light);
    self.lbSaveLess.layer.cornerRadius = 2;
    self.lbSaveLess.clipsToBounds = YES;

    self.lbSaveMore.layer.cornerRadius = 2;
    self.lbSaveMore.layer.borderWidth = 0.8;
    self.lbSaveMore.layer.borderColor = UIColorFromRGB(color_osmand_orange).CGColor;
    self.lbSaveMore.clipsToBounds = YES;

    _topDiv = [[CALayer alloc] init];
    _topDiv.backgroundColor = UIColorFromRGB(color_card_divider_light).CGColor;
    [self.layer addSublayer:_topDiv];
    _bottomDiv = [[CALayer alloc] init];
    _bottomDiv.backgroundColor = UIColorFromRGB(color_card_divider_light).CGColor;
    [self.layer addSublayer:_bottomDiv];
}

- (void) setupButtonActive:(BOOL)active title:(NSAttributedString *)title description:(NSAttributedString *)description buttonText:(NSString *)buttonText buttonType:(EOAPurchaseDialogCardButtonType)buttonType discountDescr:(NSString *)discountDescr showDiscount:(BOOL)showDiscount highDiscount:(BOOL)highDiscount showTopDiv:(BOOL)showTopDiv showBottomDiv:(BOOL)showBottomDiv buttonClickHandler:(nullable OAPurchaseDialogCardButtonClickHandler)buttonClickHandler
{
    self.active = active;
    _topDiv.hidden = !showTopDiv;
    _bottomDiv.hidden = !showBottomDiv;

    self.backgroundColor = active ? UIColorFromRGB(0xf3edae) : UIColor.clearColor;
    self.lbTitle.attributedText = title;
    self.lbDescription.attributedText = description;

    self.btnRegular.hidden = YES;
    self.btnExtended.hidden = YES;
    self.btnDisabled.hidden = YES;
    switch (buttonType)
    {
        case EOAPurchaseDialogCardButtonTypeRegular:
            self.btnRegular.hidden = NO;
            break;
        case EOAPurchaseDialogCardButtonTypeExtended:
            self.btnExtended.hidden = NO;
            break;
        case EOAPurchaseDialogCardButtonTypeDisabled:
            self.btnDisabled.hidden = NO;
            break;
        default:
            break;
    }
    
    self.lbSaveLess.text = discountDescr;
    self.lbSaveMore.text = discountDescr;
    self.lbSaveLess.hidden = !showDiscount || highDiscount;
    self.lbSaveMore.hidden = !showDiscount || !highDiscount;
    
    UIButton *activeButton = [self getActiveButton];
    if (activeButton)
    {
        _buttonClickHandler = buttonClickHandler;
        [activeButton setTitle:buttonText forState:UIControlStateNormal];
        [activeButton addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
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

    CGFloat btnWidth = [OAUtilities calculateTextBounds:activeButton.titleLabel.text width:kMaxBtnTxtWidth font:activeButton.titleLabel.font].width + kMarginBtnHor * 2;
    btnWidth = MAX(kMinBtnTxtWidth, btnWidth);
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
        CGFloat adw = s.width + kSaveMargin * 4;
        activeDiscount.frame = CGRectMake(bf.origin.x - kMarginBtn - adw, 0, adw, s.height + kSaveMargin * 2);
        af = activeDiscount.frame;
        dw = af.origin.x - kMarginLabel - kMarginHor;
    }
    else
    {
        dw = tw;
    }
    
    CGFloat dh = [OAUtilities calculateTextBounds:self.lbDescription.attributedText width:dw].height;
    self.lbDescription.frame = CGRectMake(kMarginHor, tf.origin.y + tf.size.height + 4.0, dw, dh);
    CGRect df = self.lbDescription.frame;
    if (activeDiscount)
    {
        af.origin.y = df.origin.y + df.size.height - af.size.height + kSaveMargin;
        activeDiscount.frame = af;
    }

    h = df.origin.y + df.size.height + kMarginVert;
    bf.origin.y = h / 2 - bf.size.height / 2;
    activeButton.frame = bf;
    
    if (self.active)
    {
        _topDiv.frame = CGRectMake(0, 0, width, kDivH);
        _bottomDiv.frame = CGRectMake(0, h - kDivH, width, kDivH);
    }
    else
    {
        _topDiv.frame = CGRectMake(kMarginHor, 0, width - kMarginHor * 2, kDivH);
        _bottomDiv.frame = CGRectMake(kMarginHor, 0, width - kMarginHor * 2, kDivH);
    }
    
    return h;
}

@end
