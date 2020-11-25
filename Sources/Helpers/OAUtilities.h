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
alpha:((float)(rgbValue & 0xFF))/255.0]

#define UIColorFromARGB(rgbValue) [UIColor \
colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
green:((float)((rgbValue & 0xFF00) >> 8 ))/255.0 \
blue:((float)(rgbValue & 0xFF))/255.0 \
alpha:((float)((rgbValue & 0xFF000000) >> 24))/255.0]

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
- (int) lastIndexOf:(NSString *)text;
- (NSString *) add:(NSString *)str;
- (NSString *) trim;
- (NSString *) lowerCase;
- (NSString *) upperCase;
- (BOOL) isValidEmail;
- (NSString *) escapeUrl;
- (NSString *) sanitizeFileName;

@end

@interface UIView (util)

- (BOOL) setConstant:(NSString *)identifier constant:(CGFloat)constant;
- (CGFloat) getConstant:(NSString *)identifier;
- (BOOL) isDirectionRTL;

@end

@interface OAUtilities : NSObject

+ (BOOL) iosVersionIsAtLeast:(NSString*)testVersion;
+ (BOOL) iosVersionIsExactly:(NSString*)testVersion;

+ (void) clearTmpDirectory;

+ (NSComparisonResult) compareInt:(int)x y:(int)y;
+ (NSComparisonResult) compareDouble:(double)x y:(double)y;
+ (int) extractFirstIntegerNumber:(NSString *)s;

+ (BOOL) isWordComplete:(NSString *)text;

+ (NSString *) appendMeters:(float)value;
+ (NSString *) appendSpeed:(float)value;
+ (NSArray<NSString *> *) arrayOfMeterValues:(NSArray<NSNumber *> *) values;
+ (NSArray<NSString *> *) arrayOfSpeedValues:(NSArray<NSNumber *> *) values;

+ (UIImage *) getMxIcon:(NSString *)name;
+ (UIImage *) resizeImage:(UIImage *)image newSize:(CGSize)newSize;
+ (UIImage *) applyScaleFactorToImage:(UIImage *)image;
+ (NSString *) drawablePostfix;
+ (NSString *) drawablePath:(NSString *)resId;
+ (void) layoutComplexButton:(UIButton*)button;

+ (UIImage *) imageWithColor:(UIColor *)color;

+ (void) setMaskTo:(UIView*)view byRoundingCorners:(UIRectCorner)corners;
+ (void) setMaskTo:(UIView*)view byRoundingCorners:(UIRectCorner)corners radius:(CGFloat)radius;

+ (CGSize) calculateTextBounds:(NSAttributedString *)text width:(CGFloat)width;
+ (CGSize) calculateTextBounds:(NSString *)text width:(CGFloat)width font:(UIFont *)font;
+ (CGSize) calculateTextBounds:(NSString *)text width:(CGFloat)width height:(CGFloat)height font:(UIFont *)font;

+ (NSDictionary<NSString *, NSString *> *) parseUrlQuery:(NSURL *)url;
+ (void) getHMS:(NSTimeInterval)timeInterval hours:(int*)hours minutes:(int*)minutes seconds:(int*)seconds;

+ (NSArray *) splitCoordinates:(NSString *)string;
+ (NSString *) floatToStrTrimZeros:(CGFloat)number;

+ (UIImage *) getTintableImage:(UIImage *)image;
+ (UIImage *) getTintableImageNamed:(NSString *)name;
+ (UIImage *) tintImageWithColor:(UIImage *)source color:(UIColor *)color;
+ (UIImage *) layeredImageWithColor:(UIColor *)color bottom:(UIImage *)bottom center:(UIImage *)center top:(UIImage *)top;

+ (NSString *) colorToString:(UIColor *)color;
+ (UIColor *) colorFromString:(NSString *)colorStr;
+ (BOOL) areColorsEqual:(UIColor *)color1 color2:(UIColor *)color2;

