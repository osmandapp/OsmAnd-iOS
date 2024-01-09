//
//  OASegmentedSlider.mm
//  OsmAnd
//
//  Created by Skalii on 07.06.2022.
//  Copyright (c) 2022 OsmAnd. All rights reserved.
//

#import "OASegmentedSlider.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
#import "Localization.h"
#import "GeneratedAssetSymbols.h"

#define kMarkTag 1000
#define kAdditionalMarkTag 2000
#define kTitleLabelTag 3000

#define kMarkHeight 16.
#define kCustomMarkHeight 14.
#define kAdditionalMarkHeight 8.
#define kCurrentMarkHeight 30.

#define kMarkWidth 2.

@implementation OASegmentedSlider
{
    NSMutableArray<UIView *> *_markViews;
    UIImpactFeedbackGenerator *_feedbackGenerator;

    NSInteger _numberOfMarks;
    NSInteger _selectingMark;
    NSInteger _additionalMarksBetween;
    BOOL _isCustomSlider;

    UIView *_selectingMarkTitleBackground;
    UILabel *_selectingMarkTitle;
    UIView *_currentMarkView;
    UILabel *_currentMarkLabel;
    UIView *_currentLeftLineView;
    UIView *_currentRightLineView;
    NSMutableArray<UILabel *> *_titleViews;
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
    _currentMarkX = -1;

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

    if (_currentMarkView)
        [self layoutCurrentMarkLine];
    if (_selectingMarkTitleBackground)
        [self layoutSelectingTitle];
}

- (void)setNumberOfMarks:(NSInteger)numberOfMarks additionalMarksBetween:(NSInteger)additionalMarksBetween
{
    _numberOfMarks = numberOfMarks;
    _additionalMarksBetween = additionalMarksBetween;
    [self createMarks:numberOfMarks + (numberOfMarks - 1) * additionalMarksBetween];
    if (_selectingMarkTitleBackground)
        [self layoutSelectingTitle];
}

- (void)setCurrentMarkX:(CGFloat)currentMarkX
{
    if (!_isCustomSlider)
        [self makeCustom];

    _currentMarkX = currentMarkX;
    if (_currentMarkX == -1)
    {
        if (_currentMarkView)
            [_currentMarkView removeFromSuperview];

        if (_currentMarkLabel)
            [_currentMarkLabel removeFromSuperview];

        if (_currentLeftLineView)
            [_currentLeftLineView removeFromSuperview];
    }
    else
    {
        if (!_currentMarkView)
        {
            _currentMarkView = [[UIView alloc] initWithFrame:CGRectMake(
                    0.,
                    0.,
                    kMarkWidth,
                    kCurrentMarkHeight
            )];
            _currentMarkView.backgroundColor = [UIColor colorNamed:ACColorNameIconColorActive];
            _currentMarkView.layer.cornerRadius = kMarkWidth / 2.;
            [self addSubview:_currentMarkView];
        }
        else if (!_currentMarkView.superview)
        {
            [self addSubview:_currentMarkView];
        }
        [self sendSubviewToBack:_currentMarkView];

        if (!_currentMarkLabel)
        {
            _currentMarkLabel = [[UILabel alloc] initWithFrame:CGRectMake(0., 0., 0., 0.)];
            _currentMarkLabel.numberOfLines = 1;
            _currentMarkLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            _currentMarkLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
            _currentMarkLabel.adjustsFontForContentSizeCategory = YES;
            _currentMarkLabel.text = OALocalizedString(@"shared_string_now").lowercaseString;
            _currentMarkLabel.backgroundColor = UIColor.clearColor;
            [self addSubview:_currentMarkLabel];
        }
        else if (!_currentMarkLabel.superview)
        {
            [self addSubview:_currentMarkLabel];
        }
        [self sendSubviewToBack:_currentMarkLabel];

        if (!_currentLeftLineView)
        {
            _currentLeftLineView = [[UIView alloc] initWithFrame:[self trackRectForBounds:CGRectMake(
                    0.,
                    0.,
                    self.frame.size.width,
                    self.frame.size.height
            )]];
            _currentLeftLineView.backgroundColor = UIColorFromRGB(color_slider_minimum);
            [self addSubview:_currentLeftLineView];
        }
        else if (!_currentLeftLineView.superview)
        {
            [self addSubview:_currentLeftLineView];
        }
        [self sendSubviewToBack:_currentLeftLineView];
    }

    if (!_currentRightLineView)
    {
        _currentRightLineView = [[UIView alloc] initWithFrame:[self trackRectForBounds:CGRectMake(
                0.,
                0.,
                self.frame.size.width,
                self.frame.size.height
        )]];
        _currentRightLineView.backgroundColor = UIColorFromRGB(color_tint_gray);
        [self addSubview:_currentRightLineView];
    }
    else if (!_currentRightLineView.superview)
    {
        [self addSubview:_currentRightLineView];
    }
    [self sendSubviewToBack:_currentRightLineView];

    if (_currentMarkView.superview)
        [self layoutCurrentMarkLine];

    [self paintMarks];
}

