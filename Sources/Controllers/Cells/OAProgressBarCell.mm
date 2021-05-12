//
//  OAProgressBarCell.m
//  OsmAnd
//
//  Created by Paul on 26/06/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAProgressBarCell.h"

@implementation OAProgressBarCell

+ (NSString *) getCellIdentifier
{
    return @"OAProgressBarCell";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

@end
