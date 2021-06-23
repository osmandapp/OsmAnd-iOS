//
//  OADirectionTableViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 13/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import "MGSwipeTableCell.h"

@interface OADirectionTableViewCell : MGSwipeTableCell

@property (weak, nonatomic) IBOutlet UIImageView *leftIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *descIcon;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleLabelTopConstraint;

- (void) setTitle:(NSString *)title andDescription:(NSString *)description;

@end
