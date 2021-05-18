//
//  OAGPXRecTableViewCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 28/04/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OAGPXRecTableViewCell.h"

@implementation OAGPXRecTableViewCell

- (void)awakeFromNib {
    // Initialization code
    [super awakeFromNib];
    self.btnSaveGpx.enabled = NO;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)startStopRecPressed:(id)sender
{
    
}

- (IBAction)saveGpxPressed:(id)sender
{
    
}

@end
