//
//  OADateTimePickerTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 06/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OADateTimePickerTableViewCell.h"

@implementation OADateTimePickerTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

+ (NSString *) getCellIdentifier
{
    return @"OADateTimePickerTableViewCell";
}

@end
