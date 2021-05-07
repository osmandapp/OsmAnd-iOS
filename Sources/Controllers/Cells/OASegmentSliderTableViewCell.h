//
//  OASegmentSliderTableViewCell.h
//  OsmAnd
//
//  Created by igor on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OASegmentSliderTableViewCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;
@property (weak, nonatomic) IBOutlet UISlider *sliderView;

@property (nonatomic) NSInteger numberOfMarks;
@property (nonatomic) NSInteger selectedMark;

@end

