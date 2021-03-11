//
//  OAUtilities.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 9/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAUtilities.h"
#import "PXAlertView.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OASizes.h"
#import "OrderedDictionary.h"
#import "OAFileNameTranslationHelper.h"
#import <UIKit/UIDevice.h>

@implementation UIBezierPath (util)

/**
 * Add a cubic bezier from the last point, approaching control points
 * (x1,y1) and (x2,y2), and ending at (x3,y3). If no moveTo() call has been
 * made for this contour, the first point is automatically set to (0,0).
 *
 * @param x1 The x-coordinate of the 1st control point on a cubic curve
 * @param y1 The y-coordinate of the 1st control point on a cubic curve
 * @param x2 The x-coordinate of the 2nd control point on a cubic curve
 * @param y2 The y-coordinate of the 2nd control point on a cubic curve
 * @param x3 The x-coordinate of the end point on a cubic curve
 * @param y3 The y-coordinate of the end point on a cubic curve
 */
- (void) cubicToX:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 x3:(float)x3 y3:(float)y3
{
    [self addCurveToPoint:CGPointMake(x3, y3) controlPoint1:CGPointMake(x1, y1) controlPoint2:CGPointMake(x2, y2)];
}

/**
 * Append the specified arc to the path as a new contour. If the start of
 * the path is different from the path's current last point, then an
 * automatic lineTo() is added to connect the current contour to the
 * start of the arc. However, if the path is empty, then we call moveTo()
 * with the first point of the arc.
 *
 * @param oval        The bounds of oval defining shape and size of the arc
 * @param startAngle  Starting angle (in degrees) where the arc begins
 * @param sweepAngle  Sweep angle (in degrees) measured clockwise
 */
- (void) arcTo:(CGRect)oval startAngle:(float)startAngle sweepAngle:(float)sweepAngle
{
    CGPoint center = CGPointMake(CGRectGetMidX(oval), CGRectGetMidY(oval));
    CGFloat dX = (CGRectGetMaxX(oval) - CGRectGetMinX(oval));
    CGFloat dY = (CGRectGetMaxY(oval) - CGRectGetMinY(oval));
    CGFloat radius = MAX(dX, dY) / 2.0;
    
    if (dX == dY)
    {
        [self addArcWithCenter:center radius:radius startAngle:[OAUtilities degToRadf:startAngle] endAngle:[OAUtilities degToRadf:startAngle + sweepAngle] clockwise:sweepAngle > 0];
    }
    else
    {
        CGAffineTransform t = CGAffineTransformIdentity;
        if (dX > dY)
        {
            t = CGAffineTransformMakeScale(1.0, dY / dX);
            t = CGAffineTransformTranslate(t, 0, (dX - dY) * (dY / dX));
        }
        else if (dY > dX)
        {
            t = CGAffineTransformMakeScale(dX / dY, 1.0);
            t = CGAffineTransformTranslate(t, (dY - dX) * (dX / dY), 0);
        }
        
        CGPathRef cgPath = self.CGPath;
        CGMutablePathRef mutablePath = CGPathCreateMutableCopy(cgPath);
        
        CGPathAddArc(mutablePath, &t, center.x, center.y, radius, [OAUtilities degToRadf:startAngle], [OAUtilities degToRadf:startAngle + sweepAngle], sweepAngle < 0);
        
        self.CGPath = mutablePath;
        CGPathRelease(mutablePath);
    }
    
    //arcTo(oval.left, oval.top, oval.right, oval.bottom, startAngle, sweepAngle, false);
}

/**
 * Add the specified arc to the path as a new contour.
 *
 * @param oval The bounds of oval defining the shape and size of the arc
 * @param startAngle Starting angle (in degrees) where the arc begins
 * @param sweepAngle Sweep angle (in degrees) measured clockwise
 */
- (void) addArc:(CGRect)oval startAngle:(float)startAngle sweepAngle:(float)sweepAngle
{
    CGPoint center = CGPointMake(CGRectGetMidX(oval), CGRectGetMidY(oval));
    CGFloat dX = (CGRectGetMaxX(oval) - CGRectGetMinX(oval));
    CGFloat dY = (CGRectGetMaxY(oval) - CGRectGetMinY(oval));
    CGFloat radius = MAX(dX, dY) / 2.0;
        
    if (dX == dY)
    {
        [self addArcWithCenter:center radius:radius startAngle:[OAUtilities degToRadf:startAngle] endAngle:[OAUtilities degToRadf:startAngle + sweepAngle] clockwise:sweepAngle > 0];
    }
    else
    {
        CGAffineTransform t = CGAffineTransformIdentity;
        if (dX > dY)
        {
            t = CGAffineTransformMakeScale(1.0, dY / dX);
            t = CGAffineTransformTranslate(t, 0, (dX - dY) * (dY / dX));
        }
        else if (dY > dX)
        {
            t = CGAffineTransformMakeScale(dX / dY, 1.0);
            t = CGAffineTransformTranslate(t, (dY - dX) * (dX / dY), 0);
        }
        
        CGPathRef cgPath = self.CGPath;
        CGMutablePathRef mutablePath = CGPathCreateMutableCopy(cgPath);
        
        CGPathAddArc(mutablePath, &t, center.x, center.y, radius, [OAUtilities degToRadf:startAngle], [OAUtilities degToRadf:startAngle + sweepAngle], sweepAngle < 0);
        
        self.CGPath = mutablePath;
        CGPathRelease(mutablePath);
    }
    
    //addArc(oval.left, oval.top, oval.right, oval.bottom, startAngle, sweepAngle);
}

- (void) moveToX:(CGFloat)x y:(CGFloat)y
{
    [self moveToPoint:CGPointMake(x, y)];
}

- (void) lineToX:(CGFloat)x y:(CGFloat)y
{
    [self addLineToPoint:CGPointMake(x, y)];
}

- (void) rLineToX:(CGFloat)x y:(CGFloat)y
{
    CGPoint currentPoint = self.currentPoint;
    [self addLineToPoint:CGPointMake(currentPoint.x + x, currentPoint.y + y)];
}

@end

@implementation NSMutableArray (util)

+ (instancetype)arrayWithObject:(NSObject *)object count:(NSUInteger)cnt
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:cnt];
    for (int i = 0; i < cnt; i++)
    {
        [array addObject:object];
    }
    return array;
}

@end

@implementation NSString (util)

- (int) indexOf:(NSString *)text
{
    return [self indexOf:text start:0];
}

- (int) indexOf:(NSString *)text start:(NSInteger)start
{
    NSRange range = [self rangeOfString:text options:0 range:NSMakeRange(start, self.length - start) locale:[NSLocale currentLocale]];
    if (range.location != NSNotFound)
    {
        return (int)range.location;
    }
    else
    {
        return -1;
    }
}

