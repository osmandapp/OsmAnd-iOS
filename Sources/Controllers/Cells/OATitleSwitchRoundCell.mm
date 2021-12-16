//
//  OATitleIconRoundCell.mm
//  OsmAnd
//
//  Created by Skalii on 05.10.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATitleSwitchRoundCell.h"
#import "OAColors.h"

#define titleTextWidthDelta 64.0
#define maxButtonWidth 30.0
#define textMarginVertical 6.0
#define kSideMargin 20.0
#define kSwitchWidth 50.0

static UIFont *_titleFont;

@implementation OATitleSwitchRoundCell
{
    BOOL _bottomCorners;
    BOOL _topCorners;
    BOOL _hasLeftMargin;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

+ (CGFloat)getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - 4*kSideMargin - kSwitchWidth - kSideMargin;
    return MAX(48., [self.class getTitleViewHeightWithWidth:textWidth text:text] + kSideMargin);
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

- (void)applyCornerRadius
{
    CGFloat width = self.bounds.size.width - 2*kSideMargin;
    if (_hasLeftMargin && (_bottomCorners || _topCorners))
        width -= [OAUtilities getLeftMargin];
    CGFloat height = [self.class getHeight:_titleView.text cellWidth:self.bounds.size.width];
    _contentContainer.frame = CGRectMake(kSideMargin, 0., width, height + 0*kSideMargin);
    
    CGFloat textWidth = self.bounds.size.width - 4 * kSideMargin - kSwitchWidth - kSideMargin;
    _titleView.frame = CGRectMake(kSideMargin, 0, textWidth, height);
    _switchView.frame = CGRectMake(width - _switchView.frame.size.width - kSideMargin, height/2 - _switchView.frame.size.height/2, _switchView.frame.size.width, _switchView.frame.size.height);
    
    CGFloat separatorHeight = 1.0 / [UIScreen mainScreen].scale;
    self.separatorView.frame = CGRectMake(kSideMargin, height - separatorHeight, width, separatorHeight);
    
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
    }
    else
    {
        _titleView.textAlignment = NSTextAlignmentLeft;
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
