//
//  OATextInfoWidget.m
//  OsmAnd
//
//  Created by Alexey Kulish on 30/09/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATextInfoWidget.h"
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
#define minWidgetHeight 32

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
    OACommonBoolean *_hideIconPref;
    OAApplicationMode *_appMode;
    NSLayoutConstraint *_unitOrEmptyLabelWidthConstraint;
    UIStackView *_contentStackViewSimpleWidget;
    UIStackView *_contentUnitStackViewSimpleWidget;
    NSLayoutConstraint *_verticalStackViewSimpleWidgetTopConstraint;
    NSLayoutConstraint *_verticalStackViewSimpleWidgetBottomConstraint;
    UIColor *_iconColor;
}

NSString *const kHideIconPref = @"kHideIconPref";
NSString *const kSizeStylePref = @"kSizeStylePref";

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

- (void)updateSimpleLayout
{
    NSArray *viewsToRemove = [self subviews];
    for (UIView *v in viewsToRemove) {
        [v removeFromSuperview];
    }
    [self initSeparatorsView];
    
    UIStackView *verticalStackView = [UIStackView new];
    verticalStackView.translatesAutoresizingMaskIntoConstraints = NO;
    verticalStackView.axis = UILayoutConstraintAxisVertical;
    verticalStackView.alignment = UIStackViewAlignmentFill;
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
    
    self.topNameUnitStackView.hidden = self.widgetSizeStyle == WidgetSizeStyleSmall;
    
    auto nameView = [UIView new];
    nameView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.topNameUnitStackView addArrangedSubview:nameView];
    [NSLayoutConstraint activateConstraints:@[
        [nameView.heightAnchor constraintGreaterThanOrEqualToConstant:11]
    ]];
    
    // Create the name label ("SPEED")
    self.nameLabel = [UILabel new];
    self.nameLabel.text = [_contentTitle upperCase];
    
    self.nameLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.nameLabel.font = [UIFont scaledSystemFontOfSize:[WidgetSizeStyleObjWrapper getLabelFontSizeForType:self.widgetSizeStyle] weight:UIFontWeightRegular];
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
        [self.unitView.heightAnchor constraintGreaterThanOrEqualToConstant:11],
        [self.unitView.widthAnchor constraintGreaterThanOrEqualToConstant:20]
    ]];
    self.unitView.hidden = _subtext.length == 0;
    
    // Create the unit label ("KM/H")
    self.unitLabel = [UILabel new];
    self.unitLabel.text = [_subtext upperCase];
    self.unitLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.unitLabel.font = [UIFont scaledSystemFontOfSize:[WidgetSizeStyleObjWrapper getUnitsFontSizeForType:self.widgetSizeStyle] weight:UIFontWeightRegular];
    self.unitLabel.textAlignment = NSTextAlignmentRight;
    self.unitLabel.textColor = [UIColor colorNamed:ACColorNameWidgetUnitsColor];
    [self.unitView addSubview:self.unitLabel];
    
    [NSLayoutConstraint activateConstraints:@[
        [self.unitLabel.topAnchor constraintEqualToAnchor:self.unitView.topAnchor],
        [self.unitLabel.leadingAnchor constraintEqualToAnchor:self.unitView.leadingAnchor],
        [self.unitLabel.trailingAnchor constraintEqualToAnchor:self.unitView.trailingAnchor],
        [self.unitLabel.bottomAnchor constraintEqualToAnchor:self.unitView.bottomAnchor],
        [self.unitLabel.widthAnchor constraintGreaterThanOrEqualToConstant:20]
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
    self.valueLabel.text = _text;
    self.valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.valueLabel.adjustsFontSizeToFitWidth = YES;
    self.valueLabel.minimumScaleFactor = 0.3;
    self.valueLabel.textColor = [UIColor colorNamed:ACColorNameWidgetValueColor];
    [valueUnitOrEmptyView addSubview:self.valueLabel];
    
    _contentUnitStackViewSimpleWidget = [UIStackView new];
    _contentUnitStackViewSimpleWidget.translatesAutoresizingMaskIntoConstraints = NO;
    _contentUnitStackViewSimpleWidget.axis = UILayoutConstraintAxisVertical;
    _contentUnitStackViewSimpleWidget.alignment = UIStackViewAlignmentFill;
    _contentUnitStackViewSimpleWidget.distribution = UIStackViewDistributionEqualCentering;
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
        [self.valueLabel.heightAnchor constraintGreaterThanOrEqualToConstant:30]
    ]];
    
    [NSLayoutConstraint activateConstraints:@[
        [_contentUnitStackViewSimpleWidget.topAnchor constraintEqualToAnchor:valueUnitOrEmptyView.topAnchor],
        [_contentUnitStackViewSimpleWidget.leadingAnchor constraintEqualToAnchor:self.valueLabel.trailingAnchor],
        [_contentUnitStackViewSimpleWidget.trailingAnchor constraintEqualToAnchor:valueUnitOrEmptyView.trailingAnchor],
        [_contentUnitStackViewSimpleWidget.bottomAnchor constraintEqualToAnchor:valueUnitOrEmptyView.bottomAnchor],
        [_contentUnitStackViewSimpleWidget.heightAnchor constraintGreaterThanOrEqualToConstant:30],
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
        [_textView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-5],
        [_textView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
    ]];
    self.topTextAnchor = [_textView.topAnchor constraintEqualToAnchor:self.topAnchor constant:5];
    self.topTextAnchor.active = YES;
    
    _leadingTextAnchor = [_textView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:3];
    _leadingTextAnchor.active = YES;
    
    [NSLayoutConstraint activateConstraints:@[
        [_textShadowView.topAnchor constraintEqualToAnchor:_textView.topAnchor],
        [_textShadowView.bottomAnchor constraintEqualToAnchor:_textView.bottomAnchor],
        [_textShadowView.trailingAnchor constraintEqualToAnchor:_textView.trailingAnchor],
        [_textShadowView.leadingAnchor constraintEqualToAnchor:_textView.leadingAnchor]
    ]];

    _largeFont = [UIFont scaledSystemFontOfSize:21 weight:UIFontWeightSemibold];
    _largeBoldFont = [UIFont scaledSystemFontOfSize:21 weight:UIFontWeightBold];
    _primaryFont = _largeFont;
    _primaryColor = [UIColor blackColor];
    _smallFont = [UIFont scaledSystemFontOfSize:14 weight:UIFontWeightSemibold];
    _smallBoldFont = [UIFont scaledSystemFontOfSize:14 weight:UIFontWeightBold];
    _unitsFont = _smallFont;
    _unitsColor = [UIColor grayColor];
    _primaryShadowColor = nil;
    _unitsShadowColor = nil;
    _shadowRadius = 0;
    
    _text = @"";
    _subtext = @"";
    _textShadowView.textAlignment = NSTextAlignmentNatural;
    _textView.textAlignment = NSTextAlignmentNatural;
}

