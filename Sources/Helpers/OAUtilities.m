//
//  OAUtilities.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 9/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAUtilities.h"
#import "OAAlertBottomSheetViewController.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OsmAndApp.h"
#import "OASizes.h"
#import "OrderedDictionary.h"
#import "OAFileNameTranslationHelper.h"
#import "OAOsmAndFormatter.h"
#import "OAColors.h"
#import "OASvgHelper.h"

#import <UIKit/UIDevice.h>
#import "OAIndexConstants.h"
#import <MBProgressHUD.h>
#import "OALinks.h"
#import "OsmAnd_Maps-Swift.h"
#import "GeneratedAssetSymbols.h"
#import <mach/mach.h>
#import <mach/mach_host.h>
#include <CommonCrypto/CommonDigest.h>
#import <CocoaSecurity.h>
#import <sys/utsname.h>

#import "OsmAnd_Maps-Swift.h"

#define kBlurViewTag -999
#define kSpinnerViewTag -998

#define kNavItemStackViewWithSubtitleTag -997
#define kTitleInNavItemStackViewTag -996
#define kSubtitleInNavItemStackViewTag -995

#define kNavItemStackViewWithCenterIconTag -994
#define kCenterIconInNavItemStackViewTag -993

#define kShadowViewTag -992

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

@implementation UIImage (util)

+ (UIImage *) templateImageNamed:(NSString *)imageName
{
    return [[UIImage imageNamed:imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

+ (UIImage *) rtlImageNamed:(NSString *)imageName
{
    return [UIImage imageNamed:imageName].imageFlippedForRightToLeftLayoutDirection;
}

+ (UIImage *) svgImageNamed:(NSString *)path
{
    return [OASvgHelper imageNamed:path];
}

+ (UIImage *) mapSvgImageNamed:(NSString *)name
{
    UIImage *img = [OASvgHelper mapImageNamed:name];
    if (img)
        img = [img imageWithTintColor:[UIColor colorNamed:ACColorNameIconColorSelected]];

    return img;
}

+ (UIImage *) mapSvgImageNamed:(NSString *)name renderingMode:(UIImageRenderingMode)mode
{
    UIImage *img = [OASvgHelper mapImageNamed:name];
    if (img)
        img = [img imageWithRenderingMode:mode];
    
    return img;
}

+ (UIImage *) mapSvgImageNamed:(NSString *)name scale:(float)scale
{
    UIImage *img = [OASvgHelper mapImageNamed:name scale:scale];
    if (img)
        img = [img imageWithTintColor:[UIColor colorNamed:ACColorNameIconColorSelected]];

    return img;
}

+ (UIImage *) mapSvgImageNamed:(NSString *)name width:(float)width height:(float)height
{
    CGFloat scale = [[UIScreen mainScreen] scale];
    UIImage *img = [OASvgHelper mapImageFromSvgResource:name width:width * scale height:height * scale];
    if (img)
        img = [img imageWithTintColor:[UIColor colorNamed:ACColorNameIconColorSelected]];

    return img;
}

@end

@implementation UIDevice (util)

+ (NSString *) machine
{
    struct utsname systemInfo;
    if (uname(&systemInfo) == 0)
        return [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];

    return nil;
}

@end

@implementation UIColor (util)

- (NSString *) toHexString
{
    const CGFloat *components = CGColorGetComponents(self.CGColor);

    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
                                      lroundf(r * 255),
                                      lroundf(g * 255),
                                      lroundf(b * 255)];
}

- (NSString *) toHexARGBString
{
    const CGFloat *components = CGColorGetComponents(self.CGColor);

    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    CGFloat a = components[3];
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX",
                                      lroundf(a * 255),
                                      lroundf(r * 255),
                                      lroundf(g * 255),
                                      lroundf(b * 255)];
}

- (NSString *) toHexRGBAString
{
    const CGFloat *components = CGColorGetComponents(self.CGColor);

    CGFloat r = components[0];
    CGFloat g = components[1];
    CGFloat b = components[2];
    CGFloat a = components[3];
    return [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX",
                                      lroundf(r * 255),
                                      lroundf(g * 255),
                                      lroundf(b * 255),
                                      lroundf(a * 255)];
}

- (int)toRGBNumber
{
    CGFloat r,g,b,a;
    [self getRed:&r green:&g blue:&b alpha:&a];

    uint32_t red = r * 255;
    uint32_t green = g * 255;
    uint32_t blue = b * 255;

    int result = (red << 16) + (green << 8) + blue;
    return result;
}

- (int)toRGBANumber
{
    CGFloat r,g,b,a;
    [self getRed:&r green:&g blue:&b alpha:&a];

    uint32_t red = r * 255;
    uint32_t green = g * 255;
    uint32_t blue = b * 255;
    uint32_t alpha = a * 255;

    int result = (red << 24) + (green << 16) + (blue << 8) + alpha;
    return result;
}

- (int)toARGBNumber
{
    CGFloat r,g,b,a;
    [self getRed:&r green:&g blue:&b alpha:&a];

    uint32_t red = r * 255;
    uint32_t green = g * 255;
    uint32_t blue = b * 255;
    uint32_t alpha = a * 255;

    int result = (alpha << 24) + (red << 16) + (green << 8) + blue;
    return result;
}

+ (UIColor *) colorFromString:(NSString *)string
{
    return UIColorFromARGB([self.class toNumberFromString:string]);
}

+ (int)toNumberFromString:(NSString *)string
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
            string = [@"ff" stringByAppendingString:string];
            break;
        }
        case 8:
        {
            //do nothing
            break;
        }
        default:
        {
            return 0;
        }
    }

    uint32_t rgba;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner scanHexInt:&rgba];
    return rgba;
}

+ (BOOL)colorRGB:(UIColor *)color1 equalToColorRGB:(UIColor *)color2
{
    int col1 = [color1 toRGBNumber];
    int col2 = [color2 toRGBNumber];
    return col1 == col2;
}

- (UIColor *)currentThemeColor
{
    if ([[ThemeManager shared] isLightTheme])
        return [self light];
    else
        return [self dark];
}

@end

@implementation UIFont (util)

- (UIFont *)scaled
{
    return [self scaled:[[UIFontMetrics defaultMetrics] scaledValueForValue:self.pointSize]];
}

- (UIFont *)scaled:(CGFloat)maximumSize
{
    return [[UIFontMetrics defaultMetrics] scaledFontForFont:self maximumPointSize:maximumSize];
}

+ (UIFont *)scaledSystemFontOfSize:(CGFloat)fontSize
{
    return [[UIFont systemFontOfSize:fontSize] scaled];
}

+ (UIFont *)scaledSystemFontOfSize:(CGFloat)fontSize maximumSize:(CGFloat)maximumSize
{
    return [[UIFont systemFontOfSize:fontSize] scaled:maximumSize];
}

+ (UIFont *)scaledSystemFontOfSize:(CGFloat)fontSize weight:(UIFontWeight)weight
{
    return [[UIFont systemFontOfSize:fontSize weight:weight] scaled];
}

+ (UIFont *)scaledSystemFontOfSize:(CGFloat)fontSize weight:(UIFontWeight)weight maximumSize:(CGFloat)maximumSize
{
    return [[UIFont systemFontOfSize:fontSize weight:weight] scaled:maximumSize];
}

+ (UIFont *)scaledBoldSystemFontOfSize:(CGFloat)fontSize
{
    return [[UIFont boldSystemFontOfSize:fontSize] scaled];
}

+ (UIFont *)scaledMonospacedDigitSystemFontOfSize:(CGFloat)fontSize weight:(UIFontWeight)weight
{
    return [[UIFont monospacedDigitSystemFontOfSize:fontSize weight:weight] scaled];
}

+ (UIFont *)scaledMonospacedSystemFontOfSize:(CGFloat)fontSize weight:(UIFontWeight)weight
{
    return [[UIFont monospacedSystemFontOfSize:fontSize weight:weight] scaled];
}

@end

@implementation NSMutableAttributedString (util)

- (void) addString:(NSString *)string fontWeight:(UIFontWeight)fontWeight size:(CGFloat)size
{
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:string];
    NSRange fullRange = NSMakeRange(0, string.length);
    UIFont *font = [UIFont scaledSystemFontOfSize:size weight:fontWeight];
    [attributedString addAttribute:NSFontAttributeName value:font range:fullRange];
    [self appendAttributedString:attributedString];
}

