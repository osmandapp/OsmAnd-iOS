//
//  OAHillshadeMapLayerProvider.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>

//#include <OsmAndCore.h>
//#include <OsmAndCore/Common.h>
#include <OsmAndCore/Map/ImageMapLayerProvider.h>

class OAHillshadeMapLayerProvider : public OsmAnd::ImageMapLayerProvider
{

private:
protected:
public:
    OAHillshadeMapLayerProvider();
    virtual ~OAHillshadeMapLayerProvider();
    
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
