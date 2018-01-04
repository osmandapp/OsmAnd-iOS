//
//  OAIconTextButtonCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/01/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAIconTextButtonCell.h"
#import "OAUtilities.h"

#define textMarginVertical 5.0
#define minTextHeight 38.0
#define deltaTextWidth 128.0
#define descTextFullHeight 25.0
#define imageSize 50.0
#define detailsIconWidth 30.0

#define defaultCellHeight 51.0
#define defaultCellContentHeight 50.0

static UIFont *_textFont;

@implementation OAIconTextButtonCell

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

+ (CGFloat) getHeight:(NSString *)text descHidden:(BOOL)descHidden detailsIconHidden:(BOOL)detailsIconHidden cellWidth:(CGFloat)cellWidth
{
    if (descHidden)
    {
        return MAX(defaultCellHeight, [self.class getTextViewHeightWithWidth:cellWidth - deltaTextWidth + (detailsIconHidden ? detailsIconWidth : 0.0) text:text] + 1.0);
    }
    else
    {
        return MAX(defaultCellHeight, [self.class getTextViewHeightWithWidth:cellWidth - deltaTextWidth + (detailsIconHidden ? detailsIconWidth : 0.0) text:text] + descTextFullHeight + 1.0);
    }
}

-(void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    
    self.iconView.center = CGPointMake(imageSize / 2, h / 2);
    self.detailsIconView.center = CGPointMake(w - 62, h / 2);
    self.buttonView.center = CGPointMake(w - 25, h / 2);
    
    CGFloat textWidth = w - deltaTextWidth + (self.detailsIconView.hidden ? detailsIconWidth : 0.0);
    CGFloat textHeight = [self.class getTextViewHeightWithWidth:textWidth text:self.textView.text];
    
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

+ (CGFloat) getTextViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_textFont)
        _textFont = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];
    
    return [OAUtilities calculateTextBounds:text width:width font:_textFont].height + textMarginVertical * 2;
}

@end
