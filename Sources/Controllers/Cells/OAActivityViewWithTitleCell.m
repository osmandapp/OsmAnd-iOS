//
//  OAActivityViewWithTitleCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 20.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAActivityViewWithTitleCell.h"

@implementation OAActivityViewWithTitleCell

+ (NSString *) getCellIdentifier
{
    return @"OAActivityViewWithTitleCell";
}

- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
