//
//  OASegmentedSlider.mm
//  OsmAnd
//
//  Created by Skalii on 07.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OASegmentedSlider.h"
#import "OAColors.h"

#define kMarkTag 1000
#define kAdditionalMarkTag 2000
#define kCurrentMarkTag 999

#define kMarkHeight 16.
#define kCustomMarkHeight 14.
#define kAdditionalMarkHeight 8.
#define kCurrentMarkHeight 30.

#define kMarkWidth 2.

@implementation OASegmentedSlider
{
    NSMutableArray<UIView *> *_markViews;
    UIImpactFeedbackGenerator *_feedbackGenerator;
    NSInteger _selectingMark;
    NSInteger _additionalMarksBetween;
    NSInteger _currentMark;
    BOOL _isCustomSlider;

    UIColor *_customMinimumTrackTintColor;
    UIColor *_customMaximumTrackTintColor;
    UIColor *_customCurrentColor;
    UIView *_currentMarkView;
    UIView *_currentLineView;
    UIView *_notCurrentLineView;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.minimumTrackTintColor = UIColorFromRGB(color_menu_button);
    self.maximumTrackTintColor = UIColorFromRGB(color_slider_gray);

    [self removeTarget:nil action:NULL forControlEvents:UIControlEventValueChanged];
    [self addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(sliderDidEndEditing:) forControlEvents:UIControlEventTouchUpInside];
    [self removeTarget:nil action:NULL forControlEvents:UIControlEventTouchUpOutside];
    [self addTarget:self action:@selector(sliderDidEndEditing:) forControlEvents:UIControlEventTouchUpOutside];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    [self layoutMarks];
}

- (void)setNumberOfMarks:(NSInteger)numberOfMarks
{
    _numberOfMarks = numberOfMarks;
    _additionalMarksBetween = 0;
    [self createMarks:_numberOfMarks];
}

- (void)setNumberOfMarks:(NSInteger)numberOfMarks additionalMarksBetween:(NSInteger)additionalMarksBetween
{
    _numberOfMarks = numberOfMarks;
    _additionalMarksBetween = additionalMarksBetween;
    [self createMarks:numberOfMarks + (numberOfMarks - 1) * additionalMarksBetween];
}

- (void)setCurrentMark:(NSInteger)currentMark
{
    _currentMark = currentMark;
    if (!_currentMarkView || !_currentLineView || !_notCurrentLineView)
    {
        _currentMarkView = [[UIView alloc] initWithFrame:CGRectMake(
                0.,
                0.,
                kMarkWidth,
                kCurrentMarkHeight
        )];
        _currentMarkView.tag = kCurrentMarkTag;
        _currentMarkView.backgroundColor = _customCurrentColor;
        _currentMarkView.layer.cornerRadius = kMarkWidth / 2.;
        [self addSubview:_currentMarkView];
        [self sendSubviewToBack:_currentMarkView];

        _currentLineView = [[UIView alloc] initWithFrame:[self trackRectForBounds:CGRectMake(
                0.,
                0.,
                self.frame.size.width,
                self.frame.size.height
        )]];
        _currentLineView.backgroundColor = _customMinimumTrackTintColor;
        [self addSubview:_currentLineView];
        [self sendSubviewToBack:_currentLineView];

        _notCurrentLineView = [[UIView alloc] initWithFrame:[self trackRectForBounds:CGRectMake(
                0.,
                0.,
                self.frame.size.width,
                self.frame.size.height
        )]];
        _notCurrentLineView.backgroundColor = _customMaximumTrackTintColor;
        [self addSubview:_notCurrentLineView];
        [self sendSubviewToBack:_notCurrentLineView];
    }
}

- (void)setSelectedMark:(NSInteger)selectedMark
{
    _selectedMark = selectedMark;
    _selectingMark = selectedMark;
    self.value = (CGFloat)selectedMark / ([self getMarksCount] - 1);
    [self paintMarks];
}

- (NSInteger)getMarksCount
{
    return _numberOfMarks + (_numberOfMarks - 1) * _additionalMarksBetween;
}

- (void)createMarks:(NSInteger)marks
{
    for (UIView *v in self.subviews)
    {
        if (v.tag >= kMarkTag || v.tag >= kAdditionalMarkTag)
            [v removeFromSuperview];
    }

    _markViews = [NSMutableArray new];
    if (marks < 2)
        return;

    NSInteger ii = 1;
    NSInteger additionalStep = 0;
    for (int i = 0; i < marks; i++)
    {
        UIView *mark = [[UIView alloc] initWithFrame:CGRectMake(
                0.,
                0.,
                kMarkWidth,
                _isCustomSlider ? kCustomMarkHeight : kMarkHeight
        )];

        if (_isCustomSlider)
            mark.backgroundColor = _customMinimumTrackTintColor;

        if (_isCustomSlider && ii == i)
        {
            mark.tag = kAdditionalMarkTag + i;
            ii++;
            if (++additionalStep == _additionalMarksBetween)
            {
                additionalStep = 0;
                ii++;
            }
        }
        else
        {
            mark.tag = kMarkTag + i;
        }

        [mark.layer setCornerRadius:kMarkWidth / 2.];
        [self addSubview:mark];
        [self sendSubviewToBack:mark];
        [_markViews addObject:mark];
    }

    [self layoutMarks];
    [self paintMarks];
}

