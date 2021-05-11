//
//  OAColorsCollectionViewCell.m
//  OsmAnd
//
//  Created by igor on 06.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAColorsCollectionViewCell.h"

@implementation OAColorsCollectionViewCell

+ (NSString *) getCellIdentifier
{
    return @"OAColorsCollectionViewCell";
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.colorView.layer.cornerRadius = self.colorView.frame.size.height/2;
    self.backView.layer.cornerRadius = self.backView.frame.size.height/2;
}

@end
