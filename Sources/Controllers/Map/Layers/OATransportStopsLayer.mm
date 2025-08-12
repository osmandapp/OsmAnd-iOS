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
#import "OATransportStop+cpp.h"
#import "OAMapStyleSettings.h"
#import "OATransportStopRoute.h"
#import "OATransportStopAggregated.h"
#import "OAPOI.h"
#import "OAPointDescription.h"
#import "Localization.h"
#import "OAAppSettings.h"
#import "OsmAnd_Maps-Swift.h"

#include "OACoreResourcesTransportRouteIconProvider.h"
#include <OsmAndCore/Ref.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Data/TransportStop.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/TransportStopSymbolsProvider.h>
#include <OsmAndCore/Map/VectorLinesCollection.h>
#include <OsmAndCore/Data/Amenity.h>
#include <OsmAndCore/Data/ObfPoiSectionInfo.h>
#include <OsmAndCore/Data/ObfMapObject.h>
#include <OsmAndCore/Map/MapObjectsSymbolsProvider.h>
#include <OsmAndCore/ObfDataInterface.h>

static const int START_ZOOM_SELECTED_TRANSPORT_ROUTE = 10;
static const int START_ZOOM_ALL_TRANSPORT_STOPS = 12;

@implementation OATransportStopsLayer
{
    BOOL _showStopsOnMap;
    
    std::shared_ptr<OsmAnd::TransportStopSymbolsProvider> _transportStopSymbolsProvider;
    std::shared_ptr<OsmAnd::VectorLinesCollection> _linesCollection;
    OATransportStopRoute *_stopRoute;
    UIColor *_stopRouteColor;
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
    if (![super updateLayer])
        return NO;

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
    _stopRouteColor = [stopRoute getColor:NO];

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
            UIColor *c = _stopRouteColor;
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

        CGFloat textSize = [[OAAppSettings sharedManager].textSize get];

        _transportStopSymbolsProvider.reset(new OsmAnd::TransportStopSymbolsProvider(self.app.resourcesManager->obfsCollection, self.pointsOrder - 1000, _stopRoute.route, std::make_shared<OACoreResourcesTransportRouteIconProvider>(OsmAnd::getCoreResourcesProvider(), self.mapViewController.displayDensityFactor, textSize)));

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
        targetPoint.location = [item getLocation].coordinate;
        targetPoint.targetObj = item;
        if (item.transportStopAggregated && item.transportStopAggregated.localTransportStops.count == 0 && item.poi)
        {
            targetPoint.title = item.poi.name;
        } else {
            targetPoint.title = item.name;
        }
        
        targetPoint.sortIndex = (NSInteger)targetPoint.type;
        return targetPoint;
    }
    return nil;
}

- (OATargetPoint *) getTargetPointCpp:(const void *)obj
{
    return nil;
}

- (BOOL)isSecondaryProvider
{
    return NO;
}

- (CLLocation *) getObjectLocation:(id)obj
{
    if ([obj isKindOfClass:OATransportStop.class])
    {
        OATransportStop *transportStop = (OATransportStop *)obj;
        return [[CLLocation alloc] initWithLatitude:transportStop.latitude longitude:transportStop.longitude];
    }
    return nil;
}

- (OAPointDescription *) getObjectName:(id)obj
{
    if ([obj isKindOfClass:OATransportStop.class])
    {
        OATransportStop *transportStop = (OATransportStop *)obj;
        return [[OAPointDescription alloc] initWithType:POINT_TYPE_TRANSPORT_STOP typeName:OALocalizedString(@"transport_Stop") name:[transportStop name]];
    }
    return nil;
}

- (void) collectObjectsFromPoint:(MapSelectionResult *)result unknownLocation:(BOOL)unknownLocation excludeUntouchableObjects:(BOOL)excludeUntouchableObjects;
{
    if ([self.mapViewController getMapZoom] < START_ZOOM_ALL_TRANSPORT_STOPS)
           return;
    
    [self collectTransportStopsFromPoint:result];
}

- (void)collectTransportStopsFromPoint:(MapSelectionResult *)result
{
    NSMutableArray<NSString *> *addedTransportStops = [NSMutableArray new];
    CGPoint point = result.point;
    int delta = 20;
    OsmAnd::PointI tl = OsmAnd::PointI(point.x - delta, point.y - delta);
    OsmAnd::PointI br = OsmAnd::PointI(point.x + delta, point.y + delta);
    OsmAnd::AreaI touchPolygon31(tl, br);
    
    const auto& symbolInfos = [self.mapView getSymbolsIn:touchPolygon31 strict:NO];
    for (const auto symbolInfo : symbolInfos)
    {
        OsmAnd::TransportStopSymbolsProvider::TransportStopSymbolsGroup* transportStopSymbolGroup = dynamic_cast<OsmAnd::TransportStopSymbolsProvider::TransportStopSymbolsGroup*>(symbolInfo.mapSymbol->groupPtr);
        if (transportStopSymbolGroup != nullptr)
        {
            const auto transportStopObject = transportStopSymbolGroup->transportStop;
            if (transportStopObject != nullptr)
            {
                OATransportStop *transportStop = [[OATransportStop alloc] initWithStop:transportStopObject];
                if (transportStop && ![addedTransportStops containsObject:transportStop.name])
                {
                    [addedTransportStops addObject:transportStop.name];
                    [result collect:transportStop provider:self];
                }
            }
        }
    }
}

- (int64_t)getSelectionPointOrder:(id)selectedObject
{
    return 0;
}

- (BOOL)runExclusiveAction:(id)obj unknownLocation:(BOOL)unknownLocation
{
    return NO;
}

- (BOOL)showMenuAction:(id)object
{
    return NO;
}

@end
