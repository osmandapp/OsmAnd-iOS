//
//  OAHudButton.h
//  OsmAnd Maps
//
//  Created by nnngrach on 13.07.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAHudButton : UIButton

@property (nonatomic) UIColor *unpressedColorDay;
@property (nonatomic) UIColor *unpressedColorNight;
@property (nonatomic) UIColor *pressedColorDay;
@property (nonatomic) UIColor *pressedColorNight;

@property (nonatomic) UIColor *tintColorDay;
@property (nonatomic) UIColor *tintColorNight;

@property (nonatomic) UIColor *borderColor;

- (void) updateColorsForPressedState:(BOOL)isPressed;

@end
