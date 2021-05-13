//
//  OASettingsTitleTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 26/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OASettingsTitleTableViewCell.h"
#import "OAUtilities.h"

@implementation OASettingsTitleTableViewCell

+ (NSString *) getCellIdentifier
{
    return @"OASettingsTitleTableViewCell";
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.iconView.image = self.iconView.image.imageFlippedForRightToLeftLayoutDirection;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

@end
