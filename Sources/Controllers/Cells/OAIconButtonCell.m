//
//  OAIconButtonCell.m
//  OsmAnd
//
//  Created by Alexey Kulish on 27/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OAIconButtonCell.h"

@implementation OAIconButtonCell

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
