//
//  OACoreResourcesAmenityIconProvider.m
//  OsmAnd
//
//  Created by Alexey Kulish on 28/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#include "OACoreResourcesAmenityIconProvider.h"

#include <OsmAndCore/ICoreResourcesProvider.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/SkiaUtilities.h>
#include <SkCGUtils.h>
#include <SkImage.h>

#import <Foundation/Foundation.h>
#import "OALog.h"
#import "OAPOIHelper.h"
#import "OAPOIType.h"
#import "OAUtilities.h"
#import "OAColors.h"

const static float kTextSize = 13.0f;

OACoreResourcesAmenityIconProvider::OACoreResourcesAmenityIconProvider(
    const std::shared_ptr<const OsmAnd::ICoreResourcesProvider>& coreResourcesProvider_ /*= getCoreResourcesProvider()*/,
    const float displayDensityFactor_ /*= 1.0f*/,
    const float symbolsScaleFactor_ /*= 1.0f*/,
    const float textScaleFactor_ /*= 1.0f*/,
    const bool nightMode_ /*= false*/,
    const bool showCaptions_ /*= false*/,
    const QString lang_ /*= QString::null*/,
    const bool transliterate_ /*= false*/)
: coreResourcesProvider(coreResourcesProvider_)
, displayDensityFactor(displayDensityFactor_)
, symbolsScaleFactor(symbolsScaleFactor_)
, textScaleFactor(textScaleFactor_)
, nightMode(nightMode_)
, showCaptions(showCaptions_)
, lang(lang_)
, transliterate(transliterate_)
{
    textStyle
        .setWrapWidth(20)
        .setBold(false)
        .setItalic(false)
        .setColor(OsmAnd::ColorARGB(nightMode ? color_widgettext_night_argb : color_widgettext_day_argb))
        .setSize(textScaleFactor * kTextSize * displayDensityFactor)
        .setHaloColor(OsmAnd::ColorARGB(nightMode ? color_widgettext_shadow_night_argb : color_widgettext_shadow_day_argb))
        .setHaloRadius(5);
}

OACoreResourcesAmenityIconProvider::~OACoreResourcesAmenityIconProvider()
{
}

sk_sp<SkImage> OACoreResourcesAmenityIconProvider::getIcon(
    const std::shared_ptr<const OsmAnd::Amenity>& amenity,
    const OsmAnd::ZoomLevel zoomLevel,
    const bool largeIcon /*= false*/) const
{
    @autoreleasepool
    {
        
        if (zoomLevel <= OsmAnd::ZoomLevel13)
        {
            auto iconBackground = coreResourcesProvider->getResourceAsImage("map/shields/white_orange_poi_shield.png", displayDensityFactor);
            return OsmAnd::SkiaUtilities::scaleImage(iconBackground, 0.5f, 0.5f);
        }
        
        const auto& decodedCategories = amenity->getDecodedCategories();
        for (const auto& decodedCategory : constOf(decodedCategories))
        {
            NSString *category = decodedCategory.category.toNSString();
            NSString *subcategory = decodedCategory.subcategory.toNSString();
            
            OAPOIType *type = [[OAPOIHelper sharedInstance] getPoiTypeByCategory:category name:subcategory];
            
            if (!type)
                continue;
            
            UIImage *origIcon = [type mapIcon];
            if (!origIcon)
                continue;
            
            UIImage *tintedIcon = [OAUtilities tintImageWithColor:origIcon color:[UIColor whiteColor]];
            auto icon = SkMakeImageFromCGImage(tintedIcon.CGImage);
            if (!icon)
                continue;
            
            auto iconBackground = coreResourcesProvider->getResourceAsImage("map/shields/white_orange_poi_shield.png", displayDensityFactor);
            if (iconBackground)
            {
                const QList<sk_sp<const SkImage>> icons({
                    OsmAnd::SkiaUtilities::scaleImage(iconBackground, symbolsScaleFactor, symbolsScaleFactor),
                    OsmAnd::SkiaUtilities::scaleImage(icon, symbolsScaleFactor, symbolsScaleFactor)
                });
                return OsmAnd::SkiaUtilities::mergeImages(icons);
            }
            else
            {
                return OsmAnd::SkiaUtilities::scaleImage(icon, symbolsScaleFactor, symbolsScaleFactor);
            }
        }
        
        return nullptr;
    }
}

OsmAnd::TextRasterizer::Style OACoreResourcesAmenityIconProvider::getCaptionStyle(
    const std::shared_ptr<const OsmAnd::Amenity>& amenity,
    const OsmAnd::ZoomLevel zoomLevel) const
{
    return textStyle;
}

QString OACoreResourcesAmenityIconProvider::getCaption(
    const std::shared_ptr<const OsmAnd::Amenity>& amenity,
    const OsmAnd::ZoomLevel zoomLevel) const
{
    return showCaptions && zoomLevel > OsmAnd::ZoomLevel10 ? amenity->getName(lang, transliterate) : QString::null;
}

