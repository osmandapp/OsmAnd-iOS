//
//  OAUtilities.h
//  OsmAnd
//
//  Created by Alexey Pelykh on 9/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface OAUtilities : NSObject

+ (BOOL)iosVersionIsAtLeast:(NSString*)testVersion;
+ (BOOL)iosVersionIsExactly:(NSString*)testVersion;

+ (UIImage *)applyScaleFactorToImage:(UIImage *)image;
+ (NSString *)drawablePostfix;
+ (void)layoutComplexButton:(UIButton*)button;

+ (CGSize)calculateTextBounds:(NSString *)text width:(CGFloat)width font:(UIFont *)font;

+ (NSDictionary *)parseUrlQuery:(NSURL *)url;
+ (void)getHMS:(NSTimeInterval)timeInterval hours:(int*)hours minutes:(int*)minutes seconds:(int*)seconds;

+ (NSArray *) splitCoordinates:(NSString *)string;
+ (NSString *) floatToStrTrimZeros:(CGFloat)number;

@end
