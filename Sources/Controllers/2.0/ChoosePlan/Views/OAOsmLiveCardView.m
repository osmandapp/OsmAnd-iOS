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

#define kTextMargin 12.0

@implementation OAOsmLiveCardView

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
    cf.size.height = y;
    self.rowsContainer.frame = cf;
    
    h = y + 64 + kTextMargin;
    CGFloat dbw = width - kTextMargin * 2;
    CGFloat dbh = [OAUtilities calculateTextBounds:self.lbButtonsDescription.text width:dbw font:self.lbButtonsDescription.font].height;
    self.lbButtonsDescription.frame = CGRectMake(kTextMargin, h, dbw, dbh);
    h += dbh;
    
    BOOL progress = !self.progressView.hidden;
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
    cf.size.height = y;
    self.buttonsContainer.frame = cf;
    h += y;
    
    return h;
}

- (OAPurchaseDialogCardRow *) addInfoRowWithText:(NSString *)text image:(UIImage *)image selected:(BOOL)selected
{
    OAPurchaseDialogCardRow *row = [[OAPurchaseDialogCardRow alloc] initWithFrame:CGRectMake(0, 0, 100, 54)];
    [row setText:text image:image selected:selected];
    [self.rowsContainer addSubview:row];
    return row;
}

- (OAPurchaseDialogCardButton *) addCardButtonWithTitle:(NSAttributedString *)title description:(NSAttributedString *)description buttonText:(NSString *)buttonText buttonType:(EOAPurchaseDialogCardButtonType)buttonType active:(BOOL)active discountDescr:(NSString *)discountDescr showDiscount:(BOOL)showDiscount highDiscount:(BOOL)highDiscount onButtonClick:(nullable OAPurchaseDialogCardButtonClickHandler)onButtonClick
{
    return nil;
}

- (void) setProgressVisibile:(BOOL)visible
{
    self.progressView.hidden = !visible;
}

@end
