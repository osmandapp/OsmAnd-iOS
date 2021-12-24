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
#import "OARouteDirectionInfo.h"
#import "OAAutoObserverProxy.h"
#import "OAColors.h"
#import "OAPreviewRouteLineInfo.h"

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
    
    std::shared_ptr<OsmAnd::VectorLinesCollection> _actionLinesCollection;
    OAAutoObserverProxy* _mapZoomObserver;
    
    NSDictionary<NSString *, NSNumber *> *_routeAttributes;

    BOOL _initDone;

    OAPreviewRouteLineInfo *_previewRouteLineInfo;
    NSInteger _routeLineColor;
    OAColoringType *_routeColoringType;
    NSString *_routeInfoAttribute;
}

- (NSString *) layerId
{
    return kRouteLayerId;
}

- (void)dealloc
{
    [_mapZoomObserver detach];
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
    _actionLinesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    
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
    
    _routeAttributes = [self.mapViewController getLineRenderingAttributes:@"route"];
    
    _initDone = YES;
    
    [self.mapView addKeyedSymbolsProvider:_collection];
    [self.mapView addKeyedSymbolsProvider:_currentGraphPosition];
    [self.mapView addKeyedSymbolsProvider:_currentGraphXAxisPositions];
    [self.mapView addKeyedSymbolsProvider:_transportRouteMarkers];
    
    _mapZoomObserver = [[OAAutoObserverProxy alloc] initWith:self
                                                 withHandler:@selector(onMapZoomChanged:withKey:andValue:)
                                                  andObserve:self.mapViewController.zoomObservable];

    _routeColoringType = OAColoringType.DEFAULT;
}

- (void) resetLayer
{
    [super resetLayer];
    
    [self.mapView removeKeyedSymbolsProvider:_collection];
    [self.mapView removeKeyedSymbolsProvider:_currentGraphXAxisPositions];
    [self.mapView removeKeyedSymbolsProvider:_transportRouteMarkers];
    [self.mapView removeKeyedSymbolsProvider:_actionLinesCollection];
    
    _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _currentGraphXAxisPositions = std::make_shared<OsmAnd::MapMarkersCollection>();
    _transportRouteMarkers = std::make_shared<OsmAnd::MapMarkersCollection>();
    _actionLinesCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    
    _routeAttributes = [self.mapViewController getLineRenderingAttributes:@"route"];

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
                .setLineId(1)
                .setLineWidth(50.)
                .setPoints(points)
                .setFillColor(colorARGB);
                builder.buildAndAddToCollection(_collection);
            }
        }
    }];
}

- (OsmAnd::FColorARGB) argbFromUIColor:(UIColor *)color
{
    CGFloat red, green, blue, alpha;
    [color getRed:&red green:&green blue:&blue alpha:&alpha];
    return OsmAnd::ColorARGB(alpha * 255, red * 255, green * 255, blue * 255);
}

- (void) drawRouteSegment:(const QVector<OsmAnd::PointI> &)points addToExisting:(BOOL)addToExisting
{
    [self.mapViewController runWithRenderSync:^{
        BOOL isNight = [OAAppSettings sharedManager].nightMode;
        [self updateRouteColoringType];
        [self updateRouteColors:isNight];

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
            OsmAnd::VectorLineBuilder builder;
            builder.setBaseOrder(baseOrder--)
                    .setIsHidden(points.size() == 0)
                    .setLineId(1)
                    .setLineWidth(60.)
                    .setPoints(points);

            UIColor *color = UIColorFromARGB(_routeLineColor);
            if (CGColorGetAlpha(color.CGColor) == 0.)
                color = [color colorWithAlphaComponent:1.];

            OsmAnd::ColorARGB lineColor = [self argbFromUIColor:color];

            NSNumber *colorVal = [self getColorFromAttr];
            BOOL hasStyleColor = (colorVal && colorVal.intValue != -1 && colorVal.intValue == _routeLineColor)
                    || _routeLineColor == kDefaultRouteLineDayColor
                    || _routeLineColor == kDefaultRouteLineNightColor;

            builder.setFillColor(lineColor)
                    .setPathIcon([self bitmapForColor:hasStyleColor ? UIColor.whiteColor : color fileName:@"map_direction_arrow"])
                    .setSpecialPathIcon([self specialBitmapWithColor:lineColor])
                    .setShouldShowArrows(true)
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
        [self buildActionArrows];
    }];
}

