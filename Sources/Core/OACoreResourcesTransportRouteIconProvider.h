//
//  OACoreResourcesTransportStopIconProvider.h
//  OsmAnd
//
//  Created by Alexey on 26/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>

#include <OsmAndCore.h>
#include <OsmAndCore/Common.h>
#include <OsmAndCore/Map/ITransportRouteIconProvider.h>

class OACoreResourcesTransportRouteIconProvider : public OsmAnd::ITransportRouteIconProvider
{
private:
protected:
public:
    OACoreResourcesTransportRouteIconProvider(
        const std::shared_ptr<const OsmAnd::ICoreResourcesProvider>& coreResourcesProvider = OsmAnd::getCoreResourcesProvider(),
        const float displayDensityFactor = 1.0f,
        const float symbolsScaleFactor = 1.0f);
    virtual ~OACoreResourcesTransportRouteIconProvider();
    
    const std::shared_ptr<const OsmAnd::ICoreResourcesProvider> coreResourcesProvider;
    const float displayDensityFactor;
    const float symbolsScaleFactor;
    
    virtual sk_sp<const SkImage> getIcon(
        const std::shared_ptr<const OsmAnd::TransportRoute>& transportRoute = nullptr,
        const OsmAnd::ZoomLevel zoomLevel = OsmAnd::ZoomLevel12,
        const bool largeIcon = false) const Q_DECL_OVERRIDE;
};