- (void) setFont:(UIFont *)font forString:(NSString *)string
{
    NSRange range = [self.string rangeOfString:string];
    [self addAttribute:NSFontAttributeName value:font range:range];
}

- (void) setFontSize:(CGFloat)size forString:(NSString *)string
{
    [self setFont:[UIFont scaledSystemFontOfSize:size] forString:string];
}

- (void) setFontWeight:(UIFontWeight)fontWeight andSize:(CGFloat)size forString:(NSString *)string
{
    [self setFont:[UIFont scaledSystemFontOfSize:size weight:fontWeight] forString:string];
}

- (void) setColor:(UIColor *)color forString:(NSString *)string
{
    NSRange range = [self.string rangeOfString:string];
    [self addAttribute:NSForegroundColorAttributeName value:color range:range];
}

- (void) setMinLineHeight:(CGFloat)height alignment:(NSTextAlignment)alignment forString:(NSString *)string
{
    NSRange range = [self.string rangeOfString:string];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.minimumLineHeight = height;
    paragraphStyle.alignment = alignment;
    [self addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:range];
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

- (BOOL) isValidURL
{
    NSDataDetector *detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray<NSTextCheckingResult *> *matches = [detector matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    return matches.count == 1 && matches[0].URL.host != nil;
}

- (NSString *) escapeUrl
{
    NSMutableCharacterSet *charset = [[NSCharacterSet URLQueryAllowedCharacterSet] mutableCopy];
    [charset removeCharactersInString:@"!*'();:@&=+$,/?%#[]\" "];
    NSString *encodedValue = [self stringByAddingPercentEncodingWithAllowedCharacters:charset];
    return encodedValue;
}

- (NSString *) sanitizeFileName
{
    return [[[self componentsSeparatedByCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"length > 0"]] componentsJoinedByString:@"_"];
}

- (NSString *) xmlStringToString
{
    NSDictionary *options = @{NSDocumentTypeDocumentAttribute : NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute : @(NSUTF8StringEncoding)};
    NSAttributedString *res = [[NSAttributedString alloc] initWithData:[self dataUsingEncoding:NSUTF8StringEncoding] options:options documentAttributes:nil error:nil];
    return res.string;
}

- (NSString *) regexReplacePattern:(NSString *)pattern newString:(NSString *)newString
{
    NSMutableString *result = [NSMutableString stringWithString:self];
    NSRange searchedRange = NSMakeRange(0, [self length]);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:nil];
    NSString *modifiedString = [regex stringByReplacingMatchesInString:result options:0 range:searchedRange withTemplate:newString];
    return modifiedString;
}

- (NSArray<NSString *> *) regexSplitInStringByPattern:(NSString *)pattern
{
    NSRegularExpressionOptions regexOptions = NSRegularExpressionCaseInsensitive;
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:regexOptions error:&error];

    NSRange searchedRange = NSMakeRange(0, [self length]);
    NSArray *matches = [regex matchesInString:self options:0 range:searchedRange];
    if (matches.count == 0)
        return @[self];
    
    NSMutableArray *results = [NSMutableArray array];
    NSInteger phraseStartIndex = 0;
    
    for (NSTextCheckingResult *match in matches) {
        NSRange separatorRange = [match range];
        NSString *phrase = [self substringWithRange:NSMakeRange(phraseStartIndex, separatorRange.location - phraseStartIndex)];
        if (phrase.length > 0)
            [results addObject:phrase];
        phraseStartIndex = separatorRange.location + separatorRange.length;
    }
    
    NSString *lastPhrase = [self substringFromIndex:phraseStartIndex];
    if (lastPhrase.length > 0)
        [results addObject:lastPhrase];
  
    return [NSArray arrayWithArray:results];
}

- (BOOL)isMatchedByRegex:(NSString *)regexPattern
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:0 error:nil];
    NSRange fullRange = NSMakeRange(0, self.length);
    NSRange matchedRange = [regex rangeOfFirstMatchInString:self options:0 range:fullRange];
    
    return (matchedRange.location != NSNotFound);
}

- (NSArray<NSString *> *)componentsSeparatedByRegex:(NSString *)regexPattern
{
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexPattern options:0 error:nil];
    NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)];

    NSMutableArray<NSString *> *components = [NSMutableArray array];
    NSUInteger previousLocation = 0;

    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match range];
        NSRange componentRange = NSMakeRange(previousLocation, matchRange.location - previousLocation);
        NSString *component = [self substringWithRange:componentRange];
        [components addObject:component];
        previousLocation = matchRange.location + matchRange.length;
    }

    // Add the remaining substring after the last match
    if (previousLocation < self.length) {
        NSString *remainingComponent = [self substringFromIndex:previousLocation];
        [components addObject:remainingComponent];
    }

    return [components copy];
}


@end

@implementation UIViewController (utils)

- (BOOL)isNavbarVisible
{
    return NO;
}

@end

@implementation UINavigationItem (util)

- (void)setStackViewWithTitle:(NSString *)title
                   titleColor:(UIColor *)titleColor
                    titleFont:(UIFont *)titleFont
                     subtitle:(NSString *)subtitle
                subtitleColor:(UIColor *)subtitleColor
                 subtitleFont:(UIFont *)subtitleFont
{
    UIStackView *stackView;

    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.tag = kTitleInNavItemStackViewTag;
    titleLabel.backgroundColor = UIColor.clearColor;
    titleLabel.text = title;
    titleLabel.textColor = titleColor;
    titleLabel.font = titleFont;

    if (subtitle)
    {
        UILabel *subtitleLabel = [[UILabel alloc] init];
        subtitleLabel.tag = kSubtitleInNavItemStackViewTag;
        subtitleLabel.backgroundColor = UIColor.clearColor;
        subtitleLabel.text = subtitle;
        subtitleLabel.textColor = subtitleColor;
        subtitleLabel.font = subtitleFont;
        stackView = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, subtitleLabel]];
    }
    else
    {
        stackView = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel]];
    }

    stackView.tag = kNavItemStackViewWithSubtitleTag;
    stackView.backgroundColor = UIColor.clearColor;
    stackView.distribution = UIStackViewDistributionEqualCentering;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.axis = UILayoutConstraintAxisVertical;
    [stackView layoutSubviews];

    self.titleView = stackView;
}

- (void)hideTitleInStackView:(BOOL)hide defaultTitle:(NSString *)defaultTitle defaultSubtitle:(NSString *)defaultSubtitle
{
    if (self.titleView && self.titleView.tag == kNavItemStackViewWithSubtitleTag)
    {
        [UIView animateWithDuration:.2 animations:^{
            if (self.titleView.subviews.firstObject.tag == kTitleInNavItemStackViewTag)
            {
                UILabel *titleLabel = self.titleView.subviews.firstObject;
                titleLabel.text = hide ? @"" : defaultTitle;
                titleLabel.alpha = hide ? 0. : 1.;
            }
            if (self.titleView.subviews.count == 2 && self.titleView.subviews.lastObject.tag == kSubtitleInNavItemStackViewTag)
            {
                UILabel *subtitleLabel = self.titleView.subviews.lastObject;
                subtitleLabel.text = hide ? @"" : defaultSubtitle;
                subtitleLabel.alpha = hide ? 0. : 1.;
            }
        }];
    }
}

- (BOOL)isTitleInStackViewHidden
{
    if (self.titleView && self.titleView.tag == kNavItemStackViewWithSubtitleTag)
    {
        if (self.titleView.subviews.firstObject.tag == kTitleInNavItemStackViewTag)
            return ((UILabel *) self.titleView.subviews.firstObject).text.length == 0;
    }
    return NO;
}