- (void)commonInit
{
    _textView = [[UILabel alloc] init];
    _textView.adjustsFontForContentSizeCategory = YES;
    _textView.translatesAutoresizingMaskIntoConstraints = NO;
    _imageView = [UIImageView new];
    _imageView.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:_textView];
    [self addSubview:_imageView];
    
    _textShadowView = [[UILabel alloc] init];
    _textShadowView.adjustsFontForContentSizeCategory = YES;
    _textShadowView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_textShadowView];
    
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
            self.valueLabel.text = @"";
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

- (void)configureSimpleLayout
{
    self.nameLabel.font = [UIFont scaledSystemFontOfSize:[WidgetSizeStyleObjWrapper getLabelFontSizeForType:self.widgetSizeStyle] weight:UIFontWeightRegular];
    self.nameLabel.textColor = _contentTitleColor;
    
    self.valueLabel.font = [UIFont scaledSystemFontOfSize:[WidgetSizeStyleObjWrapper getValueFontSizeForType:self.widgetSizeStyle] weight:UIFontWeightRegular];
    self.valueLabel.textColor = _primaryColor;
    
    self.unitLabel.font = [UIFont scaledSystemFontOfSize:[WidgetSizeStyleObjWrapper getUnitsFontSizeForType:self.widgetSizeStyle] weight:UIFontWeightRegular];
    self.unitLabel.textColor = _unitsColor;
    
    self.unitOrEmptyLabel.font = [UIFont scaledSystemFontOfSize:[WidgetSizeStyleObjWrapper getUnitsFontSizeForType:self.widgetSizeStyle] weight:UIFontWeightRegular];
    self.unitOrEmptyLabel.textColor = _unitsColor;
    
    
    self.titleOrEmptyLabel.font = [UIFont scaledSystemFontOfSize:[WidgetSizeStyleObjWrapper getUnitsFontSizeForType:self.widgetSizeStyle] weight:UIFontWeightRegular];
    self.titleOrEmptyLabel.textColor = _unitsColor;
    
    
    self.valueLabel.text = _text;
    self.nameLabel.text = [_contentTitle upperCase];
    self.topNameUnitStackView.hidden = self.widgetSizeStyle == WidgetSizeStyleSmall;
    
    CGFloat topBottomPadding = [WidgetSizeStyleObjWrapper getTopBottomPaddingWithType:self.widgetSizeStyle];
    _verticalStackViewSimpleWidgetTopConstraint.constant = topBottomPadding;
    _verticalStackViewSimpleWidgetBottomConstraint.constant = -topBottomPadding;
            
    BOOL isVisibleIcon = false;
    if (_appMode && _hideIconPref)
    {
        isVisibleIcon = [_hideIconPref get:_appMode];
        self.iconWidgetView.hidden = !isVisibleIcon;
        _contentStackViewSimpleWidget.spacing = 0;
    }
    _shadowButton.accessibilityValue = [self combine:_text subtext:_subtext];
    if (_subtext.length == 0)
    {
        self.unitView.hidden = YES;
        self.unitOrEmptyLabel.text = @"";
        self.titleOrEmptyLabel.text = @"";
        _unitOrEmptyLabelWidthConstraint.constant = 0;
    }
    else
    {
        _unitOrEmptyLabelWidthConstraint.constant = (self.isFullRow || self.widgetSizeStyle != WidgetSizeStyleSmall) ? 0 : 20;
        if (self.widgetSizeStyle == WidgetSizeStyleSmall)
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
            self.unitLabel.text = [_subtext upperCase];
        }
    }
    
    if (self.isFullRow)
    {
         _contentStackViewSimpleWidget.spacing = 0;
        if (self.widgetSizeStyle == WidgetSizeStyleSmall)
        {
            self.emptyViewRightPlaceholderFullRow.hidden = YES;
            if (_subtext.length == 0)
            {
                self.emptyViewRightPlaceholderFullRow.hidden = !isVisibleIcon;
                self.valueLabel.textAlignment = NSTextAlignmentCenter;
            }
            else
            {
                self.emptyViewRightPlaceholderFullRow.hidden = YES;
                self.valueLabel.textAlignment = NSTextAlignmentNatural;
            }
        } else {
            self.emptyViewRightPlaceholderFullRow.hidden = !isVisibleIcon;
            self.valueLabel.textAlignment = NSTextAlignmentCenter;
        }
    }
    else
    {
        _contentStackViewSimpleWidget.spacing = [WidgetSizeStyleObjWrapper getPaddingBetweenIconAdndValueWithType:self.widgetSizeStyle];
       
        self.valueLabel.textAlignment = NSTextAlignmentNatural;
    }
}

