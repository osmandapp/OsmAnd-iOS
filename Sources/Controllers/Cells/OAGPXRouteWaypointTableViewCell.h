//
//  OAGPXRouteWaypointTableViewCell.h
//  OsmAnd
//
//  Created by Alexey Kulish on 09/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OABaseMGSwipeCell.h"

@interface OAGPXRouteWaypointTableViewCell : OABaseMGSwipeCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *descLabel;
@property (weak, nonatomic) IBOutlet UIImageView *leftIcon;
@property (weak, nonatomic) IBOutlet UIButton *rightButton;

@property (weak, nonatomic) IBOutlet UIImageView *vDotsTop;
@property (weak, nonatomic) IBOutlet UIImageView *vDotsBottom;

@property (weak, nonatomic) IBOutlet UIImageView *descIcon;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *vDotsTopHeightHidden;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *vDostTopHeightVisible;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *vDotsBottomHeightVisible;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *vDotsBottomHeightHidden;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descIconWidthHidden;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *descIconWidthVisible;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleTrailingButtonHidden;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *titleTrailingButtonVisible;

@property (assign, nonatomic) BOOL topVDotsVisible;
@property (assign, nonatomic) BOOL bottomVDotsVisible;

- (void)hideVDots:(BOOL)hide;
- (void)hideDescIcon:(BOOL)hide;
- (void)hideRightButton:(BOOL)hide;

@end
