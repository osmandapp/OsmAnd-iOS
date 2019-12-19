//
//  OASettingSwitchCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 03/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASettingSwitchCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 48.0
#define titleTextWidthDelta 108.0
#define secondaryImgWidth 111.0
#define switchCellWidth 67.0
#define textMarginVertical 5.0
#define minTextHeight 32.0

static UIFont *_titleFont;
static UIFont *_descFont;

@implementation OASettingSwitchCell

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

- (void) updateConstraints
{
    [super updateConstraints];

    BOOL hasImage = self.imgView.image != nil;
    BOOL hasSecondaryImage = self.secondaryImgView.image != nil;

    self.textLeftMargin.active = hasImage;
    self.textLeftMarginNoImage.active = !hasImage;
    self.textRightMargin.active = hasSecondaryImage;
    self.textRightMarginNoImage.active = !hasSecondaryImage;

    self.descrLeftMargin.active = hasImage;
    self.descrLeftMarginNoImage.active = !hasImage;
    self.descrRightMargin.active = hasSecondaryImage;
    self.descrRightMarginNoImage.active = !hasSecondaryImage;

    self.textHeightPrimary.active = self.descriptionView.hidden;
    self.textHeightSecondary.active = !self.descriptionView.hidden;
    self.descrTopMargin.active = !self.descriptionView.hidden;
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasImage = self.imgView.image != nil;
        BOOL hasSecondaryImage = self.secondaryImgView.image != nil;

        res = res || self.textLeftMargin.active != hasImage;
        res = res || self.textLeftMarginNoImage.active != !hasImage;
        res = res || self.textRightMargin.active != hasSecondaryImage;
        res = res || self.textRightMarginNoImage.active != !hasSecondaryImage;

        res = res || self.descrLeftMargin.active != hasImage;
        res = res || self.descrLeftMarginNoImage.active != !hasImage;
        res = res || self.descrRightMargin.active != hasSecondaryImage;
        res = res || self.descrRightMarginNoImage.active != !hasSecondaryImage;

        res = res || self.textHeightPrimary.active != self.descriptionView.hidden;
        res = res || self.textHeightSecondary.active != !self.descriptionView.hidden;
        res = res || self.descrTopMargin.active != !self.descriptionView.hidden;
    }
    return res;
}

- (void) setSecondaryImage:(UIImage *)image
{
    if (DirectionIsRTL)
        self.secondaryImgView.image = image.imageFlippedForRightToLeftLayoutDirection;
    else
        self.secondaryImgView.image = image;
}

+ (CGFloat) getHeight:(NSString *)text desc:(NSString *)desc hasSecondaryImg:(BOOL)hasSecondaryImg cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - titleTextWidthDelta - (hasSecondaryImg ? secondaryImgWidth : switchCellWidth);
    if (!desc || desc.length == 0)
    {
        return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text]);
    }
    else
    {
        return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text] + [self.class getDescViewHeightWithWidth:textWidth text:desc]);
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    /*
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    
    CGFloat textX = self.imgView.hidden ? 16.0 : 62.0;
    CGFloat textWidth = w - titleTextWidthDelta - (self.secondaryImgView.image ? secondaryImgWidth : switchCellWidth);
    CGFloat titleHeight = [self.class getTitleViewHeightWithWidth:textWidth text:self.textView.text];
    
    if (self.descriptionView.hidden)
    {
        self.textView.frame = CGRectMake(textX, 0.0, textWidth, MAX(defaultCellHeight, titleHeight));
    }
    else
    {
        CGFloat descHeight = [self.class getDescViewHeightWithWidth:textWidth text:self.descriptionView.text];
        self.textView.frame = CGRectMake(textX, 2.0, textWidth, MAX(minTextHeight, titleHeight));
        self.descriptionView.frame = CGRectMake(textX, h - descHeight - 1.0, textWidth, descHeight);
    }
     */
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
        _descFont = [UIFont systemFontOfSize:12.0];
    
    return [OAUtilities calculateTextBounds:text width:width font:_descFont].height + textMarginVertical;
}

@end
