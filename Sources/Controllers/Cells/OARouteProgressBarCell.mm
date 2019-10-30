//
//  OARouteProgressBarCell.m
//  OsmAnd
//
//  Created by Paul on 30/10/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OARouteProgressBarCell.h"

@implementation OARouteProgressBarCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    CGFloat w = self.bounds.size.width;
    
    self.progressBar.frame = CGRectMake(0.0, 0.0, w, 2.0);
}

@end
