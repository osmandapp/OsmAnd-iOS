//
//  OAPoiCollectionViewCell.m
//  OsmAnd Maps
//
//  Created by nnngrach on 10.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAPoiCollectionViewCell.h"

@implementation OAPoiCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.iconView.layer.cornerRadius = self.iconView.frame.size.height/2;
    self.backView.layer.cornerRadius = self.backView.frame.size.height/2;
}

@end
