//
//  OAHUDButton.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/30/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAHUDButton.h"

#define _(name) OAHUDButton__##name

@implementation OAHUDButton

- (void)setHighlighted:(BOOL)highlighted
{
    [super setHighlighted:highlighted];

    [self updateAppearance];
}

- (void)setTintColor:(UIColor *)tintColor
{
    [super setTintColor:tintColor];

    [self updateAppearance];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [self updateAppearance];
}

- (void)updateAppearance
{
    self.layer.cornerRadius = 3.0f;
    self.layer.borderWidth = 0.5f;
    self.layer.borderColor = [OAHUDButton borderColor].CGColor;
    self.layer.backgroundColor = [OAHUDButton backgroundColor].CGColor;
    self.clipsToBounds = YES;
}

+ (UIColor*)backgroundColor
{
    return [UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.9f];
}

+ (UIColor*)borderColor
{
    return [UIColor colorWithRed:0.6f green:0.6f blue:0.6f alpha:0.9f];
}

@end
