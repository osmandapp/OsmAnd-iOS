//
//  OAUtilities.m
//  OsmAnd
//
//  Created by Alexey Pelykh on 6/5/14.
//  Copyright (c) 2014 OsmAnd. All rights reserved.
//

#import "OANativeUtilities.h"

#import <UIKit/UIKit.h>

#include <QString>

#include <SkImageDecoder.h>

@implementation OANativeUtilities

+ (std::shared_ptr<SkBitmap>)skBitmapFromPngResource:(NSString*)resourceName
{
    if ([UIScreen mainScreen].scale > 1.0f)
        resourceName = [resourceName stringByAppendingString:@"@2x"];

    const auto resourcePath = [[NSBundle mainBundle] pathForResource:resourceName
                                                              ofType:@"png"];
    if (resourcePath == nil)
        return nullptr;

    const std::unique_ptr<SkImageDecoder> pngDecoder(CreatePNGImageDecoder());
    std::shared_ptr<SkBitmap> outputBitmap(new SkBitmap());
    if (!pngDecoder->DecodeFile(qPrintable(QString::fromNSString(resourcePath)), outputBitmap.get()))
        return nullptr;
    return outputBitmap;
}

@end
