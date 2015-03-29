//
//  OAUtilities.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 9/24/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OAUtilities.h"

#import <UIKit/UIDevice.h>

@implementation OAUtilities

+ (BOOL)iosVersionIsAtLeast:(NSString*)testVersion
{
    return ([[[UIDevice currentDevice] systemVersion] compare:testVersion options:NSNumericSearch] != NSOrderedAscending);
}

+ (BOOL)iosVersionIsExactly:(NSString*)testVersion
{
    return ([[[UIDevice currentDevice] systemVersion] compare:testVersion options:NSNumericSearch] == NSOrderedSame);
}

+ (UIImage *)applyScaleFactorToImage:(UIImage *)image
{
    CGFloat scaleFactor = [[UIScreen mainScreen] scale];
    CGSize newSize = CGSizeMake(image.size.width / scaleFactor, image.size.height / scaleFactor);
    
    UIGraphicsBeginImageContextWithOptions(newSize, NO, scaleFactor);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

@end
