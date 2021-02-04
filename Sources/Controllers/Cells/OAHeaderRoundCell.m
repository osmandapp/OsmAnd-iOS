//
//  OAHeaderRoundCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 15.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAHeaderRoundCell.h"
#import "OAUtilities.h"
#import "OAColors.h"

@implementation OAHeaderRoundCell

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
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
    corners =  UIRectCornerTopRight | UIRectCornerTopLeft;
    [OAUtilities setMaskTo:_contentContainer byRoundingCorners:corners radius:12.];
}

@end
