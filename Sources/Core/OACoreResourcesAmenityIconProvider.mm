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
#include <OsmAndCore/SkiaUtilities.h>

#import <Foundation/Foundation.h>

OACoreResourcesAmenityIconProvider::OACoreResourcesAmenityIconProvider(
                                                                       const std::shared_ptr<const OsmAnd::ICoreResourcesProvider>& coreResourcesProvider_ /*= getCoreResourcesProvider()*/,
                                                                       const float displayDensityFactor_ /*= 1.0f*/,
                                                                       const float symbolsScaleFactor_ /*= 1.0f*/)
: coreResourcesProvider(coreResourcesProvider_)
, displayDensityFactor(displayDensityFactor_)
, symbolsScaleFactor(symbolsScaleFactor_)
{
    
}

OACoreResourcesAmenityIconProvider::~OACoreResourcesAmenityIconProvider()
{
}

std::shared_ptr<SkBitmap> OACoreResourcesAmenityIconProvider::getIcon(
                                                                      const std::shared_ptr<const OsmAnd::Amenity>& amenity,
                                                                      const bool largeIcon /*= false*/) const
{
    const auto& decodedCategories = amenity->getDecodedCategories();
    
    const auto& iconPath = QLatin1String("map/icons/");
    const QLatin1String iconExtension(".png");
    
    for (const auto& decodedCategory : constOf(decodedCategories))
    {
        auto icon = coreResourcesProvider->getResourceAsBitmap(
                                                               iconPath + decodedCategory.subcategory + iconExtension,
                                                               displayDensityFactor);
        auto iconBackground = coreResourcesProvider->getResourceAsBitmap(
                                                               "map/shields/white_orange_poi_shield.png",
                                                               displayDensityFactor);

        if (!icon)
        {
            icon = coreResourcesProvider->getResourceAsBitmap(
                                                              iconPath + "" + iconExtension, //TODO: resolve poi_type in category by it's subcat and get tag/name
                                                              displayDensityFactor);
        }
        if (!icon)
            continue;
        
        if (iconBackground)
        {
            QList< std::shared_ptr<const SkBitmap>> icons;
            icons << OsmAnd::SkiaUtilities::scaleBitmap(iconBackground, symbolsScaleFactor, symbolsScaleFactor);
            icons << OsmAnd::SkiaUtilities::scaleBitmap(icon, symbolsScaleFactor, symbolsScaleFactor);
            return OsmAnd::SkiaUtilities::mergeBitmaps(icons);
        }
        else
        {
            return OsmAnd::SkiaUtilities::scaleBitmap(icon, symbolsScaleFactor, symbolsScaleFactor);
        }
    }
    
    return nullptr;
}
