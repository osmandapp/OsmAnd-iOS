//
//  OANoImagesCell.m
//  OsmAnd
//
//  Created by Paul on 25/05/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OANoImagesCell.h"

@implementation OANoImagesCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.addPhotosButton.layer.masksToBounds = YES;
    self.addPhotosButton.layer.cornerRadius = 9.0;
}

@end
