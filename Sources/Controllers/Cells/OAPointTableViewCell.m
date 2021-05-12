//
//  OAPointTableViewCell.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 08.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAPointTableViewCell.h"

@implementation OAPointTableViewCell

+ (NSString *) getCellIdentifier
{
    return @"OAPointTableViewCell";
}

- (void) updateConstraints
{
    BOOL hasImage = self.titleIcon.image != nil && !self.titleIcon.hidden;

    self.titleViewMarginWithIcon.active = hasImage;
    self.titleViewMarginNoIcon.active = !hasImage;
    self.imageViewMarginWithIcon.active = hasImage;
    self.imageViewMarginNoIcon.active = !hasImage;
    
    [super updateConstraints];
}

- (BOOL) needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasImage = self.titleIcon.image != nil && !self.titleIcon.hidden;

        res = res || self.titleViewMarginWithIcon.active != hasImage;
        res = res || self.titleViewMarginNoIcon.active != !hasImage;
        res = res || self.imageViewMarginWithIcon.active != hasImage;
        res = res || self.imageViewMarginNoIcon.active != !hasImage;
    }
    return res;
}


- (void)awakeFromNib {
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
