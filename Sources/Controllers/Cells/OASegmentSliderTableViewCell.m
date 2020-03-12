//
//  OASegmentSliderTableViewCell.m
//  OsmAnd
//
//  Created by igor on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASegmentSliderTableViewCell.h"
#import "OAColors.h"

@implementation OASegmentSliderTableViewCell

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [_separatorView0.layer setCornerRadius:_separatorView0.frame.size.width/2.0];
    [_separatorView1.layer setCornerRadius:_separatorView1.frame.size.width/2.0];
    [_separatorView2.layer setCornerRadius:_separatorView2.frame.size.width/2.0];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

}

- (void) setupSeparators
{
    _separatorView0.backgroundColor = _sliderView.value > 0 ? UIColorFromRGB(color_menu_button) : UIColorFromRGB(color_slider_gray);
    _separatorView1.backgroundColor = _sliderView.value > 0.5 ? UIColorFromRGB(color_menu_button) : UIColorFromRGB(color_slider_gray);
    _separatorView2.backgroundColor = _sliderView.value == 1 ? UIColorFromRGB(color_menu_button) : UIColorFromRGB(color_slider_gray);
}

- (IBAction)sliderValueChanged:(id)sender
{
    UISlider *slider = sender;
    if (slider)
    {
        [self setupSeparators];
    }
}

- (IBAction)sliderDidEndEditing:(UISlider *)sender
{
    if (sender.value < 0.25)
    {
        [sender setValue:0.0];
        _separatorView0.backgroundColor = UIColorFromRGB(color_slider_gray);
    }
    else if (sender.value < 0.75)
    {
        [sender setValue:0.5];
    }
    else
    {
        [sender setValue:1];
        _separatorView2.backgroundColor = UIColorFromRGB(color_menu_button);
    }
}

@end
