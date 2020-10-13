//
//  OAWaypointHeader.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAWaypointHeaderCell.h"
#import "OAUtilities.h"

@implementation OAWaypointHeaderCell

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) updateConstraints
{
    _leftTitleMarginNoProgress.active = self.progressView.hidden;
    _leftTitleMarginWithProgressView.active = !self.progressView.hidden;
    [super updateConstraints];
}

@end