- (void)setSelectedMark:(NSInteger)selectedMark
{
    _selectedMark = selectedMark;
    _selectingMark = selectedMark;
    self.value = (CGFloat)selectedMark / ([self getMarksCount] - 1);
    [self paintMarks];
    if (_selectingMarkTitleBackground)
        [self layoutSelectingTitle];
}

- (NSInteger)getMarksCount
{
    return _numberOfMarks + (_numberOfMarks - 1) * _additionalMarksBetween;
}

- (void)createMarks:(NSInteger)marks
{
    for (UIView *v in self.subviews)
    {
        if (v.tag >= kMarkTag)
            [v removeFromSuperview];
    }

    _markViews = [NSMutableArray new];
    _titleViews = [NSMutableArray new];
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

        if (_additionalMarksBetween > 0 && ii == i)
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
            if (_isCustomSlider)
            {
                NSInteger titleValue = _additionalMarksBetween > 0 ? i : i * 3;
                if (titleValue == 24)
                    titleValue = 0;
                UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0., 0., 0., 0.)];
                titleLabel.numberOfLines = 1;
                titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
                titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote];
                titleLabel.adjustsFontForContentSizeCategory = YES;
                titleLabel.text = [(titleValue < 10 ? @"0" : @"") stringByAppendingString:[NSString stringWithFormat:@"%li", titleValue]];
                titleLabel.backgroundColor = UIColor.clearColor;
                titleLabel.tag = kTitleLabelTag + i;

                [self addSubview:titleLabel];
                [self sendSubviewToBack:titleLabel];
                [_titleViews addObject:titleLabel];
            }
        }

        [mark.layer setCornerRadius:kMarkWidth / 2.];
        [self addSubview:mark];
        [self sendSubviewToBack:mark];
        [_markViews addObject:mark];
    }
    
    if ([self isDirectionRTL])
    {
        _titleViews = [[[_titleViews reverseObjectEnumerator] allObjects] mutableCopy];
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
    CGFloat sliderViewWidth = self.frame.size.width;
    CGFloat sliderViewHeight = self.frame.size.height;
    CGRect sliderViewBounds = CGRectMake(0., 0., sliderViewWidth, sliderViewHeight);
    CGRect trackRect = [self trackRectForBounds:sliderViewBounds];
    CGFloat trackWidth = trackRect.size.width;
    CGFloat trackHeight = trackRect.size.height;

    CGFloat inset = (sliderViewWidth - trackRect.size.width) / 2;

    CGFloat markHeight = _isCustomSlider ? kCustomMarkHeight + 1. : kMarkHeight;
    CGFloat x = inset;
    CGFloat y = _isCustomSlider
            ? (trackRect.origin.y + trackHeight - 1.)
            : (trackRect.origin.y + trackHeight / 2 - markHeight / 2);

    NSInteger marksCount = [self getMarksCount];
    NSInteger ii = 0;
    for (int i = 0; i < marksCount; i++)
    {
        UIView *mark = [self getMarkView:i];
        if (i == 0)
            mark.frame = CGRectMake(x, y, trackHeight, markHeight);
        else if (mark.tag >= kAdditionalMarkTag)
            mark.frame = CGRectMake(x - trackHeight / 2, y + 1.5, trackHeight / 2, kAdditionalMarkHeight);
        else
            mark.frame = CGRectMake(x - trackHeight, y, trackHeight, markHeight);

        if (mark.tag < kAdditionalMarkTag && _titleViews.count > 0)
        {
            UILabel *titleLabel = _titleViews[ii++];
            CGSize textSize = [OAUtilities calculateTextBounds:titleLabel.text font:titleLabel.font];

            CGFloat tx;
            if (i == 0)
                tx = mark.frame.origin.x;
            else if (i == marksCount - 1)
                tx = trackWidth - textSize.width;
            else
                tx = mark.frame.origin.x + mark.frame.size.width / 2 - textSize.width / 2;

            titleLabel.frame = CGRectMake(tx, mark.frame.origin.y + mark.frame.size.height, textSize.width, textSize.height);
        }
        x += trackWidth / segments;
    }
}

