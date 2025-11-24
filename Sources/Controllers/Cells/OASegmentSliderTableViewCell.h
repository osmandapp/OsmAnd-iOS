//
//  OASegmentSliderTableViewCell.h
//  OsmAnd
//
//  Created by igor on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OASegmentedSlider.h"

@class OASegmentedSlider;

@interface OASegmentSliderTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *topLeftLabel;
@property (weak, nonatomic) IBOutlet UILabel *topRightLabel;
@property (weak, nonatomic) IBOutlet OASegmentedSlider *sliderView;
@property (weak, nonatomic) IBOutlet UILabel *bottomLeftLabel;
@property (weak, nonatomic) IBOutlet UILabel *bottomRightLabel;

@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sliderLabelsTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sliderNoLabelsTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sliderLabelsBottomConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *sliderNoLabelsBottomConstraint;

- (void)showLabels:(BOOL)topLeft topRight:(BOOL)topRight bottomLeft:(BOOL)bottomLeft bottomRight:(BOOL)bottomRight;

@end

