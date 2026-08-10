//
//  OARoutingTargetCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/08/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARoutingTargetCell.h"
#import "OsmAnd_Maps-Swift.h"

@implementation OARoutingTargetCell
{
    SeparatorView *_divider;
}

- (void) awakeFromNib
{
    [super awakeFromNib];

    _divider = [[SeparatorView alloc] init];
    _divider.userInteractionEnabled = NO;
    [self.contentView addSubview:_divider];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat dividerHeight = [SeparatorAppearance thicknessForView:_divider];
    CGFloat dividerY = self.contentView.frame.size.height - dividerHeight;
    if (!_finishPoint)
        _divider.frame = CGRectMake(62.0, dividerY, self.contentView.frame.size.width - 62.0 - 60., dividerHeight);
    else
        _divider.frame = CGRectMake(0.0, dividerY, self.contentView.frame.size.width, dividerHeight);
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
