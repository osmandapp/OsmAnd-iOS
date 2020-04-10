//
//  OASegmentSliderTableViewCell.m
//  OsmAnd
//
//  Created by igor on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASegmentSliderTableViewCell.h"
#import "OAColors.h"

#define kMarkTag 1000
const CGFloat kMarkHeight = 16.0;
const CGFloat kMarkWidth = 2.0;

@implementation OASegmentSliderTableViewCell
{
    NSMutableArray<UIView *> *_markViews;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
}

- (void) setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}

- (void) setNumberOfMarks:(NSInteger)numberOfMarks
{
    _numberOfMarks = numberOfMarks;
    [self createMarks:_numberOfMarks];
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    [self layoutMarks];
}

- (void) createMarks:(NSInteger)marks
{
    for (UIView *v in self.sliderView.subviews)
        if (v.tag >= kMarkTag)
            [v removeFromSuperview];

    _markViews = [NSMutableArray new];
    if (marks < 2)
        return;

    for (int i = 0; i < marks; i++)
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
    if (_numberOfMarks < 2)
        return;
    
    CGFloat segments = _numberOfMarks - 1;
    CGFloat sliderViewWidth = self.frame.size.width - 2 * 14 - OAUtilities.getLeftMargin;
    CGFloat sliderViewHeight = self.sliderView.frame.size.height;
    CGRect sliderViewBounds = CGRectMake(0, 0, sliderViewWidth, sliderViewHeight);
    CGRect trackRect = [self.sliderView trackRectForBounds:sliderViewBounds];
    CGFloat trackWidth = trackRect.size.width - kMarkWidth;
    
    CGFloat inset = (sliderViewWidth - trackRect.size.width) / 2;
    
    CGFloat x = inset;
    CGFloat y = trackRect.origin.y + trackRect.size.height / 2 - kMarkHeight / 2;
    
    for (int i = 0; i < _numberOfMarks; i++)
    {
        UIView *mark = [self getMarkView:i];
        mark.frame = CGRectMake(x, y, kMarkWidth, kMarkHeight);
        x += trackWidth / segments;
    }
}

- (void) paintMarks
{
    CGFloat value = self.sliderView.value;
    for (int i = 0; i < _markViews.count; i++)
    {
        CGFloat step = (CGFloat)i / (_markViews.count - 1);
        _markViews[i].backgroundColor = UIColorFromRGB(value > step ? color_menu_button : color_slider_gray);
    }
    
    if (value == 1)
        _markViews.lastObject.backgroundColor = UIColor.clearColor;
    else if (value == 0)
        _markViews.firstObject.backgroundColor = UIColor.clearColor;
}

- (IBAction) sliderValueChanged:(id)sender
{
    [self paintMarks];
}

- (IBAction) sliderDidEndEditing:(UISlider *)sender
{
    CGFloat step = 1.0 / (_markViews.count - 1);
    int nextMark = 0;
    for (int i = 0; i < _markViews.count; i++)
    {
        if (i * step >= sender.value)
        {
            nextMark = i;
            break;
        }
    }
    if ((nextMark * step - sender.value) < (sender.value - (nextMark - 1) * step))
        sender.value = nextMark * step;
    else
        sender.value = (nextMark - 1) * step;
    
    [self paintMarks];
}

- (NSInteger) getIndex
{
    CGFloat value = self.sliderView.value;
    NSInteger marks = _numberOfMarks;
    CGFloat step = 1.0 / (marks - 1);
    int nextMark = 0;
    for (int i = 0; i < marks; i++)
    {
        if (i * step >= value)
        {
            nextMark = i;
            break;
        }
    }
    if ((nextMark * step - value) < (value - (nextMark - 1) * step))
        return nextMark;
    else
        return nextMark - 1;
}

@end
