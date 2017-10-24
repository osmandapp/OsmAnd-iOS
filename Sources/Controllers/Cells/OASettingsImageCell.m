//
//  OASettingsImageCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 23/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASettingsImageCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 44.0
#define titleTextWidthDelta 44.0
#define secondaryImgWidth 44.0
#define textMarginVertical 5.0

static UIFont *_titleTextFont;

@implementation OASettingsImageCell

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

- (void) setSecondaryImage:(UIImage *)image
{
    _secondaryImgView.image = image;
    
    CGRect tf = _textView.frame;
    if (image)
        tf.size.width = self.bounds.size.width - titleTextWidthDelta - secondaryImgWidth;
    else
        tf.size.width = self.bounds.size.width - titleTextWidthDelta;
    
    _textView.frame = tf;
}

+ (CGFloat) getHeight:(NSString *)title hasSecondaryImg:(BOOL)hasSecondaryImg cellWidth:(CGFloat)cellWidth
{
    return MAX(defaultCellHeight, [self.class getTextViewHeightWithWidth:(hasSecondaryImg ? cellWidth - secondaryImgWidth : cellWidth) title:title] + 1.0);
}

+ (CGFloat) getTextViewHeightWithWidth:(CGFloat)cellWidth title:(NSString *)title
{
    if (!_titleTextFont)
        _titleTextFont = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];
    
    CGFloat w = cellWidth - titleTextWidthDelta;
    CGFloat titleHeight = [OAUtilities calculateTextBounds:title width:w font:_titleTextFont].height + textMarginVertical * 2;
    return titleHeight;
}

@end
