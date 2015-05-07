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

+ (NSString *)drawablePostfix
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

+ (void)layoutComplexButton:(UIButton*)button
{
    // the space between the image and text
    CGFloat spacing = 6.0;
    
    // lower the text and push it left so it appears centered
    //  below the image
    CGSize imageSize = button.imageView.image.size;
    button.titleEdgeInsets = UIEdgeInsetsMake(
                                              0.0, - imageSize.width, - (imageSize.height + spacing), 0.0);
    
    // raise the image and push it right so it appears centered
    //  above the text
    CGSize titleSize = [button.titleLabel.text sizeWithAttributes:@{NSFontAttributeName: button.titleLabel.font}];
    button.imageEdgeInsets = UIEdgeInsetsMake(
                                              - (titleSize.height + spacing), 0.0, 0.0, - titleSize.width);
}


+ (CGSize)calculateTextBounds:(NSString *)text width:(CGFloat)width font:(UIFont *)font
{
    NSDictionary *attrDict = [NSDictionary dictionaryWithObjectsAndKeys:
                              font, NSFontAttributeName, nil];
    
    CGSize size = [text boundingRectWithSize:CGSizeMake(width, 1000.0)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:attrDict context:nil].size;
    
    return CGSizeMake(ceil(size.width), ceil(size.height));
}

+ (NSDictionary *)parseUrlQuery:(NSURL *)url
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

+ (void)getHMS:(NSTimeInterval)timeInterval hours:(int*)hours minutes:(int*)minutes seconds:(int*)seconds
{
    long secondsL = lroundf(timeInterval);
    *hours = abs(secondsL / 3600);
    *minutes = abs((secondsL % 3600) / 60);
    *seconds = abs(secondsL % 60);
}

@end