- (int) lastIndexOf:(NSString *)text
{
    int i = 0;
    int res = -1;
    for (;;)
    {
        int a = [self indexOf:text start:i];
        if (a != -1)
        {
            res = a;
            i = a + 1;
        }

        if (a == -1 || a >= text.length - 1)
            break;
    }
    return res;
}

- (NSString *) add:(NSString *)str
{
    return [self stringByAppendingString:str];
}

- (NSString *) trim
{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *) lowerCase
{
    return [self lowercaseStringWithLocale:[NSLocale currentLocale]];
}

- (NSString *) upperCase
{
    return [self uppercaseStringWithLocale:[NSLocale currentLocale]];
}

- (BOOL) isValidEmail
{
    NSString *email = [self trim];
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray<NSTextCheckingResult *> *matches = [detector matchesInString:email options:0 range:NSMakeRange(0, email.length)];
    return matches.count == 1 && matches[0].URL && [matches[0].URL.absoluteString containsString:@"mailto:"];
}

- (NSString *) escapeUrl
{
    return (NSString *)CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(
         NULL,
         (__bridge CFStringRef) self,
         NULL,
         CFSTR("!*'();:@&=+$,/?%#[]\" "),
         kCFStringEncodingUTF8));
}

- (NSString *) sanitizeFileName
{
    return [[[self componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]] componentsJoinedByString:@"_"];
}

@end

@implementation UIView (utils)

- (BOOL) setConstant:(NSString *)identifier constant:(CGFloat)constant
{
    for (NSLayoutConstraint *c in self.constraints)
        if ([c.identifier isEqualToString:identifier])
        {
            c.constant = constant;
            return true;
        }
    return false;
}

- (CGFloat) getConstant:(NSString *)identifier
{
    for (NSLayoutConstraint *c in self.constraints)
        if ([c.identifier isEqualToString:identifier])
        {
            return c.constant;
        }
    return NAN;
}

- (BOOL) isDirectionRTL
{
    return [UIView userInterfaceLayoutDirectionForSemanticContentAttribute:self.semanticContentAttribute] == UIUserInterfaceLayoutDirectionRightToLeft;
}

@end

@implementation OAUtilities

+ (BOOL) iosVersionIsAtLeast:(NSString*)testVersion
{
    return ([[[UIDevice currentDevice] systemVersion] compare:testVersion options:NSNumericSearch] != NSOrderedAscending);
}

+ (BOOL) iosVersionIsExactly:(NSString*)testVersion
{
    return ([[[UIDevice currentDevice] systemVersion] compare:testVersion options:NSNumericSearch] == NSOrderedSame);
}

+ (NSComparisonResult) compareInt:(int)x y:(int)y
{
    return (x < y) ? NSOrderedAscending : ((x == y) ? NSOrderedSame : NSOrderedDescending);
}

+ (NSComparisonResult) compareDouble:(double)x y:(double)y
{
    return [[NSNumber numberWithDouble:x] compare:[NSNumber numberWithDouble:y]];
}

+ (int) extractFirstIntegerNumber:(NSString *)s
{
    int i = 0;
    for (int k = 0; k < s.length; k++)
    {
        if (isdigit([s characterAtIndex:k])) {
            i = i * 10 + ([s characterAtIndex:k] - '0');
        } else {
            break;
        }
    }
    return i;
}

+ (BOOL) isWordComplete:(NSString *)text
{
    if (text.length > 0 )
    {
        unichar ch = [text characterAtIndex:text.length - 1];
        return ch == ' ' || ch == ',' || ch == '\r' || ch == '\n' || ch == ';';
    }
    return NO;
}

+ (UIImage *) applyScaleFactorToImage:(UIImage *)image
{
    CGFloat scaleFactor = [[UIScreen mainScreen] scale];
    CGSize newSize = CGSizeMake(image.size.width / scaleFactor, image.size.height / scaleFactor);
    return [self.class resizeImage:image newSize:newSize];
}

+ (UIImage *) resizeImage:(UIImage *)image newSize:(CGSize)newSize
{
    if (!image)
        return nil;
    
    @autoreleasepool
    {
        UIGraphicsBeginImageContextWithOptions(newSize, NO, [[UIScreen mainScreen] scale]);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return newImage;
    }
}

+ (UIImage *) imageWithColor:(UIColor *)color
{
    if (!color)
        return nil;
    
    @autoreleasepool
    {
        CGRect rect = CGRectMake(0, 0, 1, 1);
        
        UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0);
        [color setFill];
        CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return image;
    }
}

+ (void) clearTmpDirectory
{
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }
}

+ (NSString *) drawablePostfix
{
    int scale = (int)[UIScreen mainScreen].scale;
    
    switch (scale) {
        case 1:
            return @"mdpi";
        case 2:
            return @"xhdpi";
        case 3:
            return @"xxhdpi";
            
        default:
            return @"xxhdpi";
    }
}

+ (NSString *) drawablePath:(NSString *)resId
{
    return [NSString stringWithFormat:@"%@/drawable-%@/%@", [resId hasPrefix:@"mx_"] ? @"poi-icons-png" : @"map-icons-png", [OAUtilities drawablePostfix], resId];
}

+ (void) setMaskTo:(UIView*)view byRoundingCorners:(UIRectCorner)corners
{
    [self.class setMaskTo:view byRoundingCorners:corners radius:10.];
}

+ (void) setMaskTo:(UIView*)view byRoundingCorners:(UIRectCorner)corners radius:(CGFloat)radius
{
    UIBezierPath* rounded = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(radius, radius)];
    
    CAShapeLayer* shape = [[CAShapeLayer alloc] init];
    [shape setPath:rounded.CGPath];
    
    view.layer.mask = shape;
}

+ (void) layoutComplexButton:(UIButton*)button
{
    // the space between the image and text
    CGFloat spacing = 6.0;
    
    // lower the text and push it left so it appears centered
    //  below the image
    CGSize imageSize = button.imageView.image.size;
    button.titleEdgeInsets = UIEdgeInsetsMake(
                                              0.0, - imageSize.width, - (imageSize.height), 0.0);
    
    // raise the image and push it right so it appears centered
    //  above the text
    CGSize titleSize = [button.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: button.titleLabel.font}];
    button.imageEdgeInsets = UIEdgeInsetsMake(
                                              - (titleSize.height + spacing), 0.0, 0.0, - titleSize.width);
    [button setSemanticContentAttribute:UISemanticContentAttributeForceLeftToRight];
}

+ (CGSize) calculateTextBounds:(NSAttributedString *)text width:(CGFloat)width
{
    CGSize size = [text boundingRectWithSize:CGSizeMake(ceil(width), 10000.0)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                     context:nil].size;
    
    return CGSizeMake(ceil(size.width), ceil(size.height));
}

+ (CGSize) calculateTextBounds:(NSString *)text width:(CGFloat)width font:(UIFont *)font
{
    NSDictionary *attrDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              font, NSFontAttributeName, nil];
    
    CGSize size = [text boundingRectWithSize:CGSizeMake(ceil(width), 10000.0)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attrDict context:nil].size;
    
    return CGSizeMake(ceil(size.width), ceil(size.height));
}

