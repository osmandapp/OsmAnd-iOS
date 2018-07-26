//
//  OATransportStopsLayer.m
//  OsmAnd
//
//  Created by Alexey on 14/07/2018.
//  Copyright © 2018 OsmAnd. All rights reserved.
//

#import "OATransportStopsLayer.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OANativeUtilities.h"
#import "OAUtilities.h"
#import "OATargetPoint.h"
#import "OATransportStop.h"

#include "OACoreResourcesTransportRouteIconProvider.h"

#include <OsmAndCore/Ref.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/TransportStop.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/TransportStopSymbolsProvider.h>

#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/ObfDataInterface.h>

@implementation OATransportStopsLayer
{
    BOOL _showStopsOnMap;
    
    std::shared_ptr<OsmAnd::TransportStopSymbolsProvider> _transportStopSymbolsProvider;
}

- (NSString *) layerId
{
    return kTransportLayerId;
}

- (void) initLayer
{
    _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    
    [self.mapView addKeyedSymbolsProvider:_linesCollection];
}

- (void) resetLayer
{
    if (_transportStopSymbolsProvider)
    {
        [self.mapView removeTiledSymbolsProvider:_transportStopSymbolsProvider];
        _transportStopSymbolsProvider.reset();
    }
    
    [self.mapView removeKeyedSymbolsProvider:_linesCollection];
    
    _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
}

- (BOOL) updateLayer
{
    if (_showStopsOnMap)
        [self doShowStopsOnMap];
    
    return YES;
}

- (void) showStopsOnMap:(std::shared_ptr<OsmAnd::TransportRoute>)transportRoute
{
    _showStopsOnMap = YES;
    _transportRoute = transportRoute;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doShowStopsOnMap];
    });
}

- (void) doShowStopsOnMap
{
    [self.mapViewController runWithRenderSync:^{
        _transportStopSymbolsProvider.reset(new OsmAnd::TransportStopSymbolsProvider(self.app.resourcesManager->obfsCollection, _transportRoute, std::make_shared<OACoreResourcesTransportRouteIconProvider>(OsmAnd::getCoreResourcesProvider(), self.mapViewController.displayDensityFactor, 1.0)));
        
        [self.mapView addTiledSymbolsProvider:_transportStopSymbolsProvider];
    }];
}

- (void) hideStops
{
    if (!_showStopsOnMap)
        return;
    
    _showStopsOnMap = NO;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.mapViewController runWithRenderSync:^{
            if (_transportStopSymbolsProvider)
            {
                [self.mapView removeTiledSymbolsProvider:_transportStopSymbolsProvider];
                _transportStopSymbolsProvider.reset();
            }
        }];
    });
}

#pragma mark - OAContextMenuProvider

- (OATargetPoint *) getTargetPoint:(id)obj
{
    if ([obj isKindOfClass:[OATransportStop class]])
    {
        OATransportStop *item = (OATransportStop *)obj;
        
        OATargetPoint *targetPoint = [[OATargetPoint alloc] init];
        targetPoint.type = OATargetTransportStop;
        targetPoint.location = item.location;        
        targetPoint.targetObj = item;
        targetPoint.title = item.name;
        
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        return targetPoint;
    }
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

- (void) collectObjectsFromPoint:(CLLocationCoordinate2D)point touchPoint:(CGPoint)touchPoint symbolInfo:(const OsmAnd::IMapRenderer::MapSymbolInformation *)symbolInfo found:(NSMutableArray<OATargetPoint *> *)found unknownLocation:(BOOL)unknownLocation
{
    OsmAnd::TransportStopSymbolsProvider::TransportStopSymbolsGroup* transportStopSymbolGroup = dynamic_cast<OsmAnd::TransportStopSymbolsProvider::TransportStopSymbolsGroup*>(symbolInfo->mapSymbol->groupPtr);
    if (transportStopSymbolGroup != nullptr)
    {
        const auto transportStop = transportStopSymbolGroup->transportStop;
        OATransportStop *stop = [[OATransportStop alloc] init];
        stop.stop = transportStop;
        OATargetPoint *targetPoint = [self getTargetPoint:stop];
        if (![found containsObject:targetPoint])
            [found addObject:targetPoint];
    }
}

@end
