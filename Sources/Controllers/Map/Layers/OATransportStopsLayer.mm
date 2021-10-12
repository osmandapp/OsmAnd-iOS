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
#import "OAMapStyleSettings.h"
#import "OATransportStopRoute.h"

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
    std::shared_ptr<OsmAnd::VectorLinesCollection> _linesCollection;
    OATransportStopRoute *_stopRoute;
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
    [super updateLayer];
    
    OAMapStyleSettings *styleSettings = [OAMapStyleSettings sharedInstance];
    OAMapStyleParameter *param = [styleSettings getParameter:@"transportStops"];
    _showStopsOnMap = [param.value boolValue];

    if (_showStopsOnMap)
    {
        [self doShowStopsOnMap];
    }
    else if (_transportStopSymbolsProvider)
    {
        [self.mapView removeTiledSymbolsProvider:_transportStopSymbolsProvider];
        _transportStopSymbolsProvider.reset();
    }
    
    return YES;
}

- (void) showStopsOnMap:(OATransportStopRoute *)stopRoute
{
    _showStopsOnMap = YES;
    _stopRoute = stopRoute;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self doShowStopsOnMap];
    });
}

- (void) doShowStopsOnMap
{
    [self.mapViewController runWithRenderSync:^{

        if (_linesCollection)
            [self.mapView removeKeyedSymbolsProvider:_linesCollection];

        _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
        if (_stopRoute)
        {
            int baseOrder = self.baseOrder;
            int lineId = 1;
            UIColor *c = [_stopRoute getColor:NO];
            CGFloat r, g, b, a;
            [c getRed:&r green:&g blue:&b alpha:&a];
            const auto& color = OsmAnd::ColorARGB(255 * a, 255 * r, 255 * g, 255 * b);
            
            for (const auto& points : _stopRoute.route->forwardWays31)
            {
                if (points.size() > 1)
                {
                    OsmAnd::VectorLineBuilder builder;
                    builder.setBaseOrder(baseOrder--)
                    .setIsHidden(points.size() == 0)
                    .setLineId(lineId++)
                    .setLineWidth(6 * self.displayDensityFactor)
                    .setPoints(points)
                    .setFillColor(color);
                    
                    builder.buildAndAddToCollection(_linesCollection);
                }
            }
            
            [self.mapView addKeyedSymbolsProvider:_linesCollection];
        }
        
        if (_transportStopSymbolsProvider)
            [self.mapView removeTiledSymbolsProvider:_transportStopSymbolsProvider];

        _transportStopSymbolsProvider.reset(new OsmAnd::TransportStopSymbolsProvider(self.app.resourcesManager->obfsCollection, self.baseOrder - 1000, _stopRoute.route, std::make_shared<OACoreResourcesTransportRouteIconProvider>(OsmAnd::getCoreResourcesProvider(), self.mapViewController.displayDensityFactor, 1.0)));
        
        [self.mapView addTiledSymbolsProvider:_transportStopSymbolsProvider];
    }];
}

- (void) hideRoute
{
    _stopRoute = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.mapViewController runWithRenderSync:^{
            [self.mapView removeKeyedSymbolsProvider:_linesCollection];
            _linesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
            
            [self updateLayer];
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