+ (CGSize) calculateTextBounds:(NSString *)text width:(CGFloat)width height:(CGFloat)height font:(UIFont *)font
{
    NSDictionary *attrDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              font, NSFontAttributeName, nil];
    
    CGSize size = [text boundingRectWithSize:CGSizeMake(ceil(width), height)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingTruncatesLastVisibleLine
                                  attributes:attrDict context:nil].size;
    
    return CGSizeMake(ceil(size.width), ceil(size.height));
}

+ (NSDictionary<NSString *, NSString *> *) parseUrlQuery:(NSURL *)url
{
    NSMutableDictionary<NSString *, NSString *> *queryStrings = [[NSMutableDictionary alloc] init];
    for (NSString *qs in [url.query componentsSeparatedByString:@"&"]) {
        // Get the parameter name
        NSString *key = [[qs componentsSeparatedByString:@"="] objectAtIndex:0];
        // Get the parameter value
        NSString *value = [[qs componentsSeparatedByString:@"="] objectAtIndex:1];
        value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        value = [value stringByRemovingPercentEncoding];
        
        queryStrings[key] = value;
    }
    return [NSDictionary dictionaryWithDictionary:queryStrings];
}

+ (void) getHMS:(NSTimeInterval)timeInterval hours:(int*)hours minutes:(int*)minutes seconds:(int*)seconds
{
    long secondsL = lroundf(timeInterval);
    *hours = abs((int)(secondsL / 3600));
    *minutes = abs((int)((secondsL % 3600) / 60));
    *seconds = abs((int)(secondsL % 60));
}

+ (NSArray *) splitCoordinates:(NSString *)string
{
        NSMutableArray *split = [NSMutableArray array];
        NSMutableString *prev = [NSMutableString string];
        NSMutableString *other = [NSMutableString string];
        BOOL south = NO;
        BOOL west = NO;
        for(int i = 0; i < string.length; i++)
        {
            unichar ch = [string characterAtIndex:i];
            
            if(ch == '\'' || [[NSCharacterSet decimalDigitCharacterSet] characterIsMember:ch] || ch =='#' ||
               ch == '-' || ch == '.')
            {
                [prev appendString:[NSString stringWithCharacters:&ch length:1]];
                if ([[[other stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] lowercaseString] isEqualToString:@"s"])
                    south = true;
                
                [other setString:@""];
            }
            else
            {
                [other appendString:[NSString stringWithCharacters:&ch length:1]];
                if (prev.length > 0)
                {
                    [split addObject:[NSString stringWithString:prev]];
                    [prev setString:@""];
                }
            }
        }
        if (prev.length > 0)
        {
            [split addObject:[NSString stringWithString:prev]];
            [prev setString:@""];
        }
        if ([[[other stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]] lowercaseString] isEqualToString:@"w"])
            west = YES;
    
        NSMutableArray *numbers = [OAUtilities splitNumbers:split];
        NSMutableArray *dnumbers = [OAUtilities filterInts:numbers];
        NSMutableArray *rnumbers = dnumbers.count >= 2 ? dnumbers : numbers;
        if (rnumbers.count > 0 && [rnumbers[0] doubleValue] >= 0 && south)
            [rnumbers setObject:[NSNumber numberWithDouble:-[rnumbers[0] doubleValue]] atIndexedSubscript:0];
        if (rnumbers.count > 1 && [rnumbers[1] doubleValue] >= 0 && west)
            [rnumbers setObject:[NSNumber numberWithDouble:-[rnumbers[1] doubleValue]] atIndexedSubscript:1];

        if (rnumbers.count == 0) // Not a coordinate
            return nil;
        else if(rnumbers.count == 1) // Latitude X Longitude #.## or ##’##’##.#
            return @[rnumbers[0]];
        else // Latitude X Longitude Y
            return @[rnumbers[0], rnumbers[1]];
}

+ (NSMutableArray *) filterInts:(NSArray *)numbers
{
    NSMutableArray *dnumbers = [NSMutableArray array];
    for (NSNumber *d in numbers)
        if([d intValue] != [d doubleValue])
            [dnumbers addObject:d];
    
    return dnumbers;
}

+ (NSMutableArray *) splitNumbers:(NSArray *) split
{
        NSMutableString *prev = [NSMutableString string];
        NSMutableArray *numbers = [NSMutableArray array];
        for (NSString *p in split)
        {
            NSMutableArray *ps = [NSMutableArray array];
            [prev setString:@""];
            for (int i = 0; i < p.length; i++)
            {
                unichar ch = [p characterAtIndex:i];
                if (ch =='#' || ch == '\'')
                {
                    if(!(prev.length > 0 && [prev characterAtIndex:0] == '-'))
                        [prev replaceOccurrencesOfString:@"-" withString:@"" options:0 range:NSMakeRange(0, prev.length)];
                    
                    [OAUtilities addPrev:prev ps:ps];
                    [prev setString:@""];
                }
                else
                {
                    [prev appendString:[NSString stringWithCharacters:&ch length:1]];
                }
            }
            [OAUtilities addPrev:prev ps:ps];
            if (ps.count > 0)
            {
                double n = [ps[0] doubleValue];
                if (ps.count > 1)
                {
                    n += [ps[1] doubleValue] / 60.0;
                    if (ps.count > 2)
                        n += [ps[2] doubleValue] / 3600.0;
                }
                [numbers addObject:[NSNumber numberWithDouble:n]];
            }
        }
        return numbers;
}
    
+ (void) addPrev:(NSString *)prev ps:(NSMutableArray *)ps
{
    NSString *trimmed = [prev stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceCharacterSet]];
    if (trimmed.length > 0)
    {
        double val = [trimmed doubleValue];
        if (val != HUGE_VAL && val != -HUGE_VAL && val != 0.0)
            [ps addObject:[NSNumber numberWithDouble:val]];
    }
}

+ (NSString *) floatToStrTrimZeros:(CGFloat)number
{
    NSString *str = [NSString stringWithFormat:@"%f", number];
    long length = str.length;
    for (long i = str.length; i > 0; i--)
    {
        if  ([str rangeOfString:@"."].location != NSNotFound)
        {
            NSRange prevChar = NSMakeRange(i-1, 1);
            if ([[str substringWithRange:prevChar] isEqualToString:@"0"]||
                [[str substringWithRange:prevChar] isEqualToString:@"."])
                length--;
            else
                break;
        }
        str = [str substringToIndex:length];
    }
    return str;
}

