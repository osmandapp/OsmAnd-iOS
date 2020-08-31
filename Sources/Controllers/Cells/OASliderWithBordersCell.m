//
//  OASliderWithBordersCell.m
//  OsmAnd Maps
//
//  Created by Anna Bibyk on 29.08.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASliderWithBordersCell.h"

#import "OAColors.h"

#define kMarkTag 1000
#define kNumberOfMarks 2

const CGFloat kMarkHeight = 14.0;
const CGFloat kMarkWidth = 2.0;

@implementation OASliderWithBordersCell
{
    NSMutableArray<UIView *> *_markViews;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    [self createMarks];
    self.sliderView.minimumTrackTintColor = UIColorFromRGB(color_menu_button);
    self.sliderView.maximumTrackTintColor = UIColorFromRGB(color_slider_gray);
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    [self layoutMarks];
    [self paintMarks];
}

- (void) createMarks
{
    for (UIView *v in self.sliderView.subviews)
        if (v.tag >= kMarkTag)
            [v removeFromSuperview];

    _markViews = [NSMutableArray new];

    for (int i = 0; i < kNumberOfMarks; i++)
    {
        UIView *mark = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kMarkWidth, kMarkHeight)];
        [mark.layer setCornerRadius:kMarkWidth / 2.0];
        mark.tag = kMarkTag + i;
        [self.sliderView addSubview:mark];
        [self.sliderView sendSubviewToBack:mark];
        [_markViews addObject:mark];
    }
    [self layoutMarks];
    [self paintMarks];
}

- (UIView *) getMarkView:(NSInteger)markIndex
{
    for (UIView *v in self.sliderView.subviews)
        if (v.tag == kMarkTag + markIndex)
            return v;
    return nil;
}

- (void) layoutMarks
{
    CGFloat sliderViewWidth = self.frame.size.width - 2 * 14 - OAUtilities.getLeftMargin * 2;
    CGFloat sliderViewHeight = self.sliderView.frame.size.height;
    CGRect sliderViewBounds = CGRectMake(0, 0, sliderViewWidth, sliderViewHeight);
    CGRect trackRect = [self.sliderView trackRectForBounds:sliderViewBounds];
    CGFloat trackWidth = trackRect.size.width;
    CGFloat markWidth = trackRect.size.height;
    
    CGFloat x = (sliderViewWidth - trackRect.size.width) / 2;
    CGFloat y = trackRect.origin.y + trackRect.size.height / 2 - kMarkHeight / 2;
    
    for (int i = 0; i < kNumberOfMarks; i++)
    {
        UIView *mark = [self getMarkView:i];
        if (i == 0)
            mark.frame = CGRectMake(x, y, markWidth, kMarkHeight);
        else
            mark.frame = CGRectMake(x - markWidth, y, markWidth, kMarkHeight);
        x += trackWidth;
    }
}

- (void) paintMarks
{
    CGFloat value = self.sliderView.value;
    CGFloat minValue = self.sliderView.minimumValue;
    CGFloat maxValue = self.sliderView.maximumValue;
    
    _markViews[0].backgroundColor = UIColorFromRGB(value >= minValue ? color_menu_button : color_slider_gray);
    _markViews[1].backgroundColor = UIColorFromRGB(value == maxValue ? color_menu_button : color_slider_gray);
}

@end
