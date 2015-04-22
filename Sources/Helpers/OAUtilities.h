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

@end
