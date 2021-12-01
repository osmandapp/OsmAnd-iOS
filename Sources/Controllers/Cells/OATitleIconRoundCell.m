//
//  OATitleIconRoundCell.h
//  OsmAnd
//
//  Created by Paul on 31/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATitleIconRoundCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

#define defaultCellHeight 48.0
#define titleTextWidthDelta 64.0
#define maxButtonWidth 30.0
#define textMarginVertical 6.0

static UIFont *_titleFont;

@implementation OATitleIconRoundCell
{
    BOOL _bottomCorners;
    BOOL _topCorners;
    BOOL _hasLeftMargin;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)highlight:(BOOL)highlighted
{
    if (highlighted)
    {
        _contentContainer.backgroundColor = UIColorFromRGB(color_primary_purple);
        _titleView.textColor = UIColor.whiteColor;
        [_iconView setTintColor:UIColor.whiteColor];
    }
    else
    {
        _contentContainer.backgroundColor = UIColor.whiteColor;
        _titleView.textColor = _textColorNormal ? _textColorNormal : UIColor.blackColor;
        [_iconView setTintColor:_iconColorNormal ? _iconColorNormal : UIColorFromRGB(color_primary_purple)];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:.2 animations:^{
            [self highlight:highlighted];
        }];
    }
    else
    {
        [self highlight:highlighted];
    }
}

- (CGFloat) getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - titleTextWidthDelta - maxButtonWidth;
    return MAX(48., [self getTitleViewHeightWithWidth:textWidth text:text]);

}

- (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_titleFont)
        _titleFont = [UIFont systemFontOfSize:17.0];

    return [OAUtilities calculateTextBounds:text width:width font:_titleFont].height + textMarginVertical * 2;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self applyCornerRadius];
}

- (void) applyCornerRadius
{
    CGFloat width = self.bounds.size.width - 40.;
    if (_hasLeftMargin && (_bottomCorners || _topCorners))
        width -= [OAUtilities getLeftMargin];
    CGFloat height = [self getHeight:_titleView.text cellWidth:width];
    _contentContainer.frame = CGRectMake(20., 0., width, height);
    UIRectCorner corners;
    if (_topCorners && _bottomCorners)
        corners = UIRectCornerAllCorners;
    else
        corners = _topCorners ? UIRectCornerTopRight | UIRectCornerTopLeft : UIRectCornerBottomLeft | UIRectCornerBottomRight;
     
    if (_topCorners || _bottomCorners)
        [OAUtilities setMaskTo:_contentContainer byRoundingCorners:corners radius:12.];
}

- (void) roundCorners:(BOOL)topCorners bottomCorners:(BOOL)bottomCorners
{
    [self roundCorners:topCorners bottomCorners:bottomCorners hasLeftMargin:NO];
}

- (void) roundCorners:(BOOL)topCorners
        bottomCorners:(BOOL)bottomCorners
        hasLeftMargin:(BOOL)hasLeftMargin
{
    _bottomCorners = bottomCorners;
    _topCorners = topCorners;
    _hasLeftMargin = hasLeftMargin;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    _contentContainer.layer.mask = nil;
}

@end
