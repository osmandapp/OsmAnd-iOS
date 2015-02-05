//
//  OAPointTableViewCell.m
//  OsmAnd
//
//  Created by Anton Rogachevskiy on 08.11.14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAPointTableViewCell.h"

@implementation OAPointTableViewCell

- (void)awakeFromNib {

    self.colorView.layer.cornerRadius = 10;
    self.colorView.layer.masksToBounds = YES;

}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    
    UIColor *prevColor = self.colorView.backgroundColor;
    
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
    self.colorView.backgroundColor = prevColor;
}




@end
