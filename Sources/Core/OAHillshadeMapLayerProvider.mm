//
//  OAHillshadeMapLayerProvider.m
//  OsmAnd
//
//  Created by Alexey Kulish on 29/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#include "OAHillshadeMapLayerProvider.h"
#import "OAHillshadeLayer.h"

OAHillshadeMapLayerProvider::OAHillshadeMapLayerProvider() 
{
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
    NSData *data = [[OAHillshadeLayer sharedInstance] getBytes:request.tileId.x y:request.tileId.y zoom:request.zoom timeHolder:nil];
    //NSData *data = [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"processing_tile_light" ofType:@"png" inDirectory:@"stubs/[ddf=2.0]"]];
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
    return false;
}

OsmAnd::ZoomLevel OAHillshadeMapLayerProvider::getMinZoom() const
{
    return OsmAnd::ZoomLevel0;
}

OsmAnd::ZoomLevel OAHillshadeMapLayerProvider::getMaxZoom() const
{
    return OsmAnd::ZoomLevel31;
}
