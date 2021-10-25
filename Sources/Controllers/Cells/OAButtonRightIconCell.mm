//
//  OAButtonRightIconCell.m
//  OsmAnd
//
// Created by Skalii Dmitrii on 22.04.2021.
// Copyright (c) 2021 OsmAnd. All rights reserved.
//

#import "OAButtonRightIconCell.h"

@implementation OAButtonRightIconCell

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void)setButtonTopOffset:(CGFloat)offset
{
    self.buttonVerticallyAllignmentConstraint.active = NO;
    self.buttonTopConstraint.constant = offset;
    self.buttonHeightConstraint.constant = 17;
}

@end
