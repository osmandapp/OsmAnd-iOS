//
//  OAImageDescTableViewCell.m
//  OsmAnd
//
//  Created by igor on 24.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAImageDescTableViewCell.h"

@implementation OAImageDescTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    CGFloat ratio = self.iconView.image.size.height / self.iconView.image.size.width;
    self.iconViewHeight.constant = self.iconView.frame.size.width * ratio;
}

@end