- (void)setStackViewWithCenterIcon:(UIImage *)icon
{
    UIImageView *iconView = [[UIImageView alloc] init];
    iconView.tag = kCenterIconInNavItemStackViewTag;
    iconView.backgroundColor = UIColor.clearColor;
    iconView.image = icon;
    UIStackView *stackView = [[UIStackView alloc] initWithArrangedSubviews:@[iconView]];

    stackView.tag = kNavItemStackViewWithCenterIconTag;
    stackView.backgroundColor = UIColor.clearColor;
    stackView.distribution = UIStackViewDistributionEqualCentering;
    stackView.alignment = UIStackViewAlignmentCenter;
    stackView.axis = UILayoutConstraintAxisVertical;
    [stackView layoutSubviews];

    self.titleView = stackView;
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

- (void) setCornerRadius:(CGFloat)value
{
    self.layer.cornerRadius = value;
}

- (void) addBlurEffect:(BOOL)light cornerRadius:(CGFloat)cornerRadius padding:(CGFloat)padding
{
    self.backgroundColor = [UIColor clearColor];
    
    UIView *existingBlurView = [self viewWithTag:kBlurViewTag];
    if (existingBlurView)
        [existingBlurView removeFromSuperview];
            
    UIBlurEffect *blurEffect;

    blurEffect = [UIBlurEffect effectWithStyle:light
                ? UIBlurEffectStyleSystemUltraThinMaterialLight : UIBlurEffectStyleSystemUltraThinMaterialDark];

    UIView *blurView;
    if (!UIAccessibilityIsReduceTransparencyEnabled())
    {
        blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurView.backgroundColor = [UIColor clearColor];
    }
    else
    {
        blurView = [[UIView alloc] init];
        blurView.backgroundColor = UIColorFromRGB(color_dialog_transparent_bg_argb_light);
    }
    blurView.tag = kBlurViewTag;
    blurView.userInteractionEnabled = NO;
    if (cornerRadius > 0)
    {
        blurView.layer.cornerRadius = cornerRadius;
        blurView.layer.masksToBounds = YES;
    }

    [self insertSubview:blurView atIndex:0];

    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.leadingAnchor constraintEqualToAnchor:blurView.leadingAnchor constant:padding].active = YES;
    [self.trailingAnchor constraintEqualToAnchor:blurView.trailingAnchor constant:-padding].active = YES;
    [self.topAnchor constraintEqualToAnchor:blurView.topAnchor constant:padding].active = YES;
    [self.bottomAnchor constraintEqualToAnchor:blurView.bottomAnchor constant:-padding].active = YES;
}

- (void) removeBlurEffect
{
    [self removeBlurEffect:UIColor.whiteColor];
}

- (void) removeBlurEffect:(UIColor *)backgroundColor
{
    for (UIView *subview in self.subviews)
    {
        if (subview.tag == kBlurViewTag)
        {
            [subview removeFromSuperview];
            self.backgroundColor = backgroundColor;
            break;
        }
    }
}

- (void) addSpinner
{
    [self addSpinnerInCenterOfCurrentView:NO];
}

- (void) addSpinnerInCenterOfCurrentView:(BOOL)inCurrentView
{
    for (UIView *subview in self.subviews)
    {
        if (subview.tag == kSpinnerViewTag)
            return;
    }

    UIActivityIndicatorViewStyle spinnerStyle = UIActivityIndicatorViewStyleLarge;

    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:spinnerStyle];
    
    if (inCurrentView)
        spinner.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
    else
        spinner.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);
    
    spinner.tag = kSpinnerViewTag;
    [self addSubview:spinner];
    [spinner startAnimating];
}

- (void) removeSpinner
{
    for (UIView *subview in self.subviews)
    {
        if (subview.tag == kSpinnerViewTag)
        {
            UIActivityIndicatorView *spinner = (UIActivityIndicatorView *) subview;
            [spinner stopAnimating];
            [spinner removeFromSuperview];
            break;
        }
    }
}

- (void) addShadow
{
    OAShadowTransporentTouchesPassView *shadowView = [self viewWithTag:kShadowViewTag];
    if (shadowView)
        return;

    shadowView = [[OAShadowTransporentTouchesPassView alloc] init];
    shadowView.tag = kShadowViewTag;
    shadowView.layer.cornerRadius = 7;
    shadowView.layer.shadowOpacity = 1;
    shadowView.layer.shadowColor = [UIColor colorWithRed:0.0 green:0 blue:0 alpha:0.31].CGColor;
    shadowView.layer.shadowOffset = CGSizeMake(0, 4);
    shadowView.layer.shadowRadius = 7;
    shadowView.layer.shouldRasterize = true;
    shadowView.layer.rasterizationScale = [UIScreen mainScreen].scale;

    shadowView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:shadowView];
    [NSLayoutConstraint activateConstraints:@[
        [shadowView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [shadowView.leftAnchor constraintEqualToAnchor:self.leftAnchor],
        [shadowView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [shadowView.rightAnchor constraintEqualToAnchor:self.rightAnchor]
    ]];
}

- (void) showShadow:(BOOL)show
{
    OAShadowTransporentTouchesPassView *shadowView = [self viewWithTag:kShadowViewTag];
    if (shadowView && shadowView.hidden == show)
        shadowView.hidden = !show;
}

- (UIImage *) toUIImage
{
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.0);
    [self.layer renderInContext:UIGraphicsGetCurrentContext()];

    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return img;
}

@end

@implementation UIButton (utils)

- (void) addBlurEffect:(BOOL)light cornerRadius:(CGFloat)cornerRadius padding:(CGFloat)padding
{
    [super addBlurEffect:light cornerRadius:cornerRadius padding:padding];

    UIImageView *imageView = self.imageView;
    if (imageView)
    {
        imageView.backgroundColor = [UIColor clearColor];
        [self bringSubviewToFront:imageView];
    }
}

@end

@implementation UITabBar (utils)

- (void)makeTranslucent:(BOOL)light
{
    self.translucent = YES;
    self.backgroundImage = [UIImage new];
    self.shadowImage = [UIImage new];
    self.barTintColor = UIColor.clearColor;
    self.backgroundColor = light ? UIColor.whiteColor : UIColor.blackColor;
    self.layer.backgroundColor = UIColor.clearColor.CGColor;
}

- (void) addBlurEffect:(BOOL)light cornerRadius:(CGFloat)cornerRadius padding:(CGFloat)padding
{
    [super addBlurEffect:light cornerRadius:cornerRadius padding:padding];
    [self makeTranslucent:YES];
}

@end

@implementation UITableViewCell (util)

+ (NSString *) getCellIdentifier
{
    return NSStringFromClass(self.class);
}

@end

@implementation UICollectionViewCell (util)

+ (NSString *) getCellIdentifier
{
    return NSStringFromClass(self.class);
}

@end

@implementation UITableViewHeaderFooterView (util)

+ (NSString *) getCellIdentifier
{
    return NSStringFromClass(self.class);
}

@end

@implementation NSMeasurementFormatter (util)

- (NSString *)displayStringFromUnit:(NSUnit *)unit
{
    NSString *displaySymbol = unit.displaySymbol;
    return displaySymbol != nil ? displaySymbol : [self stringFromUnit:unit];
}

@end

@implementation NSUnit (util)

+ (NSUnit *) unitFromString:(NSString *)unitStr
{
    NSMeasurementFormatter *formatter = [NSMeasurementFormatter new];
    formatter.locale = NSLocale.autoupdatingCurrentLocale;

    if ([unitStr isEqualToString:NSUnitCloud.percent.symbol]
            || [unitStr isEqualToString:[formatter stringFromUnit:NSUnitCloud.percent]])
        return NSUnitCloud.percent;
    if ([unitStr isEqualToString:NSUnitTemperature.celsius.symbol]
            || [unitStr isEqualToString:[formatter stringFromUnit:NSUnitTemperature.celsius]])
        return NSUnitTemperature.celsius;
    if ([unitStr isEqualToString:NSUnitTemperature.fahrenheit.symbol]
            || [unitStr isEqualToString:[formatter stringFromUnit:NSUnitTemperature.fahrenheit]])
        return NSUnitTemperature.fahrenheit;
    if ([unitStr isEqualToString:NSUnitPressure.hectopascals.symbol]
            || [unitStr isEqualToString:[formatter stringFromUnit:NSUnitPressure.hectopascals]])
        return NSUnitPressure.hectopascals;
    if ([unitStr isEqualToString:NSUnitPressure.millimetersOfMercury.symbol]
            || [unitStr isEqualToString:[formatter stringFromUnit:NSUnitPressure.millimetersOfMercury]])
        return NSUnitPressure.millimetersOfMercury;
    if ([unitStr isEqualToString:NSUnitPressure.inchesOfMercury.symbol]
            || [unitStr isEqualToString:[formatter stringFromUnit:NSUnitPressure.inchesOfMercury]])
        return NSUnitPressure.inchesOfMercury;
    if ([unitStr isEqualToString:NSUnitSpeed.metersPerSecond.symbol]
            || [unitStr isEqualToString:[formatter stringFromUnit:NSUnitSpeed.metersPerSecond]])
        return NSUnitSpeed.metersPerSecond;
    if ([unitStr isEqualToString:NSUnitSpeed.kilometersPerHour.symbol]
            || [unitStr isEqualToString:[formatter stringFromUnit:NSUnitSpeed.kilometersPerHour]])
        return NSUnitSpeed.kilometersPerHour;
    if ([unitStr isEqualToString:NSUnitSpeed.milesPerHour.symbol]
            || [unitStr isEqualToString:[formatter stringFromUnit:NSUnitSpeed.milesPerHour]])
        return NSUnitSpeed.milesPerHour;
    if ([unitStr isEqualToString:NSUnitSpeed.knots.symbol]
            || [unitStr isEqualToString:[formatter stringFromUnit:NSUnitSpeed.knots]])
        return NSUnitSpeed.knots;
    if ([unitStr isEqualToString:NSUnitLength.millimeters.symbol]
            || [unitStr isEqualToString:[formatter stringFromUnit:NSUnitLength.millimeters]])
        return NSUnitLength.millimeters;
    if ([unitStr isEqualToString:NSUnitLength.inches.symbol]
            || [unitStr isEqualToString:[formatter stringFromUnit:NSUnitLength.inches]])
        return NSUnitLength.inches;

    return nil;
}

