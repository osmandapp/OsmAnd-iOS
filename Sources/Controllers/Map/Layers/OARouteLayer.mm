//
//  OARouteLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARouteLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"

#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/MapPrimitivesProvider.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/Map/MapRasterLayerProvider_Software.h>

@implementation OARouteLayer
{
    std::shared_ptr<const OsmAnd::GeoInfoDocument> _routeDoc;
    
    std::shared_ptr<OsmAnd::GeoInfoPresenter> _routePresenter;
    std::shared_ptr<OsmAnd::IMapLayerProvider> _routeRasterMapProvider;
    std::shared_ptr<OsmAnd::MapPrimitivesProvider> _routePrimitivesProvider;
    std::shared_ptr<OsmAnd::MapObjectsSymbolsProvider> _routeMapObjectsSymbolsProvider;
}

- (NSString *) layerId
{
    return kRouteLayerId;
}

- (void) initLayer
{
    [super initLayer];
}

- (void) deinitLayer
{
    [super deinitLayer];
}

- (void) resetLayer
{
    if (_routeMapObjectsSymbolsProvider)
        [self.mapView removeTiledSymbolsProvider:_routeMapObjectsSymbolsProvider];
    _routeMapObjectsSymbolsProvider.reset();
    
    [self.mapView resetProviderFor:self.layerIndex];
    
    _routePrimitivesProvider.reset();
    _routePresenter.reset();
}

- (void) setupRouteRenderer:(std::shared_ptr<OsmAnd::MapPrimitiviser>)mapPrimitiviser
{
    [self.mapViewController runWithRenderSync:^{
        
        if (!_routeDoc)
            return;
        
        if (_routeMapObjectsSymbolsProvider)
            [self.mapView removeTiledSymbolsProvider:_routeMapObjectsSymbolsProvider];
        
        _routeMapObjectsSymbolsProvider.reset();
        [self.mapView resetProviderFor:self.layerIndex];
        
        QList<std::shared_ptr<const OsmAnd::GeoInfoDocument> > gpxList;
        gpxList << _routeDoc;
        _routePresenter.reset(new OsmAnd::GeoInfoPresenter(gpxList));
        
        if (_routePresenter)
        {
            const auto rasterTileSize = OsmAnd::Utilities::getNextPowerOfTwo(256 * self.mapViewController.displayDensityFactor);
            _routePrimitivesProvider.reset(new OsmAnd::MapPrimitivesProvider(_routePresenter->createMapObjectsProvider(), mapPrimitiviser, rasterTileSize, OsmAnd::MapPrimitivesProvider::Mode::AllObjectsWithPolygonFiltering));
            
            _routeRasterMapProvider.reset(new OsmAnd::MapRasterLayerProvider_Software(_routePrimitivesProvider, false));
            [self.mapView setProvider:_routeRasterMapProvider forLayer:self.layerIndex];
            
            _routeMapObjectsSymbolsProvider.reset(new OsmAnd::MapObjectsSymbolsProvider(_routePrimitivesProvider, rasterTileSize, std::shared_ptr<const OsmAnd::SymbolRasterizer>(new OsmAnd::SymbolRasterizer())));
            [self.mapView addTiledSymbolsProvider:_routeMapObjectsSymbolsProvider];
        }
    }];
}

- (void) refreshRoute:(std::shared_ptr<const OsmAnd::GeoInfoDocument>)routeDoc mapPrimitiviser:(std::shared_ptr<OsmAnd::MapPrimitiviser>)mapPrimitiviser
{
    [self.mapViewController runWithRenderSync:^{
        [self resetLayer];
    }];
    
    _routeDoc = routeDoc;
    
    [self setupRouteRenderer:mapPrimitiviser];
}

@end
