//
//  OAIconTextFieldCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 04/01/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAIconTextFieldCell.h"

@implementation OAIconTextFieldCell

+ (NSString *) getCellIdentifier
{
    return @"OAIconTextFieldCell";
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
