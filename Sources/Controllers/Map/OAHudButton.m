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

@implementation OAHudButton

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

- (void) commonInit
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

- (void) updateColorsForPressedState:(BOOL)isPressed
{
    BOOL isNight = [OAAppSettings sharedManager].nightMode;

    if (isPressed)
        self.backgroundColor = isNight ? self.pressedColorNight : self.pressedColorDay;
    else
        self.backgroundColor = isNight ? self.unpressedColorNight : self.unpressedColorDay;

    self.tintColor = isNight ? self.tintColorNight : self.tintColorDay;
    
    self.layer.borderColor = self.borderColor.CGColor;
    self.layer.borderWidth = isNight ? self.borderWidthNight : self.borderWidthDay;
}

- (IBAction) onButtonTouched:(id)sender
{
    if ([sender isKindOfClass:UIButton.class])
        [self updateColorsForPressedState:YES];
}

- (IBAction) onButtonReleased:(id)sender
{
    if ([sender isKindOfClass:UIButton.class])
        [self updateColorsForPressedState:NO];
}

@end
