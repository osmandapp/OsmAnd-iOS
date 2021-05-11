//
//  OAEmptySearchCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAEmptySearchCell.h"
#import "OAUtilities.h"

@implementation OAEmptySearchCell

+ (NSString *) getCellIdentifier
{
    return @"OAEmptySearchCell";
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
