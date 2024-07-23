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

- (UIImage*)hudViewRoundBackgroundWithRadius:(CGFloat)radius;
- (UIImage*)hudViewBackgroundForStyle:(OAHudViewStyle)style;

- (UIColor*)hudViewBackgroundColor;
- (UIColor*)hudViewBorderColor;

+ (UIImage*)drawRoundBackgroundForHudViewWithRadius:(CGFloat)radius
                                       andFillColor:(UIColor*)fillColor
                                     andBorderColor:(UIColor*)borderColor;

+ (UIImage*)drawHudViewBackgroundForStyle:(OAHudViewStyle)style
                            withFillColor:(UIColor*)fillColor
                           andBorderColor:(UIColor*)borderColor;

@end
