//
//  OAMapMarkersCollection.h
//  OsmAnd
//
//  Created by Alexey Kulish on 31/08/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>

#include <OsmAndCore/Map/IMapKeyedSymbolsProvider.h>


class OAMapMarkersCollection : public OsmAnd::IMapKeyedSymbolsProvider
{
    
private:
protected:
    mutable QReadWriteLock _markersLock;
public:
    OAMapMarkersCollection(const OsmAnd::ZoomLevel minZoom = OsmAnd::MinZoomLevel, const OsmAnd::ZoomLevel maxZoom = OsmAnd::MaxZoomLevel);
    virtual ~OAMapMarkersCollection();
    
    //QList< std::shared_ptr<MapMarker> > getMarkers() const;
    //bool removeMarker(const std::shared_ptr<MapMarker>& marker);
    //void removeAllMarkers();
    
    const OsmAnd::ZoomLevel minZoom;
    const OsmAnd::ZoomLevel maxZoom;
    
    virtual OsmAnd::ZoomLevel getMinZoom() const;
    virtual OsmAnd::ZoomLevel getMaxZoom() const;
    
    virtual QList<OsmAnd::IMapKeyedSymbolsProvider::Key> getProvidedDataKeys() const;
    
    virtual bool supportsNaturalObtainData() const;
    virtual bool obtainData(
                            const OsmAnd::IMapDataProvider::Request& request,
                            std::shared_ptr<OsmAnd::IMapDataProvider::Data>& outData,
                            std::shared_ptr<OsmAnd::Metric>* const pOutMetric = nullptr);
    
    virtual bool supportsNaturalObtainDataAsync() const;
    virtual void obtainDataAsync(
                                 const OsmAnd::IMapDataProvider::Request& request,
                                 const OsmAnd::IMapDataProvider::ObtainDataAsyncCallback callback,
                                 const bool collectMetric = false);
    
};