+ (NSUnit *) current
{
    return nil;
}

- (NSString *) name
{
    return nil;
}

- (NSString *)displaySymbol
{
    return nil;
}

@end

@implementation NSUnitTemperature (util)

+ (NSUnitTemperature *)current
{
    NSMeasurementFormatter *formatter = [NSMeasurementFormatter new];
    formatter.locale = NSLocale.autoupdatingCurrentLocale;
    formatter.unitStyle = NSFormattingUnitStyleMedium;
    NSString *formatted = [formatter stringFromMeasurement:[[NSMeasurement alloc] initWithDoubleValue:0 unit:NSUnitTemperature.celsius]];
    NSString *symbol = [formatted substringFromIndex:2];
    NSUnitTemperature *unit = (NSUnitTemperature *) [NSUnit unitFromString:symbol];
    return unit ? unit : NSUnitTemperature.celsius;
}

- (NSString *)name
{
    if ([self.symbol isEqualToString:NSUnitTemperature.celsius.symbol])
        return OALocalizedString(@"weather_temperature_celsius");
    else if ([self.symbol isEqualToString:NSUnitTemperature.fahrenheit.symbol])
        return OALocalizedString(@"weather_temperature_fahrenheit");
    return nil;
}

- (NSString *)displaySymbol
{
    if ([self.symbol isEqualToString:NSUnitTemperature.celsius.symbol])
        return @"°C";
    else if ([self.symbol isEqualToString:NSUnitTemperature.fahrenheit.symbol])
        return @"°F";
    return nil;
}

@end

@implementation NSUnitSpeed (util)

+ (NSUnitSpeed *)current
{
    NSMeasurementFormatter *formatter = [NSMeasurementFormatter new];
    formatter.locale = NSLocale.autoupdatingCurrentLocale;
    NSString *formatted = [formatter stringFromMeasurement:[[NSMeasurement alloc] initWithDoubleValue:0 unit:NSUnitSpeed.metersPerSecond]];
    NSString *symbol = [formatted substringFromIndex:2];
    NSUnitSpeed *unit = (NSUnitSpeed *) [NSUnit unitFromString:symbol];
    return unit ? unit : NSUnitSpeed.metersPerSecond;
}

- (NSString *)name
{
    if ([self.symbol isEqualToString:NSUnitSpeed.metersPerSecond.symbol])
        return OALocalizedString(@"weather_wind_unit_m_s");
    else if ([self.symbol isEqualToString:NSUnitSpeed.kilometersPerHour.symbol])
        return OALocalizedString(@"weather_wind_kilimeters_per_hour");
    else if ([self.symbol isEqualToString:NSUnitSpeed.milesPerHour.symbol])
        return OALocalizedString(@"si_mph");
    else if ([self.symbol isEqualToString:NSUnitSpeed.knots.symbol])
        return OALocalizedString(@"weather_wind_knots");
    return nil;
}

@end

@implementation NSUnitPressure (util)

+ (NSUnitPressure *)current
{
    NSMeasurementFormatter *formatter = [NSMeasurementFormatter new];
    formatter.locale = NSLocale.autoupdatingCurrentLocale;
    NSString *formatted = [formatter stringFromMeasurement:[[NSMeasurement alloc] initWithDoubleValue:0 unit:NSUnitPressure.millimetersOfMercury]];
    NSString *symbol = [formatted substringFromIndex:2];
    NSUnitPressure *unit = (NSUnitPressure *) [NSUnit unitFromString:symbol];
    return unit ? unit : NSUnitPressure.millimetersOfMercury;
}

- (NSString *)name
{
    if ([self.symbol isEqualToString:NSUnitPressure.hectopascals.symbol])
        return OALocalizedString(@"weather_pressure_hectopascals");
    else if ([self.symbol isEqualToString:NSUnitPressure.millimetersOfMercury.symbol])
        return OALocalizedString(@"weather_pressure_millimeters_of_mercury");
    else if ([self.symbol isEqualToString:NSUnitPressure.inchesOfMercury.symbol])
        return OALocalizedString(@"weather_pressure_inches_of_mercury");
    return nil;
}

@end

@implementation NSUnitLength (util)

+ (NSUnitLength *)current
{
    NSMeasurementFormatter *formatter = [NSMeasurementFormatter new];
    formatter.locale = NSLocale.autoupdatingCurrentLocale;
    NSString *formatted = [formatter stringFromMeasurement:[[NSMeasurement alloc] initWithDoubleValue:0 unit:NSUnitLength.millimeters]];
    NSString *symbol = [formatted substringFromIndex:2];
    NSUnitLength *unit = (NSUnitLength *) [NSUnit unitFromString:symbol];
    return unit ? unit : NSUnitLength.millimeters;
}

- (NSString *)name
{
    if ([self.symbol isEqualToString:NSUnitLength.millimeters.symbol])
        return OALocalizedString(@"weather_precip_milimeters");
    else if ([self.symbol isEqualToString:NSUnitLength.inches.symbol])
        return OALocalizedString(@"weather_precip_inches");
    return nil;
}

@end

static NSUnitCloud * _percent;

@implementation NSUnitCloud

@dynamic percent;

+ (NSUnitCloud *)percent
{
    if (!_percent)
        _percent = [[NSUnitCloud alloc] initWithSymbol:@"%"];
    return _percent;
}

+ (NSUnitCloud *)current
{
    return _percent;
}

- (NSString *)name
{
    return nil;
}

@end

@implementation OAUtilities

static NSMutableArray<NSString *> * _accessingSecurityScopedResource;

+ (BOOL) getAccessToFile:(NSString *)filePath
{
    if (filePath)
    {
        if (![filePath containsString:[OsmAndApp instance].inboxPath] && ![filePath containsString:NSTemporaryDirectory()])
        {
            if (!_accessingSecurityScopedResource)
                _accessingSecurityScopedResource = [NSMutableArray array];

            BOOL access = NO;
            NSURL *url = [NSURL fileURLWithPath:filePath];
            if (url)
            {
                access = [url startAccessingSecurityScopedResource];
                if (access)
                    [_accessingSecurityScopedResource addObject:filePath];
            }
            return access;
        }
        return YES;
    }
    return NO;
}

