//
//  OASQLiteTileSourceMapLayerProvider.h
//  OsmAnd
//
//  Created by Alexey Kulish on 03/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//
#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>
#include <OsmAndCore/Map/ImageMapLayerProvider.h>
#import "OASQLiteTileSource.h"

class OASQLiteTileSourceMapLayerProvider : public OsmAnd::ImageMapLayerProvider
{
private:
protected:
public:
    OASQLiteTileSourceMapLayerProvider(const QString& fileName);
    virtual ~OASQLiteTileSourceMapLayerProvider();
    
    OASQLiteTileSource *ts;
    
    virtual QByteArray obtainImage(const OsmAnd::IMapTiledDataProvider::Request& request);
    virtual void obtainImageAsync(
                                  const OsmAnd::IMapTiledDataProvider::Request& request,
                                  const OsmAnd::ImageMapLayerProvider::AsyncImage* asyncImage);
    
    virtual OsmAnd::AlphaChannelPresence getAlphaChannelPresence() const;
    virtual OsmAnd::MapStubStyle getDesiredStubsStyle() const;
    
    virtual float getTileDensityFactor() const;
    virtual uint32_t getTileSize() const;
    
    virtual bool supportsNaturalObtainData() const;
    virtual bool supportsNaturalObtainDataAsync() const;
    
    virtual OsmAnd::ZoomLevel getMinZoom() const;
    virtual OsmAnd::ZoomLevel getMaxZoom() const;
};
