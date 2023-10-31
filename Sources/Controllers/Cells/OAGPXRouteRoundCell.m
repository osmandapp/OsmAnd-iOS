//
//  OAGPXRouteRoundCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGPXRouteRoundCell.h"
#import "OAUtilities.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OAGPXRouteRoundCell
{
    BOOL _bottomCorners;
    BOOL _topCorners;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    _rightIconImageVIew.image = [UIImage templateImageNamed:@"ic_custom_trip"];
    _distanceImageView.image = [UIImage templateImageNamed:@"ic_small_distance"];
    _timeImageView.image = [UIImage templateImageNamed:@"ic_small_time_start"];
    _wptImageView.image = [UIImage templateImageNamed:@"ic_small_waypoints"];
    
    _rightIconImageVIew.tintColor = UIColor.iconColorActive;
    _distanceImageView.tintColor = UIColor.iconColorSecondary;
    _timeImageView.tintColor = UIColor.iconColorSecondary;
    _wptImageView.tintColor = UIColor.iconColorSecondary;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)highlight:(BOOL)highlighted
{
    if (highlighted)
    {
        _contentContainer.backgroundColor = UIColor.iconColorActive;
        _fileName.textColor = UIColor.whiteColor;
        [_rightIconImageVIew setTintColor:UIColor.whiteColor];
    }
    else
    {
        _contentContainer.backgroundColor = UIColor.groupBgColor;
        _fileName.textColor = UIColor.textColorPrimary;
        [_rightIconImageVIew setTintColor: UIColor.iconColorActive];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:.2 animations:^{
            [self highlight:highlighted];
        }];
    }
    else
    {
        [self highlight:highlighted];
    }
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
