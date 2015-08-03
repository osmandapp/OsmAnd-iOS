//
//  OACoreResourcesAmenityIconProvider.h
//  OsmAnd
//
//  Created by Alexey Kulish on 28/07/15.
//  Copyright (c) 2015 OsmAnd. All rights reserved.
//

#include <CoreFoundation/CoreFoundation.h>
#include <objc/objc.h>

#include <OsmAndCore.h>
#include <OsmAndCore/Common.h>
#include <OsmAndCore/Map/IAmenityIconProvider.h>

class OACoreResourcesAmenityIconProvider : public OsmAnd::IAmenityIconProvider
{
private:
protected:
public:
    OACoreResourcesAmenityIconProvider(
                                       const std::shared_ptr<const OsmAnd::ICoreResourcesProvider>& coreResourcesProvider = OsmAnd::getCoreResourcesProvider(),
                                     const float displayDensityFactor = 1.0f,
                                     const float symbolsScaleFactor = 1.0f);
    virtual ~OACoreResourcesAmenityIconProvider();
    
    const std::shared_ptr<const OsmAnd::ICoreResourcesProvider> coreResourcesProvider;
    const float displayDensityFactor;
    const float symbolsScaleFactor;
    
    virtual std::shared_ptr<SkBitmap> getIcon(
                                              const std::shared_ptr<const OsmAnd::Amenity>& amenity,
                                              const OsmAnd::ZoomLevel zoomLevel,
                                              const bool largeIcon = false) const Q_DECL_OVERRIDE;
};

