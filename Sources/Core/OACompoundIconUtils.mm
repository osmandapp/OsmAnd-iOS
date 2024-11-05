//
//  OACompoundIconUtils.m
//  OsmAnd Maps
//
//  Created by Paul on 21.04.2022.
//  Copyright © 2022 OsmAnd. All rights reserved.
//

#import "OACompoundIconUtils.h"
#import "OADefaultFavorite.h"
#import "OANativeUtilities.h"
#import "OsmAndSharedWrapper.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/LatLon.h>
#include <OsmAndCore/QRunnableFunctor.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <SkCanvas.h>
#include <SkPaint.h>
#include <SkImageInfo.h>
#include <SkColor.h>
#include <SkColorFilter.h>
#include <SkCGUtils.h>

#include <OsmAndCore.h>
#include <OsmAndCore/CommonTypes.h>
#include <OsmAndCore/IFavoriteLocation.h>

@implementation OACompoundIconUtils

+ (sk_sp<SkImage>) createCompositeBitmapFromWpt:(OASWptPt *)point isFullSize:(BOOL)isFullSize scale:(float)scale
{
    int32_t pointColor = point.getColor;
    NSString *pointBackground = point.getBackgroundType;
    NSString *pointIcon = point.getIconName;
    UIColor* color = pointColor != 0 ? UIColorFromARGB(pointColor) : nil;
    NSString *shapeName = pointBackground;
    NSString *iconName = pointIcon;
    if (!color)
        color = [OADefaultFavorite getDefaultColor];
    if (!shapeName)
        shapeName = @"circle";
    if (!iconName)
        iconName = @"mx_special_star";

    return [self createCompositeIconWithcolor:color shapeName:shapeName iconName:iconName isFullSize:isFullSize icon:nil scale:scale];
}

+ (sk_sp<SkImage>) createCompositeBitmapFromFavorite:(const std::shared_ptr<OsmAnd::IFavoriteLocation> &)fav isFullSize:(BOOL)isFullSize scale:(float)scale
{
    UIColor *color;
    if (fav->getColor().argb == 0)
        color = [OADefaultFavorite getDefaultColor];
    else
        color = [UIColor colorWithRed:fav->getColor().r/255.0 green:fav->getColor().g/255.0 blue:fav->getColor().b/255.0 alpha:fav->getColor().a/255.0];
    
    NSString *shapeName = fav->getBackground().toNSString();
    if (!shapeName || shapeName.length == 0)
        shapeName = @"circle";
    NSString *iconName = fav->getIcon().toNSString();
    if (!iconName || iconName.length == 0)
        iconName = @"mx_special_star";

    return [self createCompositeIconWithcolor:color shapeName:shapeName iconName:iconName isFullSize:isFullSize icon:nil scale:scale];
}

