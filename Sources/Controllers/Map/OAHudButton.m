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
    self.unpressedColorDay = UIColorFromRGB(color_on_map_icon_background_color_light);
    self.unpressedColorNight = UIColorFromRGB(color_on_map_icon_background_color_dark);
    self.pressedColorDay = UIColorFromRGB(color_on_map_icon_background_color_tap_light);
    self.pressedColorNight = UIColorFromRGB(color_on_map_icon_background_color_tap_dark);
    self.tintColorDay = UIColorFromRGB(color_on_map_icon_tint_color_light);
    self.tintColorNight = UIColorFromRGB(color_on_map_icon_tint_color_dark);
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

- (void)updateColorsForPressedState:(BOOL)isPressed
{
    BOOL isNight = [OAAppSettings sharedManager].nightMode;

    if (isPressed)
        self.backgroundColor = isNight ? self.pressedColorNight : self.pressedColorDay;
    else
        self.backgroundColor = isNight ? self.unpressedColorNight : self.unpressedColorDay;
    self.backgroundColor = [self.backgroundColor colorWithAlphaComponent:[self getOpacity]];

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
    return [[ButtonAppearanceParams alloc] initWithIconName:@"ic_custom_quick_action" size:MapButtonState.defaultSizeDp opacity:MapButtonState.opaqueAlpha cornerRadius:MapButtonState.roundRadiusDp];
}

- (void)setCustomAppearanceParams:(ButtonAppearanceParams *)customAppearanceParams
{
    _customAppearanceParams = customAppearanceParams;
    [self updateContent];
}

- (void)updateContent
{
    [self updateIcon];
    [self updateBackground];
    [self updateCornerRadius];
    [self updateSize];
    [self updateShadow];
}

- (void)updateIcon
{
    NSString *iconName = _customAppearanceParams != nil ? _customAppearanceParams.iconName : nil;
    if (iconName == nil || iconName.length == 0)
        iconName = [self createDefaultAppearanceParams].iconName;
    
    UIImage *image;
    if (_buttonState)
        image = [_buttonState getPreviewIcon];
    else
        image = [UIImage imageNamed:iconName];
    [self setImage:image forState:UIControlStateNormal];
}

- (void)updateBackground
{
    self.backgroundColor = [[UIColor colorNamed:ACColorNameMapButtonBgColorDefault] colorWithAlphaComponent:[self getOpacity]];
}

- (void)updateCornerRadius
{
    self.layer.cornerRadius = [self getCornerRadius];
}

- (void)updateShadow
{
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                          cornerRadius:self.layer.cornerRadius];
    self.layer.shadowPath = shadowPath.CGPath;
}

- (void)updateSize
{
    CGFloat size = (CGFloat)[self getSize];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, size, size);
}

- (NSInteger)getSize
{
    NSInteger buttonStateSize = [self createDefaultAppearanceParams].size;
    if (_buttonState)
    {
        float size = [[_buttonState storedSizePref] get];
        buttonStateSize = size != MapButtonState.originalValue ? size : [_buttonState defaultSize];
    }
    if (_customAppearanceParams)
    {
        NSInteger size = _customAppearanceParams.size;
        return size == MapButtonState.originalValue ? buttonStateSize : size;
    }

    return buttonStateSize;
}

- (CGFloat)getOpacity
{
    float buttonStateOpacity = [self createDefaultAppearanceParams].opacity;
    if (_buttonState)
    {
        float opacity = [[_buttonState storedOpacityPref] get];
        buttonStateOpacity = opacity != MapButtonState.originalValue ? opacity : [_buttonState defaultOpacity];
    }
    if (_customAppearanceParams)
    {
        CGFloat opacity = _customAppearanceParams.opacity;
        return opacity == MapButtonState.originalValue ? buttonStateOpacity : opacity;
    }

    return buttonStateOpacity;
}

- (NSInteger)getCornerRadius
{
    NSInteger circleRadius = [self getSize] / 2;
    NSInteger buttonStateCornerRadius = [self createDefaultAppearanceParams].cornerRadius;
    if (_buttonState)
    {
        NSInteger cornerRadius = [[_buttonState storedCornerRadiusPref] get];
        buttonStateCornerRadius = cornerRadius != MapButtonState.originalValue ? cornerRadius : [_buttonState defaultCornerRadius];
    }
    if (_customAppearanceParams)
    {
        NSInteger cornerRadius = _customAppearanceParams.cornerRadius;
        if (cornerRadius == MapButtonState.originalValue)
            return buttonStateCornerRadius > circleRadius ? circleRadius : buttonStateCornerRadius;
        return cornerRadius > circleRadius ? circleRadius : cornerRadius;
    }
    return buttonStateCornerRadius > circleRadius ? circleRadius : buttonStateCornerRadius;
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

- (void)savePosition
{
    if (_buttonState && _useCustomPosition)
        [self.buttonState savePosition];
}

- (nullable OASButtonPositionSize *)getDefaultPositionSize
{
    return _buttonState ? [_buttonState getDefaultPositionSize] : nil;
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
