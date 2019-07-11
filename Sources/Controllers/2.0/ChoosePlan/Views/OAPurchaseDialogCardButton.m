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
#define kBtnHeight 42.0
#define kMinHeight 122.0
#define kTwoLinedButtonHeight 60.0
#define kDivH 0.5

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
    CALayer *buttonLayer = self.btnPurchase.layer;
    buttonLayer.cornerRadius = 9.;
    buttonLayer.borderWidth = 2.;
    buttonLayer.borderColor = UIColorFromRGB(color_primary_purple).CGColor;
    

    _topDiv = [[CALayer alloc] init];
    _topDiv.backgroundColor = UIColorFromRGB(color_tint_gray).CGColor;
    [self.layer addSublayer:_topDiv];
    _bottomDiv = [[CALayer alloc] init];
    _bottomDiv.backgroundColor = UIColorFromRGB(color_tint_gray).CGColor;
    [self.layer addSublayer:_bottomDiv];
}

- (void) setupButton:(EOAPurchaseDialogCardButtonType)type
{
    CALayer *buttonLayer = self.btnPurchase.layer;
    switch (type)
    {
        case EOAPurchaseDialogCardButtonTypeRegular:
            self.btnPurchase.userInteractionEnabled = YES;
            buttonLayer.borderWidth = 2.;
            buttonLayer.borderColor = UIColorFromRGB(color_primary_purple).CGColor;
            break;
        case EOAPurchaseDialogCardButtonTypeExtended:
            self.btnPurchase.userInteractionEnabled = YES;
            break;
        case EOAPurchaseDialogCardButtonTypeDisabled:
            self.btnPurchase.userInteractionEnabled = NO;
            buttonLayer.borderWidth = 0.;
            buttonLayer.backgroundColor = UIColorFromRGB(color_disabled_light).CGColor;
            [self.btnPurchase setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            break;
        case EOAPurchaseDialogCardButtonTypeOffer:
            self.btnPurchase.userInteractionEnabled = YES;
            buttonLayer.backgroundColor = UIColorFromRGB(color_primary_purple).CGColor;
            [self.btnPurchase setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
            break;
        default:
            break;
    }
    
}

- (void) setupButtonActive:(BOOL)active title:(NSAttributedString *)title description:(NSAttributedString *)description buttonText:(NSString *)buttonText buttonType:(EOAPurchaseDialogCardButtonType)buttonType showTopDiv:(BOOL)showTopDiv showBottomDiv:(BOOL)showBottomDiv buttonClickHandler:(nullable OAPurchaseDialogCardButtonClickHandler)buttonClickHandler
{
    self.active = active;
    _topDiv.hidden = !showTopDiv;
    _bottomDiv.hidden = !showBottomDiv;

    self.backgroundColor = active ? UIColorFromRGB(0xf3edae) : UIColor.clearColor;
    self.lbTitle.attributedText = title;
    self.lbDescription.attributedText = description;

    self.btnPurchase.hidden = NO;
    
    [self setupButton:buttonType];
    
    UIButton *activeButton = self.btnPurchase;
    if (activeButton)
    {
        _buttonClickHandler = buttonClickHandler;
        [activeButton setTitle:buttonText forState:UIControlStateNormal];
        [activeButton addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void) buttonPressed
{
    if (_buttonClickHandler)
        _buttonClickHandler();
}

- (CGFloat) updateLayout:(CGFloat)width
{
    CGFloat h = kMarginBtn;
    UIButton *activeButton = self.btnPurchase;

    CGFloat contentWidth = width - kMarginBtn * 2;
    CGFloat th = [OAUtilities calculateTextBounds:self.lbTitle.text width:contentWidth font:self.lbTitle.font].height;
    self.lbTitle.frame = CGRectMake(kMarginBtn, kMarginBtn, contentWidth, th);
    h += th;
    CGRect tf = self.lbTitle.frame;
    
    CGFloat dh = [OAUtilities calculateTextBounds:self.lbDescription.attributedText width:contentWidth].height;
    self.lbDescription.frame = CGRectMake(kMarginBtn, CGRectGetMaxY(tf) + 1.0, contentWidth, dh);
    h += dh + 1.0;
    
    [activeButton sizeToFit];
    CGFloat bh = [OAUtilities calculateTextBounds:activeButton.titleLabel.text width:contentWidth font:activeButton.titleLabel.font].height;
    NSInteger numOfLines = floor(bh / activeButton.titleLabel.font.lineHeight);
    activeButton.frame = CGRectMake(kMarginBtn, h + 11.0, contentWidth, MAX(kBtnHeight, numOfLines == 2 ? kTwoLinedButtonHeight : bh + kMarginVert));
    h += 11.0 + activeButton.frame.size.height + 16.0;
    
    _topDiv.frame = CGRectMake(0, 0, width, kDivH);
    _bottomDiv.frame = CGRectMake(0, h - kDivH, width, kDivH);

    return h;
}

@end
