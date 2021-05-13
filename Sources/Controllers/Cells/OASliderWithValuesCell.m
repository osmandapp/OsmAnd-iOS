//
//  OASliderWithValuesCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASliderWithValuesCell.h"

@implementation OASliderWithValuesCell

+ (NSString *) getCellIdentifier
{
    return @"OASliderWithValuesCell";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
