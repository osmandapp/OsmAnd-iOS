//
//  OADescrTitleIconCell.m
//  OsmAnd
//
//  Created by Paul on 17/10/19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import "OADescrTitleIconCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 60.0
#define textMarginVertical 5.0
#define titleTextWidthDelta 62.0
#define minTextHeight 35.0

static UIFont *_titleTextFont;
static UIFont *_valueTextFont;

@implementation OADescrTitleIconCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width;
    
    CGFloat textX = 62.0;
    CGFloat textWidth = w - titleTextWidthDelta - 16.0;
    CGFloat titleHeight = [self.class getTitleViewHeightWithWidth:textWidth text:self.textView.text];;
    
    if (self.descView.hidden)
    {
        self.textView.frame = CGRectMake(textX, 5.0, textWidth, MAX(defaultCellHeight, titleHeight));
    }
    else
    {
        CGFloat descHeight = [self.class getDescViewHeightWithWidth:textWidth text:self.descView.text];
        self.descView.frame = CGRectMake(textX, 10.0, textWidth, descHeight);
        self.textView.frame = CGRectMake(textX, CGRectGetMaxY(self.descView.frame), textWidth, titleHeight);
    }
}

+ (CGFloat) getHeight:(NSString *)title value:(NSString *)value cellWidth:(CGFloat)cellWidth
{
    return MAX(defaultCellHeight, [self.class getTextViewHeightWithWidth:cellWidth - titleTextWidthDelta - 16.0 title:title value:value] + 15.0);
}

+ (CGFloat) getTextViewHeightWithWidth:(CGFloat)cellWidth title:(NSString *)title value:(NSString *)value
{
    CGFloat w = cellWidth - titleTextWidthDelta - [OAUtilities getLeftMargin] * 2;
    return [self getTitleViewHeightWithWidth:w text:title] + [self getDescViewHeightWithWidth:w text:value];
}


+ (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_titleTextFont)
        _titleTextFont = [UIFont systemFontOfSize:17.0];
    CGFloat titleHeight = 0;
    if (text)
        titleHeight = [OAUtilities calculateTextBounds:text width:width font:_titleTextFont].height + textMarginVertical;
    return titleHeight;
}

+ (CGFloat) getDescViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_valueTextFont)
        _valueTextFont = [UIFont systemFontOfSize:13.0];
    
    CGFloat valueHeight = 0;
    if (text && text.length > 0)
        valueHeight = [OAUtilities calculateTextBounds:text width:width font:_valueTextFont].height;
    
    return valueHeight;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)showImage:(BOOL)show
{
    if (show)
    {
        CGRect frame = CGRectMake(62.0, self.textView.frame.origin.y, self.textView.frame.size.width, self.textView.frame.size.height);
        self.textView.frame = frame;
        
        frame = CGRectMake(62.0, self.descView.frame.origin.y, self.descView.frame.size.width, self.descView.frame.size.height);
        self.descView.frame = frame;
    }
    else
    {
        CGRect frame = CGRectMake(16.0, self.textView.frame.origin.y, self.textView.frame.size.width, self.textView.frame.size.height);
        self.textView.frame = frame;
        
        frame = CGRectMake(16.0, self.descView.frame.origin.y, self.descView.frame.size.width, self.descView.frame.size.height);
        self.descView.frame = frame;
    }
}


@end
