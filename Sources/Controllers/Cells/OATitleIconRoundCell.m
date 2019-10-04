//
//  OATitleIconRoundCell.h
//  OsmAnd
//
//  Created by Paul on 31/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATitleIconRoundCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 44.0
#define titleTextWidthDelta 108.0
#define maxButtonWidth 70.0
#define textMarginVertical 5.0
#define minTextHeight 32.0
#define leftTextMargin 62.0

static UIFont *_titleFont;

@implementation OATitleIconRoundCell
{
    BOOL _bottomCorners;
    BOOL _topCorners;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (CGFloat) getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - titleTextWidthDelta - maxButtonWidth;
    return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text]);
    
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width;
    _contentContainer.frame = CGRectMake(16.0, 0.0, w - 32.0, self.bounds.size.height);
    
    CGFloat textX = 16.0;
    CGFloat textWidth = w - titleTextWidthDelta - maxButtonWidth;
    CGFloat titleHeight = [self.class getTitleViewHeightWithWidth:textWidth text:self.titleView.text];
    
    self.titleView.frame = CGRectMake(textX, 0.0, textWidth, MAX(defaultCellHeight, titleHeight));
    
    CGRect iconFrame = self.iconView.frame;
    iconFrame.origin.x = _contentContainer.frame.size.width - 16.0 - iconFrame.size.width;
    iconFrame.origin.y = _contentContainer.frame.size.height / 2 - iconFrame.size.height / 2;
    self.iconView.frame = iconFrame;
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
    
    return [OAUtilities calculateTextBounds:text width:width font:_titleFont].height + textMarginVertical;
}

- (void) roundCorners:(BOOL)topCorners bottomCorners:(BOOL)bottomCorners
{
    _bottomCorners = bottomCorners;
    _topCorners = topCorners;
}

@end
