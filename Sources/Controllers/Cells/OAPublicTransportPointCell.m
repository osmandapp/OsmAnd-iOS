//
//  OAPublicTransportPointCell.m
//  OsmAnd
//
//  Created by Paul on 17/10/19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import "OAPublicTransportPointCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

#define kIconSizeBig 30.0
#define kIconSizeSmall 24.0

#define kIconMarginLeftBig 16.0
#define kIconMarginLeftSmall 19.0

@implementation OAPublicTransportPointCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    _iconView.layer.cornerRadius = 3.;
    _iconView.layer.borderWidth = 1.;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) showOutiline:(BOOL)show
{
    if (show)
        _iconView.layer.borderColor = UIColorFromRGB(color_tint_gray).CGColor;
    else
        _iconView.layer.borderColor = UIColor.clearColor.CGColor;
}

- (void) showSmallIcon:(BOOL)smallIcon
{
    BOOL needsUpdate = NO;
    CGFloat newConstant = smallIcon ? kIconSizeSmall : kIconSizeBig;
    CGFloat newLeftMargin = smallIcon ? kIconMarginLeftSmall : kIconMarginLeftBig;
    if (_iconHeightConstraint.constant != newConstant)
    {
        _iconHeightConstraint.constant = newConstant;
        needsUpdate = YES;
    }
    if (_iconWidthConstraint.constant != newConstant)
    {
        _iconWidthConstraint.constant = newConstant;
        needsUpdate = YES;
    }
    if (_iconViewLeftConstraint.constant != newLeftMargin)
    {
        _iconViewLeftConstraint.constant = newLeftMargin;
        needsUpdate = YES;
    }
    
    if (needsUpdate)
    {
        [self setNeedsUpdateConstraints];
        [self updateFocusIfNeeded];
    }
}

- (void) updateConstraints
{
    self.descView.hidden = !self.descView.text || self.descView.text.length == 0;
    _descHeightPrimary.active = !self.descView.hidden;
    _descHeightSecondary.active = self.descView.hidden;
    _textHeightPrimary.active = !self.descView.hidden;
    _textHeightSecondary.active = self.descView.hidden;
    
    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    self.descView.hidden = !self.descView.text || self.descView.text.length == 0;
    if (!res)
    {
        res = res || self.textHeightPrimary.active != self.descView.hidden;
        res = res || self.textHeightSecondary.active != !self.descView.hidden;
        res = res || self.descHeightPrimary.active != self.descView.hidden;
        res = res || self.descHeightSecondary.active != !self.descView.hidden;
    }
    return res;
}

@end