+ (UIImage *) tintImageWithColor:(UIImage *)source color:(UIColor *)color
{
    @autoreleasepool
    {
        // begin a new image context, to draw our colored image onto with the right scale
        UIGraphicsBeginImageContextWithOptions(source.size, NO, [UIScreen mainScreen].scale);
        
        // get a reference to that context we created
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        // set the fill color
        [color setFill];
        
        // translate/flip the graphics context (for transforming from CG* coords to UI* coords
        CGContextTranslateCTM(context, 0, source.size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        CGRect rect = CGRectMake(0, 0, source.size.width, source.size.height);
        CGContextDrawImage(context, rect, source.CGImage);
        
        CGContextClipToMask(context, rect, source.CGImage);
        CGContextAddRect(context, rect);
        CGContextDrawPath(context,kCGPathFill);
        
        // generate a new UIImage from the graphics context we drew onto
        UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        //return the color-burned image
        return coloredImg;
    }
}

+ (UIImage *) layeredImageWithColor:(UIColor *)color bottom:(UIImage *)bottom center:(UIImage *)center top:(UIImage *)top
{
    @autoreleasepool
    {
        CGSize size = bottom.size;
        if (size.width < center.size.width || size.height < center.size.height)
            size = center.size;
        if (size.width < top.size.width || size.height < top.size.height)
            size = top.size;

        UIGraphicsBeginImageContextWithOptions(size, NO, [UIScreen mainScreen].scale);
        
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        CGContextTranslateCTM(context, 0, size.height);
        CGContextScaleCTM(context, 1.0, -1.0);
        
        CGContextSetBlendMode(context, kCGBlendModeNormal);
        CGRect rect = CGRectMake(size.width / 2.0 - bottom.size.width / 2.0, size.height / 2.0 - bottom.size.height / 2.0, bottom.size.width, bottom.size.height);
        CGContextDrawImage(context, rect, bottom.CGImage);

        center = [self imageWithTintColor:color image:center];
        
        rect = CGRectMake(size.width / 2.0 - center.size.width / 2.0, size.height / 2.0 - center.size.height / 2.0, center.size.width, center.size.height);
        CGContextDrawImage(context, rect, center.CGImage);
        
        rect = CGRectMake(size.width / 2.0 - top.size.width / 2.0, size.height / 2.0 - top.size.height / 2.0, top.size.width, top.size.height);
        CGContextDrawImage(context, rect, top.CGImage);

        UIImage *res = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return res;
    }
}

+ (UIImage *) imageWithTintColor:(UIColor *)color image:(UIImage *)image
{
    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [color setFill];
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextClipToMask(context, CGRectMake(0, 0, image.size.width, image.size.height), [image CGImage]);
    CGContextFillRect(context, CGRectMake(0, 0, image.size.width, image.size.height));

    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    
    return coloredImg;
}

+ (NSString *) colorToString:(UIColor *)color
{
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    
    uint32_t red = r * 255;
    uint32_t green = g * 255;
    uint32_t blue = b * 255;
    
    return [NSString stringWithFormat:@"#%.6x", (red << 16) + (green << 8) + blue];
}

+ (int) colorToNumber:(UIColor *)color
{
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    
    uint32_t red = r * 255;
    uint32_t green = g * 255;
    uint32_t blue = b * 255;
    
    int result = (red << 16) + (green << 8) + blue;
    return result;
}

+ (NSString *) appendMeters:(float)value
{
    NSString *formattedValue = [[OsmAndApp instance] getFormattedDistance:value];
    return value == 0.f ? OALocalizedString(@"not_selected") : formattedValue;
}

+ (NSString *) appendSpeed:(float)value
{
    BOOL kilometers = [[OAAppSettings sharedManager].metricSystem get] == KILOMETERS_AND_METERS;
    value = kilometers ? value : round(value / 0.3048f);
    NSString *distUnitsFormat = [@"%g " stringByAppendingString:kilometers ? OALocalizedString(@"units_kmh") : OALocalizedString(@"units_mph")];
    return value == 0.f ? OALocalizedString(@"not_selected") : value == 0.000001f ? @">0" : [NSString stringWithFormat:distUnitsFormat, value];
}

+ (NSArray<NSString *> *) arrayOfMeterValues:(NSArray<NSNumber *> *) values
{
    NSMutableArray<NSString *> *res = [NSMutableArray new];
    for (NSNumber *num in values) {
        [res addObject:[OAUtilities appendMeters:num.floatValue]];
    }
    return [NSArray arrayWithArray:res];
}

+ (NSArray<NSString *> *) arrayOfSpeedValues:(NSArray<NSNumber *> *) values
{
    NSMutableArray<NSString *> *res = [NSMutableArray new];
    for (NSNumber *num in values) {
        [res addObject:[self appendSpeed:num.floatValue]];
    }
    return res;
}


+ (UIColor *) colorFromString:(NSString *)string
{
    string = [string lowercaseString];
    string = [string stringByReplacingOccurrencesOfString:@"#" withString:@""];
    string = [string stringByReplacingOccurrencesOfString:@"0x" withString:@""];
    
    switch ([string length])
    {
        case 0:
        {
            string = @"00000000";
            break;
        }
        case 3:
        {
            NSString *red = [string substringWithRange:NSMakeRange(0, 1)];
            NSString *green = [string substringWithRange:NSMakeRange(1, 1)];
            NSString *blue = [string substringWithRange:NSMakeRange(2, 1)];
            string = [NSString stringWithFormat:@"%1$@%1$@%2$@%2$@%3$@%3$@ff", red, green, blue];
            break;
        }
        case 6:
        {
            string = [string stringByAppendingString:@"ff"];
            break;
        }
        case 8:
        {
            //do nothing
            break;
        }
        default:
        {
            return nil;
        }
    }

    uint32_t rgba;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner scanHexInt:&rgba];
    return UIColorFromRGBA(rgba);
}

+ (BOOL) areColorsEqual:(UIColor *)color1 color2:(UIColor *)color2
{
    NSString *col1Str = [self.class colorToString:color1];
    NSString *col2Str = [self.class colorToString:color2];
    return [col1Str isEqualToString:col2Str];
}

+ (BOOL) doublesEqualUpToDigits:(int)digits source:(double)source destination:(double)destination
{
    double ap = source * pow(10.0, digits);
    double bp = destination * pow(10.0, digits);
    
    long a = (long)round(ap);
    long b = (long)round(bp);
    long af = (long)floor(ap);
    long bf = (long)floor(bp);
    
    return a == b || af == bf;
}

+ (BOOL) isCoordEqual:(double)srcLat srcLon:(double)srcLon destLat:(double)destLat destLon:(double)destLon
{
    return [OAUtilities doublesEqualUpToDigits:5 source:srcLat destination:destLat] && [OAUtilities doublesEqualUpToDigits:5 source:srcLon destination:destLon];
}

+ (BOOL) isCoordEqual:(double)srcLat srcLon:(double)srcLon destLat:(double)destLat destLon:(double)destLon upToDigits:(int)digits
{
    return [OAUtilities doublesEqualUpToDigits:digits source:srcLat destination:destLat] && [OAUtilities doublesEqualUpToDigits:digits source:srcLon destination:destLon];
}

