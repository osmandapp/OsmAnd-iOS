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

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat textX = self.leftImageView.hidden ? 16.0 : leftTextMargin;
    CGFloat w = self.bounds.size.width - textX;
    
    self.lbTitle.frame = CGRectMake(textX, 0.0, w - self.lbTime.frame.size.width, self.bounds.size.height);
    
}

- (void)showLeftImageView:(BOOL)show
{
    _leftImageView.hidden = !show;
    [self setNeedsLayout];
}

@end
