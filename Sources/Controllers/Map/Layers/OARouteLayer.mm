//
//  OARouteLayer.m
//  OsmAnd
//
//  Created by Alexey Kulish on 11/06/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OARouteLayer.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OARoutingHelper.h"
#import "OARouteCalculationResult.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OARouteStatisticsHelper.h"
#import "OATransportRoutingHelper.h"
#import "OATransportStopType.h"
#import "OAColors.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/GeoInfoDocument.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/VectorLinesCollection.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/SkiaUtilities.h>
#include <SkCGUtils.h>

#include <transportRouteResultSegment.h>

@implementation OARouteLayer
{
    OARoutingHelper *_routingHelper;
    OATransportRoutingHelper *_transportHelper;

    std::shared_ptr<OsmAnd::VectorLinesCollection> _collection;
    
    std::shared_ptr<OsmAnd::MapMarkersCollection> _currentGraphXAxisPositions;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _transportRouteMarkers;
    
    std::shared_ptr<OsmAnd::MapMarkersCollection> _currentGraphPosition;
    std::shared_ptr<OsmAnd::MapMarker> _locationMarker;
    OsmAnd::MapMarker::OnSurfaceIconKey _locationIconKey;
    
    std::shared_ptr<SkBitmap> _xAxisLocationIcon;
    std::shared_ptr<SkBitmap> _transportTransferIcon;
    std::shared_ptr<SkBitmap> _transportShieldIcon;

    BOOL _initDone;
}

- (NSString *) layerId
{
    return kRouteLayerId;
}

- (void) initLayer
{
    [super initLayer];
    
    _routingHelper = [OARoutingHelper sharedInstance];
    _transportHelper = [OATransportRoutingHelper sharedInstance];
    
    _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _currentGraphPosition = std::make_shared<OsmAnd::MapMarkersCollection>();
    _currentGraphXAxisPositions = std::make_shared<OsmAnd::MapMarkersCollection>();
    _transportRouteMarkers = std::make_shared<OsmAnd::MapMarkersCollection>();
    
    _xAxisLocationIcon = [OANativeUtilities skBitmapFromPngResource:@"map_mapillary_location"];
    _transportTransferIcon = [OANativeUtilities skBitmapFromPngResource:@"map_public_transport_transfer"];
    _transportShieldIcon = [OANativeUtilities skBitmapFromPngResource:@"map_public_transport_stop_shield"];
    
    OsmAnd::MapMarkerBuilder locationMarkerBuilder;
    locationMarkerBuilder.setIsAccuracyCircleSupported(false);
    locationMarkerBuilder.setBaseOrder(self.baseOrder - 25);
    locationMarkerBuilder.setIsHidden(true);
    
    _locationIconKey = reinterpret_cast<OsmAnd::MapMarker::OnSurfaceIconKey>(1);
    locationMarkerBuilder.addOnMapSurfaceIcon(_locationIconKey,
                                                       [OANativeUtilities skBitmapFromPngResource:@"map_pedestrian_location"]);
    _locationMarker = locationMarkerBuilder.buildAndAddToCollection(_currentGraphPosition);
    
    _initDone = YES;
    
    [self.mapView addKeyedSymbolsProvider:_collection];
    [self.mapView addKeyedSymbolsProvider:_currentGraphPosition];
    [self.mapView addKeyedSymbolsProvider:_currentGraphXAxisPositions];
    [self.mapView addKeyedSymbolsProvider:_transportRouteMarkers];
}

- (void) resetLayer
{
    [super resetLayer];
    
    [self.mapView removeKeyedSymbolsProvider:_collection];
    [self.mapView removeKeyedSymbolsProvider:_currentGraphXAxisPositions];
    [self.mapView removeKeyedSymbolsProvider:_transportRouteMarkers];
    
    _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _currentGraphXAxisPositions = std::make_shared<OsmAnd::MapMarkersCollection>();
    _transportRouteMarkers = std::make_shared<OsmAnd::MapMarkersCollection>();

    _locationMarker->setIsHidden(true);
}

