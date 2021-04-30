//
//  OADeleteButtonTableViewCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 23.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OADeleteButtonTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconHeightPrimary;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *iconWidthPrimary;

@end
