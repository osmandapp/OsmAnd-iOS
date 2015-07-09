//
//  OAGPXRouteWaypointTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 09/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRouteWaypointTableViewCell.h"

@implementation OAGPXRouteWaypointTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)hideVDots:(BOOL)hide
{
    if (hide)
    {
        self.vDotsTop.hidden = YES;
        self.vDotsBottom.hidden = YES;
    }
    else
    {
        self.vDotsTop.hidden = !self.topVDotsVisible;
        self.vDotsBottom.hidden = !self.bottomVDotsVisible;
    }
}

- (void)hideDescIcon:(BOOL)hide
{
    CGRect f = self.descLabel.frame;
    if (hide)
        f.origin.x = self.titleLabel.frame.origin.x;
    else
        f.origin.x = 66.0;

    self.descLabel.frame = f;
    self.descIcon.hidden = hide;
}

- (void)hideRightButton:(BOOL)hide
{
    if (self.rightButton.hidden == hide)
        return;
    
    self.rightButton.hidden = hide;
    
    CGRect f = self.titleLabel.frame;
    if (hide)
        f.size.width = self.contentView.frame.size.width - f.origin.x - 5.0;
    else
        f.size.width = self.contentView.frame.size.width - f.origin.x - 5.0 - self.rightButton.bounds.size.width;

    self.titleLabel.frame = f;
    
    f = self.descLabel.frame;
    if (hide)
        f.size.width = self.contentView.frame.size.width - f.origin.x - 5.0;
    else
        f.size.width = self.contentView.frame.size.width - f.origin.x - 5.0 - self.rightButton.bounds.size.width;
    
    self.descLabel.frame = f;
}

@end
