//
//  OATitleTwoIconsRoundCell.h
//  OsmAnd
//
//  Created by nnngrach on 17/08/2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OATitleTwoIconsRoundCell.h"
#import "OAUtilities.h"

@implementation OATitleTwoIconsRoundCell
{
    BOOL _bottomCorners;
    BOOL _topCorners;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    UIRectCorner corners;
    if (_topCorners && _bottomCorners)
        corners = UIRectCornerAllCorners;
    else
        corners = _topCorners ? UIRectCornerTopRight | UIRectCornerTopLeft : UIRectCornerBottomLeft | UIRectCornerBottomRight;

    if (_topCorners || _bottomCorners)
        [OAUtilities setMaskTo:self.contentContainer byRoundingCorners:corners radius:12.];
}

@end
