//
//  OAWaypointCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 20/03/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OABaseMGSwipeCell.h"

@interface OAWaypointCell : OABaseMGSwipeCell

@property (weak, nonatomic) IBOutlet UIImageView *leftIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UIButton *moreButton;
@property (weak, nonatomic) IBOutlet UIButton *removeButton;

@end
