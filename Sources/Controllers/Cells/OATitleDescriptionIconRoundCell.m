//
//  OATitleDescriptionIconRoundCell.h
//  OsmAnd
//
//  Created by Paul on 31/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATitleDescriptionIconRoundCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

#define defaultCellHeight 48.0
#define titleTextWidthDelta 64.0
#define maxButtonWidth 30.0
#define textMarginVertical 9.0
#define textForOneLineLabel @"One line"
#define cellMargin 20.0

static UIFont *_titleFont;
static UIFont *_descrFont;

@implementation OATitleDescriptionIconRoundCell
{
    BOOL _bottomCorners;
    BOOL _topCorners;
    BOOL _hasLeftMargin;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    if (!_titleFont)
        _titleFont = [UIFont systemFontOfSize:17.0];
    if (!_descrFont)
        _descrFont = [UIFont systemFontOfSize:15.0];
    
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

+ (CGFloat) getHeight:(NSString *)text descr:(NSString *)descr cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - 5*cellMargin - maxButtonWidth;
    return MAX(60., [self.class getViewHeightWithWidth:textWidth text:text font:_titleFont] + [self.class getViewHeightWithWidth:textWidth text:textForOneLineLabel font:_descrFont] + 2*textMarginVertical);
}

+ (CGFloat) getViewHeightWithWidth:(CGFloat)width text:(NSString *)text font:(UIFont *)font
{
    return [OAUtilities calculateTextBounds:text width:width font:font].height;
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
    CGFloat height = [self.class getHeight:_titleView.text descr:_descrView.text cellWidth:self.bounds.size.width];
    _contentContainer.frame = CGRectMake(20., 0., width, height);
    
    CGFloat textWidth = self.bounds.size.width - 5*cellMargin - maxButtonWidth;
    CGFloat titleHeight = [self.class getViewHeightWithWidth:textWidth text:_titleView.text font:_titleFont];
    CGFloat descHeight = [self.class getViewHeightWithWidth:textWidth text:textForOneLineLabel font:_descrFont];
    
    _titleView.frame = CGRectMake(cellMargin, textMarginVertical, textWidth, titleHeight);
    _descrView.frame = CGRectMake(cellMargin, height - _descrView.frame.size.height - textMarginVertical, textWidth, descHeight);
    
    CGRect iconFrame = self.iconView.frame;
    iconFrame.origin.x = width - maxButtonWidth - cellMargin;
    iconFrame.origin.y = _contentContainer.frame.size.height / 2 - iconFrame.size.height / 2;
    self.iconView.frame = iconFrame;
    
    CGFloat separatorHeight = 1.0 / [UIScreen mainScreen].scale;
    self.separatorView.frame = CGRectMake(_titleView.frame.origin.x, height - separatorHeight, width - _titleView.frame.origin.x, separatorHeight);
    
    UIRectCorner corners;
    if (_topCorners && _bottomCorners)
        corners = UIRectCornerAllCorners;
    else
        corners = _topCorners ? UIRectCornerTopRight | UIRectCornerTopLeft : UIRectCornerBottomLeft | UIRectCornerBottomRight;
     
    if (_topCorners || _bottomCorners)
        [OAUtilities setMaskTo:_contentContainer byRoundingCorners:corners radius:12.];
    
    if ([self isDirectionRTL])
    {
        [_contentContainer setTransform:CGAffineTransformMakeScale(-1, 1)];
        [_titleView setTransform:CGAffineTransformMakeScale(-1, 1)];
        _titleView.textAlignment = NSTextAlignmentRight;
        [_descrView setTransform:CGAffineTransformMakeScale(-1, 1)];
        _descrView.textAlignment = NSTextAlignmentRight;
    }
    else
    {
        _titleView.textAlignment = NSTextAlignmentLeft;
        _descrView.textAlignment = NSTextAlignmentLeft;
    }
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
