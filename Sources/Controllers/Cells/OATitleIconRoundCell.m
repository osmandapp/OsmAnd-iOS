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
#define cellMargin 20.0

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

+ (CGFloat) getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - titleTextWidthDelta - maxButtonWidth - 2*cellMargin;
    return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text]);
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self applyCornerRadius];
}

- (void) applyCornerRadius
{
    CGFloat fullCellWidth = self.bounds.size.width;
    CGFloat width = self.bounds.size.width - 2*cellMargin;
    if (_hasLeftMargin && (_bottomCorners || _topCorners))
        width -= [OAUtilities getLeftMargin];
    
    CGFloat height = [self.class getHeight:_titleView.text cellWidth:fullCellWidth];
    _contentContainer.frame = CGRectMake(cellMargin, 0., width, height);
    
    CGFloat textX = cellMargin;
    CGFloat textWidth = width - titleTextWidthDelta - maxButtonWidth;
    CGFloat titleHeight = [self.class getTitleViewHeightWithWidth:textWidth text:self.titleView.text];
    
    self.titleView.frame = CGRectMake(textX, 0.0, textWidth, MAX(defaultCellHeight, titleHeight));
    
    CGRect iconFrame = self.iconView.frame;
    iconFrame.origin.x = _contentContainer.frame.size.width - cellMargin - iconFrame.size.width;
    iconFrame.origin.y = _contentContainer.frame.size.height / 2 - iconFrame.size.height / 2;
    self.iconView.frame = iconFrame;
    
    CGFloat separatorHeight = 1.0 / [UIScreen mainScreen].scale;
    self.separatorView.frame = CGRectMake(cellMargin, height - separatorHeight, width, separatorHeight);
    
    UIRectCorner corners;
    if (_topCorners && _bottomCorners)
        corners = UIRectCornerAllCorners;
    else
        corners = _topCorners ? UIRectCornerTopRight | UIRectCornerTopLeft : UIRectCornerBottomLeft | UIRectCornerBottomRight;
     
    if (_topCorners || _bottomCorners)
        [OAUtilities setMaskTo:_contentContainer byRoundingCorners:corners radius:12.];
}

+ (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_titleFont)
        _titleFont = [UIFont systemFontOfSize:17.0];

    return [OAUtilities calculateTextBounds:text width:width font:_titleFont].height + textMarginVertical * 2;
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
