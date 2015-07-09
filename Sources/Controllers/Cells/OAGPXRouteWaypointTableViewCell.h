//
//  OAGPXRouteWaypointTableViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 09/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGSwipeTableCell.h"

@interface OAGPXRouteWaypointTableViewCell : MGSwipeTableCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UIImageView *leftIcon;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@property (weak, nonatomic) IBOutlet UIImageView *vDotsTop;
@property (weak, nonatomic) IBOutlet UIImageView *vDotsBottom;

@property (weak, nonatomic) IBOutlet UIImageView *descIcon;

@property (assign, nonatomic) BOOL topVDotsVisible;
@property (assign, nonatomic) BOOL bottomVDotsVisible;

- (void)hideVDots:(BOOL)hide;
- (void)hideDescIcon:(BOOL)hide;
- (void)hideRightButton:(BOOL)hide;

@end
