//
//  OAFeatureCardRow.m
//  OsmAnd
//
//  Created by Alexey on 17/12/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OAFeatureCardRow.h"
#import "OAChoosePlanHelper.h"
#import "OAColors.h"

#define kSeparatorLeftInset 66.
#define kMinRowHeight 48.
#define kImageBackgroundSize 40.
#define kTitleVerticalOffset 10.

@interface OAFeatureCardRow ()

@property (weak, nonatomic) IBOutlet UIImageView *imageViewLeftIcon;
@property (weak, nonatomic) IBOutlet UILabel *labelDescription;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewFirstRightIcon;
@property (weak, nonatomic) IBOutlet UIImageView *imageViewSecondRightIcon;
@property (weak, nonatomic) IBOutlet UIView *viewBottomSeparator;

@end

@implementation OAFeatureCardRow
{
    OAFeatureCardRowType _type;

    UIView *_imageBackground;
    CGFloat _dividerLeftMargin;

    UITapGestureRecognizer *_tapRecognizer;
    UILongPressGestureRecognizer *_longPressRecognizer;
}

- (instancetype) init
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OAFeatureCardRow class]])
        {
            self = (OAFeatureCardRow *)v;
            break;
        }

    if (self)
        self.frame = CGRectMake(0, 0, 200, 100);
    
    [self commonInit];
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    NSArray *bundle = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:nil options:nil];
    for (UIView *v in bundle)
        if ([v isKindOfClass:[OAFeatureCardRow class]])
        {
            self = (OAFeatureCardRow *)v;
            break;
        }

    if (self)
        self.frame = frame;
    
    [self commonInit];
    return self;
}

- (instancetype) initWithType:(OAFeatureCardRowType)type
{
    self = [super init];
    if (self)
    {
        _type = type;
        [self commonInit];
    }
    return self;
}

- (void) commonInit
{
    self.labelDescription.hidden = _type != EOAFeatureCardRowInclude;
    self.imageViewFirstRightIcon.hidden = _type != EOAFeatureCardRowPlan;
    self.viewBottomSeparator.hidden = _type == EOAFeatureCardRowInclude;

    if (_type == EOAFeatureCardRowPlan)
    {
        self.imageViewFirstRightIcon.image = [UIImage imageNamed:@"ic_custom_osmand_maps_plus"];
        self.imageViewSecondRightIcon.image = [UIImage imageNamed:@"ic_custom_osmand_pro_logo_colored"];
    }
    else if (_type == EOAFeatureCardRowSubscription || _type == EOAFeatureCardRowSimple)
    {
        self.imageViewSecondRightIcon.image = [UIImage templateImageNamed:@"ic_checkmark_default"];
        self.imageViewSecondRightIcon.tintColor = UIColorFromRGB(color_primary_purple);
    }
    else if (_type == EOAFeatureCardRowInclude)
    {
        self.imageViewSecondRightIcon.hidden = YES;
        self.labelDescription.font = [UIFont systemFontOfSize:15.];
        self.labelDescription.textColor = UIColorFromRGB(color_text_footer);
        _imageBackground = [[UIView alloc] init];
        _imageBackground.layer.cornerRadius = 9.;
        _imageBackground.backgroundColor = UIColorFromARGB(color_primary_purple_10);
        [self insertSubview:_imageBackground belowSubview:self.imageViewLeftIcon];
    }

    if (_type != EOAFeatureCardRowInclude && _type != EOAFeatureCardRowSubscription)
    {
        _tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapped:)];
        [self addGestureRecognizer:_tapRecognizer];
        _longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onLongPressed:)];
        _longPressRecognizer.minimumPressDuration = .2;
        [self addGestureRecognizer:_longPressRecognizer];
    }
}

- (void)updateInfo:(OAFeature *)feature showDivider:(BOOL)showDivider selected:(BOOL)selected
{
    self.backgroundColor = selected && _type == EOAFeatureCardRowPlan ? UIColorFromARGB(color_primary_purple_05) : UIColor.whiteColor;
    self.labelTitle.text = [feature getTitle];
    self.imageViewLeftIcon.image = [feature getIcon];
    if (_type == EOAFeatureCardRowPlan)
        self.imageViewFirstRightIcon.hidden = ![feature isAvailableInMapsPlus];
    else if (_type == EOAFeatureCardRowSubscription)
        self.imageViewSecondRightIcon.hidden = !selected;

    self.viewBottomSeparator.hidden = !showDivider;
}

- (void)updateSimpleRowInfo:(NSString *)title
                showDivider:(BOOL)showDivider
          dividerLeftMargin:(CGFloat)dividerLeftMargin
                       icon:(NSString *)icon
{
    _dividerLeftMargin = dividerLeftMargin;

    self.backgroundColor = UIColor.whiteColor;
    self.labelTitle.text = title;
    self.labelTitle.textColor = UIColorFromRGB(color_primary_purple);
    self.imageViewLeftIcon.hidden = YES;
    self.imageViewSecondRightIcon.image = [UIImage templateImageNamed:icon];
    self.imageViewSecondRightIcon.tintColor = UIColorFromRGB(color_primary_purple);

    self.viewBottomSeparator.hidden = !showDivider;
    CGRect viewBottomSeparatorFrame = self.viewBottomSeparator.frame;
    viewBottomSeparatorFrame.origin.x = _dividerLeftMargin;
    viewBottomSeparatorFrame.size.width = DeviceScreenWidth;
    if (_dividerLeftMargin > 0.)
    {
        viewBottomSeparatorFrame.origin.x += [OAUtilities getLeftMargin];
        viewBottomSeparatorFrame.size.width -= viewBottomSeparatorFrame.origin.x * 2;
    }
    self.viewBottomSeparator.frame = viewBottomSeparatorFrame;
}

