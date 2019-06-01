//
//  OASwitchTableViewCell.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 16.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OASwitchTableViewCell.h"
#import "OAUtilities.h"

#define defaultCellHeight 44.0
#define titleTextWidthDelta 75.0
#define textMarginVertical 5.0

static UIFont *_titleTextFont;

@implementation OASwitchTableViewCell

+ (CGFloat) getHeight:(NSString *)title cellWidth:(CGFloat)cellWidth
{
    return MAX(defaultCellHeight, [self.class getTextViewHeightWithWidth:cellWidth title:title] + 1.0);
}

+ (CGFloat) getTextViewHeightWithWidth:(CGFloat)cellWidth title:(NSString *)title
{
    if (!_titleTextFont)
        _titleTextFont = [UIFont systemFontOfSize:16.0];
    
    CGFloat w = cellWidth - titleTextWidthDelta;
    CGFloat titleHeight = [OAUtilities calculateTextBounds:title width:w font:_titleTextFont].height + textMarginVertical * 2;
    return titleHeight;
}

@end
