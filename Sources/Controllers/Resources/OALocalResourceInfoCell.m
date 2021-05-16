//
//  OALocalResourceInfoCell.m
//  OsmAnd
//
//  Created by Alexey on 2/8/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OALocalResourceInfoCell.h"

@implementation OALocalResourceInfoCell

+ (NSString *) getCellIdentifier
{
    return @"OALocalResourceInfoCell";
}

- (void)awakeFromNib
{
    self.leftLabelView.textAlignment = [self isDirectionRTL] ? NSTextAlignmentRight : NSTextAlignmentLeft;
    self.rightLabelView.textAlignment = [self isDirectionRTL] ? NSTextAlignmentLeft : NSTextAlignmentRight;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