+ (void) roundCornersOnView:(UIView *)view onTopLeft:(BOOL)tl topRight:(BOOL)tr bottomLeft:(BOOL)bl bottomRight:(BOOL)br radius:(CGFloat)radius
{    
    if (tl || tr || bl || br)
    {
        UIRectCorner corner = 0;

        if (tl)
            corner = corner | UIRectCornerTopLeft;

        if (tr)
            corner = corner | UIRectCornerTopRight;

        if (bl)
            corner = corner | UIRectCornerBottomLeft;

        if (br)
            corner = corner | UIRectCornerBottomRight;

        UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:corner cornerRadii:CGSizeMake(radius, radius)];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.frame = view.bounds;
        maskLayer.path = maskPath.CGPath;
        view.layer.mask = maskLayer;
    }
}

+ (NSString *) preferredLang
{
    NSString *prefLang = [[OAAppSettings sharedManager] settingPrefMapLanguage];
    if (!prefLang)
        prefLang = [OAUtilities currentLang];
    
    return prefLang;
}

+ (NSString *) currentLang
{
    NSString *firstLanguage = [[NSLocale preferredLanguages] firstObject];
    return [[firstLanguage componentsSeparatedByString:@"-"] firstObject];
}

+ (NSString *) capitalizeFirstLetterAndLowercase:(NSString *)s
{
    if (s && s.length > 1)
    {
        return [[[s substringToIndex:1] uppercaseStringWithLocale:[NSLocale currentLocale]] stringByAppendingString:[[s substringFromIndex:1] lowercaseStringWithLocale:[NSLocale currentLocale]]];
    }
    else
    {
        return s;
    }
}

+ (NSInteger) findFirstNumberEndIndex:(NSString *)value
{
    uint i = 0;
    BOOL valid = NO;
    if (value.length > 0 && [value characterAtIndex:i] == '-')
        i++;
    while (i < value.length && (([value characterAtIndex:i] >= '0' && [value characterAtIndex:i] <= '9') || [value characterAtIndex:i] == '.'))
    {
        i++;
        valid = YES;
    }
    if (valid)
        return i;
    else
        return -1;
}

+ (NSString *) translatedLangName:(NSString *)lang
{
    NSString *langName = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:lang];
    if (!langName)
        langName = lang;
    return langName;
}


+ (void) callUrl:(NSString *)url
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]]];
}

+ (NSString *) stripNonDigits:(NSString *)input
{
    NSCharacterSet *doNotWant = [[NSCharacterSet characterSetWithCharactersInString:@"+0123456789"] invertedSet];
    return [[input componentsSeparatedByCharactersInSet: doNotWant] componentsJoinedByString: @""];
}

+ (void) callPhone:(NSString *)phonesString
{
    NSArray* phones = [phonesString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@",:;."]];
    NSMutableArray *parsedPhones = [NSMutableArray array];
    for (NSString *phone in phones)
    {
        NSString *p = [OAUtilities stripNonDigits:phone];
        [parsedPhones addObject:p];
    }
    
    NSMutableArray *images = [NSMutableArray array];
    for (int i = 0; i <parsedPhones.count; i++)
        [images addObject:@"ic_phone_number"];
    
    [PXAlertView showAlertWithTitle:OALocalizedString(@"make_call")
                            message:nil
                        cancelTitle:OALocalizedString(@"shared_string_cancel")
                        otherTitles:parsedPhones
                          otherDesc:nil
                        otherImages:images
                         completion:^(BOOL cancelled, NSInteger buttonIndex) {
                             if (!cancelled)
                                 for (int i = 0; i < parsedPhones.count; i++)
                                 {
                                     if (buttonIndex == i)
                                     {
                                         NSString *p = parsedPhones[i];
                                         [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tel://" stringByAppendingString:p]]];
                                         break;
                                     }
                                 }
                         }];
    
}

+ (UIImage *) getMxIcon:(NSString *)name
{
    UIImage *img = [UIImage imageNamed:[OAUtilities drawablePath:[NSString stringWithFormat:@"mx_%@", name]]];
    if (img)
        return [OAUtilities applyScaleFactorToImage:img];
    else
        return nil;
}

+ (UIImage *) getTintableImage:(UIImage *)image
{
    if (image)
        return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    else
        return nil;
}

