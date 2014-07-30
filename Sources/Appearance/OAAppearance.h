//
//  OAAppearance.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/30/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "OAAppearanceProtocol.h"

@interface OAAppearance : NSObject

- (UIImage*)hudRoundButtonBackgroundForButton:(UIButton*)button;
- (UIImage*)hudButtonBackgroundForStyle:(OAButtonStyle)style;

+ (UIImage*)drawRoundBackgroundForHudButtonWithRadius:(CGFloat)radius
                                         andFillColor:(UIColor*)fillColor
                                       andBorderColor:(UIColor*)borderColor;

+ (UIImage*)drawHudButtonBackgroundForStyle:(OAButtonStyle)style
                              withFillColor:(UIColor*)fillColor
                             andBorderColor:(UIColor*)borderColor;

@end
