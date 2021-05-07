//
//  OARangeSliderCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 17.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"
#import "OARangeSlider.h"

@interface OARangeSliderCell : OABaseCell

@property (weak, nonatomic) IBOutlet UILabel *minLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxLabel;
@property (weak, nonatomic) IBOutlet UILabel *minValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxValueLabel;
@property (weak, nonatomic) IBOutlet OARangeSlider *rangeSlider;

@end
