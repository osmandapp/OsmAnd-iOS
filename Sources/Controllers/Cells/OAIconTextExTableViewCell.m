//
//  OAIconTextExTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 09/05/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAIconTextExTableViewCell.h"

@implementation OAIconTextExTableViewCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    self.arrowIconView.image = self.arrowIconView.image.imageFlippedForRightToLeftLayoutDirection;
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
