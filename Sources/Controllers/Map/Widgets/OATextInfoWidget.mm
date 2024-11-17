//
//  OATextInfoWidget.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"
#import "OARootViewController.h"
#import "OAMapPanelViewController.h"
#import "OAUtilities.h"
#import "OAColors.h"
#import "OAAppSettings.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import "OASegmentTableViewCell.h"

#define textHeight 22
#define imageSide 30
#define minTextWidth 64
#define fullTextWidth 90
#define minWidgetHeight 34

static NSString * _Nonnull const kShowIconPref = @"simple_widget_show_icon";
static NSString * _Nonnull const kSizeStylePref = @"simple_widget_size";

@implementation OATextInfoWidget
{
    NSString *_contentTitle;
    UIColor *_contentTitleColor;
    NSString *_text;
    NSString *_subtext;
    BOOL _explicitlyVisible;
    
    NSString *_icon;
    BOOL _isNight;
    
    UIButton *_shadowButton;
    
    UIFont *_largeFont;
    UIFont *_largeBoldFont;
    UIFont *_smallFont;
    UIFont *_smallBoldFont;

    BOOL _metricSystemDepended;
    BOOL _angularUnitsDepended;
    int _cachedMetricSystem;
    int _cachedAngularUnits;
    NSLayoutConstraint *_leadingTextAnchor;
    NSString *_customId;
    OACommonBoolean *_showIconPref;
    OAApplicationMode *_appMode;
    NSLayoutConstraint *_unitOrEmptyLabelWidthConstraint;
    UIStackView *_contentStackViewSimpleWidget;
    UIStackView *_contentUnitStackViewSimpleWidget;
    NSLayoutConstraint *_verticalStackViewSimpleWidgetTopConstraint;
    NSLayoutConstraint *_verticalStackViewSimpleWidgetBottomConstraint;
    UIColor *_iconColor;
}

- (instancetype) init
{
    self = [super init];

    if (self)
    {
        self.frame = CGRectMake(0, 0, kTextInfoWidgetWidth, kTextInfoWidgetHeight);
        [self initSeparatorsView];
    }
    return self;
}

- (instancetype) initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        self.frame = CGRectMake(0, 0, kTextInfoWidgetWidth, kTextInfoWidgetHeight);
        [self initSeparatorsView];
        [self commonInit];
    }
    
    return self;
}

- (NSDictionary<NSAttributedStringKey, id> *)getAttributes:(CGFloat)lineHeight
                                                      label:(UILabel *)label
                                           fontMetrics:(UIFontMetrics *)fontMetrics
{
    NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
    
    CGFloat scaledLineHeight = fontMetrics ? [fontMetrics scaledValueForValue:lineHeight] : lineHeight;
    if (scaledLineHeight < lineHeight)
    {
        scaledLineHeight = lineHeight;
    }
    paragraphStyle.minimumLineHeight = scaledLineHeight;
    paragraphStyle.maximumLineHeight = scaledLineHeight;
    
    CGFloat baselineOffset = (scaledLineHeight - label.font.lineHeight) / 4;
    
    if (label.minimumScaleFactor < 1)
    {
        CGFloat actualScaleFactor = [label actualScaleFactor];
        if (actualScaleFactor < 1)
        {
            CGFloat fontLineHeight = label.font.lineHeight * actualScaleFactor;
            baselineOffset = (scaledLineHeight - fontLineHeight) / 2;
        }
    }

    NSMutableDictionary<NSAttributedStringKey, id> *dic = [NSMutableDictionary dictionary];
    dic[NSParagraphStyleAttributeName] = paragraphStyle;
    dic[NSKernAttributeName] = @0;
    dic[NSBaselineOffsetAttributeName] = @(baselineOffset);
    if (label.font)
        dic[NSFontAttributeName] = label.font;
    return dic;
}

