//
//  OARadiusCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 19/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OARadiusCell.h"

@implementation OARadiusCell

+ (NSString *) getCellIdentifier
{
    return @"OARadiusCell";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.separatorInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

@end
