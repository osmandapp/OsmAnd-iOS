//
//  OAHudButton.m
//  OsmAnd Maps
//
//  Created by nnngrach on 13.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OAHudButton.h"
#import "OAAppSettings.h"
#import "OAColors.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"

@implementation OAHudButton
{
    NSInteger _id;
    ButtonAppearanceParams *_appearanceParams;
    ButtonAppearanceParams *_customAppearanceParams;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.unpressedColorDay = [UIColor colorNamed:ACColorNameMapButtonBgColorDefault].light;
    self.unpressedColorNight = [UIColor colorNamed:ACColorNameMapButtonBgColorDefault].dark;
    self.pressedColorDay = UIColorFromRGB(color_on_map_icon_background_color_tap_light);
    self.pressedColorNight = UIColorFromRGB(color_on_map_icon_background_color_tap_dark);
    self.tintColorDay = [UIColor colorNamed:ACColorNameMapButtonIconColorDefault].light;
    self.tintColorNight = [UIColor colorNamed:ACColorNameMapButtonIconColorDefault].dark;
    self.borderColor = UIColorFromRGB(color_on_map_icon_border_color);
    self.borderWidthDay = 0;
    self.borderWidthNight = 2;
    
    [self updateColorsForPressedState:NO];
    self.layer.cornerRadius = self.frame.size.width / 2;
    self.layer.shadowOpacity = 0.35;
    self.layer.shadowRadius = 5;
    self.layer.shadowOffset = CGSizeMake(0, 2);
    
    [self addTarget:self action:@selector(onButtonTouched:) forControlEvents:UIControlEventTouchDown];
    [self addTarget:self action:@selector(onButtonReleased:) forControlEvents:UIControlEventTouchUpInside];
    [self addTarget:self action:@selector(onButtonReleased:) forControlEvents:UIControlEventTouchUpOutside];
    [self addTarget:self action:@selector(onButtonReleased:) forControlEvents:UIControlEventTouchCancel];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if (@available(iOS 26.0, *))
    {
        for (UIView *subview in self.subviews)
        {
            if ([subview isKindOfClass:UIVisualEffectView.class] && subview != self.subviews.firstObject)
                [self sendSubviewToBack:subview];
        }
    }
}

- (void)updateColorsForPressedState:(BOOL)isPressed
{
    BOOL isNight = [OAAppSettings sharedManager].nightMode;

    if (isPressed)
        self.backgroundColor = isNight ? self.pressedColorNight : self.pressedColorDay;
    else
        self.backgroundColor = isNight ? self.unpressedColorNight : self.unpressedColorDay;
    
    [self updateBackground];

    self.tintColor = isNight ? self.tintColorNight : self.tintColorDay;
    
    self.layer.borderColor = self.borderColor.CGColor;
    self.layer.borderWidth = isNight ? self.borderWidthNight : self.borderWidthDay;
}

- (void)setButtonState:(MapButtonState *)buttonState
{
    _buttonState = buttonState;
    [self updatePositions];
}

- (ButtonAppearanceParams *)createDefaultAppearanceParams
{
    return [[ButtonAppearanceParams alloc] initWithIconName:@"ic_custom_quick_action" size:MapButtonState.defaultSizeDp opacity:MapButtonState.opaqueAlpha cornerRadius:MapButtonState.roundRadiusDp glassStyle:MapButtonState.defaultGlassStyle];
}

- (void)setCustomAppearanceParams:(ButtonAppearanceParams *)customAppearanceParams
{
    _customAppearanceParams = customAppearanceParams;
    [self updateContent];
}

- (void)updateContent
{
    ButtonAppearanceParams *params = [self getAppearanceParams];
    if (params != _appearanceParams)
        _appearanceParams = params;
    [self updateIcon];
    [self updateBackground];
    [self updateCornerRadius];
    [self updateSize];
    [self updateShadow];
}

- (void)updateIcon
{
    NSString *iconName = _customAppearanceParams != nil ? _customAppearanceParams.iconName : nil;
    
    UIImage *image;
    if (iconName.length > 0 && ![_customAppearanceParams.iconName isEqualToString:[self createDefaultAppearanceParams].iconName])
    {
        image = [UIImage imageNamed:iconName];
        if (!image)
            image = [OAUtilities getMxIcon:[iconName lowercaseString]];
    }
    else if (_buttonState)
    {
        image = _customAppearanceParams != nil && iconName.length == 0 ? [UIImage imageNamed:[_buttonState defaultPreviewIconName]] : [_buttonState previewIcon];
    }
    else
    {
        image = [UIImage imageNamed:[self createDefaultAppearanceParams].iconName];
    }
    [self setImage:image forState:UIControlStateNormal];
}

