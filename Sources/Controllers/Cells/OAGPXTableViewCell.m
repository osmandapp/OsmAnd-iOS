//
//  OAGPXTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 16/02/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXTableViewCell.h"

@implementation OAGPXTableViewCell

+ (NSString *) getCellIdentifier
{
    return @"OAGPXTableViewCell";
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    if ([self isDirectionRTL])
        _iconView.image = _iconView.image.imageFlippedForRightToLeftLayoutDirection;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