- (void)refreshLabel
{
    if (self.isSimpleLayout)
    {
        [self configureSimpleLayout];
    }
    else
    {
        NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
        if (_imageView.hidden)
        {
            NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
            paragraphStyle.alignment = NSTextAlignmentCenter;
            attributes[NSParagraphStyleAttributeName] = paragraphStyle;
        }
        else
        {
            NSMutableParagraphStyle *ps = [[NSMutableParagraphStyle alloc] init];
            ps.firstLineHeadIndent = 2.0;
            ps.tailIndent = -2.0;
            attributes[NSParagraphStyleAttributeName] = ps;
        }
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:[self combine:_text subtext:_subtext] attributes:attributes];
        NSMutableAttributedString *shadowString = [[NSMutableAttributedString alloc] initWithString:[self combine:_text subtext:_subtext] attributes:attributes];

        NSRange valueRange = NSMakeRange(0, _text.length);
        NSRange unitRange = NSMakeRange(_text.length + 1, _subtext.length);
        
        if (valueRange.length > 0)
        {
            [string addAttribute:NSFontAttributeName value:_primaryFont range:valueRange];
            [string addAttribute:NSForegroundColorAttributeName value:_primaryColor range:valueRange];
            if (_primaryShadowColor && _shadowRadius > 0)
            {
                [shadowString addAttribute:NSFontAttributeName value:_primaryFont range:valueRange];
                [shadowString addAttribute:NSForegroundColorAttributeName value:_primaryColor range:valueRange];
                [shadowString addAttribute:NSStrokeColorAttributeName value:_primaryShadowColor range:valueRange];
                [shadowString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat: -_shadowRadius] range:valueRange];
            }
        }
        if (unitRange.length > 0)
        {
            [string addAttribute:NSFontAttributeName value:_unitsFont range:unitRange];
            [string addAttribute:NSForegroundColorAttributeName value:_unitsColor range:unitRange];
            if (_unitsShadowColor && _shadowRadius > 0)
            {
                [shadowString addAttribute:NSFontAttributeName value:_unitsFont range:unitRange];
                [shadowString addAttribute:NSForegroundColorAttributeName value:_unitsColor range:unitRange];
                [shadowString addAttribute:NSStrokeColorAttributeName value:_unitsShadowColor range:unitRange];
                [shadowString addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat: -_shadowRadius] range:unitRange];
            }
        }
        
        _textShadowView.attributedText = _primaryShadowColor && _shadowRadius > 0 ? shadowString : nil;
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
    if (self.isSimpleLayout)
        return;
    CGFloat leadingOffset = _imageView.hidden ? 4 : 31;
    _leadingTextAnchor.constant = leadingOffset;
    
    [_textView sizeToFit];
    
    CGRect tf = _textView.frame;
    
    CGFloat currentWidth = MAX(tf.size.width, _imageView.hidden ? fullTextWidth : minTextWidth);
    // TODO: need a more flexible solution for OAUtilities.isLandscapeIpadAware (topWidgetsViewWidthConstraint.constant)
    CGFloat widthLimit = [[OARootViewController instance].mapPanel hasTopWidget] ? 120 : [UIScreen mainScreen].bounds.size.width / 2 - 40;
    tf.size.width = currentWidth > widthLimit ? widthLimit : currentWidth;

    CGRect f = self.frame;
    f.size.width = leadingOffset + tf.size.width + 4;
    CGFloat height = tf.size.height + 10;
    f.size.height = height < minWidgetHeight ? minWidgetHeight : height;
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
    _primaryShadowColor = state.textShadowColor;
    _unitsShadowColor = state.textShadowColor;
    _shadowRadius = state.textShadowRadius;
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
    widgetStyleRow.cellType = SegmentImagesWithRightLableTableViewCell.getCellIdentifier;
    widgetStyleRow.title = OALocalizedString(@"shared_string_height");
    [widgetStyleRow setObj:self.sizeStylePref forKey:@"prefSegment"];
    [widgetStyleRow setObj:@"simpleWidget" forKey:@"behaviour"];
    [widgetStyleRow setObj:@[ACImageNameIcCustom20HeightS, ACImageNameIcCustom20HeightM, ACImageNameIcCustom20HeightL] forKey:@"values"];
    
    OATableRowData *showIconRow = section.createNewRow;
    showIconRow.cellType = OASwitchTableViewCell.getCellIdentifier;
    showIconRow.title = OALocalizedString(@"show_icon");
    [showIconRow setObj:_hideIconPref forKey:@"pref"];

    return data;
}

