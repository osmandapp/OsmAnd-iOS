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
#include <OsmAndCore/GpxDocument.h>
#include <OsmAndCore/IFavoriteLocation.h>

@implementation OACompoundIconUtils

+ (sk_sp<SkImage>) createCompositeBitmapFromWpt:(const OsmAnd::Ref<OsmAnd::GpxDocument::WptPt> &)point isFullSize:(BOOL)isFullSize scale:(float)scale
{
    UIColor* color = nil;
    NSString *shapeName = nil;
    NSString *iconName = nil;
    const auto& values = point->getValues();
    if (!values.isEmpty())
    {
        const auto& it = values.find(QStringLiteral("color"));
        if (it != values.end())
            color = [UIColor colorFromString:it.value().toString().toNSString()];
        const auto& shapeIt = values.find(QStringLiteral("background"));
        if (shapeIt != values.end())
            shapeName = shapeIt.value().toString().toNSString();
        const auto& iconIt = values.find(QStringLiteral("icon"));
        if (iconIt != values.end())
            iconName = iconIt.value().toString().toNSString();
    }
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
    UIColor *color = [UIColor colorWithRed:fav->getColor().r/255.0 green:fav->getColor().g/255.0 blue:fav->getColor().b/255.0 alpha:fav->getColor().a/255.0];
    if (!color)
        color = [OADefaultFavorite getDefaultColor];
    NSString *shapeName = fav->getBackground().toNSString();
    if (!shapeName || shapeName.length == 0)
        shapeName = @"circle";
    NSString *iconName = fav->getIcon().toNSString();
    if (!iconName || iconName.length == 0)
        iconName = @"mx_special_star";

    return [self createCompositeIconWithcolor:color shapeName:shapeName iconName:iconName isFullSize:isFullSize icon:nil scale:scale];
}

+ (sk_sp<SkImage>) createCompositeIconWithcolor:(UIColor *)color shapeName:(NSString *)shapeName iconName:(NSString *)iconName isFullSize:(BOOL)isFullSize icon:(UIImage *)icon scale:(float)scale
{
    CGFloat screenScale = [[UIScreen mainScreen] scale];
    NSString *sizeName = isFullSize ? @"" : @"_small";
    sk_sp<SkImage> result;

    // shadow icon
    NSString *shadowIconName = [NSString stringWithFormat:@"ic_bg_point_%@_bottom%@", shapeName, sizeName];
    auto shadowIcon = [OANativeUtilities skImageFromPngResource:shadowIconName];
    if (!shadowIcon)
        return result;

    // color filled background icon
    NSString *backgroundIconName = [NSString stringWithFormat:@"ic_bg_point_%@_center%@", shapeName, sizeName];
    UIImage *img = [self getIcon:backgroundIconName defaultIconName:@"ic_bg_point_circle_center"];
    img = [OAUtilities tintImageWithColor:img color:color];
    auto backgroundIcon = [OANativeUtilities skImageFromCGImage:img.CGImage];
    if (!backgroundIcon)
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

    // highlight icon
    NSString *highlightIconName = [NSString stringWithFormat:@"ic_bg_point_%@_top%@", shapeName, sizeName];
    auto highlightIcon = [OANativeUtilities skImageFromPngResource:highlightIconName];
    if (!highlightIcon)
        return result;

    
    if (isFullSize && shadowIcon && backgroundIcon && poiIcon && highlightIcon)
    {
        const QList<sk_sp<const SkImage>> toMerge({
            [OANativeUtilities getScaledSkImage:shadowIcon scaleFactor:scale], 
            [OANativeUtilities getScaledSkImage:backgroundIcon scaleFactor:scale],
            poiIcon,
            [OANativeUtilities getScaledSkImage:highlightIcon scaleFactor:scale]});
        result = OsmAnd::SkiaUtilities::mergeImages(toMerge);
    }
    else if (!isFullSize && shadowIcon && backgroundIcon && highlightIcon)
    {
        const QList<sk_sp<const SkImage>> toMerge({
            [OANativeUtilities getScaledSkImage:shadowIcon scaleFactor:scale],
            [OANativeUtilities getScaledSkImage:backgroundIcon scaleFactor:scale],
            [OANativeUtilities getScaledSkImage:highlightIcon scaleFactor:scale]});
        result = OsmAnd::SkiaUtilities::mergeImages(toMerge);
    }
    return result;
}

+ (UIImage *) getIcon:(NSString *)iconName defaultIconName:(NSString *)defaultIconName
{
    UIImage *iconImage = [UIImage imageNamed:iconName];
    if (!iconImage)
        iconImage = [UIImage imageNamed:defaultIconName];
    return iconImage;
}

@end