- (NSNumber *)getColorFromAttr
{
    NSDictionary<NSString *, NSNumber *> *result = _routeAttributes;
    if (!result)
        result = [self.mapViewController getLineRenderingAttributes:@"route"];
    return result[@"color"];
}

- (NSInteger)getOriginalColor
{
    BOOL isNight = [OAAppSettings sharedManager].nightMode;
    NSNumber *colorVal = [self getColorFromAttr];
    BOOL hasStyleColor = colorVal && colorVal.intValue != -1;
    return hasStyleColor ? colorVal.intValue : isNight ? kDefaultRouteLineNightColor : kDefaultRouteLineDayColor;
}

- (OAPreviewRouteLineInfo *)getPreviewRouteLineInfo
{
    return _previewRouteLineInfo;
}

- (void)setPreviewRouteLineInfo:(OAPreviewRouteLineInfo *)previewInfo
{
    _previewRouteLineInfo = previewInfo;
}

- (void)updateRouteColors:(BOOL)night
{
    if ([_routeColoringType isCustomColor])
        [self updateCustomColor:night];
    else
        _routeLineColor = [self getOriginalColor];
}

- (void)updateCustomColor:(BOOL)night
{
    NSInteger customColor;
    if (_previewRouteLineInfo)
    {
        customColor = [_previewRouteLineInfo getCustomColor:night];
    }
    else
    {
        OACommonInteger *colorPreference = night
                ? [OAAppSettings sharedManager].customRouteColorNight
                : [OAAppSettings sharedManager].customRouteColorDay;
        customColor = [colorPreference get:[_routingHelper getAppMode]];
    }

    _routeLineColor = customColor;
}

- (void)updateRouteColoringType
{
    if (_previewRouteLineInfo)
    {
        _routeColoringType = _previewRouteLineInfo.coloringType;
        _routeInfoAttribute = _previewRouteLineInfo.routeInfoAttribute;
    }
    else
    {
        OAApplicationMode *mode = [_routingHelper getAppMode];
        OAAppSettings *settings = [OAAppSettings sharedManager];
        _routeColoringType = [settings.routeColoringType get:mode];
        _routeInfoAttribute = [settings.routeInfoAttribute get:mode];
    }
}

- (OsmAnd::AreaI) calculateBounds:(NSArray<CLLocation *> *)pts
{
    double left = DBL_MAX, top = DBL_MIN, right = DBL_MIN, bottom = DBL_MAX;
    for (NSInteger i = 0; i < pts.count; i++)
    {
        CLLocation *pt = pts[i];
        right = MAX(right, pt.coordinate.longitude);
        left = MIN(left, pt.coordinate.longitude);
        top = MAX(top, pt.coordinate.latitude);
        bottom = MIN(bottom, pt.coordinate.latitude);
    }
    OsmAnd::PointI topLeft = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(top, left));
    OsmAnd::PointI bottomRight = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(bottom, right));
    return OsmAnd::AreaI(topLeft, bottomRight);
}

- (void) onMapZoomChanged:(id)observable withKey:(id)key andValue:(id)value
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self buildActionArrows];
    });
}

