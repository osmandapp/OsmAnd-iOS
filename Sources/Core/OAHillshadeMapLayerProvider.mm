//
//  OAHillshadeMapLayerProvider.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#include "OAHillshadeMapLayerProvider.h"
#import "OAHillshadeLayer.h"
#import "OsmAndApp.h"

OAHillshadeMapLayerProvider::OAHillshadeMapLayerProvider()
: minZoom(OsmAnd::ZoomLevel1),
maxZoom(OsmAnd::ZoomLevel11)
{
}

OAHillshadeMapLayerProvider::OAHillshadeMapLayerProvider(OsmAnd::ZoomLevel minZoom_, OsmAnd::ZoomLevel maxZoom_)
{
    minZoom = minZoom_;
    maxZoom = maxZoom_;
}

OAHillshadeMapLayerProvider::~OAHillshadeMapLayerProvider()
{
}

OsmAnd::AlphaChannelPresence OAHillshadeMapLayerProvider::getAlphaChannelPresence() const
{
    return OsmAnd::AlphaChannelPresence::Present;
}

QByteArray OAHillshadeMapLayerProvider::obtainImage(const OsmAnd::IMapTiledDataProvider::Request& request)
{
    NSData *data;
    OsmAndAppInstance app = [OsmAndApp instance];
    if (app.data.hillshade == EOATerrainTypeHillshade)
        data = [[OAHillshadeLayer sharedInstanceHillshade] getBytes:request.tileId.x y:request.tileId.y zoom:request.zoom timeHolder:nil];
    else if (app.data.hillshade == EOATerrainTypeSlope)
        data = [[OAHillshadeLayer sharedInstanceSlope] getBytes:request.tileId.x y:request.tileId.y zoom:request.zoom timeHolder:nil];
    if (data)
        return QByteArray::fromNSData(data);
    else
        return nullptr;
}

void OAHillshadeMapLayerProvider::obtainImageAsync(
                      const OsmAnd::IMapTiledDataProvider::Request& request,
                      const OsmAnd::ImageMapLayerProvider::AsyncImage* asyncImage)
{
    //
}

OsmAnd::MapStubStyle OAHillshadeMapLayerProvider::getDesiredStubsStyle() const
{
    return OsmAnd::MapStubStyle::Unspecified;
}

float OAHillshadeMapLayerProvider::getTileDensityFactor() const
{
    return 1.0f;
}

uint32_t OAHillshadeMapLayerProvider::getTileSize() const
{
    return 256;
}

bool OAHillshadeMapLayerProvider::supportsNaturalObtainData() const
{
    return true;
}

bool OAHillshadeMapLayerProvider::supportsNaturalObtainDataAsync() const
{
    return true;
}

OsmAnd::ZoomLevel OAHillshadeMapLayerProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel1;
}

OsmAnd::ZoomLevel OAHillshadeMapLayerProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel11;
}

OsmAnd::ZoomLevel OAHillshadeMapLayerProvider::getMinVisibleZoom() const
{
    return minZoom;
}

OsmAnd::ZoomLevel OAHillshadeMapLayerProvider::getMaxVisibleZoom() const
{
    return maxZoom;
}

void OAHillshadeMapLayerProvider::performAdditionalChecks(std::shared_ptr<const SkBitmap> bitmap)
{
}
