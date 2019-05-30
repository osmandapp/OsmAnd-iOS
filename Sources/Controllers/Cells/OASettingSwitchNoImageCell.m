//
//  OASettingSwitchNoImageCell.m
//  OsmAnd
//
//  Created by Paul on 30/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OASettingSwitchNoImageCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 44.0
#define titleTextWidthDelta 108.0
#define textMarginVertical 5.0
#define minTextHeight 32.0

static UIFont *_titleFont;
static UIFont *_descFont;

@implementation OASettingSwitchNoImageCell

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

+ (CGFloat) getHeight:(NSString *)text desc:(NSString *)desc cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - titleTextWidthDelta;
    if (!desc || desc.length == 0)
    {
        return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text]);
    }
    else
    {
        return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text] + [self.class getDescViewHeightWithWidth:textWidth text:desc] + textMarginVertical);
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    
    CGFloat textX = 16.0;
    CGFloat textWidth = w - titleTextWidthDelta;
    CGFloat titleHeight = [self.class getTitleViewHeightWithWidth:textWidth text:self.textView.text];
    
    if (self.descriptionView.hidden)
    {
        self.textView.frame = CGRectMake(textX, 0.0, textWidth, MAX(defaultCellHeight, titleHeight));
    }
    else
    {
        CGFloat descHeight = [self.class getDescViewHeightWithWidth:textWidth text:self.descriptionView.text];
        self.textView.frame = CGRectMake(textX, 2.0, textWidth, MAX(minTextHeight, titleHeight));
        self.descriptionView.frame = CGRectMake(textX, h - descHeight + 2.0, textWidth, descHeight);
    }
}

+ (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_titleFont)
        _titleFont = [UIFont systemFontOfSize:17.0];

    return [OAUtilities calculateTextBounds:text width:width font:_titleFont].height + textMarginVertical;
}

+ (CGFloat) getDescViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_descFont)
        _descFont = [UIFont systemFontOfSize:15.0];
    
    return [OAUtilities calculateTextBounds:text width:width font:_descFont].height + textMarginVertical;
}

@end
