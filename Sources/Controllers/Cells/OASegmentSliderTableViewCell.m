//
//  OASegmentSliderTableViewCell.m
//  OsmAnd
//
//  Created by igor on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASegmentSliderTableViewCell.h"
#import "OAColors.h"

#define kMarkTag 100

@implementation OASegmentSliderTableViewCell
{
    NSMutableArray<UIView*> *_markViews;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}


- (void) layoutSubviews
{
    [super layoutSubviews];
    if (_numberOfMarks > 1)
        [self setupSeparators:_numberOfMarks];
}

- (void) setupSeparators:(NSInteger)marks
{
    _markViews = [NSMutableArray new];
    CGFloat segments = marks - 1;
    CGFloat markHeight = 16;
    CGFloat markWidth = 2;
    CGFloat sliderViewWidth = self.frame.size.width - 2 * 14 - OAUtilities.getLeftMargin;
    CGFloat sliderViewHeight = self.sliderView.frame.size.height;
    CGRect sliderViewBounds = CGRectMake(0, 0, sliderViewWidth, sliderViewHeight);
    CGRect trackRect = [self.sliderView trackRectForBounds:sliderViewBounds];
    CGFloat trackWidth = trackRect.size.width - markWidth;
    
    CGFloat inset = (sliderViewWidth - trackRect.size.width) / 2;
    
    CGFloat x = inset;
    CGFloat y = trackRect.origin.y + trackRect.size.height / 2 - markHeight / 2;
    NSArray *viewsToRemove = [self.sliderView subviews];
    for (UIView *v in viewsToRemove)
    {
        if (v.tag == kMarkTag)
            [v removeFromSuperview];
    }
    
    for (int i = 0; i < marks; i++)
    {
        UIView *mark = [[UIView alloc] initWithFrame:CGRectMake(x, y, markWidth, markHeight)];
        [mark.layer setCornerRadius:markWidth/2.0];
        x += trackWidth / segments;
        mark.tag = kMarkTag;
        [self.sliderView addSubview:mark];
        [self.sliderView sendSubviewToBack:mark];
        [_markViews addObject:mark];
    }
    [self paintMarks];
}

- (void) paintMarks
{
    for (int i = 0; i < _markViews.count; i++)
    {
        CGFloat step = (CGFloat)i / (_markViews.count - 1);
        if (_sliderView.value > step)
            _markViews[i].backgroundColor = UIColorFromRGB(color_menu_button);
        else
            _markViews[i].backgroundColor = UIColorFromRGB(color_slider_gray);
    }
    
    if (self.sliderView.value == 1)
        [_markViews lastObject].backgroundColor = [UIColor clearColor];
    else if (self.sliderView.value == 0)
        [_markViews firstObject].backgroundColor = [UIColor clearColor];
}

- (IBAction)sliderValueChanged:(id)sender
{
    UISlider *slider = sender;
    if (slider)
        [self paintMarks];
}

- (IBAction)sliderDidEndEditing:(UISlider *)sender
{
    CGFloat step = 1.0 / (_markViews.count - 1);
    int nextMark = 0;
    for (int i = 0; i < _markViews.count; i++)
    {
        if (i * step > sender.value)
        {
            nextMark = i;
            break;
        }
    }
    if ((nextMark*step - sender.value) < (sender.value - (nextMark - 1) * step))
        [sender setValue:nextMark * step];
    else
        [sender setValue:(nextMark - 1) * step];
    
    if (self.sliderView.value == 1)
        [_markViews lastObject].backgroundColor = [UIColor clearColor];
    else if (self.sliderView.value == 0)
        [_markViews firstObject].backgroundColor = [UIColor clearColor];
}

@end
