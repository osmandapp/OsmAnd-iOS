//
//  OAUtilities.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 9/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

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

#define kHeaderBigTitleFont [UIFont scaledSystemFontOfSize:34. weight:UIFontWeightBold]
#define kHeaderDescriptionFont [UIFont preferredFontForTextStyle:UIFontTextStyleSubheadline]
#define kHeaderDescriptionFontSmall [UIFont preferredFontForTextStyle:UIFontTextStyleFootnote]

static inline UIColor * colorFromRGB(NSInteger rgbValue)
{
    return UIColorFromRGB(rgbValue);
}

static inline UIColor * colorFromARGB(NSInteger rgbValue)
{
    return UIColorFromARGB(rgbValue);
}

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
- (BOOL) isValidURL;
- (NSString *) escapeUrl;
- (NSString *) sanitizeFileName;
- (NSString *) xmlStringToString;
- (NSString *) regexReplacePattern:(NSString *)pattern newString:(NSString *)newString;
- (NSArray<NSString *> *) regexSplitInStringByPattern:(NSString *)pattern;
- (BOOL)isMatchedByRegex:(NSString *)regexPattern;
- (NSArray<NSString *> *)componentsSeparatedByRegex:(NSString *)regexPattern;

@end

@interface UIImage (util)

+ (UIImage *) templateImageNamed:(NSString *)imageName;
+ (UIImage *) rtlImageNamed:(NSString *)imageName;
+ (UIImage *) svgImageNamed:(NSString *)path;
+ (UIImage *) mapSvgImageNamed:(NSString *)name;
+ (UIImage *) mapSvgImageNamed:(NSString *)name scale:(float)scale;
+ (UIImage *) mapSvgImageNamed:(NSString *)name width:(float)width height:(float)height;

@end

@interface UIViewController (util)

- (BOOL)isNavbarVisible;

@end

@interface UINavigationItem (util)


- (void)setStackViewWithTitle:(NSString *)title
                   titleColor:(UIColor *)titleColor
                    titleFont:(UIFont *)titleFont
                     subtitle:(NSString *)subtitle
                subtitleColor:(UIColor *)subtitleColor
                 subtitleFont:(UIFont *)subtitleFont;

- (void)hideTitleInStackView:(BOOL)hide defaultTitle:(NSString *)defaultTitle defaultSubtitle:(NSString *)defaultSubtitle;

- (BOOL)isTitleInStackViewHidden;

- (void)setStackViewWithCenterIcon:(UIImage *)icon;

@end

@interface UIView (util)

- (BOOL) setConstant:(NSString *)identifier constant:(CGFloat)constant;
- (CGFloat) getConstant:(NSString *)identifier;
- (BOOL) isDirectionRTL;
- (void) setCornerRadius:(CGFloat)value;
- (void) addBlurEffect:(BOOL)light cornerRadius:(CGFloat)cornerRadius padding:(CGFloat)padding;
- (void) removeBlurEffect;
- (void) removeBlurEffect:(UIColor *)backgroundColor;
- (void) addSpinner;
- (void) addSpinnerInCenterOfCurrentView:(BOOL)inCurrentView;
- (void) removeSpinner;
- (UIImage *) toUIImage;

@end

@interface UITabBar (util)

- (void) makeTranslucent:(BOOL)light;

@end

@interface UITableViewCell (util)

+ (NSString *) getCellIdentifier;

@end

@interface UICollectionViewCell (util)

+ (NSString *) getCellIdentifier;

@end

@interface UITableViewHeaderFooterView (util)

+ (NSString *) getCellIdentifier;

@end

@interface UIColor (util)

- (NSString *) toHexString;
- (NSString *) toHexARGBString;
- (NSString *) toHexRGBAString;
- (int) toRGBNumber;
- (int) toRGBANumber;
- (int) toARGBNumber;

+ (UIColor *) colorFromString:(NSString *)string;
+ (int) toNumberFromString:(NSString *)string;
+ (BOOL) colorRGB:(UIColor *)color1 equalToColorRGB:(UIColor *)color2;

- (UIColor *)lightThemeColor;
- (UIColor *)darkThemeColor;
- (UIColor *)currentThemeColor;

@end

@interface UIFont (util)

