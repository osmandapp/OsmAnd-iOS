//
//  OAIconTitleIconRoundCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 06.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAIconTitleIconRoundCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

#define kTitleTopBottomMargin 13.0
#define defaultCellHeight 48.0
#define titleTextWidthDelta 64.0
#define maxButtonWidth 30.0
#define textMarginVertical 6.0
#define cellMargin 20.0

static UIFont *_titleFont;

@implementation OAIconTitleIconRoundCell
{
    BOOL _bottomCorners;
    BOOL _topCorners;
}

+ (CGFloat) getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - maxButtonWidth - 7*cellMargin;
    return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text]);
}

+ (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
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
	CGFloat height = self.bounds.size.height;
	_contentContainer.frame = CGRectMake(20., 0., width, height);
    
    CGRect iconFrame = self.iconView.frame;
    iconFrame.origin.x = cellMargin;
    iconFrame.origin.y = _contentContainer.frame.size.height / 2 - iconFrame.size.height / 2;
    self.iconView.frame = iconFrame;
    
    CGRect secondaryIconFrame = self.iconView.frame;
    secondaryIconFrame.origin.x = _contentContainer.frame.size.width - cellMargin - iconFrame.size.width;
    secondaryIconFrame.origin.y = _contentContainer.frame.size.height / 2 - iconFrame.size.height / 2;
    self.secondaryImageView.frame = secondaryIconFrame;
    
    CGFloat textWidth = width - _titleView.frame.origin.x - 2*cellMargin;
    if (!self.secondaryImageView.hidden)
        textWidth = textWidth - self.secondaryImageView.frame.size.width - cellMargin;
    _titleView.frame = CGRectMake(2*cellMargin + self.iconView.frame.size.width, _titleView.frame.origin.y, textWidth, height - 2 * kTitleTopBottomMargin);
    
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
        [self.titleView setTransform:CGAffineTransformMakeScale(-1, 1)];
        self.titleView.textAlignment = NSTextAlignmentRight;
    }
    else
    {
        self.titleView.textAlignment = NSTextAlignmentLeft;
    }
}

- (void) roundCorners:(BOOL)topCorners bottomCorners:(BOOL)bottomCorners
{
    _bottomCorners = bottomCorners;
    _topCorners = topCorners;
}

- (void)prepareForReuse
{
	[super prepareForReuse];
	_contentContainer.layer.mask = nil;
}

@end
