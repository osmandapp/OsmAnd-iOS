//
//  OAPoiCollectionViewCell.h
//  OsmAnd Maps
//
//  Created by nnngrach on 10.03.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OABaseCollectionCell.h"

@interface OAPoiCollectionViewCell : OABaseCollectionCell

@property (weak, nonatomic) IBOutlet UIView *backView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UIView *iconView;

@end
