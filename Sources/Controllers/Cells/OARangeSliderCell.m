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

+ (NSString *) getCellIdentifier
{
    return @"OARangeSliderCell";
}

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
    if ([self.rangeSlider isDirectionRTL])
        self.rangeSlider.transform = CGAffineTransformMakeScale(-1.0, 1.0);
    self.rangeSlider.handleColor = UIColorFromRGB(color_menu_button);
    self.rangeSlider.lineBorderColor = UIColorFromRGB(color_slider_gray);
    UIImage *handle = [UIImage imageNamed:@"ic_control_knob"];
    [self.rangeSlider setHandleImage:handle];
    self.rangeSlider.handleDiameter = 30.;
    self.rangeSlider.handleBorderColor = UIColorFromRGB(color_slider_gray);
    self.rangeSlider.selectedHandleDiameterMultiplier = 1.;
}

@end