+ (sk_sp<SkImage>)createCompositeIconWithcolor:(UIColor *)color
                                     shapeName:(NSString *)shapeName
                                      iconName:(NSString *)iconName
                                    isFullSize:(BOOL)isFullSize
                                          icon:(UIImage *)icon
                                         scale:(float)scale
{
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    NSString *sizeName = isFullSize ? @"" : @"_small";
    sk_sp<SkImage> result;

    // shadow icon
    auto shadowIcon = [self getScaledIcon:[NSString stringWithFormat:@"ic_bg_point_%@_bottom%@", shapeName, sizeName]
                      defaultResourceName:@"ic_bg_point_circle_bottom"
                                    scale:scale
                                    color:nil];
    if (!shadowIcon)
        return result;

    // color filled background icon
    auto backgroundIcon = [self getScaledIcon:[NSString stringWithFormat:@"ic_bg_point_%@_center%@", shapeName, sizeName]
                          defaultResourceName:@"ic_bg_point_circle_center"
                                        scale:scale
                                        color:color];
    if (!backgroundIcon)
        return result;

    // highlight icon
    auto highlightIcon = [self getScaledIcon:[NSString stringWithFormat:@"ic_bg_point_%@_top%@", shapeName, sizeName]
                         defaultResourceName:@"ic_bg_point_circle_top"
                                       scale:scale
                                       color:nil];
    if (!highlightIcon)
        return result;

    // poi image icon
    sk_sp<SkImage> poiIcon;
    if (isFullSize)
    {
        UIImage *origImage = icon;
        CGSize imgSize = {14 * screenScale * scale, 14 * screenScale * scale};
        if (!origImage)
        {
            NSString *name = [iconName stringByReplacingOccurrencesOfString:@"osmand_" withString:@""];
            int mxIndex = [name indexOf:@"mx_"];
            if (mxIndex > 0)
                name = [name substringFromIndex:mxIndex];
            if (![name hasPrefix:@"mx_"])
                name = [@"mx_" stringByAppendingString:name];

            const auto skImg = [OANativeUtilities skImageFromSvgResource:name width:imgSize.width height:imgSize.height];
            if (skImg)
            	origImage = [OANativeUtilities skImageToUIImage:skImg];
        }
        if (!origImage)
        {
            const auto skImg = [OANativeUtilities skImageFromSvgResource:@"mx_special_star" width:imgSize.width height:imgSize.height];
            if (skImg)
                origImage = [OANativeUtilities skImageToUIImage:skImg];
        }

        UIImage *resizedImage = origImage;
        
        CGSize imgPtSize = {14 * scale, 14 * scale};
        if (!CGSizeEqualToSize(origImage.size, imgPtSize))
            resizedImage  = [OAUtilities resizeImage:origImage newSize:imgPtSize];

        UIImage *coloredImage = [OAUtilities tintImageWithColor:resizedImage color:UIColor.whiteColor];
        poiIcon = [OANativeUtilities skImageFromCGImage:coloredImage.CGImage];
        if (!poiIcon)
            return result;
    }

    if (isFullSize && shadowIcon && backgroundIcon && poiIcon && highlightIcon)
    {
        const QList<sk_sp<const SkImage>> toMerge({ shadowIcon, backgroundIcon, poiIcon, highlightIcon });
        result = OsmAnd::SkiaUtilities::mergeImages(toMerge);
    }
    else if (!isFullSize && shadowIcon && backgroundIcon && highlightIcon)
    {
        const QList<sk_sp<const SkImage>> toMerge({ shadowIcon, backgroundIcon, highlightIcon });
        result = OsmAnd::SkiaUtilities::mergeImages(toMerge);
    }
    return result;
}

+ (sk_sp<SkImage>)getScaledIcon:(NSString *)resourceName
                          scale:(CGFloat)scale
{
    return [self getScaledIcon:resourceName defaultResourceName:nil scale:scale color:nil];
}

+ (sk_sp<SkImage>)getScaledIcon:(NSString *)resourceName
            defaultResourceName:(NSString *)defaultResourceName
                          scale:(CGFloat)scale
                          color:(UIColor *)color
{
    sk_sp<SkImage> result;
    NSString *iconName = [OANativeUtilities getScaledResourceName:resourceName];
    UIImage *img = [self getIcon:iconName
                 defaultIconName:defaultResourceName ? [OANativeUtilities getScaledResourceName:defaultResourceName] : nil
                           scale:scale];
    if (img)
    {
        if (color)
            img = [OAUtilities tintImageWithColor:img color:color];
        result = [OANativeUtilities skImageFromCGImage:img.CGImage];
    }
    return result;
}

+ (UIImage *)getIcon:(NSString *)iconName
     defaultIconName:(NSString *)defaultIconName
               scale:(float)scale
{
    UIImage *iconImage = [UIImage imageNamed:iconName];
    if (!iconImage && defaultIconName && [iconName isEqualToString:defaultIconName])
        iconImage = [UIImage imageNamed:defaultIconName];
    if (!iconImage)
        return nil;
    if (scale != 1 || iconImage.scale != scale)
    {
        CGSize iconPtSize = { iconImage.size.width * scale, iconImage.size.height * scale };
        iconImage = [OAUtilities resizeImage:iconImage newSize:iconPtSize];
        iconImage = [UIImage imageWithCGImage:iconImage.CGImage
                                        scale:scale
                                  orientation:UIImageOrientationUp]
            .imageFlippedForRightToLeftLayoutDirection;
    }
    return iconImage;
}

@end
