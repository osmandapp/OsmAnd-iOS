//
//  OATargetPointViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 12/12/2016.
//  Copyright © 2016 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OATargetPoint;

@interface OATargetPointViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet OAColoredImageView *iconView;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *descriptionView;

@property (nonatomic) OATargetPoint *targetPoint;

@end
