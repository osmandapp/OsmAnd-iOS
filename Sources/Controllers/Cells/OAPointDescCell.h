//
//  OAPointDescCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 22/03/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAPOI.h"

@interface OAPointDescCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *titleIcon;
@property (weak, nonatomic) IBOutlet UILabel *titleView;
@property (weak, nonatomic) IBOutlet UILabel *descView;
@property (weak, nonatomic) IBOutlet UILabel *openingHoursView;
@property (weak, nonatomic) IBOutlet UIImageView *directionImageView;
@property (weak, nonatomic) IBOutlet UILabel *distanceView;
// the address of a poi on a line of its own under the distance; empty, it takes no height
@property (weak, nonatomic) IBOutlet UILabel *addressView;
@property (weak, nonatomic) IBOutlet UIView *cellView;
@property (weak, nonatomic) IBOutlet UIImageView *timeIcon;
@property (nonatomic) IBOutlet NSLayoutConstraint *distanceViewLeadingOutlet;

- (void) updateOpeningTimeInfo:(OAPOI *)poi;

@end