+ (UIImage *) getTintableImageNamed:(NSString *)name
{
    UIImage *image = [UIImage imageNamed:name];
    if (image)
        return [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    else
        return nil;
}

+ (BOOL) is12HourTimeFormat
{
    NSString *formatStringForHours = [NSDateFormatter dateFormatFromTemplate:@"j" options:0 locale:[NSLocale currentLocale]];
    NSRange containsA = [formatStringForHours rangeOfString:@"a"];
    BOOL hasAMPM = containsA.location != NSNotFound;
    return hasAMPM;
}

static const float fPI180 = M_PI / 180.f;
static const double dPI180 = M_PI / 180.0;
static const float f180PI =  180.f / M_PI;
static const double d180PI = 180.0 / M_PI_2;

+ (float) degToRadf:(float)degrees
{
    return degrees * fPI180;
}

+ (double) degToRadd:(double)degrees
{
    return degrees * dPI180;
}

+ (float) radToDegf:(float)radians
{
    return radians * f180PI;
}

+ (double) radToDegd:(double)radians
{
    return radians * d180PI;
}

+ (BOOL) isLeftSideLayout:(UIInterfaceOrientation)interfaceOrientation
{
    return (UIInterfaceOrientationIsLandscape(interfaceOrientation) || UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}

+ (CGFloat) getStatusBarHeight
{
    if ([NSThread isMainThread])
    {
        return [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    else
    {
        __block CGFloat height = 20.0;
        dispatch_block_t onMain = ^{
            height = [UIApplication sharedApplication].statusBarFrame.size.height;
        };
        if ([NSThread isMainThread])
            onMain();
        else
            dispatch_sync(dispatch_get_main_queue(), onMain);
        
        return height;
    }
}

+ (CGFloat) getTopMargin
{
    return [UIApplication sharedApplication].keyWindow.safeAreaInsets.top;
}

+ (CGFloat) getBottomMargin
{
    return [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom;
}

+ (CGFloat) getLeftMargin
{
    return [UIApplication sharedApplication].keyWindow.safeAreaInsets.left;
}

+ (CGFloat) calculateScreenWidth
{
    if (NSThread.isMainThread)
        return UIApplication.sharedApplication.delegate.window.bounds.size.width;
    // else dispatch to the main thread
    __block CGFloat result;
    dispatch_sync(dispatch_get_main_queue(), ^{
        result = UIApplication.sharedApplication.delegate.window.bounds.size.width;
    });
    return result;
}

+ (CGFloat) calculateScreenHeight
{
    if (NSThread.isMainThread)
    {
        CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
        return UIApplication.sharedApplication.delegate.window.bounds.size.height - ((statusBarHeight == 40.0) ? (statusBarHeight - 20.0) : 0);
    }
    __block CGFloat result;
    dispatch_sync(dispatch_get_main_queue(), ^{
        CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
        result = UIApplication.sharedApplication.delegate.window.bounds.size.height - ((statusBarHeight == 40.0) ? (statusBarHeight - 20.0) : 0);
    });
    return result;
}

+ (BOOL) isWindowed
{
    if (@available(iOS 13.0, *)) {
        return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad && (DeviceScreenWidth != [[UIScreen mainScreen] bounds].size.width ||
            UIApplication.sharedApplication.delegate.window.bounds.size.height != [[UIScreen mainScreen] bounds].size.height);
    }
    return NO;
}

+ (void) adjustViewsToNotch:(CGSize)size topView:(UIView *)topView middleView:(UIView *)middleView bottomView:(UIView *)bottomView
        navigationBarHeight:(CGFloat)navigationBarHeight toolBarHeight:(CGFloat)toolBarHeight
{
    CGRect navBarFrame = topView.frame;
    CGFloat navBarHeight = [OAUtilities getStatusBarHeight];
    navBarHeight = navBarHeight == inCallStatusBarHeight ? navBarHeight / 2 : navBarHeight;
    navBarFrame.size.height = navigationBarHeight + navBarHeight;
    navBarFrame.size.width = size.width;
    topView.frame = navBarFrame;
    CGRect toolBarFrame = CGRectMake(0, 0, 0, 0);
    if (bottomView)
    {
        toolBarFrame = bottomView.frame;
        toolBarFrame.size.height = toolBarHeight + [OAUtilities getBottomMargin];
        toolBarFrame.size.width = size.width;
        toolBarFrame.origin.y = size.height - toolBarFrame.size.height;
        bottomView.frame = toolBarFrame;
    }

    CGRect tableViewFrame = middleView.frame;
    tableViewFrame.origin.y = navBarFrame.size.height;
    tableViewFrame.size.height = size.height - navBarFrame.size.height - toolBarFrame.size.height;
    tableViewFrame.size.width = size.width;
    middleView.frame = tableViewFrame;
}

+ (BOOL) isLandscape
{
    UIInterfaceOrientation orientation = UIApplication.sharedApplication.statusBarOrientation;
    return orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight;
}

+ (BOOL) isLandscapeIpadAware
{
    return (self.class.isLandscape || self.class.isIPad) && !self.class.isWindowed;
}

/*
 controlPointsFromPoints calculates control points of smooth Bezier path through set os points.
 
 Usage:
 
 UIBezierPath *linePath = [UIBezierPath bezierPath];
 NSArray<NSValue *> *controlPoints = [OAUtilities controlPointsFromPoints:dataPoints];
 for (NSInteger i = 0; i < dataPoints.count; i++)
 {
    CGPoint point = dataPoints[i].CGPointValue;
     if (i == 0)
     {
        [linePath moveToPoint:point];
     }
     else
     {
         CGPoint cp1 = controlPoints[(i - 1) * 2].CGPointValue;
         CGPoint cp2 = controlPoints[(i - 1) * 2 + 1].CGPointValue;
         [linePath addCurveToPoint:point controlPoint1:cp1 controlPoint2:cp2];
     }
 }
 [linePath stroke];
 */
+ (NSArray<NSValue *> *) controlPointsFromPoints:(NSArray<NSValue *> *)dataPoints
{
    NSMutableArray<NSValue *> *firstControlPoints = [NSMutableArray array];
    NSMutableArray<NSValue *> *secondControlPoints = [NSMutableArray array];

    //Number of Segments
    NSInteger count = dataPoints.count - 1;
    
    //P0, P1, P2, P3 are the points for each segment, where P0 & P3 are the knots and P1, P2 are the control points.
    if (count == 1)
    {
        CGPoint P0 = dataPoints[0].CGPointValue;
        CGPoint P3 = dataPoints[1].CGPointValue;
        
        //Calculate First Control Point
        //3P1 = 2P0 + P3
        
        double P1x = (2.0 * P0.x + P3.x) / 3.0;
        double P1y = (2.0 * P0.y + P3.y) / 3.0;
        
        [firstControlPoints addObject:[NSValue valueWithCGPoint:CGPointMake(P1x, P1y)]];
        
        //Calculate second Control Point
        //P2 = 2P1 - P0
        double P2x = (2.0 * P1x - P0.x);
        double P2y = (2.0 * P1y - P0.y);
        
        [secondControlPoints addObject:[NSValue valueWithCGPoint:CGPointMake(P2x, P2y)]];
    }
    else
    {
        firstControlPoints = [NSMutableArray arrayWithObject:NSNull.null count:count];
        
        NSMutableArray<NSValue *> *rhsArray = [NSMutableArray array];
        
        //Array of Coefficients
        NSMutableArray<NSNumber *> *a = [NSMutableArray array];
        NSMutableArray<NSNumber *> *b = [NSMutableArray array];
        NSMutableArray<NSNumber *> *c = [NSMutableArray array];
        
        for (NSInteger i = 0; i < count; i++)
        {
            CGFloat rhsValueX = 0;
            CGFloat rhsValueY = 0;
            
            CGPoint P0 = dataPoints[i].CGPointValue;
            CGPoint P3 = dataPoints[i + 1].CGPointValue;
            
            if (i == 0)
            {
                [a addObject:@0.0];
                [b addObject:@2.0];
                [c addObject:@1.0];
                
                //rhs for first segment
                rhsValueX = P0.x + 2 * P3.x;
                rhsValueY = P0.y + 2 * P3.y;
            }
            else if (i == count - 1)
            {
                [a addObject:@2.0];
                [b addObject:@7.0];
                [c addObject:@0.0];
                
                //rhs for last segment
                rhsValueX = 8 * P0.x + P3.x;
                rhsValueY = 8 * P0.y + P3.y;
            }
            else
            {
                [a addObject:@1.0];
                [b addObject:@4.0];
                [c addObject:@1.0];

                rhsValueX = 4 * P0.x + 2 * P3.x;
                rhsValueY = 4 * P0.y + 2 * P3.y;
            }
            [rhsArray addObject:[NSValue valueWithCGPoint:CGPointMake(rhsValueX, rhsValueY)]];
        }
        
        //Solve Ax=B. Use Tridiagonal matrix algorithm a.k.a Thomas Algorithm
        for (NSInteger i = 1; i < count; i++)
        {
            CGFloat rhsValueX = rhsArray[i].CGPointValue.x;
            CGFloat rhsValueY = rhsArray[i].CGPointValue.y;
            
            CGFloat prevRhsValueX = rhsArray[i - 1].CGPointValue.x;
            CGFloat prevRhsValueY = rhsArray[i - 1].CGPointValue.y;
            
            CGFloat m = a[i].doubleValue / b[i - 1].doubleValue;
            
            CGFloat b1 = b[i].doubleValue - m * c[i - 1].doubleValue;
            b[i] = @(b1);
            
            CGFloat r2x = rhsValueX - m * prevRhsValueX;
            CGFloat r2y = rhsValueY - m * prevRhsValueY;
            
            rhsArray[i] = [NSValue valueWithCGPoint:CGPointMake(r2x, r2y)];
        }
        //Get First Control Points
        
        //Last control Point
        CGFloat lastControlPointX = rhsArray[count - 1].CGPointValue.x / b[count-1].doubleValue;
        CGFloat lastControlPointY = rhsArray[count - 1].CGPointValue.y / b[count-1].doubleValue;
        
        firstControlPoints[count-1] = [NSValue valueWithCGPoint:CGPointMake(lastControlPointX, lastControlPointY)];
        
        for (NSInteger i = count - 2; i >= 0; i--)
        {
            NSValue *nextControlPoint = firstControlPoints[i + 1];
            if (![nextControlPoint isEqual:NSNull.null])
            {
                CGFloat controlPointX = (rhsArray[i].CGPointValue.x - c[i].doubleValue * nextControlPoint.CGPointValue.x) / b[i].doubleValue;
                CGFloat controlPointY = (rhsArray[i].CGPointValue.y - c[i].doubleValue * nextControlPoint.CGPointValue.y) / b[i].doubleValue;
                
                firstControlPoints[i] = [NSValue valueWithCGPoint:CGPointMake(controlPointX, controlPointY)];
            }
        }
        
        //Compute second Control Points from first
        for (NSInteger i = 0; i < count; i++)
        {
            if (i == count - 1)
            {
                CGPoint P3 = dataPoints[i + 1].CGPointValue;
                NSValue *P1Value = firstControlPoints[i];
                if ([P1Value isEqual:NSNull.null])
                    continue;

                CGPoint P1 = P1Value.CGPointValue;
                
                CGFloat controlPointX = (P3.x + P1.x) / 2.0;
                CGFloat controlPointY = (P3.y + P1.y) / 2.0;
                
                [secondControlPoints addObject:[NSValue valueWithCGPoint:CGPointMake(controlPointX, controlPointY)]];
            }
            else
            {
                CGPoint P3 = dataPoints[i+1].CGPointValue;
                NSValue *nextP1Value = firstControlPoints[i + 1];
                if ([nextP1Value isEqual:NSNull.null])
                    continue;

                CGPoint nextP1 = nextP1Value.CGPointValue;
                CGFloat controlPointX = 2 * P3.x - nextP1.x;
                CGFloat controlPointY = 2 * P3.y - nextP1.y;
                
                [secondControlPoints addObject:[NSValue valueWithCGPoint:CGPointMake(controlPointX, controlPointY)]];
            }
        }
    }
    
    NSMutableArray<NSValue *> *controlPoints = [NSMutableArray array];
    for (NSInteger i = 0; i < count; i++)
    {
        NSValue *firstControlPoint = firstControlPoints[i];
        NSValue *secondControlPoint = secondControlPoints[i];
        if (![firstControlPoint isEqual:NSNull.null] && ![secondControlPoint isEqual:NSNull.null])
        {
            [controlPoints addObject:firstControlPoint];
            [controlPoints addObject:secondControlPoint];
        }
    }
    return controlPoints;
}

+ (unsigned long long) folderSize:(NSString *)folderPath
{
    NSArray *filesArray = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:folderPath error:nil];
    NSEnumerator *filesEnumerator = [filesArray objectEnumerator];
    NSString *fileName;
    unsigned long long fileSize = 0;
    while (fileName = [filesEnumerator nextObject])
    {
        NSDictionary *fileDictionary = [[NSFileManager defaultManager] attributesOfItemAtPath:[folderPath stringByAppendingPathComponent:fileName] error:nil];
        fileSize += [fileDictionary fileSize];
        NSLog(@"file=%@ (%llu)", fileName, fileSize);
    }
    
    return fileSize;
}

+ (NSString *) getLocalizedRouteInfoProperty:(NSString *)properyName
{
    return OALocalizedString([NSString stringWithFormat:@"%@_name", properyName]);
}

+ (BOOL) isIPad
{
    return UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad;
}

+ (BOOL) isColorBright:(UIColor *)color
{
    CGFloat luminance = 0;

    CGColorSpaceRef colorSpace = CGColorGetColorSpace(color.CGColor);
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(colorSpace);

    if(colorSpaceModel == kCGColorSpaceModelRGB)
    {
        CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
        [color getRed:&red green:&green blue:&blue alpha:&alpha];

        luminance = ((red * 0.299) + (green * 0.587) + (blue * 0.114));
    }
    else
    {
        [color getWhite:&luminance alpha:0];
    }

    return luminance >= .5f;
}

+ (NSAttributedString *) createAttributedString:(NSString *)text font:(UIFont *)font color:(UIColor *)color strokeColor:(UIColor *)strokeColor strokeWidth:(float)strokeWidth
{
    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    attributes[NSParagraphStyleAttributeName] = paragraphStyle;

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    NSRange valueRange = NSMakeRange(0, text.length);
    if (valueRange.length > 0)
    {
        [string addAttribute:NSFontAttributeName value:font range:valueRange];
        [string addAttribute:NSForegroundColorAttributeName value:color range:valueRange];
        if (strokeColor)
            [string addAttribute:NSStrokeColorAttributeName value:strokeColor range:valueRange];
        if (strokeWidth > 0)
            [string addAttribute:NSStrokeWidthAttributeName value:[NSNumber numberWithFloat: -strokeWidth] range:valueRange];
    }
    return string;
}

+ (NSDictionary *) getSortedVoiceProviders
{
    OAAppSettings *settings = [OAAppSettings sharedManager];
    NSArray *screenVoiceProviderNames = [OAFileNameTranslationHelper getVoiceNames:settings.ttsAvailableVoices];
    OrderedDictionary *mapping = [OrderedDictionary dictionaryWithObjects:settings.ttsAvailableVoices forKeys:screenVoiceProviderNames];
    
    NSArray *sortedKeys = [mapping.allKeys sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    MutableOrderedDictionary *res = [[MutableOrderedDictionary alloc] init];
    for (NSString *key in sortedKeys)
    {
        [res setObject:[mapping objectForKey:key] forKey:key];
    }
    return res;
}

+ (UIView *) setupTableHeaderViewWithText:(NSString *)text font:(UIFont *)font textColor:(UIColor *)textColor lineSpacing:(CGFloat)lineSpacing isTitle:(BOOL)isTitle
{
    CGFloat textWidth = DeviceScreenWidth - (16 + OAUtilities.getLeftMargin) * 2;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16 + OAUtilities.getLeftMargin, 0.0, textWidth, CGFLOAT_MAX)];
    if (!isTitle)
    {
        NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
        [style setLineSpacing:lineSpacing];
        label.attributedText = [[NSAttributedString alloc] initWithString:text
                                attributes:@{NSParagraphStyleAttributeName : style}];
    }
    label.text = text;
    label.font = font;
    label.textColor = textColor;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [label sizeToFit];
    CGRect frame = label.frame;
    frame.size.height = label.frame.size.height + (isTitle ? 0.0 : 30.0);
    frame.size.width = textWidth;
    frame.origin.y = 8.0;
    label.frame = frame;
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, label.frame.size.height + 8)];
    [tableHeaderView addSubview:label];
    return tableHeaderView;
}

+ (UIView *) setupTableHeaderViewWithText:(NSString *)text font:(UIFont *)font tintColor:(UIColor *)tintColor icon:(NSString *)iconName
{
    CGFloat iconFrameSize = 34;
    CGFloat textWidth = DeviceScreenWidth - (16 + OAUtilities.getLeftMargin * 2) - 12 - iconFrameSize - 16;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(16 + OAUtilities.getLeftMargin, 0.0, textWidth, CGFLOAT_MAX)];
    label.text = text;
    label.font = font;
    label.textColor = UIColor.blackColor;
    label.numberOfLines = 2;
    label.lineBreakMode = NSLineBreakByTruncatingTail;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [label sizeToFit];
    CGRect frame = label.frame;
    frame.size.height = label.frame.size.height;
    frame.origin.y = 8.0;
    label.frame = frame;
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, label.frame.size.height + 8)];
    [tableHeaderView addSubview:label];
    UIView *imageContainer = [[UIView alloc] initWithFrame:CGRectMake(DeviceScreenWidth - 12 - OAUtilities.getLeftMargin - iconFrameSize, tableHeaderView.frame.size.height / 2 - iconFrameSize / 2, iconFrameSize, iconFrameSize)];
    imageContainer.backgroundColor = UIColor.whiteColor;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(2, 2, 30, 30);
    imageView.contentMode = UIViewContentModeCenter;
    [imageView setTintColor:tintColor];
    [imageView setImage:[[UIImage imageNamed:iconName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    
    [imageContainer insertSubview:imageView atIndex:0];
    imageContainer.layer.cornerRadius = iconFrameSize / 2;
    
    [tableHeaderView addSubview:imageContainer];
    
    return tableHeaderView;
}

+ (CGFloat) heightForHeaderViewText:(NSString *)text width:(CGFloat)width font:(UIFont *)font lineSpacing:(CGFloat)lineSpacing
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = lineSpacing;
    style.alignment = NSTextAlignmentCenter;
    NSAttributedString *attributedText = [[NSAttributedString alloc] initWithString:text attributes:@{NSParagraphStyleAttributeName : style, NSFontAttributeName : font}];
    
    return [self calculateTextBounds:attributedText width:width].height;
}

+ (NSMutableAttributedString *) getStringWithBoldPart:(NSString *)wholeString mainString:(NSString *)ms boldString:(NSString *)bs lineSpacing:(CGFloat)lineSpacing
{
    return [self.class getStringWithBoldPart:wholeString mainString:ms boldString:bs lineSpacing:lineSpacing fontSize:0. highlightColor:nil];
}

+ (NSMutableAttributedString *) getStringWithBoldPart:(NSString *)wholeString mainString:(NSString *)ms boldString:(NSString *)bs lineSpacing:(CGFloat)lineSpacing fontSize:(CGFloat)fontSize;
{
    return [self.class getStringWithBoldPart:wholeString mainString:ms boldString:bs lineSpacing:lineSpacing fontSize:fontSize highlightColor:nil];
}

+ (NSMutableAttributedString *) getStringWithBoldPart:(NSString *)wholeString mainString:(NSString *)ms boldString:(NSString *)bs lineSpacing:(CGFloat)lineSpacing fontSize:(CGFloat)fontSize highlightColor:(UIColor *)highlightColor
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:lineSpacing];
    NSMutableAttributedString *descriptionAttributedString = [[NSMutableAttributedString alloc] initWithString:wholeString
                                                                                                    attributes:@{NSParagraphStyleAttributeName : style}];
    NSString *boldString = bs;
    NSString *mainString = ms;
    NSRange boldRange = [wholeString rangeOfString:boldString];
    NSRange mainRange = [wholeString rangeOfString:mainString];
    [descriptionAttributedString addAttribute: NSFontAttributeName value:[UIFont systemFontOfSize:fontSize > 0 ? fontSize : 15] range:mainRange];
    [descriptionAttributedString addAttribute: NSFontAttributeName value:[UIFont boldSystemFontOfSize:fontSize] range:boldRange];
    if (highlightColor)
        [descriptionAttributedString addAttribute: NSForegroundColorAttributeName value:highlightColor range:boldRange];
    return descriptionAttributedString;
}