- (void)updateVerticalStackImageTitleSubtitleLayout
{
    NSArray *viewsToRemove = [self subviews];
    for (UIView *v in viewsToRemove) {
        [v removeFromSuperview];
    }
    [self initSeparatorsView];
    [self showBottomSeparator:NO];
    [self updatesSeparatorsColor:[UIColor colorNamed:ACColorNameCustomSeparator]];

    UIStackView *verticalStackView = [UIStackView new];
    verticalStackView.translatesAutoresizingMaskIntoConstraints = NO;
    verticalStackView.axis = UILayoutConstraintAxisVertical;
    verticalStackView.alignment = UIStackViewAlignmentFill;
    verticalStackView.spacing = 7;
    verticalStackView.distribution = UIStackViewDistributionEqualSpacing;
    [self addSubview:verticalStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [verticalStackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:9],
        [verticalStackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:3],
        [verticalStackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-3],
    ]];
    _imageView = [UIImageView new];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    UIImage *image = [UIImage imageNamed:_icon];
    [self setImage:image];
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [verticalStackView addArrangedSubview:_imageView];
    
    UIStackView *verticalNameUnitStackView = [UIStackView new];
    verticalNameUnitStackView.translatesAutoresizingMaskIntoConstraints = NO;
    verticalNameUnitStackView.axis = UILayoutConstraintAxisVertical;
    verticalNameUnitStackView.alignment = UIStackViewAlignmentFill;
    verticalNameUnitStackView.spacing = 7;
    verticalNameUnitStackView.distribution = UIStackViewDistributionEqualSpacing;
    [verticalStackView addArrangedSubview:verticalNameUnitStackView];
    
    self.valueLabel = [UILabel new];
    self.valueLabel.text = @"-";
    self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.valueLabel.textAlignment = NSTextAlignmentCenter;
    self.valueLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle3];
    self.valueLabel.textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];
    [verticalNameUnitStackView addArrangedSubview:self.valueLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.valueLabel.heightAnchor constraintEqualToConstant:24],
    ]];
    
    self.unitLabel = [UILabel new];
    self.unitLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.unitLabel.textAlignment = NSTextAlignmentCenter;
    self.unitLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleCaption2];
    self.unitLabel.textColor = [UIColor colorNamed:ACColorNameTextColorSecondary];
    [verticalNameUnitStackView addArrangedSubview:self.unitLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.unitLabel.heightAnchor constraintEqualToConstant:13]
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [_imageView.heightAnchor constraintEqualToConstant:30],
        [_imageView.widthAnchor constraintEqualToConstant:30],
    ]];
}