- (BOOL) updateLayer
{
    [super updateLayer];

    [self refreshRoute];
    return YES;
}

- (void)drawRouteMarkers:(const std::shared_ptr<TransportRouteResultSegment> &)routeSegment
{
    OsmAnd::MapMarkerBuilder transportMarkerBuilder;
    transportMarkerBuilder.setIsAccuracyCircleSupported(false);
    transportMarkerBuilder.setBaseOrder(self.baseOrder - 15);
    transportMarkerBuilder.setIsHidden(false);
    transportMarkerBuilder.setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal);
    transportMarkerBuilder.setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical);
    OsmAnd::LatLon startLatLon(routeSegment->getStart().lat, routeSegment->getStart().lon);
    transportMarkerBuilder.setPinIcon(_transportTransferIcon);
    
    auto marker = transportMarkerBuilder.buildAndAddToCollection(_transportRouteMarkers);
    marker->setPosition(OsmAnd::Utilities::convertLatLonTo31(startLatLon));
    
    OATransportStopType *type = [OATransportStopType findType:[NSString stringWithUTF8String:routeSegment->route->type.c_str()]];
    NSString *resId = type != nil ? type.resId : [OATransportStopType getResId:TST_BUS];
    UIImage *origIcon = [UIImage imageNamed:[OAUtilities drawablePath:resId]];
    std::shared_ptr<SkBitmap> stopBmp = std::make_shared<SkBitmap>();
    bool res = false;
    if (origIcon)
    {
        origIcon = [OAUtilities applyScaleFactorToImage:origIcon];
        UIImage *tintedIcon = [OAUtilities tintImageWithColor:origIcon color:[UIColor blackColor]];
        res = SkCreateBitmapFromCGImage(stopBmp.get(), tintedIcon.CGImage);
    }
    std::shared_ptr<SkBitmap> icon = nullptr;
    if (res)
    {
        QList< std::shared_ptr<const SkBitmap>> composition;
        composition << _transportShieldIcon;
        composition << OsmAnd::SkiaUtilities::scaleBitmap(stopBmp, 0.5, 0.5);
        icon = OsmAnd::SkiaUtilities::mergeBitmaps(composition);
    }
    
    transportMarkerBuilder.setPinIcon(res ? icon : _transportShieldIcon);
    for (int i = routeSegment->start + 1; i < routeSegment->end; i++)
    {
        const auto& stop = routeSegment->getStop(i);
        OsmAnd::LatLon latLon(stop.lat, stop.lon);
        const auto& marker = transportMarkerBuilder.buildAndAddToCollection(_transportRouteMarkers);
        marker->setPosition(OsmAnd::Utilities::convertLatLonTo31(latLon));
    }
    transportMarkerBuilder.setPinIcon(_transportTransferIcon);
    OsmAnd::LatLon endLatLon(routeSegment->getEnd().lat, routeSegment->getEnd().lon);
    marker = transportMarkerBuilder.buildAndAddToCollection(_transportRouteMarkers);
    marker->setPosition(OsmAnd::Utilities::convertLatLonTo31(endLatLon));
}

- (void) drawTransportSegment:(SHARED_PTR<TransportRouteResultSegment>)routeSegment
{
    [self.mapViewController runWithRenderSync:^{
        [self drawRouteMarkers:routeSegment];
            
        OATransportStopType *type = [OATransportStopType findType:[NSString stringWithUTF8String:routeSegment->route->type.c_str()]];
        NSString *str = [NSString stringWithUTF8String:routeSegment->route->color.c_str()];
        str = str.length == 0 ? type.renderAttr : str;
        OsmAnd::ColorARGB colorARGB;
        UIColor *color = [self.mapViewController getTransportRouteColor:OAAppSettings.sharedManager.nightMode renderAttrName:str];
        CGFloat red, green, blue, alpha;
        if (str.length > 0 && color)
        {
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
        }
        else
        {
            color = UIColorFromARGB(color_nav_route_default_argb);
            [color getRed:&red green:&green blue:&blue alpha:&alpha];
        }
        colorARGB = OsmAnd::ColorARGB(255 * alpha, 255 * red, 255 * green, 255 * blue);
        
        int baseOrder = self.baseOrder;
        vector<std::shared_ptr<Way>> list;
        routeSegment->getGeometry(list);
        for (const auto& way : list)
        {
            QVector<OsmAnd::PointI> points;
            for (const auto& node : way->nodes)
            {
                points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(node.lat, node.lon)));
            }
            if (points.size() > 1)
            {
                OsmAnd::VectorLineBuilder builder;
                builder.setBaseOrder(baseOrder--)
                .setIsHidden(way->nodes.size() == 0)
                .setApproximationEnabled(false)
                .setLineId(1)
                .setLineWidth(30)
                .setPoints(points)
                .setFillColor(colorARGB);
                builder.buildAndAddToCollection(_collection);
            }
        }
    }];
}

