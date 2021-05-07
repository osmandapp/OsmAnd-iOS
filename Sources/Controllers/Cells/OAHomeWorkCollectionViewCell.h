//
//  OAHomeWorkCollectionViewCell.h
//  OsmAnd
//
//  Created by Paul on 25/15/2019.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OABaseCollectionCell.h"

@interface OAHomeWorkCollectionViewCell : OABaseCollectionCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descrLabel;


@end
