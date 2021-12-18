//
//  OASegmentSliderTableViewCell.m
//  OsmAnd
//
//  Created by igor on 03.03.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OASegmentSliderTableViewCell.h"
#import "OAColors.h"
#import "OAUtilities.h"

#define kMarkTag 1000
const CGFloat kMarkHeight = 16.0;
const CGFloat kMarkWidth = 2.0;

@implementation OASegmentSliderTableViewCell
{
    NSMutableArray<UIView *> *_markViews;
    UIImpactFeedbackGenerator *_feedbackGenerator;
    NSInteger _selectingMark;
}

- (void) awakeFromNib
{
    [super awakeFromNib];
    self.sliderView.minimumTrackTintColor = UIColorFromRGB(color_menu_button);
    self.sliderView.maximumTrackTintColor = UIColorFromRGB(color_slider_gray);

    if ([self isDirectionRTL])
    {
        self.topRightLabel.textAlignment = NSTextAlignmentLeft;
        self.bottomRightLabel.textAlignment = NSTextAlignmentLeft;
    }
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

- (void) setSelectedMark:(NSInteger)selectedMark
{
    _selectedMark = selectedMark;
    _selectingMark = selectedMark;
    self.sliderView.value = (CGFloat)selectedMark / (_numberOfMarks - 1);
    [self paintMarks];
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
    CGFloat sliderViewWidth = self.frame.size.width - self.sliderView.frame.origin.x * 2 - OAUtilities.getLeftMargin;
    CGFloat sliderViewHeight = self.sliderView.frame.size.height;
    CGRect sliderViewBounds = CGRectMake(0, 0, sliderViewWidth, sliderViewHeight);
    CGRect trackRect = [self.sliderView trackRectForBounds:sliderViewBounds];
    CGFloat trackWidth = trackRect.size.width;
    CGFloat markWidth = trackRect.size.height;

    CGFloat inset = (sliderViewWidth - trackRect.size.width) / 2;
    
    CGFloat x = inset;
    CGFloat y = trackRect.origin.y + trackRect.size.height / 2 - kMarkHeight / 2;

    for (int i = 0; i < _numberOfMarks; i++)
    {
        UIView *mark = [self getMarkView:i];
        if (i == 0)
            mark.frame = CGRectMake(x, y, markWidth, kMarkHeight);
        else
            mark.frame = CGRectMake(x - markWidth, y, markWidth, kMarkHeight);
        
        x += trackWidth / segments;
    }
}

- (void) paintMarks
{
    BOOL isRTL = [self isDirectionRTL];
    CGFloat value = self.sliderView.value;
    for (int i = 0; i < _markViews.count; i++)
    {
        CGFloat step = (CGFloat) i / (_markViews.count - 1);
        BOOL filled = (value > (isRTL ? 1 - step : step)) || (value == (isRTL ? 1 - step : step));
        _markViews[i].backgroundColor = UIColorFromRGB(filled ? color_menu_button : color_slider_gray);
    }
}

- (void) generateFeedback
{
    if (!_feedbackGenerator)
    {
        // Instantiate a new generator.
        _feedbackGenerator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        // Prepare the generator when the gesture begins.
        [_feedbackGenerator prepare];
    }
    // Trigger selection feedback.
    [_feedbackGenerator impactOccurred];
    // Keep the generator in a prepared state.
    [_feedbackGenerator prepare];
}

- (IBAction) sliderValueChanged:(UISlider *)sender
{
    NSInteger selectingMark = _selectingMark;
    CGFloat selectingMarkValue = (CGFloat)selectingMark / (_numberOfMarks - 1);
    CGFloat step = 1.0 / (_markViews.count - 1);
    if (ABS(sender.value - selectingMarkValue) >= step)
    {
        _selectingMark += sender.value - selectingMarkValue > 0 ? 1 : -1;
        [self generateFeedback];
    }
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
 
    _selectedMark = [self getIndex];
    if (_selectedMark != _selectingMark)
        [self generateFeedback];

    _selectingMark = _selectedMark;
    
    // Release the current generator.
    _feedbackGenerator = nil;

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

- (void)showLabels:(BOOL)topLeft topRight:(BOOL)topRight bottomLeft:(BOOL)bottomLeft bottomRight:(BOOL)bottomRight;
{
    self.topLeftLabel.hidden = !topLeft;
    self.topRightLabel.hidden = !topRight;
    self.bottomLeftLabel.hidden = !bottomLeft;
    self.bottomRightLabel.hidden = !bottomRight;

    UIFont *bottomLabelsFont = [UIFont systemFontOfSize:topLeft || topRight ? 15. : 17.];
    self.bottomLeftLabel.font = bottomLabelsFont;
    self.bottomRightLabel.font = bottomLabelsFont;
}

- (void)updateConstraints
{
    BOOL hasLeftTopLabel = !self.topLeftLabel.hidden;
    BOOL hasRightTopLabel = !self.topRightLabel.hidden;
    BOOL hasTopLabels = hasLeftTopLabel || hasRightTopLabel;

    BOOL hasLeftBottomLabel = !self.bottomLeftLabel.hidden;
    BOOL hasRightBottomLabel = !self.bottomRightLabel.hidden;
    BOOL hasBottomLabels = hasLeftBottomLabel || hasRightBottomLabel;

    self.sliderLabelsTopConstraint.active = hasTopLabels;
    self.sliderNoLabelsTopConstraint.active = !hasTopLabels;

    self.sliderLabelsBottomConstraint.constant = hasTopLabels ? 7. : 13.;
    self.sliderLabelsBottomConstraint.active = hasBottomLabels;
    self.sliderNoLabelsBottomConstraint.active = !hasBottomLabels;

    [super updateConstraints];
}

- (BOOL)needsUpdateConstraints
{
    BOOL res = [super needsUpdateConstraints];
    if (!res)
    {
        BOOL hasLeftTopLabel = !self.topLeftLabel.hidden;
        BOOL hasRightTopLabel = !self.topRightLabel.hidden;
        BOOL hasTopLabels = hasLeftTopLabel || hasRightTopLabel;

        BOOL hasLeftBottomLabel = !self.bottomLeftLabel.hidden;
        BOOL hasRightBottomLabel = !self.bottomRightLabel.hidden;
        BOOL hasBottomLabels = hasLeftBottomLabel || hasRightBottomLabel;

        res = res || self.sliderLabelsTopConstraint.active != hasTopLabels;
        res = res || self.sliderNoLabelsTopConstraint.active != !hasTopLabels;

        res = res || self.sliderLabelsBottomConstraint.constant != (hasTopLabels ? 7. : 13.);
        res = res || self.sliderLabelsBottomConstraint.active != hasBottomLabels;
        res = res || self.sliderNoLabelsBottomConstraint.active != !hasBottomLabels;
    }
    return res;
}

@end
