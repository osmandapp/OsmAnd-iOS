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
    
    [self addArcWithCenter:center radius:radius startAngle:[OAUtilities degToRadf:startAngle] endAngle:[OAUtilities degToRadf:startAngle + sweepAngle] clockwise:sweepAngle > 0];
    
    // TODO
    /*
    CGAffineTransform t = CGAffineTransformIdentity;
    if (dX > dY)
        t = CGAffineTransformMakeScale(1.0, dY / dX);
    else if (dY > dX)
        t = CGAffineTransformMakeScale(dX / dY, 1.0);

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, self.currentPoint.x, self.currentPoint.y);
    CGPathAddArc(path, &t, center.x, center.y, radius, [OAUtilities degToRadf:startAngle], [OAUtilities degToRadf:startAngle + sweepAngle], sweepAngle < 0);

    [self appendPath:[UIBezierPath bezierPathWithCGPath:path]];
    */
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
    CGFloat radius = MIN(dX, dY) / 2.0;
    [self addArcWithCenter:center radius:radius startAngle:[OAUtilities degToRadf:startAngle] endAngle:[OAUtilities degToRadf:startAngle + sweepAngle] clockwise:sweepAngle > 0];
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
    if (!image)
        return nil;
    
    @autoreleasepool
    {
        CGFloat scaleFactor = [[UIScreen mainScreen] scale];
        CGSize newSize = CGSizeMake(image.size.width / scaleFactor, image.size.height / scaleFactor);
        
        UIGraphicsBeginImageContextWithOptions(newSize, NO, scaleFactor);
        [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
        UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        return newImage;
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

+ (NSDictionary *) parseUrlQuery:(NSURL *)url
{
    NSMutableDictionary *queryStrings = [[NSMutableDictionary alloc] init];
    for (NSString *qs in [url.query componentsSeparatedByString:@"&"]) {
        // Get the parameter name
        NSString *key = [[qs componentsSeparatedByString:@"="] objectAtIndex:0];
        // Get the parameter value
        NSString *value = [[qs componentsSeparatedByString:@"="] objectAtIndex:1];
        value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
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

+ (NSString *) colorToString:(UIColor *)color
{
    CGFloat r,g,b,a;
    [color getRed:&r green:&g blue:&b alpha:&a];
    
    uint32_t red = r * 255;
    uint32_t green = g * 255;
    uint32_t blue = b * 255;
    
    return [NSString stringWithFormat:@"#%.6x", (red << 16) + (green << 8) + blue];
}

+ (UIColor *)colorFromString:(NSString *)string
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

+ (NSString *) translatedLangName:(NSString *)lang
{
    NSString *langName = [[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:lang];
    if (!langName)
        langName = lang;
    return langName;
}


+ (void) callUrl:(NSString *)url
{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[url stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]]];
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
    UIImage *img = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/mx_%@", [OAUtilities drawablePostfix], name]];
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


@end
