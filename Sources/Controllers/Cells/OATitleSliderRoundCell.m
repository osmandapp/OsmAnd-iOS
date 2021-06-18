//
//  OATitleSliderRoundCell.m
//  OsmAnd
//
//  Created by Skalii on 02.06.2021.
//  Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OATitleSliderRoundCell.h"

@implementation OATitleSliderRoundCell
{
    BOOL _bottomCorners;
    BOOL _topCorners;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self applyCornerRadius];
}

- (void)applyCornerRadius
{
    UIRectCorner corners;
    if (_topCorners && _bottomCorners)
        corners = UIRectCornerAllCorners;
    else
        corners = _topCorners ? UIRectCornerTopRight | UIRectCornerTopLeft : UIRectCornerBottomLeft | UIRectCornerBottomRight;

    if (_topCorners || _bottomCorners)
        [OAUtilities setMaskTo:_contentContainer byRoundingCorners:corners radius:12.];
}

- (void)roundCorners:(BOOL)topCorners bottomCorners:(BOOL)bottomCorners
{
    _bottomCorners = bottomCorners;
    _topCorners = topCorners;
}

@end
