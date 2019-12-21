//
//  OAIconTextDescCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 20/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAIconTextDescCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 50.0
#define titleTextWidthKoef (320.0 / 154.0)
#define valueTextWidthKoef (320.0 / 118.0)
#define textMarginVertical 5.0

static UIFont *_titleTextFont;
static UIFont *_valueTextFont;

@implementation OAIconTextDescCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.arrowIconView.image = self.arrowIconView.image.imageFlippedForRightToLeftLayoutDirection;
}

- (void) updateConstraints
{
    [super updateConstraints];

    BOOL hasImage = self.iconView.image != nil;

    self.textLeftMargin.active = hasImage;
    self.textLeftMarginNoImage.active = !hasImage;

    self.descrLeftMargin.active = hasImage;
    self.descrLeftMarginNoImage.active = !hasImage;

    self.textHeightPrimary.active = self.descView.hidden;
    self.textHeightSecondary.active = !self.descView.hidden;
    self.descrTopMargin.active = !self.descView.hidden;
    self.textBottomMargin.active = self.descView.hidden;
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasImage = self.iconView.image != nil;

        res = res || self.textLeftMargin.active != hasImage;
        res = res || self.textLeftMarginNoImage.active != !hasImage;

        res = res || self.descrLeftMargin.active != hasImage;
        res = res || self.descrLeftMarginNoImage.active != !hasImage;

        res = res || self.textHeightPrimary.active != self.descView.hidden;
        res = res || self.textHeightSecondary.active != !self.descView.hidden;
        res = res || self.descrTopMargin.active != !self.descView.hidden;
        res = res || self.textBottomMargin.active != self.descView.hidden;
    }
    return res;
}

+ (CGFloat) getHeight:(NSString *)title value:(NSString *)value cellWidth:(CGFloat)cellWidth
{
    return MAX(defaultCellHeight, [self.class getTextViewHeightWithWidth:cellWidth title:title value:value] + 1.0);
}

+ (CGFloat) getTextViewHeightWithWidth:(CGFloat)cellWidth title:(NSString *)title value:(NSString *)value
{
    if (!_titleTextFont)
        _titleTextFont = [UIFont fontWithName:@"AvenirNext-Regular" size:15.0];
    
    if (!_valueTextFont)
        _valueTextFont = [UIFont fontWithName:@"AvenirNext-Regular" size:12.0];
    
    CGFloat w = cellWidth / titleTextWidthKoef;
    CGFloat titleHeight = 0;
    if (title)
        titleHeight = [OAUtilities calculateTextBounds:title width:w font:_titleTextFont].height + textMarginVertical * 2;
    
    w = cellWidth / valueTextWidthKoef;
    CGFloat valueHeight = 0;
    if (value && value.length > 0)
        valueHeight = [OAUtilities calculateTextBounds:value width:w font:_valueTextFont].height + textMarginVertical * 2;
    
    return MAX(titleHeight, valueHeight);
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