- (void)configurePrefsWithId:(NSString *)id appMode:(OAApplicationMode *)appMode widgetParams:(NSDictionary * _Nullable)widgetParams
{
    _appMode = appMode;
    _hideIconPref = [self registerHideIconPrefWith:id];
    self.sizeStylePref = [self registerSizeStylePrefWith:id];
    
    if (widgetParams)
    {
        OAApplicationMode *selectedAppMode = (OAApplicationMode *)widgetParams[@"selectedAppMode"];
        if (selectedAppMode)
        {
            NSString *widgetSizeStyle = widgetParams[@"widgetSizeStyle"];
            if (widgetSizeStyle)
            {
                [self.sizeStylePref set:[widgetSizeStyle intValue] mode:selectedAppMode];
            }
            NSNumber *isVisibleIconNumber = widgetParams[@"isVisibleIcon"];
            if (isVisibleIconNumber)
            {
                BOOL isVisibleIcon = [isVisibleIconNumber boolValue];
                [_hideIconPref set:isVisibleIcon mode:selectedAppMode];
            }
        }
    }
}

- (OACommonInteger *)registerSizeStylePrefWith:(NSString *)customId
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSString *prefId = self.widgetType.title;
    if (customId.length > 0)
        prefId = [prefId stringByAppendingFormat:@"%@_%@",kSizeStylePref,customId];
    else
        prefId = [prefId stringByAppendingFormat:@"%@",kSizeStylePref];
    
    return [settings registerIntPreference:prefId defValue:WidgetSizeStyleMedium];
}

- (OACommonBoolean *)registerHideIconPrefWith:(NSString *)customId
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSString *prefId = self.widgetType.title;
    if (customId.length > 0)
        prefId = [prefId stringByAppendingFormat:@"%@_%@",kHideIconPref,customId];
    else
        prefId = [prefId stringByAppendingFormat:@"%@",kHideIconPref];
    
    return [settings registerBooleanPreference:prefId defValue:YES];
}

@end
