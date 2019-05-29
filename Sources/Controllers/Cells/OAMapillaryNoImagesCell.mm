//
//  OAMapillaryNoImagesCell.m
//  OsmAnd
//
//  Created by Paul on 25/05/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAMapillaryNoImagesCell.h"

@implementation OAMapillaryNoImagesCell
{
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    // Initialization code
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    self.addPhotosButton.layer.cornerRadius = 9.0;
}

@end
