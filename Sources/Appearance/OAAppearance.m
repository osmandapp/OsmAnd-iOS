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

    UIImage* _hudViewRoundBackground;
    UIImage* _hudViewBackgroundsByStyle[9];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _lock = [[NSObject alloc] init];
    }
    return self;
}

- (UIImage*)hudViewRoundBackgroundWithRadius:(CGFloat)radius
{
    @synchronized(_lock)
    {
        if (!_hudViewRoundBackground)
        {
            _hudViewRoundBackground = [OAAppearance drawRoundBackgroundForHudViewWithRadius:radius
                                                                               andFillColor:[self hudViewBackgroundColor]
                                                                             andBorderColor:[self hudViewBorderColor]];
        }

        return _hudViewRoundBackground;
    }
}

- (UIImage*)hudViewBackgroundForStyle:(OAHudViewStyle)style
{
    @synchronized(_lock)
    {
        UIImage* image = _hudViewBackgroundsByStyle[style];
        if (!image)
        {
            image = [OAAppearance drawHudViewBackgroundForStyle:style
                                                  withFillColor:[self hudViewBackgroundColor]
                                                 andBorderColor:[self hudViewBorderColor]];

            _hudViewBackgroundsByStyle[style] = image;
        }

        return image;
    }
}

- (UIColor*)hudViewBackgroundColor
{
    return[UIColor colorWithRed:1.0f green:1.0f blue:1.0f alpha:0.9f];
}

- (UIColor*)hudViewBorderColor
{
    return [UIColor colorWithRed:0.6f green:0.6f blue:0.6f alpha:0.9f];
}

+ (UIImage*)drawRoundBackgroundForHudViewWithRadius:(CGFloat)radius
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

+ (UIImage*)drawHudViewBackgroundForStyle:(OAHudViewStyle)style
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
        case OAHudViewStyleRegular:
        {
            CGRect fillRect = CGRectInset(fullRect,
                                          kDefaultHudBorderWidthInPixels / screenScale, kDefaultHudBorderWidthInPixels / screenScale);
            CGRect strokeRect = CGRectInset(fullRect,
                                            0.5f * (kDefaultHudBorderWidthInPixels / screenScale), 0.5f * (kDefaultHudBorderWidthInPixels / screenScale));

            fillPath = [UIBezierPath bezierPathWithRoundedRect:fillRect cornerRadius:cornerRadius];
            strokePath = [UIBezierPath bezierPathWithRoundedRect:strokeRect cornerRadius:cornerRadius];
            break;
        }

        case OAHudViewStyleLeadingSideDock:
        case OAHudViewStyleTrailingSideDock:
        {
            BOOL isLeft =
                (style == OAHudViewStyleLeadingSideDock) &&
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

        case OAHudViewStyleTopSideDock:
        case OAHudViewStyleBottomSideDock:
        {
            BOOL isTop = (style == OAHudViewStyleTopSideDock);
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