+ (void) denyAccessToFile:(NSString *)filePath removeFromInbox:(BOOL)remove
{
    if (filePath)
    {
        if (remove && [filePath containsString:[OsmAndApp instance].inboxPath])
        {
            [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
        }
        else if (remove && [filePath containsString:[[OsmAndApp instance].gpxPath stringByAppendingPathComponent:TEMP_DIR]])
        {
            [NSFileManager.defaultManager removeItemAtPath:[[OsmAndApp instance].gpxPath stringByAppendingPathComponent:TEMP_DIR] error:nil];
        }
        else
        {
            NSURL *url = [NSURL fileURLWithPath:filePath];
            if (url)
            {
                [url stopAccessingSecurityScopedResource];
                if (_accessingSecurityScopedResource)
                    [_accessingSecurityScopedResource removeObject:filePath];
            }
        }
    }
}

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

+ (int) extractIntegerNumber:(NSString *)s
{
    int i = 0;
    int k;
    for (k = 0; k < s.length; k++) {
        if (isdigit([s characterAtIndex:k])) {
            break;
        }
    }
    for (; k < s.length; k++) {
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

+ (BOOL) hasMapImage:(NSString *)resId
{
    return [[NSBundle mainBundle] pathForResource:resId
                                           ofType:@"svg"
                                      inDirectory:@"map-icons-svg"] != nil;
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

+ (CGSize) calculateTextBounds:(NSString *)text font:(UIFont *)font
{
    CGSize size = [text boundingRectWithSize:CGSizeMake(10000.0, 10000.0)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:@{ NSFontAttributeName: font }
                                     context:nil].size;

    return CGSizeMake(ceil(size.width), ceil(size.height));
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
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:attrDict context:nil].size;
    
    return CGSizeMake(ceil(size.width), ceil(size.height));
}

+ (CGSize) calculateTextBounds:(NSString *)text width:(CGFloat)width height:(CGFloat)height font:(UIFont *)font
{
    NSDictionary *attrDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              font, NSFontAttributeName, nil];
    
    CGSize size = [text boundingRectWithSize:CGSizeMake(ceil(width), height)
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading | NSStringDrawingTruncatesLastVisibleLine
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

+ (CLLocation *)parseLatLon:(NSString *)latLon
{
    NSArray<NSString *> *coords = [latLon componentsSeparatedByString:@","];
    if (coords.count != 2)
        return nil;
    
    double lat = [coords[0] doubleValue];
    double lon = [coords[1] doubleValue];
    return [[CLLocation alloc] initWithLatitude:lat longitude:lon];
}

+ (BOOL) isOsmAndMapUrl:(NSURL *)url
{
    return [self isOsmAndSite:url] && [self isPathPrefix:url pathPrefix:kOsmAndMapPathPrefix];
}

+ (BOOL) isOsmAndGoUrl:(NSURL *)url
{
    return [self isOsmAndSite:url] && [self isPathPrefix:url pathPrefix:kOsmAndGoPathPrefix];
}

+ (BOOL) isOsmAndSite:(NSURL *)url
{
    return [self isHttpOrHttpsScheme:url] && [self isOsmAndHost:url];
}

+ (BOOL) isHttpOrHttpsScheme:(NSURL *)url
{
    NSString *scheme = url.scheme;
    return scheme && ([scheme.lowercaseString isEqualToString:kHttpScheme] || [scheme.lowercaseString isEqualToString:kHttpsScheme]);
}

+ (BOOL) isOsmAndHost:(NSURL *)url
{
    NSString *host = url.host;
    return host && [host.lowercaseString hasSuffix:kOsmAndHost];
}

+ (BOOL) isPathPrefix:(NSURL *)url pathPrefix:(NSString *)pathPrefix
{
    NSString *path = url.path;
    return path && [path.lowercaseString hasPrefix:pathPrefix];
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
        CGImageRef maskImage = source.CGImage;
        CGFloat width = source.scale * source.size.width;
        CGFloat height = source.scale * source.size.height;
        CGRect bounds = CGRectMake(0,0,width,height);

        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef bitmapContext = CGBitmapContextCreate(NULL, width, height, 8, 0, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
        CGContextClipToMask(bitmapContext, bounds, maskImage);
        CGContextSetFillColorWithColor(bitmapContext, color.CGColor);
        CGContextFillRect(bitmapContext, bounds);

        CGImageRef mainViewContentBitmapContext = CGBitmapContextCreateImage(bitmapContext);
        CGContextRelease(bitmapContext);
        CGColorSpaceRelease(colorSpace);

        UIImage *res = [UIImage imageWithCGImage:mainViewContentBitmapContext scale:source.scale orientation:UIImageOrientationUp].imageFlippedForRightToLeftLayoutDirection;
        CGImageRelease(mainViewContentBitmapContext);
        return res;
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

+ (NSString *) appendMeters:(float)value
{
    NSString *formattedValue = [OAOsmAndFormatter getFormattedDistance:value];
    return value == 0.f ? OALocalizedString(@"shared_string_not_selected") : formattedValue;
}

+ (NSString *) appendSpeed:(float)value
{
    BOOL kilometers = [[OAAppSettings sharedManager].metricSystem get] == KILOMETERS_AND_METERS;
    value = kilometers ? value : round(value / 0.3048f);
    NSString *distUnitsFormat = [@"%g " stringByAppendingString:kilometers ? OALocalizedString(@"km_h") : OALocalizedString(@"mile_per_hour")];
    return value == 0.f ? OALocalizedString(@"shared_string_not_selected") : value == 0.000001f ? @">0" : [NSString stringWithFormat:distUnitsFormat, value];
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

+ (BOOL) isCoordEqual:(CLLocationCoordinate2D)srcLatLon destLat:(CLLocationCoordinate2D)desLatLon
{
    return [OAUtilities doublesEqualUpToDigits:5 source:srcLatLon.latitude destination:desLatLon.latitude] && [OAUtilities doublesEqualUpToDigits:5 source:srcLatLon.longitude destination:desLatLon.longitude];
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
    NSString *prefLang = [OAAppSettings sharedManager].settingPrefMapLanguage.get;
    if (!prefLang)
        prefLang = [OAUtilities currentLang];
    
    return prefLang;
}

+ (NSString *) currentLang
{
    NSString *firstLanguage = [[NSLocale preferredLanguages] firstObject];
    return [[firstLanguage componentsSeparatedByString:@"-"] firstObject];
}

+ (NSString *) capitalizeFirstLetter:(NSString *)s
{
    if (s && s.length > 1)
        return [[s substringToIndex:1].uppercaseString stringByAppendingString:[s substringFromIndex:1]];
    else
        return s;
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
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[url stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet]]
                                       options:@{}
                             completionHandler:nil];
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
    
    [OAAlertBottomSheetViewController showAlertWithTitle:OALocalizedString(@"make_call")
                                               titleIcon:@"ic_custom_info"
                                             cancelTitle:OALocalizedString(@"shared_string_cancel")
                                   selectableItemsTitles:parsedPhones
                                   selectableItemsImages:images
                                      selectColpletition:^(NSInteger selectedIndex) {
                                            for (int i = 0; i < parsedPhones.count; i++)
                                            {
                                                if (selectedIndex == i)
                                                {
                                                    NSString *p = parsedPhones[i];
                                                    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tel://" stringByAppendingString:p]] options:@{} completionHandler:nil];
                                                    break;
                                                }
                                            }
    }];
}

+ (UIImage *) getMxIcon:(NSString *)name
{
    NSString *fullIconName = name;
    if (![fullIconName hasPrefix:@"mx_"])
        fullIconName = [@"mx_" stringByAppendingString:name];

    return [UIImage mapSvgImageNamed:fullIconName];
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
    return [UIApplication sharedApplication].mainWindow.safeAreaInsets.top ?: 0.0;
}

+ (CGFloat) getBottomMargin
{
    return [UIApplication sharedApplication].mainWindow.safeAreaInsets.bottom ?: 0.0;
}

+ (CGFloat) getLeftMargin
{
    return [UIApplication sharedApplication].mainWindow.safeAreaInsets.left ?: 0.0;
}


+ (CGFloat) calculateScreenWidth
{
    if (NSThread.isMainThread)
        return [UIApplication sharedApplication].mainWindow ? [UIApplication sharedApplication].mainWindow.frame.size.width : UIScreen.mainScreen.bounds.size.width;
    // else dispatch to the main thread
    __block CGFloat result;
    dispatch_sync(dispatch_get_main_queue(), ^{
        result = [UIApplication sharedApplication].mainWindow ? [UIApplication sharedApplication].mainWindow.frame.size.width : UIScreen.mainScreen.bounds.size.width;
    });
    return result;
}

+ (CGFloat) calculateScreenHeight
{
    if (NSThread.isMainThread)
    {
        CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
        CGFloat screenHeigth = [UIApplication sharedApplication].mainWindow ? [UIApplication sharedApplication].mainWindow.frame.size.height : UIScreen.mainScreen.bounds.size.height;
        return screenHeigth - ((statusBarHeight == 40.0) ? (statusBarHeight - 20.0) : 0);
    }
    __block CGFloat result;
    dispatch_sync(dispatch_get_main_queue(), ^{
        CGFloat statusBarHeight = [OAUtilities getStatusBarHeight];
        CGFloat screenHeigth = [UIApplication sharedApplication].mainWindow ? [UIApplication sharedApplication].mainWindow.frame.size.height : UIScreen.mainScreen.bounds.size.height;
        result = screenHeigth - ((statusBarHeight == 40.0) ? (statusBarHeight - 20.0) : 0);
    });
    return result;
}

+ (BOOL)isiOSAppOnMac
{
    return [NSProcessInfo processInfo].isiOSAppOnMac;
}

+ (BOOL) isWindowed
{
    BOOL isiOSAppOnMac = [[self class] isiOSAppOnMac];
    return !isiOSAppOnMac && [self isIPad] && (DeviceScreenWidth != [[UIScreen mainScreen] bounds].size.width || [UIApplication sharedApplication].mainWindow.bounds.size.height != [[UIScreen mainScreen] bounds].size.height);
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

+ (BOOL) isPortrait
{
    return [[OAScreenOrientationHelper sharedInstance] isPortrait];
}

+ (BOOL) isLandscape
{
    return [[OAScreenOrientationHelper sharedInstance] isLandscape];
}

+ (BOOL) isLandscape:(UIInterfaceOrientation)intefaceOrientation
{
    return UIInterfaceOrientationIsLandscape(intefaceOrientation);
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
    NSInteger count = (NSInteger) dataPoints.count - 1;
    
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
    }
    
    return fileSize;
}

+ (NSString *) getLocalizedRouteInfoProperty:(NSString *)properyName
{
    return OALocalizedString([NSString stringWithFormat:@"%@_name", properyName]);
}

+ (BOOL) isIPhone
{
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone;
}

+ (BOOL) isIPad
{
    return [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad;
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

+ (NSAttributedString *) createAttributedString:(NSString *)text font:(UIFont *)font color:(UIColor *)color strokeColor:(UIColor *)strokeColor strokeWidth:(float)strokeWidth alignment:(NSTextAlignment)alignment;
{
    NSMutableDictionary<NSAttributedStringKey, id> *attributes = [NSMutableDictionary dictionary];
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.alignment = alignment;
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

+ (UIView *) setupTableHeaderViewWithText:(NSString *)text
                                     font:(UIFont *)font
                                textColor:(UIColor *)textColor
                               isBigTitle:(BOOL)isBigTitle
                          parentViewWidth:(CGFloat)parentViewWidth
{
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:text];
    [attributedText setFont:font forString:text];
    [attributedText setColor:textColor forString:text];
    return [self setupTableHeaderViewWithText:attributedText isBigTitle:isBigTitle rightIconName:nil tintColor:nil parentViewWidth:parentViewWidth];
}

+ (UIView *) setupTableHeaderViewWithText:(NSAttributedString *)attributedText
                               isBigTitle:(BOOL)isBigTitle
                            rightIconName:(NSString *)iconName
                                tintColor:(UIColor *)tintColor
                          parentViewWidth:(CGFloat)parentViewWidth
{
    CGFloat topOffset = isBigTitle ? 5. : kPaddingOnSideOfContent;
    CGFloat bottomOffset = isBigTitle ? 7. : kPaddingOnSideOfContent;
    return [self setupTableHeaderViewWithText:attributedText isBigTitle:isBigTitle topOffset:topOffset bottomOffset:bottomOffset rightIconName:iconName tintColor:tintColor parentViewWidth:parentViewWidth];
}

+ (UIView *) setupTableHeaderViewWithText:(NSAttributedString *)attributedText
                               isBigTitle:(BOOL)isBigTitle
                                topOffset:(CGFloat)topOffset
                             bottomOffset:(CGFloat)bottomOffset
                            rightIconName:(NSString *)iconName
                                tintColor:(UIColor *)tintColor
                          parentViewWidth:(CGFloat)parentViewWidth
{
    CGFloat sideOffset = [OAUtilities getLeftMargin] + (isBigTitle ? kSmallPaddingOnSideOfContent : kPaddingOnSideOfContent);
    CGFloat textWidth = parentViewWidth - sideOffset * 2;
    CGFloat textHeight = [self calculateTextBounds:attributedText width:textWidth].height;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(sideOffset, topOffset, textWidth, textHeight)];

    label.attributedText = attributedText;
    label.adjustsFontForContentSizeCategory = YES;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., parentViewWidth, topOffset + textHeight + bottomOffset)];
    [tableHeaderView addSubview:label];
    tableHeaderView.backgroundColor = UIColorFromRGB(color_primary_table_background);

    if (iconName && iconName.length > 0)
    {
        CGFloat iconFrameSize = 30.;
        CGFloat iconFrameOffsetSize = 4.;
        UIView *iconContainer = [[UIView alloc] initWithFrame:CGRectMake(parentViewWidth - 12. - [OAUtilities getLeftMargin] - iconFrameSize - iconFrameOffsetSize, tableHeaderView.frame.size.height / 2 - iconFrameSize / 2, iconFrameSize + iconFrameOffsetSize, iconFrameSize + iconFrameOffsetSize)];
        iconContainer.backgroundColor = UIColor.whiteColor;
        UIImageView *iconView = [[UIImageView alloc] init];
        iconView.frame = CGRectMake(iconFrameOffsetSize / 2, iconFrameOffsetSize / 2, iconFrameSize, iconFrameSize);
        iconView.contentMode = UIViewContentModeCenter;
        if (tintColor)
        {
            iconView.tintColor = tintColor;
            iconView.image = [UIImage templateImageNamed:iconName];
        }
        else
        {
            iconView.image = [UIImage imageNamed:iconName];
        }

        [iconContainer insertSubview:iconView atIndex:0];
        iconContainer.layer.cornerRadius = iconFrameSize / 2;
        [tableHeaderView addSubview:iconContainer];
    }

    return tableHeaderView;
}

+ (UIView *) setupTableHeaderViewWithText:(NSAttributedString *)text tintColor:(UIColor *)tintColor icon:(UIImage *)icon iconFrameSize:(CGFloat)iconFrameSize iconBackgroundColor:(UIColor *)iconBackgroundColor iconContentMode:(UIViewContentMode)contentMode
{
    return [self setupTableHeaderViewWithText:text tintColor:tintColor icon:icon iconFrameSize:iconFrameSize iconBackgroundColor:iconBackgroundColor iconContentMode:contentMode iconYOffset:0];
}

+ (UIView *) setupTableHeaderViewWithText:(NSAttributedString *)text tintColor:(UIColor *)tintColor icon:(UIImage *)icon iconFrameSize:(CGFloat)iconFrameSize iconBackgroundColor:(UIColor *)iconBackgroundColor iconContentMode:(UIViewContentMode)contentMode iconYOffset:(CGFloat)iconYOffset
{
    BOOL hasIcon = iconFrameSize > 0;
    CGFloat iconOffset = hasIcon ? 12 + iconFrameSize + 20 : 0;
    CGFloat textWidth = DeviceScreenWidth - (20 + OAUtilities.getLeftMargin * 2) - iconOffset;
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20 + OAUtilities.getLeftMargin, 0.0, textWidth, CGFLOAT_MAX)];
    label.adjustsFontForContentSizeCategory = YES;
    label.attributedText = text;
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    [label sizeToFit];
    CGRect frame = label.frame;
    frame.size.height = label.frame.size.height;
    frame.origin.y = 12.0;
    label.frame = frame;
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, DeviceScreenWidth, label.frame.size.height + 16)];
    [tableHeaderView addSubview:label];
    
    if (hasIcon)
    {
        CGFloat yOffset = iconYOffset == 0 ? tableHeaderView.frame.size.height / 2 - iconFrameSize / 2 : iconYOffset;
        UIView *imageContainer = [[UIView alloc] initWithFrame:CGRectMake(DeviceScreenWidth - 20 - OAUtilities.getLeftMargin - iconFrameSize, yOffset, iconFrameSize, iconFrameSize)];
        imageContainer.backgroundColor = iconBackgroundColor;
        
        UIImageView *imageView = [[UIImageView alloc] init];
        imageView.frame = CGRectMake(iconFrameSize / 2 - 15., iconFrameSize / 2 - 15., 30, 30);
        imageView.contentMode = contentMode;
        [imageView setTintColor:tintColor];
        [imageView setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        
        [imageContainer insertSubview:imageView atIndex:0];
        imageContainer.layer.cornerRadius = iconFrameSize / 2;
        
        [tableHeaderView addSubview:imageContainer];
    }
    
    return tableHeaderView;
}

+ (UIView *) setupTableHeaderViewWithAttributedText:(NSAttributedString *)attributedText
                                  topCenterIconName:(NSString *)iconName
                                           iconSize:(CGFloat)iconSize
                                    parentViewWidth:(CGFloat)parentViewWidth
{
    BOOL hasIcon = iconName != nil && iconName.length > 0 && iconSize > 0;
    BOOL hasText = attributedText != nil && attributedText.length > 0;

    UIImageView *imageView;
    if (hasIcon)
    {
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(parentViewWidth / 2 - iconSize / 2, 8., iconSize, iconSize)];
        imageView.image = [UIImage imageNamed:iconName];
    }

    UILabel *label;
    if (hasText)
    {
        CGFloat width = parentViewWidth - ([OAUtilities getLeftMargin] + 20) * 2;
        CGFloat height = [self calculateTextBounds:attributedText width:width].height;
        label = [[UILabel alloc] initWithFrame:CGRectMake(
            parentViewWidth / 2 - width / 2,
            (imageView ? imageView.frame.origin.y + imageView.frame.size.height + 34. : 4.),
            width,
            height)];
        label.attributedText = attributedText;
        label.numberOfLines = 0;
    }

    CGFloat headerHeight = 0.;
    if (imageView && !label)
        headerHeight = imageView.frame.origin.y + imageView.frame.size.height + 8.;
    else
        headerHeight = label.frame.origin.y + label.frame.size.height + 4.;
    
    UIView *tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0., 0., parentViewWidth, headerHeight)];
    if (imageView)
        [tableHeaderView addSubview:imageView];
    if (label)
        [tableHeaderView addSubview:label];

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
    return [self getStringWithBoldPart:wholeString mainString:ms boldString:bs lineSpacing:lineSpacing fontSize:fontSize boldFontSize:0 boldColor:highlightColor mainColor:nil];
}

