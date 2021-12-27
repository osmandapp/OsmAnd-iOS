//
//  OAHillshadeMapLayerProvider.h
//  OsmAnd
//
//  Created by Alexey Kulish on 29/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>

#include <OsmAndCore/Map/ImageMapLayerProvider.h>

class OATerrainMapLayerProvider : public OsmAnd::ImageMapLayerProvider
{

private:
    virtual void performAdditionalChecks(sk_sp<SkImage> bitmap);
    
    OsmAnd::ZoomLevel minZoom;
    OsmAnd::ZoomLevel maxZoom;
protected:
public:
    OATerrainMapLayerProvider();
    OATerrainMapLayerProvider(OsmAnd::ZoomLevel minZoom_, OsmAnd::ZoomLevel maxZoom_);
    virtual ~OATerrainMapLayerProvider();
    
    virtual QByteArray obtainImageData(const OsmAnd::ImageMapLayerProvider::Request& request);
    virtual sk_sp<SkImage> obtainImage(const OsmAnd::IMapTiledDataProvider::Request& request);
    virtual void obtainImageAsync(
                          const OsmAnd::IMapTiledDataProvider::Request& request,
                          const OsmAnd::ImageMapLayerProvider::AsyncImageData* asyncImageData);

    virtual OsmAnd::AlphaChannelPresence getAlphaChannelPresence() const;
    virtual OsmAnd::MapStubStyle getDesiredStubsStyle() const;
    
    virtual float getTileDensityFactor() const;
    virtual uint32_t getTileSize() const;
    
    virtual bool supportsNaturalObtainData() const;
    virtual bool supportsNaturalObtainDataAsync() const;

    virtual OsmAnd::ZoomLevel getMinZoom() const;
    virtual OsmAnd::ZoomLevel getMaxZoom() const;
    
    virtual OsmAnd::ZoomLevel getMinVisibleZoom() const override;
    virtual OsmAnd::ZoomLevel getMaxVisibleZoom() const override;

};
