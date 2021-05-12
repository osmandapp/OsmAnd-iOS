//
//  OASliderWithValuesCell.h
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OABaseCell.h"

@interface OASliderWithValuesCell : OABaseCell

@property (weak, nonatomic) IBOutlet UISlider *sliderView;
@property (weak, nonatomic) IBOutlet UILabel *leftValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightValueLabel;

@end