+ (NSMutableAttributedString *) getStringWithBoldPart:(NSString *)wholeString mainString:(NSString *)ms boldString:(NSString *)bs lineSpacing:(CGFloat)lineSpacing fontSize:(CGFloat)fontSize boldFontSize:(CGFloat)boldFontSize boldColor:(UIColor *)boldColor mainColor:(UIColor *)mainColor
{
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    [style setLineSpacing:lineSpacing];
    NSMutableAttributedString *descriptionAttributedString = [[NSMutableAttributedString alloc] initWithString:wholeString
                                                                                                    attributes:@{NSParagraphStyleAttributeName : style}];
    NSString *boldString = bs;
    NSString *mainString = ms;
    NSRange boldRange = [wholeString rangeOfString:boldString];
    NSRange mainRange = [wholeString rangeOfString:mainString];
    [descriptionAttributedString addAttribute: NSFontAttributeName value:[UIFont scaledSystemFontOfSize:fontSize > 0 ? fontSize : 15] range:mainRange];
    [descriptionAttributedString addAttribute: NSFontAttributeName value:[UIFont scaledBoldSystemFontOfSize:boldFontSize > 0 ? boldFontSize : 15] range:boldRange];
    if (boldColor)
        [descriptionAttributedString addAttribute: NSForegroundColorAttributeName value:boldColor range:boldRange];
    if (mainColor)
        [descriptionAttributedString addAttribute:NSForegroundColorAttributeName value:mainColor range:mainRange];
    return descriptionAttributedString;
}

