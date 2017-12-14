//
//  OAUtilities.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 9/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

//RGB color macro
#define UIColorFromRGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

#define UIColorFromRGBA(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF000000) >> 24))/255.0 \
green:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
blue:((float)((rgbValue & 0xFF00) >> 8 ))/255.0 \
alpha:((float)((rgbValue & 0xFF))/255.0)]

#define UIColorFromARGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 24))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 16))/255.0 \
blue:((float)((rgbValue & 0xFF) >> 8 ))/255.0 \
alpha:((float)((rgbValue & 0xFF000000))/255.0)]

@interface UIBezierPath (util)

- (void) cubicToX:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 x3:(float)x3 y3:(float)y3;
- (void) arcTo:(CGRect)oval startAngle:(float)startAngle sweepAngle:(float)sweepAngle;
- (void) addArc:(CGRect)oval startAngle:(float)startAngle sweepAngle:(float)sweepAngle;
- (void) moveToX:(CGFloat)x y:(CGFloat)y;
- (void) lineToX:(CGFloat)x y:(CGFloat)y;
- (void) rLineToX:(CGFloat)x y:(CGFloat)y;

@end

@interface NSMutableArray (util)

+ (instancetype)arrayWithObject:(NSObject *)object count:(NSUInteger)cnt;

@end

@interface NSString (util)

- (int) indexOf:(NSString *)text;
- (int) indexOf:(NSString *)text start:(NSInteger)start;
- (NSString *) add:(NSString *)str;
- (NSString *) trim;
- (NSString *) lowerCase;
- (NSString *) upperCase;

@end

@interface OAUtilities : NSObject

+ (BOOL) iosVersionIsAtLeast:(NSString*)testVersion;
+ (BOOL) iosVersionIsExactly:(NSString*)testVersion;

+ (void) clearTmpDirectory;

+ (NSComparisonResult) compareInt:(int)x y:(int)y;
+ (NSComparisonResult) compareDouble:(double)x y:(double)y;

+ (BOOL) isWordComplete:(NSString *)text;

+ (UIImage *) getMxIcon:(NSString *)name;
+ (UIImage *) applyScaleFactorToImage:(UIImage *)image;
+ (NSString *) drawablePostfix;
+ (void) layoutComplexButton:(UIButton*)button;

+ (CGSize) calculateTextBounds:(NSString *)text width:(CGFloat)width font:(UIFont *)font;
+ (CGSize) calculateTextBounds:(NSString *)text width:(CGFloat)width height:(CGFloat)height font:(UIFont *)font;

+ (NSDictionary *) parseUrlQuery:(NSURL *)url;
+ (void) getHMS:(NSTimeInterval)timeInterval hours:(int*)hours minutes:(int*)minutes seconds:(int*)seconds;

+ (NSArray *) splitCoordinates:(NSString *)string;
+ (NSString *) floatToStrTrimZeros:(CGFloat)number;

+ (UIImage *) getTintableImage:(UIImage *)image;
+ (UIImage *) getTintableImageNamed:(NSString *)name;
+ (UIImage *) tintImageWithColor:(UIImage *)source color:(UIColor *)color;

+ (NSString *) colorToString:(UIColor *)color;
+ (UIColor *) colorFromString:(NSString *)colorStr;
+ (BOOL) areColorsEqual:(UIColor *)color1 color2:(UIColor *)color2;

+ (BOOL) doublesEqualUpToDigits:(int)digits source:(double)source destination:(double)destination;

+ (void) roundCornersOnView:(UIView *)view onTopLeft:(BOOL)tl topRight:(BOOL)tr bottomLeft:(BOOL)bl bottomRight:(BOOL)br radius:(CGFloat)radius;

+ (NSString *) currentLang;
+ (NSString *) capitalizeFirstLetterAndLowercase:(NSString *)s;
+ (NSString *) translatedLangName:(NSString *)lang;

+ (void) callUrl:(NSString *)url;
+ (void) callPhone:(NSString *)phonesString;

+ (BOOL) is12HourTimeFormat;

+ (float) degToRadf:(float)degrees;
+ (double) degToRadd:(double)degrees;
+ (float) radToDegf:(float)radians;
+ (double) radToDegd:(double)radians;

@end
