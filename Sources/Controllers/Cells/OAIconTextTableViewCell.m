//
//  OAIconTextTableViewCell.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 08.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAIconTextTableViewCell.h"

@implementation OAIconTextTableViewCell

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

- (void) showImage:(BOOL)show
{
    self.iconView.hidden = !show;
}

@end
