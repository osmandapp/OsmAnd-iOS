//
//  OANavigationSettingsFooter.h
//  OsmAnd
//
//  Created by nnngrach on 02.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OANavigationSettingsFooter.h"
#import "OAUtilities.h"

#define defaultCellHeight 18.0
#define titleTextDelta 50.0
#define textMarginVertical 5.0

static UIFont *_titleTextFont;

@implementation OANavigationSettingsFooter

+ (CGFloat) getHeight:(NSString *)title cellWidth:(CGFloat)cellWidth
{
    return MAX(defaultCellHeight, [self.class getTextViewHeightWithWidth:cellWidth title:title] + 1.0);
}

+ (CGFloat) getTextViewHeightWithWidth:(CGFloat)cellWidth title:(NSString *)title
{
    if (!_titleTextFont)
        _titleTextFont = [UIFont fontWithName:@"AvenirNext-Regular" size:13.0];
    
    CGFloat w = cellWidth - titleTextDelta;
    CGFloat titleHeight = 0;
    if (title)
        titleHeight = [OAUtilities calculateTextBounds:title width:w font:_titleTextFont].height + textMarginVertical * 2;
    
    return titleHeight;
}

@end

