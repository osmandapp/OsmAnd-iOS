//
//  OASegmentedControlCell.m
//  OsmAnd
//
//  Created by Paul on 24/11/2020.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OASegmentedControlCell.h"

@implementation OASegmentedControlCell

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)changeHeight:(BOOL)higher
{
    self.segmentedControlPrimaryHeight.active = !higher;
    self.segmentedControlSecondaryHeight.active = higher;
}

@end
