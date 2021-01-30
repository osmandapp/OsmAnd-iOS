//
//  OARangeSliderCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 17.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OARangeSlider.h"

@interface OARangeSliderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *minLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxLabel;
@property (weak, nonatomic) IBOutlet UILabel *minValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *maxValueLabel;
@property (weak, nonatomic) IBOutlet OARangeSlider *rangeSlider;

@end
