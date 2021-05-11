//
//  OAGPXRouteRoundCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAGPXRouteRoundCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

@implementation OAGPXRouteRoundCell
{
    BOOL _bottomCorners;
    BOOL _topCorners;
}

+ (NSString *) getCellIdentifier
{
    return @"OAGPXRouteRoundCell";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    _rightIconImageVIew.image = [[UIImage imageNamed:@"ic_custom_trip"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _distanceImageView.image = [[UIImage imageNamed:@"ic_small_distance"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _timeImageView.image = [[UIImage imageNamed:@"ic_small_time_start"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    _wptImageView.image = [[UIImage imageNamed:@"ic_small_waypoints"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    _rightIconImageVIew.tintColor = UIColorFromRGB(color_primary_purple);
    _distanceImageView.tintColor = UIColorFromRGB(color_tint_gray);
    _timeImageView.tintColor = UIColorFromRGB(color_tint_gray);
    _wptImageView.tintColor = UIColorFromRGB(color_tint_gray);
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)highlight:(BOOL)highlighted
{
    if (highlighted)
    {
        _contentContainer.backgroundColor = UIColorFromRGB(color_primary_purple);
        _fileName.textColor = UIColor.whiteColor;
        [_rightIconImageVIew setTintColor:UIColor.whiteColor];
    }
    else
    {
        _contentContainer.backgroundColor = UIColor.whiteColor;
        _fileName.textColor = UIColor.blackColor;
        [_rightIconImageVIew setTintColor: UIColorFromRGB(color_primary_purple)];
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