- (void)updateSimpleLayout
{
    NSArray *viewsToRemove = [self subviews];
    for (UIView *v in viewsToRemove)
    {
        [v removeFromSuperview];
    }
    [self initSeparatorsView];
    
    UIStackView *verticalStackView = [UIStackView new];
    verticalStackView.translatesAutoresizingMaskIntoConstraints = NO;
    verticalStackView.axis = UILayoutConstraintAxisVertical;
    verticalStackView.alignment = UIStackViewAlignmentFill;
    switch (self.widgetSizeStyle)
    {
        case EOAWidgetSizeStyleLarge:
            verticalStackView.spacing = 4;
            break;
        case EOAWidgetSizeStyleMedium:
            verticalStackView.spacing = 2;
            break;
        default:
            break;
    }
   
    verticalStackView.distribution = UIStackViewDistributionEqualSpacing;
    [self addSubview:verticalStackView];
    
    [NSLayoutConstraint activateConstraints:@[
        [verticalStackView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:16],
        [verticalStackView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-16],
    ]];
    _verticalStackViewSimpleWidgetTopConstraint = [verticalStackView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0];
    _verticalStackViewSimpleWidgetTopConstraint.active = YES;
    
    _verticalStackViewSimpleWidgetBottomConstraint = [verticalStackView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:0];
    _verticalStackViewSimpleWidgetBottomConstraint.active = YES;
    
    // Create the topNameUnitStackView
    self.topNameUnitStackView = [UIStackView new];
    self.topNameUnitStackView.translatesAutoresizingMaskIntoConstraints = NO;
    self.topNameUnitStackView.axis = UILayoutConstraintAxisHorizontal;
    self.topNameUnitStackView.alignment = UIStackViewAlignmentFill;
    self.topNameUnitStackView.distribution = UIStackViewDistributionEqualSpacing;
    [verticalStackView addArrangedSubview:self.topNameUnitStackView];

    self.topNameUnitStackView.hidden = self.widgetSizeStyle == EOAWidgetSizeStyleSmall;
    
    auto nameView = [UIView new];
    nameView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.topNameUnitStackView addArrangedSubview:nameView];
    [NSLayoutConstraint activateConstraints:@[
        [nameView.heightAnchor constraintEqualToConstant:13]
    ]];
    
    // Create the name label ("SPEED")
    self.nameLabel = [UILabel new];
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.allowsDefaultTighteningForTruncation = YES;
    self.nameLabel.lineBreakMode = NSLineBreakByTruncatingTail;
    self.nameLabel.font = [UIFont scaledSystemFontOfSize:[OAWidgetSizeStyleObjWrapper
                                                          getLabelFontSizeForType:self.widgetSizeStyle] weight:UIFontWeightMedium];
    [nameView addSubview:self.nameLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.nameLabel.topAnchor constraintEqualToAnchor:nameView.topAnchor],
        [self.nameLabel.leadingAnchor constraintEqualToAnchor:nameView.leadingAnchor],
        [self.nameLabel.trailingAnchor constraintEqualToAnchor:nameView.trailingAnchor],
        [self.nameLabel.bottomAnchor constraintEqualToAnchor:nameView.bottomAnchor]
    ]];
    
    self.unitView = [UIView new];
    self.unitView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.topNameUnitStackView addArrangedSubview:self.unitView];
    [NSLayoutConstraint activateConstraints:@[
        [self.unitView.heightAnchor constraintGreaterThanOrEqualToConstant:13],
        [self.unitView.widthAnchor constraintGreaterThanOrEqualToConstant:15]
    ]];
    self.unitView.hidden = _subtext.length == 0;
    
    // Create the unit label ("KM/H")
    self.unitLabel = [UILabel new];
    self.unitLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.unitLabel.font = [UIFont scaledSystemFontOfSize:[OAWidgetSizeStyleObjWrapper getUnitsFontSizeForType:self.widgetSizeStyle] weight:UIFontWeightMedium];
    self.unitLabel.textColor = [UIColor colorNamed:ACColorNameWidgetUnitsColor];
    [self.unitView addSubview:self.unitLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.unitLabel.topAnchor constraintEqualToAnchor:self.unitView.topAnchor],
        [self.unitLabel.leadingAnchor constraintEqualToAnchor:self.unitView.leadingAnchor],
        [self.unitLabel.trailingAnchor constraintEqualToAnchor:self.unitView.trailingAnchor],
        [self.unitLabel.bottomAnchor constraintEqualToAnchor:self.unitView.bottomAnchor],
    ]];
    
    // Create the _contentStackViewSimpleWidget
    _contentStackViewSimpleWidget = [UIStackView new];
    _contentStackViewSimpleWidget.translatesAutoresizingMaskIntoConstraints = NO;
    _contentStackViewSimpleWidget.axis = UILayoutConstraintAxisHorizontal;
    _contentStackViewSimpleWidget.alignment = UIStackViewAlignmentFill;
    _contentStackViewSimpleWidget.distribution = UIStackViewDistributionFill;
    [verticalStackView addArrangedSubview:_contentStackViewSimpleWidget];
    
    self.iconWidgetView = [UIView new];
    self.iconWidgetView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentStackViewSimpleWidget addArrangedSubview:self.iconWidgetView];
    [NSLayoutConstraint activateConstraints:@[
        [self.iconWidgetView.heightAnchor constraintGreaterThanOrEqualToConstant:30],
        [self.iconWidgetView.widthAnchor constraintEqualToConstant:30]
    ]];
    
    _imageView = [UIImageView new];
    UIImage *image = [UIImage imageNamed:_icon];
    if (_iconColor) {
        [self setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        [_imageView setTintColor:_iconColor];
        _iconColor = nil;
    } else {
        [self setImage:image];
    }
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.iconWidgetView addSubview:_imageView];
    [NSLayoutConstraint activateConstraints:@[
        [_imageView.heightAnchor constraintEqualToConstant:30],
        [_imageView.widthAnchor constraintEqualToConstant:30],
        [_imageView.centerXAnchor constraintEqualToAnchor:self.iconWidgetView.centerXAnchor],
        [_imageView.centerYAnchor constraintEqualToAnchor:self.iconWidgetView.centerYAnchor]
    ]];
    
    auto valueUnitOrEmptyView = [UIView new];
    valueUnitOrEmptyView.translatesAutoresizingMaskIntoConstraints = NO;
    [_contentStackViewSimpleWidget addArrangedSubview:valueUnitOrEmptyView];
    
    // Create the unit label ("150")
    self.valueLabel = [UILabel new];
    self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.valueLabel.adjustsFontSizeToFitWidth = YES;
    self.valueLabel.minimumScaleFactor = 0.3;
    self.valueLabel.textColor = [UIColor colorNamed:ACColorNameWidgetValueColor];
    [valueUnitOrEmptyView addSubview:self.valueLabel];
    
    _contentUnitStackViewSimpleWidget = [UIStackView new];
    _contentUnitStackViewSimpleWidget.translatesAutoresizingMaskIntoConstraints = NO;
    _contentUnitStackViewSimpleWidget.axis = UILayoutConstraintAxisVertical;
    _contentUnitStackViewSimpleWidget.alignment = UIStackViewAlignmentFill;
    _contentUnitStackViewSimpleWidget.spacing = 2;
    _contentUnitStackViewSimpleWidget.distribution = UIStackViewDistributionEqualSpacing;
    [valueUnitOrEmptyView addSubview:_contentUnitStackViewSimpleWidget];
    
    self.titleOrEmptyLabel = [UILabel new];
    self.titleOrEmptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.titleOrEmptyLabel.allowsDefaultTighteningForTruncation = YES;
    self.titleOrEmptyLabel.textColor = [UIColor colorNamed:ACColorNameWidgetUnitsColor];
    self.titleOrEmptyLabel.textAlignment = NSTextAlignmentRight;
    [_contentUnitStackViewSimpleWidget addArrangedSubview:self.titleOrEmptyLabel];
    
    // Create the unitOrEmptyLabel ("KM/H")
    self.unitOrEmptyLabel = [UILabel new];
    self.unitOrEmptyLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.unitOrEmptyLabel.allowsDefaultTighteningForTruncation = YES;
    self.unitOrEmptyLabel.textColor = [UIColor colorNamed:ACColorNameWidgetUnitsColor];
    self.unitOrEmptyLabel.textAlignment = NSTextAlignmentRight;
    [_contentUnitStackViewSimpleWidget addArrangedSubview:self.unitOrEmptyLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.valueLabel.topAnchor constraintEqualToAnchor:valueUnitOrEmptyView.topAnchor],
        [self.valueLabel.leadingAnchor constraintEqualToAnchor:valueUnitOrEmptyView.leadingAnchor],
        [self.valueLabel.bottomAnchor constraintEqualToAnchor:valueUnitOrEmptyView.bottomAnchor],
        [self.valueLabel.heightAnchor constraintGreaterThanOrEqualToConstant:26]
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [_contentUnitStackViewSimpleWidget.centerYAnchor constraintEqualToAnchor:valueUnitOrEmptyView.centerYAnchor],
        [_contentUnitStackViewSimpleWidget.leadingAnchor constraintEqualToAnchor:self.valueLabel.trailingAnchor constant:3],
        [_contentUnitStackViewSimpleWidget.trailingAnchor constraintEqualToAnchor:valueUnitOrEmptyView.trailingAnchor],
    ]];
    _unitOrEmptyLabelWidthConstraint = [_contentUnitStackViewSimpleWidget.widthAnchor constraintGreaterThanOrEqualToConstant:15];
    _unitOrEmptyLabelWidthConstraint.active = YES;
    
    self.emptyViewRightPlaceholderFullRow = [UIView new];
    self.emptyViewRightPlaceholderFullRow.translatesAutoresizingMaskIntoConstraints = NO;
    self.emptyViewRightPlaceholderFullRow.hidden = YES;
    [_contentStackViewSimpleWidget addArrangedSubview:self.emptyViewRightPlaceholderFullRow];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.emptyViewRightPlaceholderFullRow.widthAnchor constraintEqualToAnchor:_imageView.widthAnchor],
        [self.emptyViewRightPlaceholderFullRow.heightAnchor constraintGreaterThanOrEqualToConstant:30]
    ]];

    _shadowButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _shadowButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_shadowButton addTarget:self action:@selector(onWidgetClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_shadowButton];
    
    [NSLayoutConstraint activateConstraints:@[
        [_shadowButton.topAnchor constraintEqualToAnchor:self.topAnchor],
        [_shadowButton.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [_shadowButton.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [_shadowButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    
    _metricSystemDepended = NO;
    _angularUnitsDepended = NO;
    _cachedMetricSystem = -1;
    _cachedAngularUnits = -1;
    
    [self refreshLabel];
}

- (void)commonLayout
{
    [NSLayoutConstraint activateConstraints:@[
        [_imageView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:3],
        [_imageView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [_imageView.heightAnchor constraintEqualToConstant:imageSide],
        [_imageView.widthAnchor constraintEqualToConstant:imageSide]
    ]];

    [NSLayoutConstraint activateConstraints:@[
        [_textView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-6],
        [_textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10]
    ]];
    self.topTextAnchor = [_textView.topAnchor constraintEqualToAnchor:self.topAnchor constant:5];
    self.topTextAnchor.active = YES;
    
    _leadingTextAnchor = [_textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:3];
    _leadingTextAnchor.active = YES;
    
    _largeFont = [UIFont scaledSystemFontOfSize:21 weight:UIFontWeightSemibold];
    _largeBoldFont = [UIFont scaledSystemFontOfSize:21 weight:UIFontWeightBold];
    _primaryFont = _largeFont;
    _primaryColor = [UIColor blackColor];
    _smallFont = [UIFont scaledSystemFontOfSize:14 weight:UIFontWeightSemibold];
    _smallBoldFont = [UIFont scaledSystemFontOfSize:14 weight:UIFontWeightBold];
    _unitsFont = _smallFont;
    _unitsColor = [UIColor grayColor];
    _primaryOutlineColor = nil;
    _unitsShadowColor = nil;
    _textOutlineWidth = 0;
    
    _text = @"";
    _subtext = @"";
    _textView.textAlignment = NSTextAlignmentNatural;
}

- (void)commonInit
{
    _textView = [[OutlineLabel alloc] init];
    _textView.adjustsFontForContentSizeCategory = YES;
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    _imageView = [UIImageView new];
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:_textView];
    [self addSubview:_imageView];
    
    [self commonLayout];
    _shadowButton = [[UIButton alloc] initWithFrame:self.frame];
    _shadowButton.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [_shadowButton addTarget:self action:@selector(onWidgetClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_shadowButton];
    
    _metricSystemDepended = NO;
    _angularUnitsDepended = NO;
    _cachedMetricSystem = -1;
    _cachedAngularUnits = -1;
}

- (BOOL)isTextInfo
{
    return YES;
}

- (void)onWidgetClicked:(id)sender
{
    if (self.onClickFunction)
        self.onClickFunction(self);
    
    if (self.delegate)
        [self.delegate widgetClicked:self];
}

- (void)setImage:(UIImage *)image
{
    [_imageView setImage:image];
}

- (void)setImage:(UIImage *)image withColor:(UIColor *)color
{
    [self setImage:image];
    _imageView.tintColor = color;
}

- (void)setImage:(UIImage *)image withColor:(UIColor *)color iconName:(NSString *)iconName
{
    _icon = iconName;
    _iconColor = color;
    [self setImage:image withColor:color];
}

- (void)setImageHidden:(BOOL)hidden
{
    _imageView.hidden = hidden;
}

- (BOOL)setIconForWidgetType:(OAWidgetType *)widgetType
{
    return [self setIcon:widgetType.iconName];
}

- (BOOL)setIcon:(NSString *)widgetIcon
{
    if (![_icon isEqualToString:widgetIcon])
    {
        _icon = widgetIcon;
        [self setImage:[UIImage imageNamed:_icon]];
        return YES;
    }
    else
    {
        return NO;
    }
}

- (BOOL) isNight
{
    return _isNight;
}

- (NSString *) getIconName
{
    return _icon;
}

- (NSString *) combine:(NSString *)text subtext:(NSString *)subtext
{
    if (text.length == 0)
        return subtext;
    else if (subtext.length == 0)
        return text;
    
    return [NSString stringWithFormat:@"%@ %@", text, subtext];
}

- (void) setContentDescription:(NSString *)text
{
    //view.setContentDescription(combine(contentTitle, text));
}

- (void) setContentTitle:(NSString *)text
{
    _contentTitle = text;
    [self setContentDescription:_textView.text];
    _shadowButton.accessibilityLabel = _contentTitle;
    _shadowButton.accessibilityValue = [self combine:_text subtext:_subtext];
}

- (void) setText:(NSString *)text subtext:(NSString *)subtext
{
    [self setTextNoUpdateVisibility:text subtext:subtext];
    [self updateVisibility:text != nil];
}

- (void) setTextNoUpdateVisibility:(NSString *)text subtext:(NSString *)subtext
{
    if ([_text isEqualToString:text] && [subtext isEqualToString:subtext])
        return;
    if (text.length == 0 && subtext.length == 0)
    {
        if (self.isSimpleLayout) {
            self.valueLabel.text = nil;
        }
        else
        {
            _textView.text = @"";
        }
       
        _text = @"";
        _subtext = @"";
        _shadowButton.accessibilityValue = nil;
    }
    else
    {
        _text = text;
        _subtext = subtext;
        [self refreshLabel];
    }
}

- (void)configureVerticalStackImageTitleSubtitleLayout
{
    self.valueLabel.text = _text;
    self.unitLabel.text = _subtext;
    [self updatesSeparatorsColor:[UIColor colorNamed:ACColorNameCustomSeparator]];
}

- (void)configureSimpleLayout
{
    CGFloat labelFontSize = [OAWidgetSizeStyleObjWrapper getLabelFontSizeForType:self.widgetSizeStyle];
    CGFloat valueFontSize = [OAWidgetSizeStyleObjWrapper getValueFontSizeForType:self.widgetSizeStyle];
    CGFloat unitsFontSize = [OAWidgetSizeStyleObjWrapper getUnitsFontSizeForType:self.widgetSizeStyle];
    CGFloat paddingBetweenIconAndValue = [OAWidgetSizeStyleObjWrapper getPaddingBetweenIconAndValueWithType:self.widgetSizeStyle];

    self.nameLabel.font = [UIFont scaledSystemFontOfSize:labelFontSize weight:UIFontWeightMedium];
    self.nameLabel.textColor = _contentTitleColor;

    self.valueLabel.font = [UIFont scaledSystemFontOfSize:valueFontSize weight:UIFontWeightSemibold];
    self.valueLabel.textColor = _primaryColor;

    self.unitLabel.font = [UIFont scaledSystemFontOfSize:unitsFontSize weight:UIFontWeightMedium];
    self.unitLabel.textColor = _unitsColor;

    self.unitOrEmptyLabel.font = [UIFont scaledSystemFontOfSize:unitsFontSize weight:UIFontWeightMedium];
    self.unitOrEmptyLabel.textColor = _unitsColor;

    self.titleOrEmptyLabel.font = [UIFont scaledSystemFontOfSize:unitsFontSize weight:UIFontWeightMedium];
    self.titleOrEmptyLabel.textColor = _unitsColor;
    
    self.valueLabel.text = _text;
 
    self.nameLabel.text = [_contentTitle upperCase];
    self.topNameUnitStackView.hidden = self.widgetSizeStyle == EOAWidgetSizeStyleSmall;

    _verticalStackViewSimpleWidgetTopConstraint.constant = [OAWidgetSizeStyleObjWrapper getTopPaddingWithType:self.widgetSizeStyle];
    _verticalStackViewSimpleWidgetBottomConstraint.constant = -([OAWidgetSizeStyleObjWrapper getBottomPaddingWithType:self.widgetSizeStyle]);

    BOOL isVisibleIcon = false;
    if (_appMode && _showIconPref)
    {
        isVisibleIcon = [_showIconPref get:_appMode];
        self.iconWidgetView.hidden = !isVisibleIcon;
        _contentStackViewSimpleWidget.spacing = 0;
    }
    _shadowButton.accessibilityValue = [self combine:_text subtext:_subtext];
    if (_subtext.length == 0)
    {
        self.unitView.hidden = YES;
        self.titleOrEmptyLabel.text = self.widgetSizeStyle == EOAWidgetSizeStyleSmall
        ? [_contentTitle upperCase]
        :  @"";
        self.unitOrEmptyLabel.text = @"";
        _unitOrEmptyLabelWidthConstraint.constant = 0;
    }
    else
    {
        _unitOrEmptyLabelWidthConstraint.constant = (self.isFullRow || self.widgetSizeStyle != EOAWidgetSizeStyleSmall) ? 0 : 20;
        if (self.widgetSizeStyle == EOAWidgetSizeStyleSmall)
        {
            self.unitView.hidden = YES;
            self.titleOrEmptyLabel.text = [_contentTitle upperCase];
            self.unitOrEmptyLabel.text = [_subtext upperCase];
        }
        else
        {
            self.titleOrEmptyLabel.text = @"";
            self.unitOrEmptyLabel.text = @"";
            self.unitView.hidden = NO;
            self.unitLabel.attributedText = [[NSMutableAttributedString alloc] initWithString:[_subtext upperCase] attributes:[self getAttributes:unitsFontSize label:self.unitLabel fontMetrics:[UIFontMetrics defaultMetrics]]];
            self.unitLabel.textAlignment = NSTextAlignmentRight;
        }
    }
    
    if (self.isFullRow)
    {
         _contentStackViewSimpleWidget.spacing = 0;
        self.valueLabel.textAlignment = NSTextAlignmentCenter;
        if (self.widgetSizeStyle == EOAWidgetSizeStyleSmall)
        {
            _contentStackViewSimpleWidget.spacing = paddingBetweenIconAndValue;
            self.emptyViewRightPlaceholderFullRow.hidden = YES;
        } else {
            _contentStackViewSimpleWidget.spacing = 0;
            self.emptyViewRightPlaceholderFullRow.hidden = !isVisibleIcon;
        }
    }
    else
    {
        _contentStackViewSimpleWidget.spacing = paddingBetweenIconAndValue;
        self.valueLabel.textAlignment = NSTextAlignmentNatural;
    }
}

- (void)refreshLabel
{
    if (self.isSimpleLayout)
    {
        [self configureSimpleLayout];
    }
    else if (self.isVerticalStackImageTitleSubtitleLayout)
    {
        [self configureVerticalStackImageTitleSubtitleLayout];
    }
    else
    {
        NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
        if (_imageView.hidden)
        {
            NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
            paragraphStyle.alignment = NSTextAlignmentCenter;
            attributes[NSParagraphStyleAttributeName] = paragraphStyle;
        }
        else
        {
            NSMutableParagraphStyle *ps = [NSMutableParagraphStyle new];
            ps.firstLineHeadIndent = 2.0;
            ps.tailIndent = -2.0;
            attributes[NSParagraphStyleAttributeName] = ps;
        }
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[self combine:_text subtext:_subtext] attributes:attributes];

        NSRange valueRange = NSMakeRange(0, _text.length);
        NSRange unitRange = NSMakeRange(_text.length + 1, _subtext.length);
        
        if (valueRange.length > 0)
        {
            [string addAttribute:NSFontAttributeName value:_primaryFont range:valueRange];
            [string addAttribute:NSForegroundColorAttributeName value:_primaryColor range:valueRange];
        }
        if (unitRange.length > 0)
        {
            [string addAttribute:NSFontAttributeName value:_unitsFont range:unitRange];
            [string addAttribute:NSForegroundColorAttributeName value:_unitsColor range:unitRange];
        }
        
        if (_primaryOutlineColor && _textOutlineWidth > 0)
        {
            _textView.outlineColor = _primaryOutlineColor;
            _textView.outlineWidth = _textOutlineWidth;
        }
        else
        {
            _textView.outlineColor = nil;
            _textView.outlineWidth = 0.0;
        }
        
        _textView.attributedText = string;
        _shadowButton.accessibilityValue = string.string;
        
    }
    [self refreshLayout];
}

- (void)refreshLayout
{
    if (self.delegate)
        [self.delegate widgetChanged:self];
}

- (void) addAccessibilityLabelsWithValue:(NSString *)value
{
    // override point
}

- (CGFloat) getWidgetHeight
{
    return self.frame.size.height;
}

- (void) adjustViewSize
{
    if (self.isSimpleLayout || self.isVerticalStackImageTitleSubtitleLayout)
        return;
    CGFloat leadingOffset = _imageView.hidden ? 3 : 39;
    _leadingTextAnchor.constant = leadingOffset;
    
    [_textView sizeToFit];
    
    CGRect tf = _textView.frame;
    
    CGFloat currentWidth = MAX(tf.size.width, _imageView.hidden ? fullTextWidth : minTextWidth);
    // TODO: need a more flexible solution for OAUtilities.isLandscapeIpadAware (topWidgetsViewWidthConstraint.constant)
    CGFloat widthLimit = [[OARootViewController instance].mapPanel hasTopWidget] ? 120 : [UIScreen mainScreen].bounds.size.width / 2 - 40;
    tf.size.width = currentWidth > widthLimit ? widthLimit : currentWidth;

    CGRect f = self.frame;
    f.size.width = leadingOffset + tf.size.width + 4 + 10;
    CGFloat topBottomOffset = 10;
    CGFloat height = tf.size.height + topBottomOffset;
    if (UIScreen.mainScreen.traitCollection.preferredContentSizeCategory <= UIContentSizeCategoryLarge) {
        f.size.height = minWidgetHeight;
    }
    else
    {
        f.size.height = height < minWidgetHeight ? minWidgetHeight : height;
    }
    
    self.frame = f;
}

- (BOOL) updateVisibility:(BOOL)visible
{
    if (visible == self.hidden)
    {
        self.hidden = !visible;
        if (self.delegate)
            [self.delegate widgetVisibilityChanged:self visible:visible];
        
        return YES;
    }
    return NO;
}

- (BOOL) isVisible
{
    return !self.hidden && self.superview;
}

- (BOOL) updateInfo
{
    if (self.updateInfoFunction)
        return self.updateInfoFunction();
    else
        return NO;
}

- (BOOL) isUpdateNeeded
{
    BOOL res = NO;
    
    if ([self isMetricSystemDepended])
    {
        int metricSystem = (int)[[OAAppSettings sharedManager].metricSystem get];
        res |= _cachedMetricSystem != metricSystem;
        _cachedMetricSystem = metricSystem;
    }
    if ([self isAngularUnitsDepended])
    {
        int angularUnits = (int)[[OAAppSettings sharedManager].angularUnits get];
        res |= _cachedAngularUnits != angularUnits;
        _cachedAngularUnits = angularUnits;
    }
    return res;
}

- (BOOL) isMetricSystemDepended
{
    return _metricSystemDepended;
}

- (BOOL) isAngularUnitsDepended
{
    return _angularUnitsDepended;
}

- (void) setMetricSystemDepended:(BOOL)newValue
{
    _metricSystemDepended = newValue;
}

- (void) setAngularUnitsDepended:(BOOL)newValue
{
    _angularUnitsDepended = newValue;
}

- (void) setExplicitlyVisible:(BOOL)explicitlyVisible
{
    _explicitlyVisible = explicitlyVisible;
}

- (BOOL) isExplicitlyVisible
{
    return _explicitlyVisible;
}

- (void) setTimeText:(NSTimeInterval)time
{
    int hours, minutes, seconds;
    [OAUtilities getHMS:time hours:&hours minutes:&minutes seconds:&seconds];
    NSString *timeStr = [NSString stringWithFormat:@"%d:%02d", hours, minutes];
    [self setText:timeStr subtext:nil];
}

- (void)setNightMode:(BOOL)night
{
    _isNight = night;
}

- (void)updateIcon
{
    _imageView.overrideUserInterfaceStyle = _isNight ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
    if (_icon)
        [self setImage:[UIImage imageNamed:_icon]];
}

- (void)updateTextWitState:(OATextState *)state
{
    if (state.textBold)
    {
        _primaryFont = _largeBoldFont;
        _unitsFont = _smallBoldFont;
    }
    else
    {
        _primaryFont = _largeFont;
        _unitsFont = _smallFont;
    }
    
    _primaryColor = state.textColor;
    _unitsColor = self.isSimpleLayout ? state.unitColor : state.textColor;
    _primaryOutlineColor = state.textOutlineColor;
    _unitsShadowColor = state.textOutlineColor;
    _textOutlineWidth = state.textOutlineWidth;
    _contentTitleColor = state.titleColor;
    
    [self updatesSeparatorsColor:state.dividerColor];
    [self refreshLabel];
}

- (OATableDataModel *_Nullable)getSettingsDataForSimpleWidget:(OAApplicationMode * _Nonnull)appMode
{
    OATableDataModel *data = [[OATableDataModel alloc] init];
    OATableSectionData *section = [data createNewSection];
    section.footerText = OALocalizedString(@"simple_widget_footer");
    
    OATableRowData *widgetStyleRow = section.createNewRow;
    widgetStyleRow.cellType = SegmentImagesWithRightLabelTableViewCell.getCellIdentifier;
    widgetStyleRow.title = OALocalizedString(@"shared_string_height");
    [widgetStyleRow setObj:self.widgetSizePref forKey:@"prefSegment"];
    [widgetStyleRow setObj:@"simpleWidget" forKey:@"behaviour"];
    [widgetStyleRow setObj:@[[UIImage imageNamed:ACImageNameIcCustom20HeightS],
                             [UIImage imageNamed:ACImageNameIcCustom20HeightM],
                             [UIImage imageNamed:ACImageNameIcCustom20HeightL]]
                    forKey:@"values"];
    
    OATableRowData *showIconRow = section.createNewRow;
    showIconRow.cellType = OASwitchTableViewCell.getCellIdentifier;
    showIconRow.title = OALocalizedString(@"show_icon");
    [showIconRow setObj:_showIconPref forKey:@"pref"];

    return data;
}

- (void)configurePrefsWithId:(NSString *)id appMode:(OAApplicationMode *)appMode widgetParams:(NSDictionary * _Nullable)widgetParams
{
    _appMode = appMode;
    _customId = id;
    _showIconPref = [self registerShowIconPref:id];
    self.widgetSizePref = [self registerWidgetSizePref:id];
    
    if (widgetParams)
    {
        OAApplicationMode *selectedAppMode = (OAApplicationMode *)widgetParams[@"selectedAppMode"];
        if (selectedAppMode)
        {
            NSNumber *widgetSizeStyle = widgetParams[@"widgetSizeStyle"];
            if (widgetSizeStyle)
                [self.widgetSizePref set:(EOAWidgetSizeStyle) [widgetSizeStyle integerValue] mode:selectedAppMode];
            NSNumber *isVisibleIconNumber = widgetParams[@"isVisibleIcon"];
            if (isVisibleIconNumber)
            {
                BOOL isVisibleIcon = [isVisibleIconNumber boolValue];
                [_showIconPref set:isVisibleIcon mode:selectedAppMode];
            }
        }
    }
}

- (OAWidgetsPanel *)getWidgetPanel
{
    OAMapWidgetInfo *widgetInfo = [[OAMapWidgetRegistry sharedInstance] getWidgetInfoById:_customId];
    return widgetInfo.widgetPanel;
}

- (OACommonWidgetSizeStyle *)registerWidgetSizePref:(NSString *)customId
{
    NSString *prefId = [kSizeStylePref stringByAppendingString:self.widgetType.id];
    if (customId && customId.length > 0)
        prefId = [prefId stringByAppendingString:customId];
    return [[OAAppSettings sharedManager] registerWidgetSizeStylePreference:prefId defValue:EOAWidgetSizeStyleMedium];
}

- (OACommonBoolean *)registerShowIconPref:(NSString *)customId
{
    NSString *prefId = [kShowIconPref stringByAppendingString:self.widgetType.id];
    if (customId && customId.length > 0)
        prefId = [prefId stringByAppendingString:customId];
    return [[OAAppSettings sharedManager] registerBooleanPreference:prefId defValue:YES];
}

- (OAApplicationMode *)getAppMode
{
    return _appMode;
}

@end
