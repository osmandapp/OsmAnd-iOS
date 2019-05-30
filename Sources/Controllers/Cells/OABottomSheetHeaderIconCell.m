//
//  OABottomSheetHeaderIconCell.m
//  OsmAnd
//
//  Created by Paul on 29/05/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetHeaderIconCell.h"
#import "OAUtilities.h"

#define titleTextWidthDelta 80.0
#define defaultCellHeight 50.0
#define textMarginVertical 5.0
#define horizontalMargin 16.0
#define iconSize 30.0

const static CGFloat kMarginLeft = 16.0;
const static CGFloat kMarginRight = 16.0;

@implementation OABottomSheetHeaderIconCell

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) layoutSubviews
{
    CGSize cellSize = self.bounds.size;
    CGFloat lx = kMarginLeft;
    CGFloat rx = kMarginRight;
    
    self.separatorInset = UIEdgeInsetsMake(0.0, kMarginLeft, 0.0, 0.0);


    if (!_titleView.hidden)
    {
        _titleView.frame = CGRectMake(lx, textMarginVertical, cellSize.width - rx - lx, cellSize.height);
    }
    if (!_sliderView.hidden) {
        _sliderView.frame = CGRectMake(cellSize.width / 2 - _sliderView.frame.size.width / 2, 6.0,
                                       _sliderView.frame.size.width, _sliderView.frame.size.height);
    }
    _iconView.frame = CGRectMake(DeviceScreenWidth - _iconView.frame.size.width - horizontalMargin, cellSize.height / 2 - _iconView.frame.size.height / 2 + textMarginVertical, iconSize, iconSize);
    _sliderView.layer.cornerRadius = 3.0;
}

+ (CGFloat) getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - titleTextWidthDelta;
    return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text] + textMarginVertical * 2);
}

+ (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    UIFont *titleFont = [UIFont systemFontOfSize:18.0];
    return [OAUtilities calculateTextBounds:text width:width font:titleFont].height;
}

@end
