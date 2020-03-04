//
//  OASegmentSliderTableViewCell.m
//  OsmAnd
//
//  Created by igor on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASegmentSliderTableViewCell.h"

@implementation OASegmentSliderTableViewCell

UIColor *blueColor;// = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
UIColor *greyColor;// = [UIColor colorWithRed:120.0/255.0 green:120.0/255.0 blue:128.0/255.0 alpha:0.2];

- (void)awakeFromNib
{
    [super awakeFromNib];
    blueColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0];
    greyColor = [UIColor colorWithRed:120.0/255.0 green:120.0/255.0 blue:128.0/255.0 alpha:0.2];
    _separatorView0.backgroundColor = _sliderView.value > 0 ? blueColor : greyColor;
    _separatorView1.backgroundColor = _sliderView.value > 0.5 ? blueColor : greyColor;
    _separatorView2.backgroundColor = _sliderView.value == 1 ? blueColor : greyColor;
    [_separatorView0.layer setCornerRadius:_separatorView0.frame.size.width/2.0];
    [_separatorView1.layer setCornerRadius:_separatorView1.frame.size.width/2.0];
    [_separatorView2.layer setCornerRadius:_separatorView2.frame.size.width/2.0];
    
//    NSInteger ticksCount = 3;
//    CGFloat tickWidth = 2.0;
//    CGFloat tickHeight = 16.0;
//    CGFloat segmentWidth = _sliderView.frame.size.width / (ticksCount - 1);
//    CGFloat xPadding = 0;
//
//    for (int i = 1; i <= ticksCount; i++)
//    {
//        UIView *tick = [[UIView alloc] init];//WithFrame:CGRectMake(xPos, _segmentView.frame.size.height/2 - tickHeight/2, tickWidth, tickHeight)];
//        [_sliderView insertSubview:tick belowSubview:self];
//        tick.backgroundColor = _sliderView.minimumTrackTintColor;// [UIColor colorWithRed:255 green:0 blue:0 alpha:1];
//        tick.translatesAutoresizingMaskIntoConstraints = false;
//        [tick.widthAnchor constraintEqualToConstant:tickWidth].active = YES;
//        [tick.heightAnchor constraintEqualToConstant:tickHeight].active = YES;
//        [tick.leadingAnchor constraintEqualToAnchor:_sliderView.leadingAnchor constant:xPadding].active = YES;
//        [tick.centerYAnchor constraintEqualToAnchor:_sliderView.centerYAnchor].active = YES;
//        [tick.layer setCornerRadius:tickWidth/2.0];
//        //           tick.layer.shadowColor = [[UIColor whiteColor] CGColor];
//        //           tick.layer.shadowOffset = CGSizeMake(0.0f, 1.0f);
//        //           tick.layer.shadowOpacity = 1.0f;
//        //           tick.layer.shadowRadius = 0.0f;
//
//        xPadding += segmentWidth;
//    }
    _sliderView.backgroundColor = [UIColor clearColor];
//   // [_sliderView insertSubview:tickview belowSubview:self];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

}

- (IBAction)sliderValueChanged:(id)sender
{
    UISlider *slider = sender;
    if (slider)
    {
        _separatorView0.backgroundColor = slider.value > 0 ? blueColor : greyColor;
        _separatorView1.backgroundColor = slider.value > 0.5 ? blueColor : greyColor;
        _separatorView2.backgroundColor = slider.value == 1 ? blueColor : greyColor;
    }
}
- (IBAction)sliderDidEndEditing:(UISlider *)sender
{
    if (sender.value < 0.25)
    {
        [sender setValue:0.0];
        _separatorView0.backgroundColor = greyColor;
    }
    else if (sender.value < 0.75)
    {
        [sender setValue:0.5];
    }
    else
    {
        [sender setValue:1];
        _separatorView2.backgroundColor = blueColor;
    }
}

@end
