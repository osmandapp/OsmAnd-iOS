//
//  OATitleTwoIconsRoundCell.h
//  OsmAnd
//
//  Created by nnngrach on 17/08/2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATitleTwoIconsRoundCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

#define defaultCellHeight 48.0
#define titleTextWidthDelta 64.0
#define maxButtonWidth 30.0
#define textMarginVertical 5.0

static UIFont *_titleFont;

@implementation OATitleTwoIconsRoundCell
{
    BOOL _bottomCorners;
    BOOL _topCorners;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width;
    self.contentContainer.frame = CGRectMake(16.0, 0.0, w - 32.0, self.bounds.size.height);
    
    CGFloat textX = 62.0;
    CGFloat textWidth = w - titleTextWidthDelta - maxButtonWidth;
    CGFloat titleHeight = [self.class getTitleViewHeightWithWidth:textWidth text:self.titleView.text];
    self.titleView.frame = CGRectMake(textX, 0.0, textWidth, MAX(defaultCellHeight, titleHeight));
    
    CGRect leftIconFrame = self.leftIconView.frame;
    leftIconFrame.origin.x = 16.0;
    leftIconFrame.origin.y = self.contentContainer.frame.size.height / 2 - leftIconFrame.size.height / 2;
    self.leftIconView.frame = leftIconFrame;
    
    CGRect rightIconFrame = self.rightIconView.frame;
    rightIconFrame.origin.x = self.contentContainer.frame.size.width - 16.0 - rightIconFrame.size.width;
    rightIconFrame.origin.y = self.contentContainer.frame.size.height / 2 - rightIconFrame.size.height / 2;
    self.rightIconView.frame = rightIconFrame;
    
    
    UIRectCorner corners;
    if (_topCorners && _bottomCorners)
        corners = UIRectCornerAllCorners;
    else
        corners = _topCorners ? UIRectCornerTopRight | UIRectCornerTopLeft : UIRectCornerBottomLeft | UIRectCornerBottomRight;
     
    if (_topCorners || _bottomCorners)
        [OAUtilities setMaskTo:self.contentContainer byRoundingCorners:corners radius:12.];
}

@end