+ (NSAttributedString *) getColoredString:(NSString *)wholeString highlightedString:(NSString *)hs highlightColor:(UIColor *)highlightColor fontSize:(CGFloat)fontSize centered:(BOOL)centered
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:wholeString
                                                                                                    attributes:@{NSParagraphStyleAttributeName : style}];
    NSString *highlightedString = hs;
    NSString *mainString = wholeString;
    NSRange highlightedRange = [wholeString rangeOfString:highlightedString];
    NSRange mainRange = [wholeString rangeOfString:mainString];
    [attributedString addAttribute: NSFontAttributeName value:[UIFont systemFontOfSize:fontSize > 0 ? fontSize : 15] range:mainRange];
    [attributedString addAttribute: NSFontAttributeName value:[UIFont systemFontOfSize:fontSize > 0 ? fontSize : 15] range:highlightedRange];
    if (highlightColor)
        [attributedString addAttribute: NSForegroundColorAttributeName value:highlightColor range:highlightedRange];
    if (centered)
    {
        NSMutableParagraphStyle *paragraphStyle = NSMutableParagraphStyle.new;
        paragraphStyle.alignment = NSTextAlignmentCenter;
        [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, attributedString.length)];
    }
    return attributedString;
}

+ (NSDate *) getFileLastModificationDate:(NSString *)fileName
{
    NSString *path = [[OsmAndApp instance].gpxPath stringByAppendingPathComponent:fileName];
    if (path)
    {
        NSDictionary* fileAttribs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
        return [fileAttribs objectForKey:NSFileModificationDate];
    }
    return nil;
}

+ (NSString *) getGpxShortPath:(NSString *)fullFilePath
{
    NSString *pathToDelete = [OsmAndApp.instance.gpxPath stringByAppendingString:@"/"];
    NSString *trackFolderName =  [[fullFilePath stringByReplacingOccurrencesOfString:pathToDelete withString:@""] stringByDeletingLastPathComponent];
    return [trackFolderName stringByAppendingPathComponent:fullFilePath.lastPathComponent];
}

@end
