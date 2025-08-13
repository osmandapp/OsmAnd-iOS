//
//  OAHudButton.h
//  OsmAnd Maps
//
//  Created by nnngrach on 13.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MapButtonState, OASButtonPositionSize;

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

- (void) updateColorsForPressedState:(BOOL)isPressed;
- (void) updatePositions;
- (void) setUseCustomPosition:(BOOL)useCustomPosition;
- (void) savePosition;
- (nullable OASButtonPositionSize *) getDefaultPositionSize;

@end
