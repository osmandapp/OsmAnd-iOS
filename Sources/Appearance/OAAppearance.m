//
//  OAAppearance.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 7/30/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAAppearance.h"

#import <Foundation/Foundation.h>

#define kDefaultHudRectangleCornerRadius 1.5f
#define kDefaultHudBorderWidthInPixels 1.0f

@implementation OAAppearance
{
    NSObject* _lock;

    UIImage* _hudRoundButtonBackgroundForButton;
    UIImage* _hudButtonBackgroundsByStyle[4];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [[NSObject alloc] init];
    }
    return self;
}

- (UIImage*)hudRoundButtonBackgroundForButton:(UIButton*)button
{
    @synchronized(_lock)
    {
        if (!_hudRoundButtonBackgroundForButton)
        {
            _hudRoundButtonBackgroundForButton = [OAAppearance drawRoundBackgroundForHudButtonWithRadius:(button.frame.size.width / 2.0f)
                                                                                            andFillColor:[self hudButtonBackgroundColor]
                                                                                          andBorderColor:[self hudButtonBorderColor]];
        }

        return _hudRoundButtonBackgroundForButton;
    }
}

- (UIImage*)hudButtonBackgroundForStyle:(OAButtonStyle)style
{
    @synchronized(_lock)
    {
        UIImage* image = _hudButtonBackgroundsByStyle[style];
        if (!image)
        {
            image = [OAAppearance drawHudButtonBackgroundForStyle:style
                                                    withFillColor:[self hudButtonBackgroundColor]
                                                   andBorderColor:[self hudButtonBorderColor]];

            _hudButtonBackgroundsByStyle[style] = image;
        }

        return image;
    }
}

- (UIColor*)hudButtonBackgroundColor
{
    return[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.9f];
}

- (UIColor*)hudButtonBorderColor
{
    return [UIColor colorWithRed:0.6f green:0.6f blue:0.6f alpha:0.9f];
}

+ (UIImage*)drawRoundBackgroundForHudButtonWithRadius:(CGFloat)radius
                                         andFillColor:(UIColor*)fillColor
                                       andBorderColor:(UIColor*)borderColor
{
    CGRect rect = CGRectMake(0, 0, 2.0f * radius, 2.0f * radius);
    UIGraphicsBeginImageContext(CGSizeMake(rect.size.width, rect.size.height));
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetLineWidth(context, 1.0f);

    CGContextSetFillColorWithColor(context, fillColor.CGColor);
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);

    CGContextFillEllipseInRect(context, rect);
    CGContextStrokeEllipseInRect(context, rect);

    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return result;
}

+ (UIImage*)drawHudButtonBackgroundForStyle:(OAButtonStyle)style
                              withFillColor:(UIColor*)fillColor
                             andBorderColor:(UIColor*)borderColor
{
    CGFloat screenScale = [UIScreen mainScreen].scale;
    CGFloat cornerRadius = kDefaultHudRectangleCornerRadius * screenScale;

    CGRect fullRect = CGRectMake(0, 0,
                                 40.0f, 40.0f);

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(40.0f, 40.0f),
                                           NO,
                                           screenScale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetAllowsAntialiasing(context, true);
    CGContextSetLineWidth(context, kDefaultHudBorderWidthInPixels / screenScale);
    CGContextSetLineCap(context, kCGLineCapRound);
    CGContextSetLineJoin(context, kCGLineJoinRound);

    CGContextSetFillColorWithColor(context, fillColor.CGColor);
    CGContextSetStrokeColorWithColor(context, borderColor.CGColor);

    UIBezierPath* fillPath = nil;
    UIBezierPath* strokePath = nil;
    switch (style)
    {
        default:
        case OAButtonStyleRegular:
        {
            CGRect fillRect = CGRectInset(fullRect,
                                          kDefaultHudBorderWidthInPixels / screenScale, kDefaultHudBorderWidthInPixels / screenScale);
            CGRect strokeRect = CGRectInset(fullRect,
                                            0.5f * (kDefaultHudBorderWidthInPixels / screenScale), 0.5f * (kDefaultHudBorderWidthInPixels / screenScale));

            fillPath = [UIBezierPath bezierPathWithRoundedRect:fillRect cornerRadius:cornerRadius];
            strokePath = [UIBezierPath bezierPathWithRoundedRect:strokeRect cornerRadius:cornerRadius];
            break;
        }

        case OAButtonStyleLeadingSideDock:
        case OAButtonStyleTrailingSideDock:
        {
            BOOL isLeft =
                (style == OAButtonStyleLeadingSideDock) &&
                ([NSLocale lineDirectionForLanguage:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]] == NSLocaleLanguageDirectionLeftToRight);
            UIRectCorner corners = isLeft ? (UIRectCornerTopRight|UIRectCornerBottomRight) : (UIRectCornerTopLeft|UIRectCornerBottomLeft);

            CGRect fillRect = CGRectInset(fullRect,
                                          0.5f * (kDefaultHudBorderWidthInPixels / screenScale), kDefaultHudBorderWidthInPixels / screenScale);
            fillRect = CGRectOffset(fillRect,
                                    (isLeft ? -0.5f : 0.5f) * (kDefaultHudBorderWidthInPixels / screenScale), 0.0f);

            CGRect strokeRect = CGRectInset(fullRect,
                                            0.0f, 0.5f * (kDefaultHudBorderWidthInPixels / screenScale));
            strokeRect = CGRectOffset(strokeRect,
                                      (isLeft ? -0.5f : 0.5f) * (kDefaultHudBorderWidthInPixels / screenScale), 0.0f);

            fillPath = [UIBezierPath bezierPathWithRoundedRect:fillRect
                                             byRoundingCorners:corners
                                                   cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];

            strokePath = [UIBezierPath bezierPathWithRoundedRect:strokeRect
                                               byRoundingCorners:corners
                                                     cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];

            break;
        }

        case OAButtonStyleTopSideDock:
        case OAButtonStyleBottomSideDock:
        {
            BOOL isTop = (style == OAButtonStyleTopSideDock);
            UIRectCorner corners = isTop ? (UIRectCornerBottomLeft|UIRectCornerBottomRight) : (UIRectCornerTopLeft|UIRectCornerTopRight);

            CGRect fillRect = CGRectInset(fullRect,
                                          kDefaultHudBorderWidthInPixels / screenScale, 0.5f * (kDefaultHudBorderWidthInPixels / screenScale));
            fillRect = CGRectOffset(fillRect,
                                    0.0f, (isTop ? -0.5f : 0.5f) * (kDefaultHudBorderWidthInPixels / screenScale));

            CGRect strokeRect = CGRectInset(fullRect,
                                            0.5f * (kDefaultHudBorderWidthInPixels / screenScale), 0.0f);
            strokeRect = CGRectOffset(strokeRect,
                                      0.0f, (isTop ? -0.5f : 0.5f) * (kDefaultHudBorderWidthInPixels / screenScale));

            fillPath = [UIBezierPath bezierPathWithRoundedRect:fillRect
                                             byRoundingCorners:corners
                                                   cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];

            strokePath = [UIBezierPath bezierPathWithRoundedRect:strokeRect
                                               byRoundingCorners:corners
                                                     cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];

            break;
        }
    }

    CGContextAddPath(context, fillPath.CGPath);
    CGContextDrawPath(context, kCGPathFill);

    CGContextAddPath(context, strokePath.CGPath);
    CGContextDrawPath(context, kCGPathStroke);

    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    result = [result resizableImageWithCapInsets:UIEdgeInsetsMake(10.0f, 10.0f,
                                                                  10.0f, 10.0f)];

    return result;
}

@end
