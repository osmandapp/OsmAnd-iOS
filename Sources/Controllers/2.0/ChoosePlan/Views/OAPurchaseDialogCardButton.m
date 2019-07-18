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
#define kMarginBtnHor 13.0
#define kMarginLabel 4.0
#define kSaveMargin 2.0

#define kImgViewSide 30.0
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
    
    EOAPurchaseDialogCardButtonType _buttonType;
    UIImageView *_currentSubscriptionIw;
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

    self.btnPurchase.titleLabel.textAlignment = NSTextAlignmentCenter;
    [self.btnPurchase addTarget:self action:@selector(onButtonTouched:) forControlEvents:UIControlEventTouchDown];
    [self.btnPurchase addTarget:self action:@selector(onButtonDeselected) forControlEvents:UIControlEventTouchUpOutside];
    
    _topDiv = [[CALayer alloc] init];
    _topDiv.backgroundColor = UIColorFromRGB(color_tint_gray).CGColor;
    [self.layer addSublayer:_topDiv];
    _bottomDiv = [[CALayer alloc] init];
    _bottomDiv.backgroundColor = UIColorFromRGB(color_tint_gray).CGColor;
    [self.layer addSublayer:_bottomDiv];
}

- (void) onButtonDeselected
{
    [UIView animateWithDuration:0.2 animations:^{
        [self setupButton:_buttonType];
    }];
}

- (void) onButtonTouched:(id) sender
{
    UIButton *btn = sender;
    [UIView animateWithDuration:0.3 animations:^{
        btn.layer.borderWidth = 0.;
        btn.layer.backgroundColor = UIColorFromRGB(color_coordinates_background).CGColor;
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:[btn attributedTitleForState:UIControlStateNormal]];
        [str addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(0, str.length)];
        [btn setAttributedTitle:str forState:UIControlStateNormal];
    } completion:nil];
}

- (void) setupButton:(EOAPurchaseDialogCardButtonType)type
{
    CALayer *buttonLayer = self.btnPurchase.layer;
    switch (type)
    {
        case EOAPurchaseDialogCardButtonTypeRegular:
        {
            self.btnPurchase.userInteractionEnabled = YES;
            buttonLayer.borderWidth = 2.;
            buttonLayer.borderColor = UIColorFromRGB(color_primary_purple).CGColor;
            buttonLayer.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.1].CGColor;
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:[self.btnPurchase attributedTitleForState:UIControlStateNormal]];
            [str addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_primary_purple) range:NSMakeRange(0, str.length)];
            [self.btnPurchase setAttributedTitle:str forState:UIControlStateNormal];
            break;
        }
        case EOAPurchaseDialogCardButtonTypeExtended:
        {
            buttonLayer.borderWidth = 0.;
            buttonLayer.backgroundColor = UIColorFromRGB(color_bottom_sheet_secondary).CGColor;
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:[self.btnPurchase attributedTitleForState:UIControlStateNormal]];
            [str addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_text_dark_yellow) range:NSMakeRange(0, str.length)];
            [self.btnPurchase setAttributedTitle:str forState:UIControlStateNormal];
            self.btnPurchase.userInteractionEnabled = YES;
            break;
        }
        case EOAPurchaseDialogCardButtonTypeDisabled:
        {
            self.btnPurchase.userInteractionEnabled = NO;
            buttonLayer.borderWidth = 2.;
            buttonLayer.backgroundColor = [UIColorFromRGB(color_bottom_sheet_secondary) colorWithAlphaComponent:.1].CGColor;
            buttonLayer.borderColor = UIColorFromRGB(color_bottom_sheet_secondary).CGColor;
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:[self.btnPurchase attributedTitleForState:UIControlStateNormal]];
            [str addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_text_footer) range:NSMakeRange(0, str.length)];
            [self.btnPurchase setAttributedTitle:str forState:UIControlStateNormal];
            break;
        }
        case EOAPurchaseDialogCardButtonTypeOffer:
        {
            self.btnPurchase.userInteractionEnabled = YES;
            buttonLayer.backgroundColor = UIColorFromRGB(color_primary_purple).CGColor;
            NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:[self.btnPurchase attributedTitleForState:UIControlStateNormal]];
            [str addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(0, str.length)];
            [self.btnPurchase setAttributedTitle:str forState:UIControlStateNormal];
            break;
        }
        default:
            break;
    }
    
}

