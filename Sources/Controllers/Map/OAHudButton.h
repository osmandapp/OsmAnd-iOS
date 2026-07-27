//
//  OAHudButton.h
//  OsmAnd Maps
//
//  Created by nnngrach on 13.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MapButtonState, OASButtonPositionSize, ButtonAppearanceParams;

NS_ASSUME_NONNULL_BEGIN

@interface OAHudButton : UIButton

@property (nonatomic) UIColor *unpressedColorDay;
@property (nonatomic) UIColor *unpressedColorNight;
@property (nonatomic) UIColor *pressedColorDay;
@property (nonatomic) UIColor *pressedColorNight;

@property (nonatomic) UIColor *tintColorDay;
@property (nonatomic) UIColor *tintColorNight;

@property (nonatomic) UIColor *borderColor;

@property (nonatomic) CGFloat borderWidthDay;
@property (nonatomic) CGFloat borderWidthNight;

@property (nonatomic, strong, nullable) MapButtonState *buttonState;
@property (nonatomic, assign) BOOL useCustomPosition;
@property (nonatomic, assign) BOOL useDefaultAppearance;

- (void)updateColorsForPressedState:(BOOL)isPressed;
- (void)updatePositions;
- (void)setUseCustomPosition:(BOOL)useCustomPosition;
- (void)setUseDefaultAppearance:(BOOL)useDefaultAppearance;
- (void)savePosition;
- (void)setCustomAppearanceParams:(nullable ButtonAppearanceParams *)appearanceParams;
- (nullable OASButtonPositionSize *)getDefaultPositionSize;

@end

NS_ASSUME_NONNULL_END
