//
//  OATargetPointViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 12/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@class OATargetPoint;

@interface OATargetPointViewCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;

@property (nonatomic) OATargetPoint *targetPoint;

@end
