//
//  OALabelCollectionViewCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 27.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OALabelCollectionViewCell.h"

@implementation OALabelCollectionViewCell

+ (NSString *)getCellIdentifier
{
    return @"OALabelCollectionViewCell";
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backView.layer.cornerRadius = 14.;
}

@end