- (UIFont *)scaled;
- (UIFont *)scaled:(CGFloat)maximumSize;
+ (UIFont *)scaledSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)scaledSystemFontOfSize:(CGFloat)fontSize maximumSize:(CGFloat)maximumSize;
+ (UIFont *)scaledSystemFontOfSize:(CGFloat)fontSize weight:(UIFontWeight)weight;
+ (UIFont *)scaledSystemFontOfSize:(CGFloat)fontSize weight:(UIFontWeight)weight maximumSize:(CGFloat)maximumSize;
+ (UIFont *)scaledBoldSystemFontOfSize:(CGFloat)fontSize;
+ (UIFont *)scaledMonospacedDigitSystemFontOfSize:(CGFloat)fontSize weight:(UIFontWeight)weight;
+ (UIFont *)scaledMonospacedSystemFontOfSize:(CGFloat)fontSize weight:(UIFontWeight)weight API_AVAILABLE(ios(13.0));

@end

@interface NSMutableAttributedString (util)

- (void) addString:(NSString *)string fontWeight:(UIFontWeight)fontWeight size:(CGFloat)size;
- (void) setFont:(UIFont *)font forString:(NSString *)string;
- (void) setFontSize:(CGFloat)size forString:(NSString *)string;
- (void) setFontWeight:(UIFontWeight)fontWeight andSize:(CGFloat)size forString:(NSString *)string;
- (void) setColor:(UIColor *)color forString:(NSString *)string;
- (void) setMinLineHeight:(CGFloat)height alignment:(NSTextAlignment)alignment forString:(NSString *)string;

@end

@interface NSMeasurementFormatter (util)

- (NSString *)displayStringFromUnit:(NSUnit *)unit;

@end

@interface NSUnit (util)

+ (NSUnit *) unitFromString:(NSString *)unitStr;

+ (NSUnit *) current;
- (NSString *) name;
- (NSString *) displaySymbol;

@end

@interface NSUnitTemperature (util)

+ (NSUnitTemperature *) current;

@end

@interface NSUnitSpeed (util)

+ (NSUnitSpeed *) current;

@end

@interface NSUnitPressure (util)

+ (NSUnitPressure *) current;

@end

@interface NSUnitLength (util)

+ (NSUnitLength *) current;

@end

@interface NSUnitCloud : NSUnit

@property (class, readonly, copy) NSUnitCloud *percent;

+ (NSUnitCloud *) current;

@end

@interface OAUtilities : NSObject

+ (BOOL) getAccessToFile:(NSString *)filePath;
+ (void) denyAccessToFile:(NSString *)filePath removeFromInbox:(BOOL)remove;

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
+ (BOOL) hasMapImage:(NSString *)resId;
+ (void) layoutComplexButton:(UIButton*)button;

+ (UIImage *) imageWithColor:(UIColor *)color;

+ (void) setMaskTo:(UIView*)view byRoundingCorners:(UIRectCorner)corners;
+ (void) setMaskTo:(UIView*)view byRoundingCorners:(UIRectCorner)corners radius:(CGFloat)radius;

+ (CGSize) calculateTextBounds:(NSString *)text font:(UIFont *)font;
+ (CGSize) calculateTextBounds:(NSAttributedString *)text width:(CGFloat)width;
+ (CGSize) calculateTextBounds:(NSString *)text width:(CGFloat)width font:(UIFont *)font;
+ (CGSize) calculateTextBounds:(NSString *)text width:(CGFloat)width height:(CGFloat)height font:(UIFont *)font;

+ (NSDictionary<NSString *, NSString *> *) parseUrlQuery:(NSURL *)url;
+ (CLLocation *)parseLatLon:(NSString *)latLon;
+ (BOOL) isOsmAndMapUrl:(NSURL *)url;
+ (BOOL) isOsmAndGoUrl:(NSURL *)url;
+ (BOOL) isOsmAndSite:(NSURL *)url;
+ (BOOL) isPathPrefix:(NSURL *)url pathPrefix:(NSString *)pathPrefix;

+ (void) getHMS:(NSTimeInterval)timeInterval hours:(int*)hours minutes:(int*)minutes seconds:(int*)seconds;

+ (NSArray *) splitCoordinates:(NSString *)string;
+ (NSString *) floatToStrTrimZeros:(CGFloat)number;

