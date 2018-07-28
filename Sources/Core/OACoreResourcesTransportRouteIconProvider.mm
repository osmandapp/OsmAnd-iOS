//
//  OACoreResourcesTransportStopIconProvider.m
//  OsmAnd
//
//  Created by Alexey on 26/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#include "OACoreResourcesTransportRouteIconProvider.h"

#include <OsmAndCore/ICoreResourcesProvider.h>
#include <OsmAndCore/Data/TransportRoute.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/SkiaUtilities.h>
#include <SkCGUtils.h>
#include <SkBitmap.h>

#import <Foundation/Foundation.h>
#import "OALog.h"
#import "OAPOIHelper.h"
#import "OAPOIType.h"
#import "OAUtilities.h"
#import "OATransportStopType.h"

OACoreResourcesTransportRouteIconProvider::OACoreResourcesTransportRouteIconProvider(
    const std::shared_ptr<const OsmAnd::ICoreResourcesProvider>& coreResourcesProvider_ /*= getCoreResourcesProvider()*/,
    const float displayDensityFactor_ /*= 1.0f*/,
    const float symbolsScaleFactor_ /*= 1.0f*/)
: coreResourcesProvider(coreResourcesProvider_)
, displayDensityFactor(displayDensityFactor_)
, symbolsScaleFactor(symbolsScaleFactor_)
{
    
}

OACoreResourcesTransportRouteIconProvider::~OACoreResourcesTransportRouteIconProvider()
{
}

std::shared_ptr<SkBitmap> OACoreResourcesTransportRouteIconProvider::getIcon(
    const std::shared_ptr<const OsmAnd::TransportRoute>& transportRoute /*= nullptr*/,
    const OsmAnd::ZoomLevel zoomLevel,
    const bool largeIcon /*= false*/) const
{
    @autoreleasepool
    {
        if (transportRoute)
        {
            UIImage *backgroundImg = [UIImage imageNamed:@"map_transport_stop_bg"];
            auto backgroundBmp = std::make_shared<SkBitmap>();
            bool res = SkCreateBitmapFromCGImage(backgroundBmp.get(), backgroundImg.CGImage);
            if (res)
            {
                OATransportStopType *type = [OATransportStopType findType:transportRoute->type.toNSString()];
                UIImage *origIcon = [UIImage imageNamed:[NSString stringWithFormat:@"style-icons/drawable-%@/mm_%@", [OAUtilities drawablePostfix], [type.resName stringByAppendingString:@".png"]]];
                if (origIcon)
                {
                    origIcon = [OAUtilities applyScaleFactorToImage:origIcon];
                    UIImage *tintedIcon = [OAUtilities tintImageWithColor:origIcon color:[UIColor whiteColor]];
                    auto stopBmp = std::make_shared<SkBitmap>();
                    bool res = SkCreateBitmapFromCGImage(stopBmp.get(), tintedIcon.CGImage);
                    if (res)
                    {
                        QList< std::shared_ptr<const SkBitmap>> composition;
                        composition << OsmAnd::SkiaUtilities::scaleBitmap(backgroundBmp, symbolsScaleFactor, symbolsScaleFactor);
                        composition << OsmAnd::SkiaUtilities::scaleBitmap(stopBmp, symbolsScaleFactor, symbolsScaleFactor);
                        return OsmAnd::SkiaUtilities::mergeBitmaps(composition);
                    }
                }
            }
        }
        else
        {
            UIImage *busImage = [UIImage imageNamed:@"map_transport_stop_bus"];
            auto icon = std::make_shared<SkBitmap>();
            bool res = SkCreateBitmapFromCGImage(icon.get(), busImage.CGImage);
            if (res)
                return icon;
        }
    }
    return nullptr;
}
