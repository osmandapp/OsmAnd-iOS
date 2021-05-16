//
//  OAWaypointCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 20/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAWaypointCell.h"

@implementation OAWaypointCell

+ (NSString *) getCellIdentifier
{
    return @"OAWaypointCell";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
