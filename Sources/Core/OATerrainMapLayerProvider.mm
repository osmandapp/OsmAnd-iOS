//
//  OAHillshadeMapLayerProvider.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#include "OATerrainMapLayerProvider.h"
#import "OATerrainLayer.h"
#import "OsmAndApp.h"
#import "OsmAnd_Maps-Swift.h"

#include <OsmAndCore/SkiaUtilities.h>

OATerrainMapLayerProvider::OATerrainMapLayerProvider()
: minZoom(OsmAnd::ZoomLevel1),
maxZoom(OsmAnd::ZoomLevel11)
{
}

OATerrainMapLayerProvider::OATerrainMapLayerProvider(OsmAnd::ZoomLevel minZoom_, OsmAnd::ZoomLevel maxZoom_)
{
    minZoom = minZoom_;
    maxZoom = maxZoom_;
}

OATerrainMapLayerProvider::~OATerrainMapLayerProvider()
{
}

OsmAnd::AlphaChannelPresence OATerrainMapLayerProvider::getAlphaChannelPresence() const
{
    return OsmAnd::AlphaChannelPresence::Present;
}

bool OATerrainMapLayerProvider::supportsObtainImage() const
{
    return true;
}

long long OATerrainMapLayerProvider::obtainImageData(const OsmAnd::IMapTiledDataProvider::Request& request, QByteArray& byteArray)
{
    return 0;
}

sk_sp<const SkImage> OATerrainMapLayerProvider::obtainImage(const OsmAnd::IMapTiledDataProvider::Request& request)
{
    QByteArray byteArray;
    TerrainMode *terrainMode = [((OASRTMPlugin *) [OAPluginsHelper getPlugin:OASRTMPlugin.class]) getTerrainMode];
    if ([terrainMode isHillshade])
        byteArray = [[OATerrainLayer sharedInstanceHillshade] getByteArray:request.tileId.x y:request.tileId.y zoom:request.zoom timeHolder:nil];
    else if ([terrainMode isSlope])
        byteArray = [[OATerrainLayer sharedInstanceSlope] getByteArray:request.tileId.x y:request.tileId.y zoom:request.zoom timeHolder:nil];
    if (!byteArray.isEmpty())
    {
        return OsmAnd::SkiaUtilities::createImageFromData(byteArray);
    }
    else
    {
        return nullptr;
    }
}

OsmAnd::MapStubStyle OATerrainMapLayerProvider::getDesiredStubsStyle() const
{
    return OsmAnd::MapStubStyle::Unspecified;
}

float OATerrainMapLayerProvider::getTileDensityFactor() const
{
    return 1.0f;
}

uint32_t OATerrainMapLayerProvider::getTileSize() const
{
    return 256;
}

bool OATerrainMapLayerProvider::supportsNaturalObtainData() const
{
    return true;
}

bool OATerrainMapLayerProvider::supportsNaturalObtainDataAsync() const
{
    return true;
}

OsmAnd::ZoomLevel OATerrainMapLayerProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel1;
}

OsmAnd::ZoomLevel OATerrainMapLayerProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel11;
}

OsmAnd::ZoomLevel OATerrainMapLayerProvider::getMinVisibleZoom() const
{
    return minZoom;
}

OsmAnd::ZoomLevel OATerrainMapLayerProvider::getMaxVisibleZoom() const
{
    return maxZoom;
}

void OATerrainMapLayerProvider::performAdditionalChecks(sk_sp<SkImage> bitmap)
{
}