- (UIView *)getMarkView:(NSInteger)markIndex
{
    for (UIView *v in self.subviews)
    {
        if ((v.tag == kMarkTag + markIndex) || (v.tag == kAdditionalMarkTag + markIndex))
            return v;
    }

    return nil;
}

- (void)layoutMarks
{
    if (_numberOfMarks < 2)
        return;

    CGFloat segments = [self getMarksCount] - 1;
    CGFloat sliderViewWidth = self.frame.size.width;// - self.frame.origin.x * 2 - OAUtilities.getLeftMargin;
    CGFloat sliderViewHeight = self.frame.size.height;
    CGRect sliderViewBounds = CGRectMake(0., 0., sliderViewWidth, sliderViewHeight);
    CGRect trackRect = [self trackRectForBounds:sliderViewBounds];
    CGFloat trackWidth = trackRect.size.width;
    CGFloat markWidth = trackRect.size.height;

    CGFloat inset = (sliderViewWidth - trackRect.size.width) / 2;

    CGFloat markHeight = _isCustomSlider ? kCustomMarkHeight + 1. : kMarkHeight;
    CGFloat x = inset;
    CGFloat y = _isCustomSlider
            ? (trackRect.origin.y + trackRect.size.height - 1.)
            : (trackRect.origin.y + trackRect.size.height / 2 - markHeight / 2);

    for (int i = 0; i < [self getMarksCount]; i++)
    {
        UIView *mark = [self getMarkView:i];
        if (i == 0)
            mark.frame = CGRectMake(x, y, markWidth, markHeight);
        else if (mark.tag >= kAdditionalMarkTag)
            mark.frame = CGRectMake(x, y + 1.5, markWidth / 2, kAdditionalMarkHeight);
        else
            mark.frame = CGRectMake(x - markWidth, y, markWidth, markHeight);

        if (_isCustomSlider && i == _currentMark)
        {
            _currentMarkView.frame = CGRectMake(
                    mark.frame.origin.x - mark.frame.size.width / 2,
                    trackRect.origin.y + trackRect.size.height / 2 - kCurrentMarkHeight / 2,
                    markWidth,
                    kCurrentMarkHeight
            );

            _currentLineView.frame = CGRectMake(
                    inset,
                    trackRect.origin.y,
                    _currentMarkView.frame.origin.x - inset,
                    trackRect.size.height
            );

            _notCurrentLineView.frame = CGRectMake(
                    _currentMarkView.frame.origin.x + _currentMarkView.frame.size.width,
                    trackRect.origin.y,
                    trackWidth - _currentMarkView.frame.origin.x,
                    trackRect.size.height
            );
        }

        x += trackWidth / segments;
    }
}

- (void)paintMarks
{
    BOOL isRTL = [self isDirectionRTL];
    CGFloat value = self.value;
    for (int i = 0; i < [self getMarksCount]; i++)
    {
        CGFloat step = (CGFloat) i / ([self getMarksCount] - 1);
        BOOL filled = _isCustomSlider
                ? i <= _currentMark
                : (value > (isRTL ? 1 - step : step)) || (value == (isRTL ? 1 - step : step));

        _markViews[i].backgroundColor = _isCustomSlider
                ? filled ? _customMinimumTrackTintColor : _customMaximumTrackTintColor
                : UIColorFromRGB(filled ? color_menu_button : color_slider_gray);
    }
}

- (void)generateFeedback
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

- (void)sliderValueChanged:(id)sender
{
    UISlider *slider = (UISlider *) sender;
    if (slider)
    {
        NSInteger selectingMark = _selectingMark;
        CGFloat selectingMarkValue = (CGFloat) selectingMark / ([self getMarksCount] - 1);
        CGFloat step = 1. / ([self getMarksCount ] - 1);
        if (ABS(slider.value - selectingMarkValue) >= step)
        {
            _selectingMark += slider.value - selectingMarkValue > 0 ? 1 : -1;
            [self generateFeedback];
        }
        [self paintMarks];
    }
}

- (void)sliderDidEndEditing:(id)sender
{
    UISlider *slider = (UISlider *) sender;
    if (slider)
    {
        CGFloat step = 1. / ([self getMarksCount] - 1);
        int nextMark = 0;
        for (int i = 0; i < [self getMarksCount]; i++)
        {
            if (i * step >= slider.value)
            {
                nextMark = i;
                break;
            }
        }
        if ((nextMark * step - slider.value) < (slider.value - (nextMark - 1) * step))
            slider.value = nextMark * step;
        else
            slider.value = (nextMark - 1) * step;

        _selectedMark = [self getIndex];
        if (_selectedMark != _selectingMark)
            [self generateFeedback];

        _selectingMark = _selectedMark;

        // Release the current generator.
        _feedbackGenerator = nil;

        [self paintMarks];
    }
}

- (NSInteger)getIndex
{
    CGFloat value = self.value;
    NSInteger marks = [self getMarksCount];
    CGFloat step = 1. / (marks - 1);
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

- (void)makeCustom:(UIColor *)customMinimumTrackTintColor
    customMaximumTrackTintColor:(UIColor *)customMaximumTrackTintColor
         customCurrentMarkColor:(UIColor *)customCurrentMarkColor
{
    _isCustomSlider = YES;
    _customMinimumTrackTintColor = customMinimumTrackTintColor;
    _customMaximumTrackTintColor = customMaximumTrackTintColor;
    self.minimumTrackTintColor = UIColor.clearColor;
    self.maximumTrackTintColor = UIColor.clearColor;
    _customCurrentColor = customCurrentMarkColor;
}

@end
