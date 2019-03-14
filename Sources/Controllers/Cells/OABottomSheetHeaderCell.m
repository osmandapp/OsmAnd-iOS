//
//  OAWaypointHeader.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABottomSheetHeaderCell.h"
#import "OAUtilities.h"

#define titleTextWidthDelta 44.0
#define defaultCellHeight 44.0
#define textMarginVertical 5.0

const static CGFloat kMarginLeft = 16.0;
const static CGFloat kMarginRight = 16.0;

@implementation OABottomSheetHeaderCell

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

//    if (!_progressView.hidden)
//    {
//        _progressView.center = CGPointMake(8 + _progressView.frame.size.width / 2.0, cellSize.height / 2.0);
//        lx += 20;
//    }
//    
//    if (!_textButton.hidden)
//    {
//        CGFloat w = [OAUtilities calculateTextBounds:_textButton.titleLabel.text width:160 font:_textButton.titleLabel.font].width + 16;
//        _textButton.frame = CGRectMake(cellSize.width - w - (rx - 8), 0, w, cellSize.height);
//        rx += w;
//    }
//    if (!_imageButton.hidden)
//    {
//        CGRect btnFrame = _imageButton.frame;
//        _imageButton.center = CGPointMake(cellSize.width - rx - btnFrame.size.width / 2, _imageButton.center.y);
//        rx += btnFrame.size.width;
//    }
//    if (!_switchView.hidden)
//    {
//        CGRect swFrame = _switchView.frame;
//        _switchView.center = CGPointMake(cellSize.width - rx - swFrame.size.width / 2, _switchView.center.y);
//        rx += swFrame.size.width;
//    }
    if (!_titleView.hidden)
    {
        _titleView.frame = CGRectMake(lx, 0, cellSize.width - rx - lx, cellSize.height);
    }
    if (!_sliderView.hidden) {
        _sliderView.frame = CGRectMake(cellSize.width / 2 - _sliderView.frame.size.width / 2, 6.0,
                                       _sliderView.frame.size.width, _sliderView.frame.size.height);
    }
}

+ (CGFloat) getHeight:(NSString *)text cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - titleTextWidthDelta;
    return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text]);
}

+ (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    UIFont *titleFont = [UIFont systemFontOfSize:16.0];
    return [OAUtilities calculateTextBounds:text width:width font:titleFont].height + textMarginVertical;
}

@end