- (void) buildActionArrows
{
    [self.mapViewController runWithRenderSync:^{
        const auto zoom = self.mapView.zoomLevel;
        
        if (_collection->getLines().isEmpty() || zoom <= OsmAnd::ZoomLevel14)
        {
            [self.mapView removeKeyedSymbolsProvider:_actionLinesCollection];
            _actionLinesCollection->removeAllLines();
            return;
        }
        else
        {
            NSDictionary<NSString *, NSNumber *> *result = _routeAttributes;
            if (!result)
                result = [self.mapViewController getLineRenderingAttributes:@"route"];
            NSNumber *colorVal = [result valueForKey:@"color_3"];
            BOOL hasStyleColor = colorVal && colorVal.intValue != -1;
            BOOL isNight = [OAAppSettings sharedManager].nightMode;
            OsmAnd::ColorARGB lineColor = hasStyleColor ? OsmAnd::ColorARGB(colorVal.intValue) : isNight ?
            OsmAnd::ColorARGB(0xff41a6d9) : OsmAnd::ColorARGB(0xffffde5b);
            
            int baseOrder = self.baseOrder - 1000;
            NSArray<NSArray<CLLocation *> *> *actionPoints = [self calculateActionPoints];
            if (actionPoints.count > 0)
            {
                int lineIdx = 0;
                int initialLinesCount = _actionLinesCollection->getLines().count();
                for (NSArray<CLLocation *> *line in actionPoints)
                {
                    QVector<OsmAnd::PointI> points;
                    for (CLLocation *point in line)
                    {
                        points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(point.coordinate.latitude, point.coordinate.longitude)));
                    }
                    if (lineIdx < initialLinesCount)
                    {
                        auto line = _actionLinesCollection->getLines()[lineIdx];
                        line->setPoints(points);
                        line->setIsHidden(false);
                        lineIdx++;
                    }
                    else
                    {
                        OsmAnd::VectorLineBuilder builder;
                        builder.setBaseOrder(baseOrder--)
                            .setIsHidden(false)
                            .setLineId(_actionLinesCollection->getLines().size())
                            .setLineWidth(25.) // change this to dynamic width in the future
                            .setPoints(points)
                            .setEndCapStyle(OsmAnd::LineEndCapStyle::ARROW)
                            .setFillColor(lineColor);
                        builder.buildAndAddToCollection(_actionLinesCollection);
                    }
                }
                QList< std::shared_ptr<OsmAnd::VectorLine> > toDelete;
                while (lineIdx < initialLinesCount)
                {
                    _actionLinesCollection->getLines()[lineIdx]->setIsHidden(true);
                    lineIdx++;
                }
            }
        }
        [self.mapView addKeyedSymbolsProvider:_actionLinesCollection];
    }];
}

