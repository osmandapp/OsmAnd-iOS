//
//  OASettingsCheckmarkCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 18.04.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OASettingsCheckmarkCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *checkmarkImageView;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
