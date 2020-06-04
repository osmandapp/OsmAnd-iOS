//
//  OATimeTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OATimeTableViewCell.h"
#import "OAColors.h"

#define leftTextMargin 62.0

@implementation OATimeTableViewCell
{
    UIView *_separator;
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)showLeftImageView:(BOOL)show
{
    _leftImageView.hidden = !show;
    [self setNeedsLayout];
}

@end