+ (NSAttributedString *) getColoredString:(NSString *)wholeString highlightedString:(NSString *)hs highlightColor:(UIColor *)highlightColor fontSize:(CGFloat)fontSize centered:(BOOL)centered
{
    if (!wholeString || wholeString.length == 0 || !hs || hs.length == 0)
        return nil;
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:wholeString
                                                                                                    attributes:@{NSParagraphStyleAttributeName : style}];
    NSString *highlightedString = hs;
    NSString *mainString = wholeString;
    NSRange highlightedRange = [wholeString rangeOfString:highlightedString];
    NSRange mainRange = [wholeString rangeOfString:mainString];
    [attributedString addAttribute: NSFontAttributeName value:[UIFont scaledSystemFontOfSize:fontSize > 0 ? fontSize : 15] range:mainRange];
    [attributedString addAttribute: NSFontAttributeName value:[UIFont scaledSystemFontOfSize:fontSize > 0 ? fontSize : 15] range:highlightedRange];
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

+ (NSArray<NSString *> *) getGpxFoldersListSorted:(BOOL)shouldSort shouldAddRootTracksFolder:(BOOL)shouldAddRootTracksFolder
{
    NSMutableArray<NSString *> *flattenedFilePaths = [self.class getFlattenedFileList:OsmAndApp.instance.gpxPath];
    NSMutableArray<NSString *> *flattenedRelativeFilePaths = [NSMutableArray array];
    for (NSString *path in flattenedFilePaths)
    {
        NSString *pathToDelete = [OsmAndApp.instance.gpxPath stringByAppendingString:@"/"];
        [flattenedRelativeFilePaths addObject:[path stringByReplacingOccurrencesOfString:pathToDelete withString:@""]];
    }
    
    if (shouldAddRootTracksFolder)
        [flattenedRelativeFilePaths addObject:OALocalizedString(@"shared_string_gpx_tracks")];
    
    if (shouldSort)
    {
        return [flattenedRelativeFilePaths sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            if ([obj1 isEqualToString:OALocalizedString(@"shared_string_gpx_tracks")])
                return NSOrderedAscending;
            else if ([obj2 isEqualToString:OALocalizedString(@"shared_string_gpx_tracks")])
                return NSOrderedDescending;
            else
                return [obj1 compare:obj2];
        }];
    }
    else
    {
        return [NSArray arrayWithArray:flattenedRelativeFilePaths];
    }
}

+ (NSMutableArray<NSString *> *) getFlattenedFileList:(NSString *)path
{
    NSMutableArray<NSString *> *allSubfolderPaths = [NSMutableArray new];
    
    NSString *currentFolderPath = path;
    if (!currentFolderPath || currentFolderPath.length == 0)
        currentFolderPath = OsmAndApp.instance.documentsPath;
    
    NSArray<NSString *> *subfolderPaths = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:currentFolderPath error:nil];
    for (NSString *subfolderPath in subfolderPaths)
    {
        if([subfolderPath.lastPathComponent hasPrefix:@"."])
            continue;
        
        NSString *fullSubfolderPath = [currentFolderPath stringByAppendingPathComponent:subfolderPath];
        BOOL isDir = NO;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:fullSubfolderPath isDirectory:&isDir];
        if (exists && isDir)
        {
            if (![allSubfolderPaths containsObject:fullSubfolderPath])
                [allSubfolderPaths addObject:fullSubfolderPath];
            
            NSMutableArray<NSString *> *foundSubfolderPaths = [self.class getFlattenedFileList:fullSubfolderPath];
            if (foundSubfolderPaths.count > 0)
            {
                for (NSString *path in foundSubfolderPaths)
                {
                    if (![allSubfolderPaths containsObject:path])
                        [allSubfolderPaths addObject:path];
                }
            }
        }
        
    }
    return allSubfolderPaths;
}

+ (NSAttributedString *) attributedStringFromHtmlString:(NSString *)html fontSize:(NSInteger)fontSize textColor:(UIColor *)textColor
{
    if (!textColor)
        textColor = [UIColor colorNamed:ACColorNameTextColorPrimary];

    CGFloat red, green, blue, alpha;
    [textColor.currentThemeColor getRed:&red green:&green blue:&blue alpha:&alpha];
    NSString *textColorString = [NSString stringWithFormat:@"rgba(%.0f, %.0f, %.0f, %.2f)", red*255, green*255, blue*255, alpha];

    NSString *modifiedFontHtml =
    @" <style> \n"
    @"   a { color: #5714CC; text-decoration: none;} \n"
    @"   body { font-family: -apple-system, BlinkMacSystemFont, HelveticaNeue; font-size: %ld; color: %@;} \n"
    @" </style> \n"
    @" <p>%@</p>";
    
    modifiedFontHtml = [NSString stringWithFormat:modifiedFontHtml, fontSize, textColorString, html];

    @try {
        @autoreleasepool {
            return [[NSMutableAttributedString alloc] initWithData:[modifiedFontHtml dataUsingEncoding:NSUTF8StringEncoding] options:@{NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType, NSCharacterEncodingDocumentAttribute:@(NSUTF8StringEncoding)} documentAttributes:nil error:nil];
        }
    } @catch (NSException *exception) {
        NSLog(@"Failed to attributedStringFromHtmlString from: %@ %@", html, exception);
        return [[NSAttributedString alloc] initWithString:@""];
    }
}

