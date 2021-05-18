//
//  OARoutingTargetCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutingTargetCell.h"

@implementation OARoutingTargetCell
{
    CALayer *_divider;
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    // Initialization code
    _divider = [CALayer layer];
    _divider.backgroundColor = [[UIColor colorWithWhite:0.50 alpha:0.3] CGColor];
    [self.contentView.layer addSublayer:_divider];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    if (!_finishPoint)
        _divider.frame = CGRectMake(62.0, self.contentView.frame.size.height - 0.5, self.contentView.frame.size.width - 62.0 - 60., 0.5);
    else
        _divider.frame = CGRectMake(0.0, self.contentView.frame.size.height - 0.5, self.contentView.frame.size.width, 0.5);
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setDividerVisibility:(BOOL)hidden
{
    _divider.hidden = hidden;
}

@end