- (void) setupButtonActive:(BOOL)active title:(NSAttributedString *)title description:(NSAttributedString *)description buttonText:(NSAttributedString *)buttonText buttonType:(EOAPurchaseDialogCardButtonType)buttonType showTopDiv:(BOOL)showTopDiv showBottomDiv:(BOOL)showBottomDiv buttonClickHandler:(nullable OAPurchaseDialogCardButtonClickHandler)buttonClickHandler
{
    _buttonType = buttonType;
    
    self.active = active;
    _topDiv.hidden = !showTopDiv;
    _bottomDiv.hidden = !showBottomDiv;
    
    if (buttonType == EOAPurchaseDialogCardButtonTypeExtended && active)
    {
        _currentSubscriptionIw = [[UIImageView alloc] initWithFrame:CGRectMake(0., 0., 30., 30.)];
        [_currentSubscriptionIw setImage:[UIImage imageNamed:@"ic_custom_success"]];
        [self addSubview:_currentSubscriptionIw];
    }

    self.backgroundColor = /*active ? UIColorFromRGB(0xf3edae) : */UIColor.clearColor;
    self.lbTitle.attributedText = title;
    self.lbDescription.attributedText = description;

    self.btnPurchase.hidden = NO;
    
    UIButton *activeButton = self.btnPurchase;
    if (activeButton)
    {
        _buttonClickHandler = buttonClickHandler;
        [activeButton setAttributedTitle:buttonText forState:UIControlStateNormal];
        [activeButton addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
    
    [self setupButton:buttonType];
}

- (void) buttonPressed
{
    [self onButtonDeselected];
    
    if (_buttonClickHandler)
        _buttonClickHandler();
}

- (CGFloat) updateLayout:(CGFloat)width
{
    CGFloat h = kMarginHor;
    UIButton *activeButton = self.btnPurchase;
    
    BOOL hasImageView = _currentSubscriptionIw && _currentSubscriptionIw.superview;

    CGFloat contentWidth = width - kMarginBtn * 2;
    CGFloat th = [OAUtilities calculateTextBounds:self.lbTitle.text width:contentWidth font:self.lbTitle.font].height;
    self.lbTitle.frame = CGRectMake(kMarginBtn, kMarginHor, contentWidth - (hasImageView ? 46 : 0), th);
    h += th;
    CGRect tf = self.lbTitle.frame;
    
    CGFloat dh = [OAUtilities calculateTextBounds:self.lbDescription.attributedText.string width:contentWidth font:self.lbDescription.font].height;
    self.lbDescription.frame = CGRectMake(kMarginBtn, CGRectGetMaxY(tf) + 3.0, contentWidth - (hasImageView ? 46 : 0), dh);
    h += dh + 3.0;
    
    if (hasImageView)
        _currentSubscriptionIw.frame = CGRectMake(width - kImgViewSide - kMarginBtn, (h + kMarginHor) / 2 - kImgViewSide / 2, kImgViewSide, kImgViewSide);
    
    [activeButton sizeToFit];
    CGFloat bh = [OAUtilities calculateTextBounds:[activeButton attributedTitleForState:UIControlStateNormal] width:contentWidth].height;
    NSInteger numOfLines = floor(bh / activeButton.titleLabel.font.lineHeight);
    activeButton.frame = CGRectMake(kMarginBtn, h + kMarginBtnHor, contentWidth, MAX(kBtnHeight, numOfLines == 2 ? kTwoLinedButtonHeight : bh + kMarginVert));
    h += kMarginBtnHor + activeButton.frame.size.height + 16.0;
    
    _topDiv.frame = CGRectMake(0, 0, width, kDivH);
    _bottomDiv.frame = CGRectMake(0, h - kDivH, width, kDivH);

    return h;
}

@end