+ (UIImage *) getTintableImage:(UIImage *)image;
+ (UIImage *) getTintableImageNamed:(NSString *)name;
+ (UIImage *) tintImageWithColor:(UIImage *)source color:(UIColor *)color;
+ (UIImage *) layeredImageWithColor:(UIColor *)color bottom:(UIImage *)bottom center:(UIImage *)center top:(UIImage *)top;

+ (BOOL) doublesEqualUpToDigits:(int)digits source:(double)source destination:(double)destination;
+ (BOOL) isCoordEqual:(double)srcLat srcLon:(double)srcLon destLat:(double)destLat destLon:(double)destLon;
+ (BOOL) isCoordEqual:(double)srcLat srcLon:(double)srcLon destLat:(double)destLat destLon:(double)destLon upToDigits:(int)digits;

+ (void) roundCornersOnView:(UIView *)view onTopLeft:(BOOL)tl topRight:(BOOL)tr bottomLeft:(BOOL)bl bottomRight:(BOOL)br radius:(CGFloat)radius;

+ (NSString *) preferredLang;
+ (NSString *) currentLang;
+ (NSString *) capitalizeFirstLetter:(NSString *)s;
+ (NSString *) translatedLangName:(NSString *)lang;
+ (NSInteger) findFirstNumberEndIndex:(NSString *)value;

+ (void) callUrl:(NSString *)url;
+ (void) callPhone:(NSString *)phonesString;

+ (BOOL) is12HourTimeFormat;

+ (float) degToRadf:(float)degrees;
+ (double) degToRadd:(double)degrees;
+ (float) radToDegf:(float)radians;
+ (double) radToDegd:(double)radians;

+ (CGFloat) getStatusBarHeight;
+ (CGFloat) getTopMargin;
+ (CGFloat) getBottomMargin;
+ (CGFloat) getLeftMargin;
+ (CGFloat) calculateScreenHeight;
+ (CGFloat) calculateScreenWidth;
+ (BOOL) isWindowed;
+ (BOOL) isIPhone;
+ (BOOL) isIPad;
+ (void) adjustViewsToNotch:(CGSize)size topView:(UIView *)topView middleView:(UIView *)middleView bottomView:(UIView *)bottomView
        navigationBarHeight:(CGFloat)navigationBarHeight toolBarHeight:(CGFloat)toolBarHeight;
+ (BOOL) isPortrait;
+ (BOOL) isLandscape;
+ (BOOL) isLandscape:(UIInterfaceOrientation)interfaceOrientation;
+ (BOOL) isLandscapeIpadAware;

+ (NSArray<NSValue *> *) controlPointsFromPoints:(NSArray<NSValue *> *)dataPoints;

+ (unsigned long long) folderSize:(NSString *)folderPath;

+ (NSString *) getLocalizedRouteInfoProperty:(NSString *)properyName;

+ (BOOL) isColorBright:(UIColor *)color;
+ (NSAttributedString *) createAttributedString:(NSString *)text font:(UIFont *)font color:(UIColor *)color strokeColor:(UIColor *)strokeColor strokeWidth:(float)strokeWidth alignment:(NSTextAlignment)alignment;
+ (UIView *) setupTableHeaderViewWithText:(NSString *)text font:(UIFont *)font textColor:(UIColor *)textColor isBigTitle:(BOOL)isBigTitle parentViewWidth:(CGFloat)parentViewWidth;
+ (UIView *) setupTableHeaderViewWithText:(NSAttributedString *)attributedText isBigTitle:(BOOL)isBigTitle rightIconName:(NSString *)iconName tintColor:(UIColor *)tintColor parentViewWidth:(CGFloat)parentViewWidth;
+ (UIView *) setupTableHeaderViewWithText:(NSAttributedString *)attributedText isBigTitle:(BOOL)isBigTitle topOffset:(CGFloat)topOffset bottomOffset:(CGFloat)bottomOffset rightIconName:(NSString *)iconName tintColor:(UIColor *)tintColor parentViewWidth:(CGFloat)parentViewWidth;
+ (UIView *) setupTableHeaderViewWithText:(NSAttributedString *)text tintColor:(UIColor *)tintColor icon:(UIImage *)icon iconFrameSize:(CGFloat)iconFrameSize iconBackgroundColor:(UIColor *)iconBackgroundColor iconContentMode:(UIViewContentMode)contentMode;
+ (UIView *) setupTableHeaderViewWithText:(NSAttributedString *)text tintColor:(UIColor *)tintColor icon:(UIImage *)icon iconFrameSize:(CGFloat)iconFrameSize iconBackgroundColor:(UIColor *)iconBackgroundColor iconContentMode:(UIViewContentMode)contentMode iconYOffset:(CGFloat)iconYOffset;