- (NSArray<NSArray<CLLocation *> *> *) calculateActionPoints
{
    NSArray<OARouteDirectionInfo *> *directions = _routingHelper.getRouteDirections;
    NSInteger dirIdx = 0;
    NSArray<CLLocation *> *routeNodes = _routingHelper.getRoute.getRouteLocations;
    CLLocation *lastProjection = _routingHelper.getLastProjection;
    int cd = _routingHelper.getRoute.currentRoute;
    OsmAnd::ZoomLevel zoom = self.mapView.zoomLevel;
    
    OARouteDirectionInfo *nf = nil;
    double DISTANCE_ACTION = 35;
    if(zoom >= OsmAnd::ZoomLevel17)
        DISTANCE_ACTION = 15;
    else if (zoom == OsmAnd::ZoomLevel15)
        DISTANCE_ACTION = 70;
    else if (zoom < OsmAnd::ZoomLevel15)
        DISTANCE_ACTION = 110;
    
    double actionDist = 0;
    CLLocation *previousAction = nil;
    NSMutableArray<NSArray<CLLocation *> *> *res = [NSMutableArray array];
    NSMutableArray<CLLocation *> *actionPoints = [NSMutableArray array];
    int prevFinishPoint = -1;
    for (int routePoint = 0; routePoint < routeNodes.count; routePoint++)
    {
        CLLocation *loc = routeNodes[routePoint];
        if(nf != nil)
        {
            int pnt = nf.routeEndPointOffset == 0 ? nf.routePointOffset : nf.routeEndPointOffset;
            if (pnt < routePoint + cd)
                nf = nil;
        }
        while (nf == nil && dirIdx < directions.count)
        {
            nf = directions[dirIdx++];
            int pnt = nf.routeEndPointOffset == 0 ? nf.routePointOffset : nf.routeEndPointOffset;
            if (pnt < routePoint + cd)
                nf = nil;
        }
        BOOL action = nf != nil && (nf.routePointOffset == routePoint + cd ||
                                        (nf.routePointOffset <= routePoint + cd && routePoint + cd  <= nf.routeEndPointOffset));
        if(!action && previousAction == nil)
        {
            // no need to check
            continue;
        }
        if (!action)
        {
            // previousAction != null
            double dist = [loc distanceFromLocation:previousAction];
            actionDist += dist;
            if (actionDist >= DISTANCE_ACTION)
            {
                [actionPoints addObject:[self calculateProjection:1 - (actionDist - DISTANCE_ACTION) / dist lp:previousAction l:loc]];
                [res addObject:actionPoints];
                actionPoints = [NSMutableArray array];
                prevFinishPoint = routePoint;
                previousAction = nil;
                actionDist = 0;
            }
            else
            {
                [actionPoints addObject:loc];
                previousAction = loc;
            }
        }
        else
        {
            // action point
            if (previousAction == nil)
            {
                [self addPreviousToActionPoints:actionPoints
                                 lastProjection:lastProjection
                                     routeNodes:routeNodes
                                DISTANCE_ACTION:DISTANCE_ACTION
                                prevFinishPoint:prevFinishPoint
                                     routePoint:routePoint
                                            loc:loc];
            }
            [actionPoints addObject:loc];
            previousAction = loc;
            prevFinishPoint = -1;
            actionDist = 0;
        }
    }
    if(previousAction != nil)
    {
        [res addObject:actionPoints];
    }
    return res;
}

- (void) addPreviousToActionPoints:(NSMutableArray<CLLocation *> *)actionPoints
                    lastProjection:(CLLocation *)lastProjection
                        routeNodes:(NSArray<CLLocation *> *)routeNodes
                   DISTANCE_ACTION:(double)DISTANCE_ACTION
                   prevFinishPoint:(int)prevFinishPoint
                        routePoint:(int)routePoint
                               loc:(CLLocation *)loc
{
    // put some points in front
    NSInteger ind = actionPoints.count;
    CLLocation *lprevious = loc;
    double dist = 0;
    for (NSInteger k = routePoint - 1; k >= -1; k--)
    {
        CLLocation *l = k == -1 ? lastProjection : routeNodes[k];
        double locDist = [lprevious distanceFromLocation:l];
        dist += locDist;
        if (dist >= DISTANCE_ACTION)
        {
            if (locDist > 1)
            {
                [actionPoints insertObject:[self calculateProjection:(1 - (dist - DISTANCE_ACTION) / locDist) lp:lprevious l:l] atIndex:ind];
            }
            break;
        }
        else
        {
            [actionPoints insertObject:l atIndex:ind];
            lprevious = l;
        }
        if (prevFinishPoint == k)
        {
            if (ind >= 2)
            {
                [actionPoints removeObjectAtIndex:ind - 2];
                [actionPoints removeObjectAtIndex:ind - 2];
            }
            break;
        }
    }
}

- (CLLocation *) calculateProjection:(double)part lp:(CLLocation *)lp l:(CLLocation *)l
{
    CLLocation *p = [[CLLocation alloc] initWithLatitude:lp.coordinate.latitude + part * (l.coordinate.latitude - lp.coordinate.latitude) longitude:lp.coordinate.longitude + part * (l.coordinate.longitude - lp.coordinate.longitude)];
    return p;
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
