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
    
    self.iconView.layer.cornerRadius = 6.0;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateConstraints
{
    CGFloat ratio = self.iconView.image.size.height / self.iconView.image.size.width;
    self.iconViewHeight.constant = self.iconView.frame.size.width * ratio;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        CGFloat ratio = self.iconView.image.size.height / self.iconView.image.size.width;
        res |= self.iconViewHeight.constant != self.iconView.frame.size.width * ratio;
    }
    return res;
}

@end
