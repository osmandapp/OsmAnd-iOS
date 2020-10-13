//
//  OATitleIconRoundCell.h
//  OsmAnd
//
//  Created by Paul on 31/05/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OATitleIconRoundCell.h"
#import "OAColors.h"

@implementation OATitleIconRoundCell
{
    BOOL _bottomCorners;
    BOOL _topCorners;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)highlight:(BOOL)highlighted
{
    if (highlighted)
    {
        _contentContainer.backgroundColor = UIColorFromRGB(color_primary_purple);
        _titleView.textColor = UIColor.whiteColor;
        [_iconView setTintColor:UIColor.whiteColor];
    }
    else
    {
        _contentContainer.backgroundColor = UIColor.whiteColor;
        _titleView.textColor = UIColor.blackColor;
        [_iconView setTintColor:_iconColorNormal ? _iconColorNormal : UIColorFromRGB(color_primary_purple)];
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

- (void) roundCorners:(BOOL)topCorners bottomCorners:(BOOL)bottomCorners
{
    _bottomCorners = bottomCorners;
    _topCorners = topCorners;
}

@end
