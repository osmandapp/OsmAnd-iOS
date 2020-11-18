//
//  OARangeSliderCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 17.11.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OARangeSliderCell.h"
#import "OAColors.h"

@implementation OARangeSliderCell

- (void) awakeFromNib
{
    [super awakeFromNib];
    
    [self setupSliderView];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) setupSliderView
{
    self.rangeSlider.handleColor = UIColorFromRGB(color_menu_button);
    self.rangeSlider.lineBorderColor = UIColorFromRGB(color_slider_gray);
    self.rangeSlider.handleDiameter = 28.;
    self.rangeSlider.handleBorderWidth = 0.5;
    self.rangeSlider.handleColor = UIColor.whiteColor;
    self.rangeSlider.handleBorderColor = UIColorFromRGB(color_slider_gray);
    self.rangeSlider.selectedHandleDiameterMultiplier = 1.;
}

@end
