//
//  OATextInputFloatingCellWithIcon.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/04/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATextInputFloatingCellWithIcon.h"
#import "OAUtilities.h"

#define defaultCellHeight 60.0
#define rightMargin 16.0
#define clearButtonWidth 20.0
#define titleTextWidthDelta 50.0
#define textMarginVertical 5.0
#define minTextHeight 32.0

static UIFont *_titleFont;
static UIFont *_descFont;

@implementation OATextInputFloatingCellWithIcon

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

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width;
    
    CGFloat textX = 50.0;
    CGFloat textWidth = w - titleTextWidthDelta - rightMargin - [OAUtilities getLeftMargin] * 2;
    CGFloat titleHeight = [self.class getTitleViewHeightWithWidth:textWidth - clearButtonWidth text:self.textField.text];
    
    if (self.fieldLabel.hidden)
    {
        self.textField.frame = CGRectMake(textX, 0.0, textWidth, MAX(defaultCellHeight, titleHeight));
    }
    else
    {
        CGFloat descHeight = [self.class getDescViewHeightWithWidth:textWidth text:self.textLabel.text];
        self.fieldLabel.frame = CGRectMake(textX, 4.0, textWidth, descHeight);
        self.textField.frame = CGRectMake(textX, descHeight - textMarginVertical, textWidth, MAX(minTextHeight, titleHeight));
        
    }
    self.buttonView.frame = CGRectMake(0.0, 0.0, 50.0, self.bounds.size.height);
}

+ (CGFloat) getHeight:(NSString *)text desc:(NSString *)desc cellWidth:(CGFloat)cellWidth
{
    CGFloat textWidth = cellWidth - titleTextWidthDelta - rightMargin - clearButtonWidth - [OAUtilities getLeftMargin] * 2;
    if (!desc || desc.length == 0)
    {
        return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text]);
    }
    else
    {
        return MAX(defaultCellHeight, [self.class getTitleViewHeightWithWidth:textWidth text:text] + [self.class getDescViewHeightWithWidth:textWidth text:desc] * 2);
    }
}

+ (CGFloat) getTitleViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_titleFont)
        _titleFont = [UIFont systemFontOfSize:17.0];

    text = text.length == 0 ? @"a" : text;
    return [OAUtilities calculateTextBounds:text width:width font:_titleFont].height + textMarginVertical;
}

+ (CGFloat) getDescViewHeightWithWidth:(CGFloat)width text:(NSString *)text
{
    if (!_descFont)
        _descFont = [UIFont systemFontOfSize:12.0];
    
    return [OAUtilities calculateTextBounds:text width:width font:_descFont].height + textMarginVertical;
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder
{
    return YES;
}

- (BOOL)becomeFirstResponder
{
    return [self.textField becomeFirstResponder];
}

@end
