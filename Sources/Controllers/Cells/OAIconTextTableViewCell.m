//
//  OAIconTextTableViewCell.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 08.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAIconTextTableViewCell.h"

@implementation OAIconTextTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

-(void)showImage:(BOOL)show {
    if (show) {
        self.imageWidthConstraint.constant = 50;
    } else {
        self.imageWidthConstraint.constant = 10;
    }
}

@end
