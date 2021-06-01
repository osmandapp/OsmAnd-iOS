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

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) updateSeparator:(NSInteger)x
{

}

- (void) updateConstraints
{
    self.iconView.hidden = self.iconView.image == nil;
    _leftTextPrimaryConstraint.active = !self.iconView.hidden;
    _leftTextSecondaryConstraint.active = self.iconView.hidden;
    _leftSeparatorPrimaryConstraint.active = !self.iconView.hidden;
    _leftSeparatorSecondaryConstraint.active = self.iconView.hidden;

    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    self.iconView.hidden = self.iconView.image == nil;
    if (!res)
    {
        res = res || self.leftTextPrimaryConstraint.active != self.iconView.hidden;
        res = res || self.leftTextSecondaryConstraint.active != !self.iconView.hidden;
        res = res || self.leftSeparatorPrimaryConstraint.active != self.iconView.hidden;
        res = res || self.leftSeparatorSecondaryConstraint.active != !self.iconView.hidden;
    }
    return res;
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
