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

#define kTitleTopBottomMargin 13.0

@implementation OAIconTitleIconRoundCell
{
    BOOL _bottomCorners;
    BOOL _topCorners;
}

- (void) updateConstraints
{
    _leftTextPrimaryConstraint.active = !self.iconView.hidden;
    _leftTextSecondaryConstraint.active = self.iconView.hidden;
    _leftSeparatorPrimaryConstraint.active = !self.iconView.hidden;
    _leftSeparatorSecondaryConstraint.active = self.iconView.hidden;

    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        res = res || self.leftTextPrimaryConstraint.active != self.iconView.hidden;
        res = res || self.leftTextSecondaryConstraint.active != !self.iconView.hidden;
        res = res || self.leftSeparatorPrimaryConstraint.active != self.iconView.hidden;
        res = res || self.leftSeparatorSecondaryConstraint.active != !self.iconView.hidden;
    }
    return res;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	[self applyCornerRadius];
}

- (void) applyCornerRadius
{
	CGFloat width = self.bounds.size.width - 40.;
	CGFloat height = self.bounds.size.height;
	_contentContainer.frame = CGRectMake(20., 0., width, height);
    
    _titleView.frame = CGRectMake( _titleView.frame.origin.x, _titleView.frame.origin.y,  _titleView.frame.size.width, height - 2 * kTitleTopBottomMargin);
    
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

- (void)prepareForReuse
{
	[super prepareForReuse];
	_contentContainer.layer.mask = nil;
}

@end
