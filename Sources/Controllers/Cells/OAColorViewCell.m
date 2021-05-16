//
//  OAColorViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 01/06/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAColorViewCell.h"

@implementation OAColorViewCell

+ (NSString *) getCellIdentifier
{
    return @"OAColorViewCell";
}

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    
    if (self.isDirectionRTL)
    {
        _descriptionView.textAlignment = NSTextAlignmentLeft;
        _iconView.image = _iconView.image.imageFlippedForRightToLeftLayoutDirection;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
