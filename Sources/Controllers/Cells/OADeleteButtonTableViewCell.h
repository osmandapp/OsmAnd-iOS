//
//  OADeleteButtonTableViewCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 23.06.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OADeleteButtonTableViewCell : OABaseCell

@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;

@end
