//
//  OADirectionTableViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 13/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "OABaseMGSwipeCell.h"

@interface OADirectionTableViewCell : OABaseMGSwipeCell

@property (weak, nonatomic) IBOutlet UIImageView *leftIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *descIcon;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;

@end
