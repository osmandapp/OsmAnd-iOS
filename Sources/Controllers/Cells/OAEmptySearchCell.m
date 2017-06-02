//
//  OAEmptySearchCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAEmptySearchCell.h"
#import "OAUtilities.h"

#define contentMarginTopBottom 20.0
#define textMarginBottom 10.0
#define textMarginRight 8.0

static UIFont *_titleTextFont;
static UIFont *_messageTextFont;

@implementation OAEmptySearchCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (void) initFonts
{
    if (!_titleTextFont)
        _titleTextFont = [UIFont fontWithName:@"AvenirNext-Medium" size:16.0];
    if (!_messageTextFont)
        _messageTextFont = [UIFont fontWithName:@"AvenirNext-Regular" size:14.0];
}

+ (CGFloat) getHeightWithTitle:(NSString *)title message:(NSString *)message cellWidth:(CGFloat)cellWidth
{
    [self initFonts];
    
    CGFloat rightImageX = cellWidth / 2 - 56;
    CGFloat textWidth = cellWidth - rightImageX - textMarginRight;
    CGFloat titleHeight = [OAUtilities calculateTextBounds:title width:textWidth font:_titleTextFont].height;
    CGFloat messageHeight = [OAUtilities calculateTextBounds:message width:textWidth font:_messageTextFont].height;
    
    return contentMarginTopBottom + titleHeight + textMarginBottom + messageHeight + contentMarginTopBottom;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    [self.class initFonts];
    
    CGFloat w = self.bounds.size.width;
    CGFloat h = self.bounds.size.height;
    
    CGFloat rightImageX = w / 2 - 56;
    CGFloat textWidth = w - rightImageX - textMarginRight;
    CGFloat titleHeight = [OAUtilities calculateTextBounds:self.titleView.text width:textWidth font:_titleTextFont].height;
    CGFloat messageHeight = [OAUtilities calculateTextBounds:self.messageView.text width:textWidth font:_messageTextFont].height;

    self.iconView.center = CGPointMake(rightImageX - self.iconView.bounds.size.width / 2, h / 2);
    self.titleView.frame = CGRectMake(rightImageX, contentMarginTopBottom, textWidth, titleHeight);
    self.messageView.frame = CGRectMake(rightImageX, contentMarginTopBottom + titleHeight + textMarginBottom, textWidth, messageHeight);
}

@end
