//
//  OAIconTitleIconRoundCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 06.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAIconTitleIconRoundCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

@implementation OAIconTitleIconRoundCell
{
    BOOL _bottomCorners;
    BOOL _topCorners;
}

+ (NSString *)getCellIdentifier
{
    return @"OAIconTitleIconRoundCell";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    for (UIView *view in self.subviews) {
        if ([view isEqual:self.contentView]) continue;
        view.hidden = view.bounds.size.width == self.bounds.size.width;
    }
    CGFloat w = self.bounds.size.width;
    _contentContainer.frame = CGRectMake(16.0, 0.0, w - 32.0, self.bounds.size.height);
    
    UIRectCorner corners;
    if (_topCorners && _bottomCorners)
        corners = UIRectCornerAllCorners;
    else
        corners = _topCorners ? UIRectCornerTopRight | UIRectCornerTopLeft : UIRectCornerBottomLeft | UIRectCornerBottomRight;
     
    if (_topCorners || _bottomCorners)
        [OAUtilities setMaskTo:_contentContainer byRoundingCorners:corners radius:12.];
}

- (void) roundCorners:(BOOL)topCorners bottomCorners:(BOOL)bottomCorners
{
    _bottomCorners = bottomCorners;
    _topCorners = topCorners;
}

@end
