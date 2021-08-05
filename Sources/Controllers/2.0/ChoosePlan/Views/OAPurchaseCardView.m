//
//  OAPurchaseCardView.m
//  OsmAnd
//
//  Created by Alexey on 21/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAPurchaseCardView.h"
#import "OAColors.h"

#define kTextMargin 16.0
#define kTextMarginH 11.0
#define kTwoLinedButtonHeight 60.0
#define kDivH 0.5

@implementation OAPurchaseCardView
{
    CALayer *_bottomDiv;
    OAPurchaseCardButtonClickHandler _buttonClickHandler;
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OAPurchaseCardView class]])
        {
            self = (OAPurchaseCardView *)v;
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
        if ([v isKindOfClass:[OAPurchaseCardView class]])
        {
            self = (OAPurchaseCardView *)v;
            break;
        }
    
    if (self)
        self.frame = frame;
    
    [self commonInit];
    return self;
}

- (void) setupCardButton
{
    self.cardButton.layer.cornerRadius = 9.0;
    self.cardButton.layer.borderWidth = 2.0;
    self.cardButton.layer.borderColor = UIColorFromRGB(color_primary_purple).CGColor;
    self.cardButton.layer.backgroundColor = [UIColorFromRGB(color_primary_purple) colorWithAlphaComponent:.1].CGColor;
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:[self.cardButton attributedTitleForState:UIControlStateNormal]];
    [str addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(color_primary_purple) range:NSMakeRange(0, str.length)];
    [self.cardButton setAttributedTitle:str forState:UIControlStateNormal];
    self.cardButtonDisabled.layer.cornerRadius = 9.0;
}

- (void) commonInit
{
    self.layer.cornerRadius = 9.0;
    self.layer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:0.05].CGColor;
    self.layer.shadowOpacity = 1.0;
    self.layer.shadowRadius = 8.0;
    self.layer.shadowOffset = CGSizeMake(0.0, 2.0);
    self.layer.masksToBounds = NO;
    
    [self setupCardButton];
    
    _bottomDiv = [[CALayer alloc] init];
    _bottomDiv.backgroundColor = UIColorFromRGB(color_tint_gray).CGColor;
    [self.layer addSublayer:_bottomDiv];
}

- (void) onButtonDeselected
{
    [UIView animateWithDuration:0.2 animations:^{
        [self setupCardButton];
    }];
}

- (void) onButtonTouched:(id)sender
{
    UIButton *btn = sender;
    [UIView animateWithDuration:0.3 animations:^{
        btn.layer.backgroundColor = UIColorFromRGB(color_coordinates_background).CGColor;
        btn.layer.borderWidth = 0.;
        NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:[btn attributedTitleForState:UIControlStateNormal]];
        [str addAttribute:NSForegroundColorAttributeName value:UIColor.whiteColor range:NSMakeRange(0, str.length)];
        [btn setAttributedTitle:str forState:UIControlStateNormal];
    } completion:nil];
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
    
    _bottomDiv.frame = CGRectMake(0, y + cf.origin.y, width, kDivH);

    h = y + cf.origin.y + kTextMarginH;
    
    CGFloat dbw = width - kTextMargin * 2;
    
    CGFloat dbth = [OAUtilities calculateTextBounds:self.lbButtonTitle.text width:dbw font:self.lbButtonTitle.font].height;
    self.lbButtonTitle.frame = CGRectMake(kTextMargin, h, dbw, dbth);
    h += dbth + 2.0;
    
    CGFloat dbh = [OAUtilities calculateTextBounds:self.lbButtonDescription.text width:dbw font:self.lbButtonDescription.font].height;
    self.lbButtonDescription.frame = CGRectMake(kTextMargin, h, dbw, dbh);
    h += dbh + kTextMarginH;

    UIButton *button = !self.cardButton.hidden ? self.cardButton : self.cardButtonDisabled;
    [button sizeToFit];
    CGFloat buttonHeight = [OAUtilities calculateTextBounds:button.titleLabel.text width:dbw font:button.titleLabel.font].height;
    NSInteger numOfLines = floor(buttonHeight / button.titleLabel.font.lineHeight);
    CGRect bf = button.frame;
    bf.origin.x = kTextMargin;
    bf.origin.y = h;
    bf.size.width = dbw;
    bf.size.height = MAX(42.0, numOfLines == 2 ? kTwoLinedButtonHeight : buttonHeight + 10.0);
    button.frame = bf;
    
    self.progressView.center = button.center;

    h += bf.size.height + kTextMargin;    
    return h;
}

- (void) setupCardWithTitle:(NSString *)title description:(NSString *)description buttonTitle:(NSString *)buttonTitle buttonDescription:(NSString *)buttonDescription
{
    self.lbTitle.text = title;
    self.lbDescription.text = description;
    self.lbButtonDescription.text = buttonDescription;
    self.lbButtonTitle.text = buttonTitle;
}

- (void) setupCardButtonEnabled:(BOOL)buttonEnabled buttonText:(NSAttributedString *)buttonText buttonClickHandler:(nullable OAPurchaseCardButtonClickHandler)buttonClickHandler
{
    self.cardButton.hidden = !buttonEnabled;
    self.cardButtonDisabled.hidden = buttonEnabled;
    [self.cardButton setAttributedTitle:buttonText forState:UIControlStateNormal];
    [self.cardButtonDisabled setAttributedTitle:buttonText forState:UIControlStateNormal];
    
    if (buttonEnabled)
    {
        _buttonClickHandler = buttonClickHandler;
        [self.cardButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchDown];
        [self.cardButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpOutside];
        [self.cardButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [self.cardButton addTarget:self action:@selector(onButtonTouched:) forControlEvents:UIControlEventTouchDown];
        [self.cardButton addTarget:self action:@selector(onButtonDeselected) forControlEvents:UIControlEventTouchUpOutside];
        [self.cardButton addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void) buttonPressed
{
    [self onButtonDeselected];
    if (_buttonClickHandler)
        _buttonClickHandler();
}

- (OAPurchaseDialogCardRow *) addInfoRowWithText:(NSString *)text image:(UIImage *)image selected:(BOOL)selected showDivider:(BOOL)showDivider
{
    OAPurchaseDialogCardRow *row = [[OAPurchaseDialogCardRow alloc] initWithFrame:CGRectMake(0, 0, 100, 54)];
    [row setText:text textColor:UIColor.blackColor image:image selected:selected showDivider:showDivider];
    [self.rowsContainer addSubview:row];
    return row;
}

- (void) setProgressVisibile:(BOOL)visible
{
    self.progressView.hidden = !visible;
    if (visible)
        [self.progressView startAnimating];
    else
        [self.progressView stopAnimating];
}

@end
