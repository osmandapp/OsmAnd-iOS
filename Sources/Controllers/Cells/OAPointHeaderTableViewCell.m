//
//  OAPointHeaderTableViewCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 16.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAPointHeaderTableViewCell.h"

@implementation OAPointHeaderTableViewCell

+ (NSString *) getCellIdentifier
{
    return @"OAPointHeaderTableViewCell";
}

- (void)awakeFromNib {
    [super awakeFromNib];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