+ (BOOL) doublesEqualUpToDigits:(int)digits source:(double)source destination:(double)destination;
+ (BOOL) isCoordEqual:(double)srcLat srcLon:(double)srcLon destLat:(double)destLat destLon:(double)destLon;
+ (BOOL) isCoordEqual:(double)srcLat srcLon:(double)srcLon destLat:(double)destLat destLon:(double)destLon upToDigits:(int)digits;

+ (void) roundCornersOnView:(UIView *)view onTopLeft:(BOOL)tl topRight:(BOOL)tr bottomLeft:(BOOL)bl bottomRight:(BOOL)br radius:(CGFloat)radius;

+ (NSString *) preferredLang;
+ (NSString *) currentLang;
+ (NSString *) capitalizeFirstLetterAndLowercase:(NSString *)s;
+ (NSString *) translatedLangName:(NSString *)lang;
+ (NSInteger) findFirstNumberEndIndex:(NSString *)value;

+ (void) callUrl:(NSString *)url;
+ (void) callPhone:(NSString *)phonesString;

+ (BOOL) is12HourTimeFormat;

+ (float) degToRadf:(float)degrees;
+ (double) degToRadd:(double)degrees;
+ (float) radToDegf:(float)radians;
+ (double) radToDegd:(double)radians;

+ (BOOL) isLeftSideLayout:(UIInterfaceOrientation)interfaceOrientation;
+ (CGFloat) getStatusBarHeight;
+ (CGFloat) getTopMargin;
+ (CGFloat) getBottomMargin;
+ (CGFloat) getLeftMargin;
+ (CGFloat) calculateScreenHeight;
+ (CGFloat) calculateScreenWidth;
+ (BOOL) isWindowed;
+ (BOOL) isIPad;
+ (void) adjustViewsToNotch:(CGSize)size topView:(UIView *)topView middleView:(UIView *)middleView bottomView:(UIView *)bottomView
        navigationBarHeight:(CGFloat)navigationBarHeight toolBarHeight:(CGFloat)toolBarHeight;
+ (BOOL) isLandscape;
+ (BOOL) isLandscapeIpadAware;

+ (NSArray<NSValue *> *) controlPointsFromPoints:(NSArray<NSValue *> *)dataPoints;

+ (unsigned long long) folderSize:(NSString *)folderPath;

+ (NSString *) getLocalizedRouteInfoProperty:(NSString *)properyName;

+ (BOOL) isColorBright:(UIColor *)color;
+ (NSAttributedString *) createAttributedString:(NSString *)text font:(UIFont *)font color:(UIColor *)color strokeColor:(UIColor *)strokeColor strokeWidth:(float)strokeWidth;
+ (UIView *) setupTableHeaderViewWithText:(NSString *)text font:(UIFont *)font textColor:(UIColor *)textColor lineSpacing:(CGFloat)lineSpacing isTitle:(BOOL)isTitle;
+ (UIView *) setupTableHeaderViewWithText:(NSString *)text font:(UIFont *)font tintColor:(UIColor *)tintColor icon:(NSString *)iconName;

+ (CGFloat) heightForHeaderViewText:(NSString *)text width:(CGFloat)width font:(UIFont *)font lineSpacing:(CGFloat)lineSpacing;

+ (NSDictionary *) getSortedVoiceProviders;
+ (NSMutableAttributedString *) getStringWithBoldPart:(NSString *)wholeString mainString:(NSString *)ms boldString:(NSString *)bs lineSpacing:(CGFloat)lineSpacing;
+ (NSMutableAttributedString *) getStringWithBoldPart:(NSString *)wholeString mainString:(NSString *)ms boldString:(NSString *)bs lineSpacing:(CGFloat)lineSpacing fontSize:(CGFloat)fontSize highlightColor:(UIColor *)highlightColor;
+ (NSMutableAttributedString *) getStringWithBoldPart:(NSString *)wholeString mainString:(NSString *)ms boldString:(NSString *)bs lineSpacing:(CGFloat)lineSpacing fontSize:(CGFloat)fontSize;

@end
