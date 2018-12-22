//
//  OAPurchaseCardView.m
//  OsmAnd
//
//  Created by Alexey on 21/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAPurchaseCardView.h"
#import "OAColors.h"

#define kTextMargin 12.0
#define kDivH 1.0

@implementation OAPurchaseCardView
{
    CALayer *_topDiv;
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

- (void) commonInit
{
    self.layer.cornerRadius = 3;
    self.layer.shadowColor = UIColor.blackColor.CGColor;
    self.layer.shadowOpacity = 0.2;
    self.layer.shadowRadius = 1.5;
    self.layer.shadowOffset = CGSizeMake(0.0, 0.5);
    
    self.cardButton.layer.cornerRadius = 3;
    self.cardButtonDisabled.layer.cornerRadius = 3;
    
    _topDiv = [[CALayer alloc] init];
    _topDiv.backgroundColor = UIColorFromRGB(color_card_divider_light).CGColor;
    [self.layer addSublayer:_topDiv];
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
    cf.origin.y = 64;
    cf.size.width = width;
    cf.size.height = y;
    self.rowsContainer.frame = cf;
    
    _topDiv.frame = CGRectMake(0, cf.origin.y - kDivH, width, kDivH);

    h = y + cf.origin.y + kTextMargin;
    CGFloat dbw = width - kTextMargin * 2;
    CGFloat dbh = [OAUtilities calculateTextBounds:self.lbButtonDescription.text width:dbw font:self.lbButtonDescription.font].height;
    self.lbButtonDescription.frame = CGRectMake(kTextMargin, h, dbw, dbh);
    h += dbh + kTextMargin;

    UIButton *button = !self.cardButton.hidden ? self.cardButton : self.cardButtonDisabled;
    [button sizeToFit];
    CGRect bf = button.frame;
    bf.origin.x = kTextMargin;
    bf.origin.y = h;
    bf.size.width = dbw;
    button.frame = bf;
    
    self.progressView.center = button.center;

    h += bf.size.height + kTextMargin;    
    return h;
}

- (void) setupCardWithImage:(UIImage *)image title:(NSString *)title description:(NSString *)description buttonDescription:(NSString *)buttonDescription
{
    self.imageView.image = image;
    self.lbTitle.text = title;
    self.lbDescription.text = description;
    self.lbButtonDescription.text = buttonDescription;
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
        [self. cardButton removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
        [self.cardButton addTarget:self action:@selector(buttonPressed) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void) buttonPressed
{
    if (_buttonClickHandler)
        _buttonClickHandler();
}

- (OAPurchaseDialogCardRow *) addInfoRowWithText:(NSString *)text image:(UIImage *)image selected:(BOOL)selected showDivider:(BOOL)showDivider
{
    OAPurchaseDialogCardRow *row = [[OAPurchaseDialogCardRow alloc] initWithFrame:CGRectMake(0, 0, 100, 54)];
    [row setText:text image:image selected:selected showDivider:showDivider];
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
