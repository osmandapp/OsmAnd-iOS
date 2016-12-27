//
//  OAIconTextSwitchCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAIconTextSwitchCell.h"
#import "OAUtilities.h"

#define textMarginVertical 5.0
#define minTextHeight 38.0
#define descTextFullHeight 25.0
#define imageSize 50.0

#define defaultCellHeight 51.0
#define defaultCellContentHeight 50.0

@implementation OAIconTextSwitchCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (CGFloat) getCellHeight
{
    if (self.descView.hidden)
    {
        return MAX(defaultCellHeight, [self getTextViewHeightWithWidth:self.textView.bounds.size.width]);
    }
    else
    {
        return MAX(defaultCellHeight, [self getTextViewHeightWithWidth:self.textView.bounds.size.width] + descTextFullHeight);
    }
    return defaultCellHeight;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    
    self.iconView.center = CGPointMake(imageSize / 2, h / 2);
    self.detailsIconView.center = CGPointMake(w - 82, h / 2);
    self.switchView.center = CGPointMake(w - 38, h / 2);
    
    CGFloat textWidth = self.detailsIconView.frame.origin.x - (imageSize + 1.0);
    CGFloat textHeight = [self getTextViewHeightWithWidth:textWidth];

    if (self.descView.hidden)
    {
        self.textView.frame = CGRectMake(imageSize + 1.0, 0.0, textWidth, MAX(defaultCellContentHeight, textHeight));
    }
    else
    {
        self.textView.frame = CGRectMake(imageSize + 1.0, 0.0, textWidth, MAX(minTextHeight, textHeight));
        self.descView.frame = CGRectMake(imageSize + 1.0, h - descTextFullHeight, textWidth, self.descView.frame.size.height);
    }
}

- (CGFloat) getTextViewHeightWithWidth:(CGFloat)width
{
    return [OAUtilities calculateTextBounds:self.textView.text width:width font:self.textView.font].height + textMarginVertical * 2;
}

@end
