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
#include <SkBitmap.h>

#import <Foundation/Foundation.h>
#import "OALog.h"
#import "OAPOIHelper.h"
#import "OAPOIType.h"
#import "OAUtilities.h"

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
        
        auto icon = std::make_shared<SkBitmap>();
        bool res = SkCreateBitmapFromCGImage(icon.get(), tintedIcon.CGImage);
        if (!res)
            continue;

        auto iconBackground = coreResourcesProvider->getResourceAsBitmap(
                                                                         "map/shields/white_orange_poi_shield.png",
                                                                         displayDensityFactor);
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