- (void)layoutCurrentMarkLine
{
    CGRect sliderViewBounds = CGRectMake(0., 0., self.frame.size.width, self.frame.size.height);
    CGRect trackRect = [self trackRectForBounds:sliderViewBounds];
    CGFloat trackWidth = trackRect.size.width;
    CGFloat trackHeight = trackRect.size.height;
    CGFloat inset = (self.frame.size.width - trackRect.size.width) / 2;

    if (_currentMarkX != -1)
    {
        _currentMarkView.frame = CGRectMake(
                _currentMarkX / _maximumForCurrentMark * trackWidth,
                trackRect.origin.y + trackHeight / 2 - kCurrentMarkHeight / 2 - 2.,
                trackHeight,
                kCurrentMarkHeight
        );
    }

    if (_currentMarkLabel)
    {
        CGSize textSize = [OAUtilities calculateTextBounds:_currentMarkLabel.text font:_currentMarkLabel.font];
        _currentMarkLabel.frame = CGRectMake(
                _currentMarkView.frame.origin.x + _currentMarkView.frame.size.width / 2 - textSize.width / 2,
                _currentMarkView.frame.origin.y - 3. - textSize.height,
                textSize.width,
                textSize.height
        );
    }

    if (_currentLeftLineView)
        _currentLeftLineView.frame = CGRectMake(inset, trackRect.origin.y, _currentMarkView.frame.origin.x - inset, trackHeight);

    if (_currentRightLineView)
        _currentRightLineView.frame = CGRectMake(inset, trackRect.origin.y, trackWidth, trackHeight);
}

- (void)layoutSelectingTitle
{
    _selectingMarkTitle.textColor = self.userInteractionEnabled ? [UIColor colorNamed:ACColorNameTextColorPrimary] : [UIColor colorNamed:ACColorNameTextColorSecondary];
    NSInteger index = [self getIndex];
    NSInteger markValue = _additionalMarksBetween > 0 ? index : index * 3;
    _selectingMarkTitle.text = !self.userInteractionEnabled ? OALocalizedString(@"rendering_value_disabled_name")
            : [markValue < 10 || index == [self getMarksCount] - 1 ? @"0" : @""
                    stringByAppendingString:[NSString stringWithFormat:@"%li:00", index == [self getMarksCount] - 1 ? 0 : markValue]];

    CGSize textSize = [OAUtilities calculateTextBounds:_selectingMarkTitle.text font:_selectingMarkTitle.font];
    _selectingMarkTitle.frame = CGRectMake(6., 2., textSize.width, textSize.height);

    CGRect trackRect = [self trackRectForBounds:self.bounds];
    CGRect thumbRect = [self thumbRectForBounds:self.bounds trackRect:trackRect value:self.value];
    CGFloat width = textSize.width + 6. * 2;
    CGFloat height = textSize.height + 2. * 2;
    CGFloat x = thumbRect.origin.x + thumbRect.size.width / 2 - width / 2;
    CGFloat firstX = _markViews.firstObject.frame.origin.x;
    CGFloat lastX = _markViews.lastObject.frame.origin.x + _markViews.lastObject.frame.size.width;
    if (x < firstX)
        x = firstX;
    if (x + width > lastX)
        x = lastX - width;

    _selectingMarkTitleBackground.frame = CGRectMake(
            x,
            thumbRect.origin.y - 4. - height,
            width,
            height
    );

    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0., 0., width, height)
                                                          cornerRadius:_selectingMarkTitleBackground.layer.cornerRadius];
    _selectingMarkTitleBackground.layer.shadowPath = shadowPath.CGPath;
}

