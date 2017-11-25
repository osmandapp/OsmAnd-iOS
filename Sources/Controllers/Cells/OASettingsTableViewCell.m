//
//  OASettingsTableViewCell.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 06.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASettingsTableViewCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 44.0
#define titleTextWidthKoef (320.0 / 154.0)
#define valueTextWidthKoef (320.0 / 118.0)
#define textMarginVertical 5.0

static UIFont *_titleTextFont;
static UIFont *_valueTextFont;

@implementation OASettingsTableViewCell

+ (CGFloat) getHeight:(NSString *)title value:(NSString *)value cellWidth:(CGFloat)cellWidth
{
    return MAX(defaultCellHeight, [self.class getTextViewHeightWithWidth:cellWidth title:title value:value] + 1.0);
}

+ (CGFloat) getTextViewHeightWithWidth:(CGFloat)cellWidth title:(NSString *)title value:(NSString *)value
{
    if (!_titleTextFont)
        _titleTextFont = [UIFont fontWithName:@"AvenirNext-Regular" size:16.0];
    
    if (!_valueTextFont)
        _valueTextFont = [UIFont fontWithName:@"AvenirNext-Regular" size:13.0];
    
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
