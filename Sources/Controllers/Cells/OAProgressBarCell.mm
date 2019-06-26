//
//  OAProgressBarCell.m
//  OsmAnd
//
//  Created by Paul on 26/06/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OAProgressBarCell.h"

@implementation OAProgressBarCell

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
    CGFloat h = self.bounds.size.height;
    
    self.progressBar.frame = CGRectMake(16.0, h / 2 + 1, w - 32, 2.0);
}

@end
