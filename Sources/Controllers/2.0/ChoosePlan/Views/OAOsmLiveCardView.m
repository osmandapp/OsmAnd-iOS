//
//  OAOsmLiveCardView.m
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAOsmLiveCardView.h"
#import "OAPurchaseDialogCardRow.h"
#import "OAPurchaseDialogCardButton.h"
#import "OAColors.h"

#define kTextMargin 16.0
#define kButtonHeight 42.0
#define kDivH 0.5

@implementation OAOsmLiveCardView
{
    CALayer *_midDiv;
    BOOL _showProgress;
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OAOsmLiveCardView class]])
        {
            self = (OAOsmLiveCardView *)v;
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
        if ([v isKindOfClass:[OAOsmLiveCardView class]])
        {
            self = (OAOsmLiveCardView *)v;
            break;
        }
    
    if (self)
        self.frame = frame;
    
    [self commonInit];
    return self;
}

- (void) commonInit
{
    self.layer.cornerRadius = 9.0;
    self.layer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.05].CGColor;
    self.layer.shadowOpacity = 1.0;
    self.layer.shadowRadius = 8.0;
    self.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    self.layer.masksToBounds = NO;
    
    CALayer *buttonsLayer = _plansPricesButton.layer;
    buttonsLayer.cornerRadius = 9.0;
    
    _midDiv = [[CALayer alloc] init];
    _midDiv.backgroundColor = UIColorFromRGB(color_tint_gray).CGColor;
    [self.layer addSublayer:_midDiv];
}

- (CGFloat) updateLayout:(CGFloat)width
{
    CGFloat h = 0;
    CGFloat y = 0;
    CGRect cf = self.rowsContainer.frame;
    for (OAPurchaseDialogCardRow *row in self.rowsContainer.subviews)
    {
        CGRect rf = [row updateFrame:width];
        rf.origin.y = y;
        row.frame = rf;
        y += rf.size.height;
    }
    cf.origin.y = 70;
    cf.size.width = width;
    cf.size.height = y;
    self.rowsContainer.frame = cf;

    h = y + cf.origin.y;
    _midDiv.frame = CGRectMake(0, h - kDivH, width, kDivH);

    BOOL progress = _showProgress;
    y = progress ? self.progressView.bounds.size.height + kTextMargin * 2 : 0;
    cf = self.buttonsContainer.frame;
    for (UIView *v in self.buttonsContainer.subviews)
    {
        if (progress)
        {
            if (![v isKindOfClass:[UIActivityIndicatorView class]])
                v.hidden = YES;
        }
        else if ([v isKindOfClass:[OAPurchaseDialogCardButton class]])
        {
            OAPurchaseDialogCardButton *btn = (OAPurchaseDialogCardButton *)v;
            CGRect btnf = [btn updateFrame:width];
            btnf.origin.y = y;
            btn.frame = btnf;
            y += btnf.size.height;
            btn.hidden = NO;
        }
    }
    
    cf.origin.y = h;
    cf.size.width = width;
    cf.size.height = y;
    self.buttonsContainer.frame = cf;
    h += y + (progress ? kTextMargin : 0.0);
    
    _plansPricesButton.frame = CGRectMake(kTextMargin, h, width - kTextMargin * 2, kButtonHeight);
    h += kTextMargin + kButtonHeight;
    
    return h;
}

- (OAPurchaseDialogCardRow *) addInfoRowWithText:(NSString *)text image:(UIImage *)image selected:(BOOL)selected showDivider:(BOOL)showDivider
{
    OAPurchaseDialogCardRow *row = [[OAPurchaseDialogCardRow alloc] initWithFrame:CGRectMake(0, 0, 100, 54)];
    [row setText:text textColor:[UIColor blackColor] image:image selected:selected showDivider:showDivider];
    [self.rowsContainer addSubview:row];
    return row;
}

- (OAPurchaseDialogCardButton *) addCardButtonWithTitle:(NSAttributedString *)title description:(NSAttributedString *)description buttonText:(NSAttributedString *)buttonText buttonType:(EOAPurchaseDialogCardButtonType)buttonType active:(BOOL)active showTopDiv:(BOOL)showTopDiv showBottomDiv:(BOOL)showBottomDiv onButtonClick:(nullable OAPurchaseDialogCardButtonClickHandler)onButtonClick
{
    OAPurchaseDialogCardButton *button = [[OAPurchaseDialogCardButton alloc] init];
    [button setupButtonActive:active title:title description:description buttonText:buttonText buttonType:buttonType showTopDiv:showTopDiv showBottomDiv:showBottomDiv buttonClickHandler:onButtonClick];
    
    [self.buttonsContainer addSubview:button];
    return button;
}

- (void) setProgressVisibile:(BOOL)visible
{
    _showProgress = visible;
    self.progressView.hidden = !visible;
    if (visible)
        [self.progressView startAnimating];
    else
        [self.progressView stopAnimating];
}

@end
