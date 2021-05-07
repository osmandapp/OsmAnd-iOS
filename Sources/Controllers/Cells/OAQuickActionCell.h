//
//  OAQuickActionCell.h
//  OsmAnd
//
//  Created by Paul on 03/08/2019.
//  Copyright © 2019 OsmAnd. All rights reserved.
//

#import "OABaseCollectionCell.h"

@interface OAQuickActionCell : OABaseCollectionCell


@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *actionTitleView;

@end
