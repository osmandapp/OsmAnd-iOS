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
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>


@implementation OAGPXLayer
{
    QList<std::shared_ptr<const OsmAnd::GeoInfoDocument>> _gpxDocs;
    
    std::shared_ptr<OsmAnd::GeoInfoPresenter> _gpxPresenter;
    std::shared_ptr<OsmAnd::IMapLayerProvider> _gpxRasterMapProvider;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _gpxPrimitivesProvider;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _gpxMapObjectsSymbolsProvider;

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

- (void) resetLayer
{
    if (_gpxMapObjectsSymbolsProvider)
        [self.mapView removeTiledSymbolsProvider:_gpxMapObjectsSymbolsProvider];
    _gpxMapObjectsSymbolsProvider.reset();
    
    [self.mapView resetProviderFor:self.layerIndex];
    
    _gpxPrimitivesProvider.reset();
    _gpxPresenter.reset();
}

- (void) setupGpxRenderer:(std::shared_ptr<OsmAnd::MapPrimitiviser>)mapPrimitiviser
{
    [self.mapViewController runWithRenderSync:^{
        
        if (_gpxDocs.isEmpty())
            return;
        
        if (_gpxMapObjectsSymbolsProvider)
            [self.mapView removeTiledSymbolsProvider:_gpxMapObjectsSymbolsProvider];
        
        _gpxMapObjectsSymbolsProvider.reset();
        [self.mapView resetProviderFor:self.layerIndex];
        
        _gpxPresenter.reset(new OsmAnd::GeoInfoPresenter(_gpxDocs));
        
        if (_gpxPresenter)
        {
            const auto rasterTileSize = OsmAnd::Utilities::getNextPowerOfTwo(256 * self.mapViewController.displayDensityFactor);
            _gpxPrimitivesProvider.reset(new OsmAnd::MapPrimitivesProvider(_gpxPresenter->createMapObjectsProvider(), mapPrimitiviser, rasterTileSize, OsmAnd::MapPrimitivesProvider::Mode::AllObjectsWithPolygonFiltering));
            
            _gpxRasterMapProvider.reset(new OsmAnd::MapRasterLayerProvider_Software(_gpxPrimitivesProvider, false));
            [self.mapView setProvider:_gpxRasterMapProvider forLayer:self.layerIndex];
            
            _gpxMapObjectsSymbolsProvider.reset(new OsmAnd::MapObjectsSymbolsProvider(_gpxPrimitivesProvider, rasterTileSize, std::shared_ptr<const OsmAnd::SymbolRasterizer>(new OsmAnd::SymbolRasterizer())));
            [self.mapView addTiledSymbolsProvider:_gpxMapObjectsSymbolsProvider];
        }
    }];
}

- (void) refreshGpxTracks:(QList<std::shared_ptr<const OsmAnd::GeoInfoDocument>>)gpxDocs mapPrimitiviser:(std::shared_ptr<OsmAnd::MapPrimitiviser>)mapPrimitiviser
{
    [self.mapViewController runWithRenderSync:^{
        [self resetLayer];
    }];
    
    _gpxDocs.clear();
    _gpxDocs << gpxDocs;

    [self setupGpxRenderer:mapPrimitiviser];
}

@end
