//
//  OAHeaderCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 28/05/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAHeaderCell.h"

@implementation OAHeaderCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void) setImage:(UIImage *)image tint:(BOOL)tint
{
    if (image && tint)
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
    self.imageView.image = image;
}

@end
