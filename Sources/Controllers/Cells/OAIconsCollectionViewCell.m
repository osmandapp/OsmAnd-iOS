//
//  OAIconsCollectionViewCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAIconsCollectionViewCell.h"

@implementation OAIconsCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.iconView.layer.cornerRadius = self.iconView.frame.size.height/2;
    self.backView.layer.cornerRadius = self.backView.frame.size.height/2;
}

@end