- (void)paintMarks
{
    BOOL isRTL = [self isDirectionRTL];
    CGFloat value = self.value;
    CGFloat currentValue = _currentMarkX / _maximumForCurrentMark * _markViews.lastObject.frame.origin.x;
    for (int i = 0; i < [self getMarksCount]; i++)
    {
        CGFloat step = (CGFloat) i / ([self getMarksCount] - 1);
        BOOL filled = _isCustomSlider
                ? _markViews[i].frame.origin.x <= currentValue
                : (value > (isRTL ? 1 - step : step)) || (value == (isRTL ? 1 - step : step));

        _markViews[i].backgroundColor = _isCustomSlider
                ? filled ? UIColorFromRGB(color_slider_minimum) : UIColorFromRGB(color_tint_gray)
                : UIColorFromRGB(filled ? color_menu_button : color_slider_gray);
        [self sendSubviewToBack:_markViews[i]];
    }
    for (UILabel *titleLabel in _titleViews)
    {
        titleLabel.textColor = self.userInteractionEnabled ? [UIColor colorNamed:ACColorNameTextColorPrimary] : [UIColor colorNamed:ACColorNameTextColorSecondary];
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

        if (_selectingMarkTitleBackground)
            [self layoutSelectingTitle];
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
        if (_selectingMarkTitleBackground)
            [self layoutSelectingTitle];
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

- (void)makeCustom
{
    _isCustomSlider = YES;
    self.minimumTrackTintColor = UIColor.clearColor;
    self.maximumTrackTintColor = UIColor.clearColor;

    if (!_selectingMarkTitleBackground)
    {
        _selectingMarkTitleBackground = [[UIView alloc] initWithFrame:CGRectMake(0., 0., 0., 0.)];
        _selectingMarkTitleBackground.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        _selectingMarkTitleBackground.backgroundColor = [UIColor colorNamed:ACColorNameWeatherSliderLabelBg];

        _selectingMarkTitleBackground.layer.masksToBounds = NO;
        _selectingMarkTitleBackground.layer.shadowColor = [UIColor.blackColor colorWithAlphaComponent:.2].CGColor;
        _selectingMarkTitleBackground.layer.shadowOpacity = 1;
        _selectingMarkTitleBackground.layer.shadowRadius = 1.;
        _selectingMarkTitleBackground.layer.shadowOffset = CGSizeMake(0., 2.);

        _selectingMarkTitleBackground.layer.cornerRadius = 10.;
        _selectingMarkTitleBackground.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;

        [self addSubview:_selectingMarkTitleBackground];
        [self bringSubviewToFront:_selectingMarkTitleBackground];

        _selectingMarkTitle = [[UILabel alloc] initWithFrame:CGRectMake(0., 0., 0., 0.)];
        _selectingMarkTitle.numberOfLines = 1;
        _selectingMarkTitle.font = [UIFont scaledSystemFontOfSize:13. weight:UIFontWeightMedium];
        _selectingMarkTitle.adjustsFontForContentSizeCategory = YES;
        _selectingMarkTitle.backgroundColor = UIColor.clearColor;

        [_selectingMarkTitleBackground addSubview:_selectingMarkTitle];

        [self layoutSelectingTitle];
    }
}

@end