- (void) drawRouteSegment:(const QVector<OsmAnd::PointI> &)points addToExisting:(BOOL)addToExisting
{
    [self.mapViewController runWithRenderSync:^{
        const auto& lines = _collection->getLines();
        if (lines.empty() || addToExisting)
        {
            BOOL isFirstLine = lines.empty() && !addToExisting;
            if (isFirstLine)
            {
                [self.mapView removeKeyedSymbolsProvider:_collection];
                _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
            }
            
            int baseOrder = self.baseOrder;
            BOOL isNight = [OAAppSettings sharedManager].nightMode;
            
            NSDictionary<NSString *, NSNumber *> *result = [self.mapViewController getLineRenderingAttributes:@"route"];
            NSNumber *val = [result valueForKey:@"color"];
            OsmAnd::ColorARGB lineColor = (val && val.intValue != -1) ? OsmAnd::ColorARGB(val.intValue) : isNight ?
            OsmAnd::ColorARGB(0xff, 0xff, 0xdf, 0x3d) : OsmAnd::ColorARGB(0x88, 0x2a, 0x4b, 0xd1);
            
            OsmAnd::VectorLineBuilder builder;
            builder.setBaseOrder(baseOrder--)
            .setIsHidden(points.size() == 0)
            .setApproximationEnabled(false)
            .setLineId(1)
            .setLineWidth(30)
            .setPoints(points);
            
            builder.setFillColor(lineColor)
            .setPathIcon([OANativeUtilities skBitmapFromMmPngResource:@"arrow_triangle_black_nobg"])
            .setPathIconStep(40)
            .setScreenScale(UIScreen.mainScreen.scale);
            
            builder.buildAndAddToCollection(_collection);
            
            if (isFirstLine)
            {
                [self.mapView addKeyedSymbolsProvider:_collection];
                [self setVectorLineProvider:_collection];
            }
        }
        else
        {
            lines[0]->setPoints(points);
        }
    }];
}

- (void) refreshRoute
{
    OARouteCalculationResult *route = [_routingHelper getRoute];
    if ([_routingHelper isPublicTransportMode])
    {
        NSInteger currentRoute = _transportHelper.currentRoute;
        const auto routes = [_transportHelper getRoutes];
        const auto route = currentRoute != -1 && routes.size() > currentRoute ? routes[currentRoute] : nullptr;
        if (route != nullptr)
        {
            CLLocation *start = _transportHelper.startLocation;
            CLLocation *end = _transportHelper.endLocation;
            
            CLLocation *p = start;
            SHARED_PTR<TransportRouteResultSegment> prev = nullptr;
            
            [self.mapView removeKeyedSymbolsProvider:_collection];
            _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
            
            [self.mapView removeKeyedSymbolsProvider:_transportRouteMarkers];
            _transportRouteMarkers = std::make_shared<OsmAnd::MapMarkersCollection>();
            for (const auto &seg : route->segments)
            {
                [self drawTransportSegment:seg];
                CLLocation *floc = [[CLLocation alloc] initWithLatitude:seg->getStart().lat longitude:seg->getStart().lon];
                [self addWalkRoute:prev s2:seg start:p end:floc];
                p = [[CLLocation alloc] initWithLatitude:seg->getEnd().lat longitude:seg->getEnd().lon];
                prev = seg;
            }
            [self addWalkRoute:prev s2:nullptr start:p end:end];
            
            [self.mapView addKeyedSymbolsProvider:_collection];
            [self.mapView addKeyedSymbolsProvider:_transportRouteMarkers];
        }
    }
    else if ([_routingHelper getFinalLocation] && route && [route isCalculated])
    {
        NSArray<CLLocation *> *locations = [route getImmutableAllLocations];
        int currentRoute = route.currentRoute;
        if (currentRoute < 0)
            currentRoute = 0;

        QVector<OsmAnd::PointI> points;
        CLLocation* lastProj = [_routingHelper getLastProjection];
        if (lastProj)
            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lastProj.coordinate.latitude, lastProj.coordinate.longitude)));

        for (int i = currentRoute; i < locations.count; i++)
        {
            CLLocation *p = locations[i];
            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(p.coordinate.latitude, p.coordinate.longitude)));
        }
        
        if (points.size() > 1)
        {
            [self drawRouteSegment:points addToExisting:NO];
        }
        else
        {
            [self.mapViewController runWithRenderSync:^{
                [self resetLayer];
            }];
        }
    }
    else
    {
        [self.mapViewController runWithRenderSync:^{
            [self resetLayer];
        }];
    }
}
                 