+ (UIView *) setupTableHeaderViewWithAttributedText:(NSAttributedString *)attributedText topCenterIconName:(NSString *)iconName iconSize:(CGFloat)iconSize parentViewWidth:(CGFloat)parentViewWidth;

+ (CGFloat) heightForHeaderViewText:(NSString *)text width:(CGFloat)width font:(UIFont *)font lineSpacing:(CGFloat)lineSpacing;

+ (NSDictionary *) getSortedVoiceProviders;
+ (NSMutableAttributedString *) getStringWithBoldPart:(NSString *)wholeString mainString:(NSString *)ms boldString:(NSString *)bs lineSpacing:(CGFloat)lineSpacing;
+ (NSMutableAttributedString *) getStringWithBoldPart:(NSString *)wholeString mainString:(NSString *)ms boldString:(NSString *)bs lineSpacing:(CGFloat)lineSpacing fontSize:(CGFloat)fontSize highlightColor:(UIColor *)highlightColor;
+ (NSMutableAttributedString *) getStringWithBoldPart:(NSString *)wholeString mainString:(NSString *)ms boldString:(NSString *)bs lineSpacing:(CGFloat)lineSpacing fontSize:(CGFloat)fontSize;
+ (NSAttributedString *) getColoredString:(NSString *)wholeString highlightedString:(NSString *)hs highlightColor:(UIColor *)highlightColor fontSize:(CGFloat)fontSize centered:(BOOL)centered;
+ (NSMutableAttributedString *) getStringWithBoldPart:(NSString *)wholeString mainString:(NSString *)ms boldString:(NSString *)bs lineSpacing:(CGFloat)lineSpacing fontSize:(CGFloat)fontSize boldFontSize:(CGFloat)boldFontSize boldColor:(UIColor *)boldColor mainColor:(UIColor *)mainColor;

+ (NSDate *) getFileLastModificationDate:(NSString *)fileName;

+ (NSString *) getGpxShortPath:(NSString *)fullFilePath;

+ (NSArray<NSString *> *) getGpxFoldersListSorted:(BOOL)shouldSort shouldAddTracksFolder:(BOOL)shouldAddTracksFolder;

+ (NSAttributedString *) attributedStringFromHtmlString:(NSString *)html fontSize:(NSInteger)fontSize textColor:(UIColor *)textColor;

+ (NSString *) createNewFileName:(NSString *)oldName;

+ (natural_t) get_free_memory;

+ (NSString *) getLocalizedString:(NSString *)key;
+ (void) collectDirFiles:(NSString *)filePath list:(NSMutableArray<NSString *> *)list;
+ (NSString*) fileMD5:(NSString*)path;

+ (NSString *) toMD5:(NSString *)text;

+ (void) showMenuInView:(UIView *)parentView fromView:(UIView *)targetView;

+ (NSString *) getFormattedValue:(NSString *)value unit:(NSString *)unit;
+ (NSString *) getFormattedValue:(NSString *)value unit:(NSString *)unit separateWithSpace:(BOOL)separateWithSpace;

+ (NSString *) buildGeoUrl:(double)latitude longitude:(double)longitude zoom:(int)zoom;

+ (void)showToast:(NSString *)title details:(NSString *)details duration:(NSTimeInterval)duration inView:(UIView *)view;
+ (NSString *) formatWarnings:(NSArray<NSString *> *)warnings;

+ (NSDate *)getCurrentTimezoneDate:(NSDate *)sourceDate;

+ (NSString *) getRoutingStringPropertyName:(NSString *)propertyName defaultName:(NSString *)defaultName;

+ (int) convertCharToDist:(NSString *)ch firstLetter:(NSString *)firstLetter firstDist:(int)firstDist mult1:(int)mult1 mult2:(int)mult2;

+ (BOOL) isValidFileName:(NSString *)name;

@end
