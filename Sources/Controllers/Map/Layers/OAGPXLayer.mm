//
//  OAGPXLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OAGPXLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/GeoInfoPresenter.h>
#include <OsmAndCore/Map/MapPrimitiviser.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>


@implementation OAGPXLayer
{
    // Active gpx
    QList< std::shared_ptr<const OsmAnd::GeoInfoDocument> > _geoInfoDocsGpx;
    std::shared_ptr<OsmAnd::GeoInfoPresenter> _gpxPresenter;
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterMapProviderGpx;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _gpxPrimitivesProvider;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _mapObjectsSymbolsProviderGpx;
        
    // Temp gpx
    QList< std::shared_ptr<const OsmAnd::GeoInfoDocument> > _geoInfoDocsGpxTemp;
    
    // Currently recording gpx
    QList< std::shared_ptr<const OsmAnd::GeoInfoDocument> > _geoInfoDocsGpxRec;
    std::shared_ptr<OsmAnd::GeoInfoPresenter> _gpxPresenterRec;
    std::shared_ptr<OsmAnd::IMapLayerProvider> _rasterMapProviderGpxRec;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _gpxPrimitivesProviderRec;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _mapObjectsSymbolsProviderGpxRec;
}

+ (NSString *) getLayerId
{
    return kGpxLayerId;
}

- (void) initLayer
{
    
}

- (void) deinitLayer
{
    
}

@end
