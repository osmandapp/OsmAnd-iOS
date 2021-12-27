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
#include <SkImage.h>

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

sk_sp<const SkImage> OACoreResourcesTransportRouteIconProvider::getIcon(
    const std::shared_ptr<const OsmAnd::TransportRoute>& transportRoute /*= nullptr*/,
    const OsmAnd::ZoomLevel zoomLevel,
    const bool largeIcon /*= false*/) const
{
    @autoreleasepool
    {
        if (transportRoute)
        {
            UIImage *backgroundImg = [UIImage imageNamed:@"map_transport_stop_bg"];
            auto backgroundBmp = SkMakeImageFromCGImage(backgroundImg.CGImage);
            if (backgroundBmp)
            {
                OATransportStopType *type = [OATransportStopType findType:transportRoute->type.toNSString()];
                UIImage *origIcon = [UIImage imageNamed:[OAUtilities drawablePath:[NSString stringWithFormat:@"mm_%@", type.resName]]];
                if (origIcon)
                {
                    origIcon = [OAUtilities applyScaleFactorToImage:origIcon];
                    UIImage *tintedIcon = [OAUtilities tintImageWithColor:origIcon color:[UIColor whiteColor]];
                    auto stopBmp = SkMakeImageFromCGImage(tintedIcon.CGImage);
                    if (stopBmp)
                    {
                        const QList< sk_sp<const SkImage>> composition({
                            OsmAnd::SkiaUtilities::scaleImage(backgroundBmp, symbolsScaleFactor, symbolsScaleFactor),
                            OsmAnd::SkiaUtilities::scaleImage(stopBmp, symbolsScaleFactor, symbolsScaleFactor)
                        });
                        return OsmAnd::SkiaUtilities::mergeImages(composition);
                    }
                }
            }
        }
        else
        {
            UIImage *busImage = [UIImage imageNamed:@"map_transport_stop_bus"];
            auto icon = SkMakeImageFromCGImage(busImage.CGImage);
            if (icon)
                return icon;
        }
    }
    return nullptr;
}
