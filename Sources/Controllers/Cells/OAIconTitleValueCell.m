//
//  OAIconTitleValueCell.m
//  OsmAnd
//
//  Created by Paul on 01.06.19.
//  Copyright (c) 2019 OsmAnd. All rights reserved.
//

#import "OAIconTitleValueCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 44.0
#define titleTextWidthKoef (320.0 / 154.0)
#define valueTextWidthKoef (320.0 / 118.0)
#define textMarginVertical 5.0

static UIFont *_titleTextFont;
static UIFont *_valueTextFont;

@implementation OAIconTitleValueCell

+ (CGFloat) getHeight:(NSString *)title value:(NSString *)value cellWidth:(CGFloat)cellWidth
{
    return MAX(defaultCellHeight, [self.class getTextViewHeightWithWidth:cellWidth title:title value:value] + 1.0);
}

+ (CGFloat) getTextViewHeightWithWidth:(CGFloat)cellWidth title:(NSString *)title value:(NSString *)value
{
    if (!_titleTextFont)
        _titleTextFont = [UIFont systemFontOfSize:17.0];
    
    if (!_valueTextFont)
        _valueTextFont = [UIFont systemFontOfSize:13.0];
    
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

@end
