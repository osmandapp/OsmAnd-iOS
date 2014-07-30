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

- (UIImage*)hudRoundButtonBackgroundForButton:(UIButton*)button
{
    return nil;
}

- (UIImage*)hudButtonBackgroundForStyle:(OAButtonStyle)style
{
    return nil;
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

    CGRect fillRect = CGRectInset(fullRect,
                                  kDefaultHudBorderWidthInPixels / screenScale, kDefaultHudBorderWidthInPixels / screenScale);
    CGRect strokeRect = CGRectInset(fullRect,
                                    0.5f * (kDefaultHudBorderWidthInPixels / screenScale), 0.5f * (kDefaultHudBorderWidthInPixels / screenScale));

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
            fillPath = [UIBezierPath bezierPathWithRoundedRect:fillRect cornerRadius:cornerRadius];
            strokePath = [UIBezierPath bezierPathWithRoundedRect:strokeRect cornerRadius:cornerRadius];
            break;
/*
        case OAButtonStyleLeadingSideDock:
        case OAButtonStyleTrailingSideDock:
        {
            BOOL isLeft =
                (style == OAButtonStyleLeadingSideDock) &&
                ([NSLocale lineDirectionForLanguage:[[NSLocale currentLocale] objectForKey:NSLocaleLanguageCode]] == NSLocaleLanguageDirectionLeftToRight);
            UIRectCorner corners = isLeft ? (UIRectCornerTopRight|UIRectCornerBottomRight) : (UIRectCornerTopLeft|UIRectCornerBottomLeft);

            path = [UIBezierPath bezierPathWithRoundedRect:rect
                                         byRoundingCorners:corners
                                               cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
            break;
        }

        case OAButtonStyleTopSideDock:
            path = [UIBezierPath bezierPathWithRoundedRect:rect
                                         byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight
                                               cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
            break;

        case OAButtonStyleBottomSideDock:
            path = [UIBezierPath bezierPathWithRoundedRect:rect
                                         byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight
                                               cornerRadii:CGSizeMake(cornerRadius, cornerRadius)];
            break;
            */
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