- (void)updateBackground
{
    if (@available(iOS 26.0, *))
    {
        NSInteger glassStyle = [self getGlassStyle];
        BOOL isGlass = glassStyle == UIGlassEffectStyleRegular || glassStyle == UIGlassEffectStyleClear;
        
        for (UIView *subview in self.subviews)
        {
            if ([subview isKindOfClass:UIVisualEffectView.class])
                [subview removeFromSuperview];
        }
        
        if (isGlass)
        {
            UIGlassEffect *glass = [UIGlassEffect effectWithStyle:UIGlassEffectStyleClear];
            if (glassStyle == UIGlassEffectStyleRegular)
                glass.tintColor = self.backgroundColor;
            UIVisualEffectView *glassView =
                [[UIVisualEffectView alloc] initWithEffect:glass];
            glassView.frame = self.bounds;
            glassView.userInteractionEnabled = NO;
            glassView.layer.cornerRadius = [self getCornerRadius];
            glassView.overrideUserInterfaceStyle = [OAAppSettings sharedManager].nightMode ? UIUserInterfaceStyleDark : UIUserInterfaceStyleLight;
            
            [self insertSubview:glassView atIndex:0];
        }
        
        self.backgroundColor = [self.backgroundColor colorWithAlphaComponent:isGlass ? 0.5 : [self getOpacity]];
    }
    else
    {
        self.backgroundColor = [self.backgroundColor colorWithAlphaComponent:[self getOpacity]];
    }
}

- (void)updateCornerRadius
{
    self.layer.cornerRadius = [self getCornerRadius];
}

- (void)updateShadow
{
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds cornerRadius:self.layer.cornerRadius];
    self.layer.shadowPath = shadowPath.CGPath;
}

- (void)updateSize
{
    CGFloat size = (CGFloat)[self getSize];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, size, size);
}

- (NSInteger)getSize
{
    if (_customAppearanceParams)
    {
        NSInteger size = _customAppearanceParams.size;
        if (size == MapButtonState.originalValue)
            return _buttonState ? _buttonState.defaultSize : [self createDefaultAppearanceParams].size;
        return size;
    }

    ButtonAppearanceParams *params = _appearanceParams ? _appearanceParams : [self getAppearanceParams];
    return params.size;
}

- (CGFloat)getOpacity
{
    if (_customAppearanceParams)
    {
        CGFloat opacity = _customAppearanceParams.opacity;
        if (opacity == MapButtonState.originalValue)
            return _buttonState ? _buttonState.defaultOpacity : [self createDefaultAppearanceParams].opacity;
        return opacity;
    }
    
    ButtonAppearanceParams *params = _appearanceParams ? _appearanceParams : [self getAppearanceParams];
    return params.opacity;
}

- (NSInteger)getCornerRadius
{
    NSInteger circleRadius = [self getSize] / 2;
    if (_customAppearanceParams)
    {
        NSInteger cornerRadius = _customAppearanceParams.cornerRadius;
        if (cornerRadius == MapButtonState.originalValue)
        {
            NSInteger defaultCornerRadius = _buttonState ? _buttonState.defaultCornerRadius : [self createDefaultAppearanceParams].cornerRadius;
            return defaultCornerRadius > circleRadius ? circleRadius : defaultCornerRadius;
        }
            
        return cornerRadius > circleRadius ? circleRadius : cornerRadius;
    }
    ButtonAppearanceParams *params = _appearanceParams ? _appearanceParams : [self getAppearanceParams];
    return params.cornerRadius > circleRadius ? circleRadius : params.cornerRadius;
}

- (NSInteger)getGlassStyle
{
    if (_customAppearanceParams)
    {
        CGFloat glassStyle = _customAppearanceParams.glassStyle;
        if (glassStyle == MapButtonState.originalValue)
            return _buttonState ? _buttonState.defaultGlassStyle : [self createDefaultAppearanceParams].glassStyle;
        return glassStyle;
    }
    
    ButtonAppearanceParams *params = _appearanceParams ? _appearanceParams : [self getAppearanceParams];
    return params.glassStyle;
}

- (void)updatePositions
{
    [_buttonState updatePositions];
}

- (void)setUseCustomPosition:(BOOL)useCustomPosition
{
    _useCustomPosition = useCustomPosition;
    if (_buttonState && _useCustomPosition)
        [self updatePositions];
}

- (void)setUseDefaultAppearance:(BOOL)useDefaultAppearance
{
    _useDefaultAppearance = useDefaultAppearance;
}

- (void)savePosition
{
    if (_buttonState && _useCustomPosition)
        [self.buttonState savePosition];
}

- (nullable OASButtonPositionSize *)getDefaultPositionSize
{
    return _buttonState ? [_buttonState getDefaultPositionSize] : nil;
}

- (ButtonAppearanceParams *)getAppearanceParams
{
    if (_buttonState)
        return _useDefaultAppearance ? [_buttonState createDefaultAppearanceParams] : [_buttonState createAppearanceParams];
    return [self createDefaultAppearanceParams];
}

- (IBAction)onButtonTouched:(id)sender
{
    if ([sender isKindOfClass:UIButton.class])
        [self updateColorsForPressedState:YES];
}

- (IBAction)onButtonReleased:(id)sender
{
    if ([sender isKindOfClass:UIButton.class])
        [self updateColorsForPressedState:NO];
}

@end