- (void)updateIncludeInfo:(OAFeature *)feature
{
    self.backgroundColor = UIColor.clearColor;
    self.labelTitle.text = [feature getTitle];
    self.labelDescription.text = [feature getDescription];
    self.imageViewLeftIcon.image = [feature getIcon];
}

- (CGFloat)updateLayout:(CGFloat)y
{
    CGFloat width = DeviceScreenWidth;
    CGFloat iconMargin = _type == EOAFeatureCardRowSimple || _type == EOAFeatureCardRowInclude
            ? 0.
            : kIconSize + kPrimarySpaceMargin;
    CGFloat iconMargins = _type == EOAFeatureCardRowInclude
            ? 0
            : 20. + iconMargin + (self.imageViewFirstRightIcon.hidden ? iconMargin : iconMargin * 2) + 20.;

    CGSize titleSize = [OAUtilities calculateTextBounds:self.labelTitle.text
                                                  width:width - [OAUtilities getLeftMargin] * 2 - iconMargins
                                                   font:self.labelTitle.font];

    self.labelTitle.frame = CGRectMake(
            20. + iconMargin + [OAUtilities getLeftMargin],
            _type == EOAFeatureCardRowInclude ? kImageBackgroundSize + kTitleVerticalOffset : kTitleVerticalOffset,
            width - [OAUtilities getLeftMargin] * 2 - iconMargins,
            titleSize.height
    );

    if (_type != EOAFeatureCardRowInclude)
    {
        CGFloat viewBottomSeparatorY = self.labelTitle.frame.origin.y + self.labelTitle.frame.size.height + kTitleVerticalOffset - kSeparatorHeight;
        if (_type == EOAFeatureCardRowSimple)
        {
            CGRect viewBottomSeparatorFrame = self.viewBottomSeparator.frame;
            viewBottomSeparatorFrame.origin.x = _dividerLeftMargin;
            viewBottomSeparatorFrame.origin.y = viewBottomSeparatorY;
            viewBottomSeparatorFrame.size.width = width;
            viewBottomSeparatorFrame.size.height = kSeparatorHeight;
            if (_dividerLeftMargin > 0.)
            {
                viewBottomSeparatorFrame.origin.x += [OAUtilities getLeftMargin];
                viewBottomSeparatorFrame.size.width -= viewBottomSeparatorFrame.origin.x * 2;
            }
            self.viewBottomSeparator.frame = viewBottomSeparatorFrame;
        }
        else
        {
            self.viewBottomSeparator.frame = CGRectMake(
                    kSeparatorLeftInset + [OAUtilities getLeftMargin],
                    viewBottomSeparatorY,
                    width - kSeparatorLeftInset - [OAUtilities getLeftMargin],
                    kSeparatorHeight
            );
        }
    }
    else
    {
        CGSize descriptionSize = [OAUtilities calculateTextBounds:self.labelDescription.text
                                                            width:width - (20. + [OAUtilities getLeftMargin]) * 2
                                                             font:self.labelDescription.font];
        self.labelDescription.frame = CGRectMake(
                20. + [OAUtilities getLeftMargin],
                self.labelTitle.frame.origin.y + self.labelTitle.frame.size.height + 5.,
                width - (20. + [OAUtilities getLeftMargin]) * 2,
                descriptionSize.height
        );
    }

    self.frame = CGRectMake(
            0.,
            y,
            width,
            _type == EOAFeatureCardRowInclude
                    ? self.labelDescription.frame.origin.y + self.labelDescription.frame.size.height
                    : self.viewBottomSeparator.frame.origin.y + self.viewBottomSeparator.frame.size.height
    );

    if (_type != EOAFeatureCardRowInclude)
    {
        CGFloat iconVerticalOffset = _type == EOAFeatureCardRowInclude
                ? 0.
                : self.frame.size.height - self.frame.size.height / 2 - kIconSize / 2;
        self.imageViewLeftIcon.frame = CGRectMake(20. + [OAUtilities getLeftMargin], iconVerticalOffset, kIconSize, kIconSize);
        self.imageViewSecondRightIcon.frame = CGRectMake(width - 20. - kIconSize - [OAUtilities getLeftMargin], iconVerticalOffset, kIconSize, kIconSize);
        self.imageViewFirstRightIcon.frame = CGRectMake(self.imageViewSecondRightIcon.frame.origin.x - kPrimarySpaceMargin - kIconSize, iconVerticalOffset, kIconSize, kIconSize);
    }
    else
    {
        CGFloat iconOffset = (kImageBackgroundSize - kIconSize) / 2;
        _imageBackground.frame = CGRectMake(
                20. + [OAUtilities getLeftMargin],
                0.,
                kImageBackgroundSize,
                kImageBackgroundSize
        );
        self.imageViewLeftIcon.frame = CGRectMake(
                _imageBackground.frame.origin.x + iconOffset,
                _imageBackground.frame.origin.y + iconOffset,
                kIconSize,
                kIconSize
        );
    }

    return self.frame.size.height;
}

- (void)onTapped:(UIGestureRecognizer *)recognizer
{
    if (self.delegate)
        [self.delegate onFeatureSelected:self.tag state:recognizer.state];
}

- (void)onLongPressed:(UIGestureRecognizer *)recognizer
{
    if (self.delegate)
        [self.delegate onFeatureSelected:self.tag state:recognizer.state];
}

@end