+ (NSString *) createNewFileName:(NSString *)oldName
{
    NSString *ext = oldName.pathExtension;
    NSString *nameWithoutExt = oldName.stringByDeletingPathExtension;
    
    NSMutableString *numberSection = [NSMutableString string];
    NSInteger i = nameWithoutExt.length - 1;
    BOOL hasNameNumberSection = NO;
    NSCharacterSet *numericSet = [NSCharacterSet decimalDigitCharacterSet];
    do {
        unichar c = [nameWithoutExt characterAtIndex:i];
        if ([numericSet characterIsMember:c])
        {
            [numberSection insertString:[NSString stringWithFormat:@"%C", c] atIndex:0];
        }
        else if (c == ' ' && numberSection.length > 0)
        {
            hasNameNumberSection = YES;
            break;
        }
        else
        {
            break;
        }
        i--;
    } while (i >= 0);
    NSInteger newNumberValue = (hasNameNumberSection ? [numberSection integerValue] : 0) + 1;
    
    NSString *newName;
    if (newNumberValue == 1)
        newName = [[NSString stringWithFormat:@"%@ %ld", nameWithoutExt, newNumberValue] stringByAppendingPathExtension:ext];
    else
        newName = [[NSString stringWithFormat:@"%@ %ld", [nameWithoutExt substringToIndex:i], newNumberValue] stringByAppendingPathExtension:ext];
    
    return newName;
}

+ (natural_t) get_free_memory
{
    mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;
    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);
    vm_statistics_data_t vm_stat;
    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
    {
        NSLog(@"Failed to fetch vm statistics");
        return 0;
    }
    /* Stats in bytes */
    natural_t mem_free = vm_stat.free_count * pagesize;
    return mem_free;
}

+ (NSString *) getLocalizedString:(NSString *)key
{
    return OALocalizedString(key);
}

+ (void) collectDirFiles:(NSString *)filePath list:(NSMutableArray<NSString *> *)list
{
    NSFileManager *fileManager = NSFileManager.defaultManager;
    BOOL isDir = NO;
    [fileManager fileExistsAtPath:filePath isDirectory:&isDir];
    if (isDir)
    {
        NSArray *files = [fileManager contentsOfDirectoryAtPath:filePath error:nil];
        if (files.count > 0)
        {
            for (NSString *subfolderFile in files)
            {
                [self collectDirFiles:subfolderFile list:list];
            }
        }
    }
    else if (filePath)
    {
        [list addObject:filePath];
    }
}

+ (NSString*) fileMD5:(NSString*)path
{
    NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];
    if( handle== nil )
        return @""; // file didnt exist

    CC_MD5_CTX md5;

    CC_MD5_Init(&md5);

    BOOL done = NO;
    while(!done)
    {
        NSData* fileData = [handle readDataOfLength:1000000]; // 1 mb chunk
        CC_MD5_Update(&md5, [fileData bytes], [fileData length]);
        if( [fileData length] == 0 )
            done = YES;
    }
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5_Final(digest, &md5);
    NSString* s = [NSString stringWithFormat: @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                   digest[0], digest[1],
                   digest[2], digest[3],
                   digest[4], digest[5],
                   digest[6], digest[7],
                   digest[8], digest[9],
                   digest[10], digest[11],
                   digest[12], digest[13],
                   digest[14], digest[15]];
    return s;
}

+ (NSString *) toMD5:(NSString *)text
{
    return [CocoaSecurity md5:text].hexLower;
}

+ (void) showMenuInView:(UIView *)parentView fromView:(UIView *)targetView
{
    if ([parentView canBecomeFirstResponder])
    {
        [parentView becomeFirstResponder];
        UIMenuController *menuController = UIMenuController.sharedMenuController;
        
        [menuController hideMenu];
        [menuController showMenuFromView:targetView rect:targetView.bounds];
    }
}

+ (NSString *) getFormattedValue:(NSString *)value unit:(NSString *)unit
{
    return [self getFormattedValue:value unit:unit separateWithSpace:YES];
}

+ (NSString *) getFormattedValue:(NSString *)value unit:(NSString *)unit separateWithSpace:(BOOL)separateWithSpace
{
    return [NSString stringWithFormat:separateWithSpace ? OALocalizedString(@"ltr_or_rtl_combine_via_space") : @"%@%@", value, unit];
}

+ (NSString *) buildGeoUrl:(double)latitude longitude:(double)longitude zoom:(int)zoom
{
    return [NSString stringWithFormat:@"geo:%.5f,%.5f?z=%i", latitude, longitude, zoom];
}

+ (void)showToast:(NSString *)title details:(NSString *)details duration:(NSTimeInterval)duration inView:(UIView *)view
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *allHUDs = [MBProgressHUD allHUDsForView:view];
        for (MBProgressHUD *hudView in allHUDs)
        {
            if (hudView.mode == MBProgressHUDModeText)
                [MBProgressHUD hideHUDForView:view animated:YES];
        }

        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:view animated:YES];
        hud.mode = MBProgressHUDModeText;
        hud.margin = 10.f;
        hud.yOffset = view.frame.size.height / 2 - 100;
        hud.cornerRadius = 18.f;
        hud.removeFromSuperViewOnHide = YES;
        hud.userInteractionEnabled = NO;

        hud.labelText = title ? title : details;
        hud.labelFont = [UIFont scaledSystemFontOfSize:14];

        hud.detailsLabelText = title ? details : nil;
        hud.detailsLabelFont = [UIFont scaledSystemFontOfSize:14];

        [hud hide:YES afterDelay:duration];
    });
}

+ (NSString *) formatWarnings:(NSArray<NSString *> *)warnings
{
    NSMutableString *builder = [[NSMutableString alloc] init];
    BOOL f = YES;
    for (NSString *w in warnings)
    {
        if (f)
            f = NO;
        else
            [builder appendString:@"\n"];
        [builder appendString:w];
    }
    return builder;
}

+ (NSDate *)getCurrentTimezoneDate:(NSDate *)sourceDate
{
    NSTimeZone *sourceTimeZone = [NSTimeZone timeZoneWithAbbreviation:@"GMT"];
    NSTimeZone *destinationTimeZone = [NSTimeZone systemTimeZone];
    NSInteger sourceGMTOffset = [sourceTimeZone secondsFromGMTForDate:sourceDate];
    NSInteger destinationGMTOffset = [destinationTimeZone secondsFromGMTForDate:sourceDate];
    NSTimeInterval interval = destinationGMTOffset - sourceGMTOffset;
    return [[NSDate alloc] initWithTimeInterval:interval sinceDate:sourceDate];
}

+ (NSString *)getRoutingStringPropertyName:(NSString *)propertyName defaultName:(NSString *)defaultName
{
    NSString *key = [NSString stringWithFormat:@"routing_attr_%@_name", propertyName];
    NSString *res = OALocalizedString(key);
    if ([res isEqualToString:key])
        res = defaultName;
    return res;
}

+ (int) convertCharToDist:(NSString *)ch firstLetter:(NSString *)firstLetter firstDist:(int)firstDist mult1:(int)mult1 mult2:(int)mult2
{
    int dist = firstDist;
    
    const char *chChar = [ch UTF8String];
    const char *firstLetterChar = [firstLetter UTF8String];
    
    for(int iteration = 1; iteration < chChar - firstLetterChar + 1; ++iteration)
    {
        dist *= iteration % 2 == 1 ? mult1 : mult2;
    }
    
    return dist;;
}

+ (BOOL) isValidFileName:(NSString *)name
{
    NSArray<NSString *> *illegalCharacters = @[ @"?", @":", @"\"", @"*", @"|", @"/", @"<", @">" ];
    if (!name)
    {
        return NO;
    }
    else
    {
        for (NSString *symbol in illegalCharacters)
        {
            int index = [name indexOf:symbol];
            if (index != -1)
                return NO;
        }
    }
    return YES;
}

+ (BOOL) isReleaseVersion
{
    return ![kDocsLatestVersion containsString:@"future-ios"];
}

@end