- (void) addWalkRoute:(SHARED_PTR<TransportRouteResultSegment>) s1 s2:(SHARED_PTR<TransportRouteResultSegment>)s2 start:(CLLocation *)start end:(CLLocation *)end
{
    OARouteCalculationResult *res = [_transportHelper.walkingRouteSegments objectForKey:@[[[OATransportRouteResultSegment alloc] initWithSegment:s1], [[OATransportRouteResultSegment alloc] initWithSegment:s2]]];
    NSArray<CLLocation *> *locations = [res getRouteLocations];
    if (res && locations.count > 0)
    {
        QVector<OsmAnd::PointI> points;
        for (NSInteger i = 0; i < locations.count; i++)
        {
            CLLocation *p = locations[i];
            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(p.coordinate.latitude, p.coordinate.longitude)));
        }
        [self drawRouteSegment:points addToExisting:YES];
    }
}

- (void) showCurrentStatisticsLocation:(OATrackChartPoints *) trackPoints
{
    if (_locationMarker && trackPoints.highlightedPoint.latitude != 0 && trackPoints.highlightedPoint.longitude != 0)
    {
        _locationMarker->setPosition(OsmAnd::Utilities::convertLatLonTo31(trackPoints.highlightedPoint));
        _locationMarker->setIsHidden(false);
    }
    OsmAnd::MapMarkerBuilder xAxisMarkerBuilder;
    xAxisMarkerBuilder.setIsAccuracyCircleSupported(false);
    xAxisMarkerBuilder.setBaseOrder(self.baseOrder - 15);
    xAxisMarkerBuilder.setIsHidden(false);
    if (trackPoints.axisPointsInvalidated)
    {
        [self.mapView removeKeyedSymbolsProvider:_currentGraphXAxisPositions];
        _currentGraphXAxisPositions = std::make_shared<OsmAnd::MapMarkersCollection>();
        
        for (CLLocation *location in trackPoints.xAxisPoints)
        {
            xAxisMarkerBuilder.addOnMapSurfaceIcon(_locationIconKey,
                                                   _xAxisLocationIcon);
            
            const auto& marker = xAxisMarkerBuilder.buildAndAddToCollection(_currentGraphXAxisPositions);
            marker->setPosition(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.coordinate.latitude, location.coordinate.longitude)));
        }
        [self.mapView addKeyedSymbolsProvider:_currentGraphXAxisPositions];
        trackPoints.axisPointsInvalidated = NO;
    }
}

- (void) hideCurrentStatisticsLocation
{
    if (_locationMarker)
        _locationMarker->setIsHidden(true);
    
    [self.mapView removeKeyedSymbolsProvider:_currentGraphXAxisPositions];
    _currentGraphXAxisPositions = std::make_shared<OsmAnd::MapMarkersCollection>();
}

@end
