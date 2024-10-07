//
//  OAMeasurementToolLayer.m
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMeasurementToolLayer.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OARoutingHelper.h"
#import "OANativeUtilities.h"
#import "OAMeasurementEditingContext.h"
#import "OAAppSettings.h"
#import "CLLocation+Extension.h"
#import "OsmAndSharedWrapper.h"

#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/VectorLinesCollection.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>
#include <OsmAndCore/SkiaUtilities.h>
#include <OsmAndCore/SingleSkImage.h>

#define MIN_POINTS_PERCENTILE 5
#define START_ZOOM 8
#define kDefaultLineWidth 16.0

@implementation OAMeasurementToolLayer
{
    OARoutingHelper *_routingHelper;

    std::shared_ptr<OsmAnd::VectorLinesCollection> _collection;
    std::shared_ptr<OsmAnd::VectorLinesCollection> _lastLineCollection;
    
    std::shared_ptr<OsmAnd::MapMarkersCollection> _pointMarkers;
    std::shared_ptr<OsmAnd::MapMarkersCollection> _selectedMarkerCollection;
    
    sk_sp<SkImage> _pointMarkerIcon;
    sk_sp<SkImage> _selectedMarkerIcon;
    
    OsmAnd::PointI _cachedCenter;
    BOOL _isInMovingMode;
    
    BOOL _initDone;
}

- (NSString *) layerId
{
    return kRoutePlanningLayerId;
}

- (void) initLayer
{
    _routingHelper = [OARoutingHelper sharedInstance];
    
    _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _lastLineCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _pointMarkers = std::make_shared<OsmAnd::MapMarkersCollection>();
    _selectedMarkerCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
    
    _pointMarkerIcon = [OANativeUtilities skImageFromPngResource:@"map_plan_route_point_normal"];
    _selectedMarkerIcon = [OANativeUtilities skImageFromPngResource:@"map_plan_route_point_movable"];
    
    _initDone = YES;
    
    [self.mapView addKeyedSymbolsProvider:_collection];
    [self.mapView addKeyedSymbolsProvider:_lastLineCollection];
    [self.mapView addKeyedSymbolsProvider:_pointMarkers];
    [self.mapView addKeyedSymbolsProvider:_selectedMarkerCollection];
}

- (void) updateDistAndBearing
{
    if (_delegate)
    {
        double distance = 0, bearing = 0;
        if (_editingCtx.getPointsCount > 0)
        {
            OASWptPt *lastPoint = _editingCtx.getPoints[_editingCtx.getPointsCount - 1];
            OsmAnd::LatLon centerLatLon = OsmAnd::Utilities::convert31ToLatLon(self.mapView.target31);
            distance = getDistance(lastPoint.getLatitude, lastPoint.getLongitude, centerLatLon.latitude, centerLatLon.longitude);
            CLLocation *loc1 = [[CLLocation alloc] initWithLatitude:lastPoint.getLatitude longitude:lastPoint.getLongitude];
            CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:centerLatLon.latitude longitude:centerLatLon.longitude];
            bearing = [loc1 bearingTo:loc2];
        }
        [_delegate onMeasure:distance bearing:bearing];
    }
}

- (void) onMapFrameRendered
{
    if (self.isVisible)
    {
        [self updateLastPointToCenter];
        [self updateDistAndBearing];
    }
}

- (void) buildLine:(OsmAnd::VectorLineBuilder &)builder collection:(std::shared_ptr<OsmAnd::VectorLinesCollection> &)collection linePoints:(const QVector<OsmAnd::PointI> &)linePoints
{
    builder.setPoints(linePoints);
    const auto line = builder.buildAndAddToCollection(collection);
}

- (void) drawLines:(const QVector<OsmAnd::PointI> &)points collection:(std::shared_ptr<OsmAnd::VectorLinesCollection>&)collection lineId:(int)lineId
{
    const auto& line = [self getLine:lineId collection:collection];
    if (points.size() < 2)
    {
        if (line)
            collection->removeLine(line);
        
        return;
    }

    double mapDensity = [[OAAppSettings sharedManager].mapDensity get];
    OsmAnd::ColorARGB lineColor = _editingCtx.getLineColor;
    std::vector<double> linePattern;
    linePattern.push_back(70 / mapDensity);
    linePattern.push_back(55 / mapDensity);
    if (line)
    {
        line->setFillColor(lineColor);
        line->setPoints(points);
    }
    else
    {
        OsmAnd::VectorLineBuilder builder;
        builder.setBaseOrder(self.baseOrder)
        .setIsHidden(false)
        .setLineId(lineId)
        .setLineWidth(kDefaultLineWidth)
        .setLineDash(linePattern)
        .setFillColor(lineColor);
        
        [self buildLine:builder collection:collection linePoints:points];
    }
}

- (const std::shared_ptr<OsmAnd::VectorLine>) getLine:(int)lineId collection:(std::shared_ptr<OsmAnd::VectorLinesCollection> &)collection
{
    const auto& lines = collection->getLines();
    for (auto it = lines.begin(); it != lines.end(); ++it)
    {
        if ((*it)->lineId == lineId)
            return *it;
    }
    return nullptr;
}

- (std::shared_ptr<OsmAnd::MapMarker>) drawMarker:(const OsmAnd::PointI &)position collection:(std::shared_ptr<OsmAnd::MapMarkersCollection> &)collection bitmap:(sk_sp<SkImage>&)bitmap
{
    if (collection->getMarkers().isEmpty())
    {
        OsmAnd::MapMarkerBuilder pointMarkerBuilder;
        pointMarkerBuilder.setIsAccuracyCircleSupported(false);
        pointMarkerBuilder.setBaseOrder(self.pointsOrder - 15);
        pointMarkerBuilder.setIsHidden(false);
        pointMarkerBuilder.setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal);
        pointMarkerBuilder.setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical);
        pointMarkerBuilder.setPinIcon(OsmAnd::SingleSkImage(bitmap));
        pointMarkerBuilder.setMarkerId(collection->getMarkers().count());
        
        auto marker = pointMarkerBuilder.buildAndAddToCollection(collection);
        marker->setPosition(position);
        return marker;
    }
    else
    {
        auto marker = collection->getMarkers().first();
        marker->setPosition(position);
        return marker;
    }
}

- (std::shared_ptr<OsmAnd::MapMarker>) drawMarker:(const OsmAnd::PointI &)position collection:(std::shared_ptr<OsmAnd::MapMarkersCollection> &)collection
{
    return [self drawMarker:position collection:collection bitmap:_pointMarkerIcon];
}

- (void) updateLastPointToCenter
{
    [self drawBeforeAfterPath];
}

- (void) resetLayer
{
    [self.mapView removeKeyedSymbolsProvider:_collection];
    [self.mapView removeKeyedSymbolsProvider:_lastLineCollection];
    [self.mapView removeKeyedSymbolsProvider:_pointMarkers];
    [self.mapView removeKeyedSymbolsProvider:_selectedMarkerCollection];
    
    _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _lastLineCollection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _pointMarkers = std::make_shared<OsmAnd::MapMarkersCollection>();
    _selectedMarkerCollection = std::make_shared<OsmAnd::MapMarkersCollection>();
    
    _cachedCenter = OsmAnd::PointI(0, 0);
}

- (BOOL) updateLayer
{
    if (![super updateLayer])
        return NO;

    if (self.isVisible)
    {
        [self.mapView addKeyedSymbolsProvider:_collection];
        [self.mapView addKeyedSymbolsProvider:_lastLineCollection];
        [self.mapView addKeyedSymbolsProvider:_pointMarkers];
        [self.mapView addKeyedSymbolsProvider:_selectedMarkerCollection];
    }
    _cachedCenter = OsmAnd::PointI(0, 0);
    
    const auto points = [self calculatePointsToDraw];
    [self drawRouteSegment:points];
    return YES;
}

- (void) enterMovingPointMode
{
    _isInMovingMode = YES;
    [self moveMapToPoint:_editingCtx.selectedPointPosition];
    OASWptPt *pt = [_editingCtx removePoint:_editingCtx.selectedPointPosition updateSnapToRoad:NO];
    _editingCtx.originalPointToMove = pt;
    [_editingCtx splitSegments:_editingCtx.selectedPointPosition];
    [self updateLayer];
}

- (void) exitMovingMode
{
    _isInMovingMode = NO;
}

- (OASWptPt *) getMovedPointToApply
{
    const auto latLon = OsmAnd::Utilities::convert31ToLatLon(self.mapViewController.mapView.target31);
    
    OASWptPt *point = [[OASWptPt alloc] initWithWptPt:_editingCtx.originalPointToMove];
    point.lat = latLon.latitude;
    point.lon = latLon.longitude;
    [point doCopyExtensionsE:_editingCtx.originalPointToMove];
    return point;
}

- (OASWptPt *) addPoint:(BOOL)addPointBefore
{
    if (_pressPointLocation)
    {
        OASWptPt *pt = [[OASWptPt alloc] init];
        pt.lat = _pressPointLocation.coordinate.latitude;
        pt.lon = _pressPointLocation.coordinate.longitude;

        _pressPointLocation = nil;
        BOOL allowed = _editingCtx.getPointsCount == 0 || ![_editingCtx.getAllPoints containsObject:pt];
        if (allowed)
        {
            [_editingCtx addPoint:pt mode:addPointBefore ? EOAAddPointModeBefore : EOAAddPointModeAfter];
            return pt;
        }
    }
    return nil;
}

- (OASWptPt *) addCenterPoint:(BOOL)addPointBefore
{
    const auto center = self.mapViewController.mapView.target31;
    const auto latLon = OsmAnd::Utilities::convert31ToLatLon(center);
    
    OASWptPt *pt = [[OASWptPt alloc] init];
    pt.lat = latLon.latitude;
    pt.lon = latLon.longitude;
    
    BOOL allowed = _editingCtx.getPointsCount == 0 || ![_editingCtx.getAllPoints containsObject:pt];
    if (allowed)
    {
        [_editingCtx addPoint:pt mode:addPointBefore ? EOAAddPointModeBefore : EOAAddPointModeAfter];
        return pt;
    }
    return nil;
}

- (double) getPointsDensity
{
    if (_editingCtx.getPointsCount < 2)
        return 0;
    NSArray<OASWptPt *> *points = [_editingCtx.getBeforePoints arrayByAddingObjectsFromArray:_editingCtx.getAfterPoints];
    
    NSMutableArray<NSNumber *> *distances = [NSMutableArray array];
    OASWptPt *prev = nil;
    for (OASWptPt *wptPt in points)
    {
        if (prev != nil)
        {
            double dist = getDistance(wptPt.lat, wptPt.lon, prev.lat, prev.lon);
            [distances addObject:@(dist)];
        }
        prev = wptPt;
    }
    
    [distances sortUsingComparator:^NSComparisonResult(NSNumber *obj1, NSNumber *obj2) {
        return [obj1 compare:obj2];
    }];
    
    return [self getPercentile:distances percentile:MIN_POINTS_PERCENTILE];
}

- (double) getPercentile:(NSArray<NSNumber *> *)sortedValues percentile:(int)percentile
{
    if (percentile < 0 || percentile > 100)
    {
        @throw [NSException exceptionWithName:@"Invalid percentile" reason:[NSString stringWithFormat:@"invalid percentile %d should be 0-100", percentile] userInfo:nil];
    }
    int index = (int) (sortedValues.count - 1) * percentile / 100;
    return sortedValues[index].doubleValue;
}

- (void) drawPointMarkers:(const QVector<OsmAnd::PointI> &)points collection:(std::shared_ptr<OsmAnd::MapMarkersCollection> &)collection
{
    collection->removeAllMarkers();
    OsmAnd::MapMarkerBuilder pointMarkerBuilder;
    pointMarkerBuilder.setIsAccuracyCircleSupported(false);
    pointMarkerBuilder.setBaseOrder(self.pointsOrder - 15);
    pointMarkerBuilder.setIsHidden(false);
    pointMarkerBuilder.setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal);
    pointMarkerBuilder.setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical);
    pointMarkerBuilder.setPinIcon(OsmAnd::SingleSkImage(_pointMarkerIcon));
    
    if (_editingCtx.getPointsCount > 500)
    {
        double density = [self getPointsDensity];
        if (density < 100)
        {
            double distThreshold = MAX(1000, _editingCtx.getRouteDistance / 100);
            double currentDist = 0;
            OsmAnd::PointI prevPnt(-1, -1);
            for (const auto& p : points)
            {
                if (prevPnt.x > 0 && prevPnt.y > 0)
                    currentDist += OsmAnd::Utilities::distance(OsmAnd::Utilities::convert31ToLatLon(prevPnt), OsmAnd::Utilities::convert31ToLatLon(p));
                prevPnt = p;
                if (currentDist > distThreshold)
                {
                    auto marker = pointMarkerBuilder.buildAndAddToCollection(collection);
                    marker->setPosition(p);
                    currentDist = 0;
                }
            }
        }
    }
    else
    {
        for (const auto& p : points)
        {
            auto marker = pointMarkerBuilder.buildAndAddToCollection(collection);
            marker->setPosition(p);
        }
    }
}

- (QVector<OsmAnd::PointI>) calculatePointsToDraw
{
    QVector<OsmAnd::PointI> points;
    
    OASWptPt *lastBeforePoint = nil;
    NSMutableArray<OASWptPt *> *beforePoints = [NSMutableArray arrayWithArray:_editingCtx.getBeforePoints];
    if (beforePoints.count > 0)
        lastBeforePoint = beforePoints[beforePoints.count - 1];
    OASWptPt *firstAfterPoint = nil;
    NSMutableArray<OASWptPt *> *afterPoints = [NSMutableArray arrayWithArray:_editingCtx.getAfterPoints];
    if (afterPoints.count > 0)
        firstAfterPoint = afterPoints.firstObject;
    
    [beforePoints addObjectsFromArray:afterPoints];

    for (int i = 0; i < beforePoints.count; i++)
    {
        OASWptPt *pt = beforePoints[i];
        points.append(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.getLatitude, pt.getLongitude)));
    }
    
    return points;
}

- (void) drawBeforeAfterPath
{
    NSArray<OASTrkSegment *> *before = _editingCtx.getBeforeSegments;
    NSArray<OASTrkSegment *> *after = _editingCtx.getAfterSegments;

    OsmAnd::PointI center;
    auto centerPixel = self.mapViewController.mapView.getCenterPixel;
    [self.mapViewController.mapView convert:CGPointMake(centerPixel.x, centerPixel.y) toLocation:&center];
    if (center == _cachedCenter)
        return;

    _cachedCenter = center;
    QVector<OsmAnd::PointI> points;
    if (before.count > 0 || after.count > 0)
    {
        BOOL hasPointsBefore = NO;
        BOOL hasGapBefore = NO;
        if (before.count > 0)
        {
            OASTrkSegment *segment = before.lastObject;
            if (segment.points.count > 0)
            {
                hasPointsBefore = YES;
                OASWptPt *pt = segment.points.lastObject;
                if (!pt.isGap || (_editingCtx.isInAddPointMode && _editingCtx.addPointMode != EOAAddPointModeBefore))
                {
                    points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.getLatitude, pt.getLongitude)));
                }
                points.push_back(center);
            }
        }
        if (after.count > 0)
        {
            OASTrkSegment *segment = after.firstObject;
            if (segment.points.count > 0)
            {
                if (!hasPointsBefore)
                {
                    points.push_back(center);
                }
                if (!hasGapBefore || (_editingCtx.isInAddPointMode && _editingCtx.addPointMode != EOAAddPointModeBefore))
                {
                    OASWptPt *pt = segment.points.firstObject;
                    points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.getLatitude, pt.getLongitude)));
                }
            }
        }
        
        [self drawLines:points collection:_lastLineCollection lineId:10000];
        
        if (_isInMovingMode || _editingCtx.isInAddPointMode)
            [self drawMarker:center collection:_selectedMarkerCollection bitmap:_selectedMarkerIcon];
        else
            _selectedMarkerCollection->removeAllMarkers();
    }
    else
    {
        _lastLineCollection->removeAllLines();
    }
}

- (void) drawRouteSegments
{
    NSArray<OASTrkSegment *> *beforeSegs = _editingCtx.getBeforeTrkSegmentLine;
    NSArray<OASTrkSegment *> *afterSegs = _editingCtx.getAfterTrkSegmentLine;
    int lineId = 100;
    for (OASTrkSegment *seg in beforeSegs)
    {
        QVector<OsmAnd::PointI> beforePoints;
        for (OASWptPt *pt in seg.points)
        {
            beforePoints.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.getLatitude, pt.getLongitude)));
        }
        [self drawLines:beforePoints collection:_collection lineId:lineId++];
    }
    
    for (OASTrkSegment *seg in afterSegs)
    {
        QVector<OsmAnd::PointI> afterPoints;
        for (OASWptPt *pt in seg.points)
        {
            afterPoints.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.getLatitude, pt.getLongitude)));
        }
        [self drawLines:afterPoints collection:_collection lineId:lineId++];
    }
}

- (void) drawRouteSegment:(const QVector<OsmAnd::PointI> &)points {
    [self drawRouteSegments];
    [self drawPointMarkers:points collection:_pointMarkers];
}

- (BOOL) isVisible
{
    return _editingCtx != nil;
}

- (void) onMapPointSelected:(CLLocationCoordinate2D)coordinate longPress:(BOOL)longPress
{
    if (self.isVisible && self.delegate)
        [self.delegate onTouch:coordinate longPress:longPress];
}

- (void) moveMapToPoint:(NSInteger)pos
{
    if (_editingCtx.getPointsCount > 0)
    {
        if (pos >= _editingCtx.getPointsCount)
            pos = _editingCtx.getPointsCount - 1;
        else if (pos < 0)
            pos = 0;
        OASWptPt *pt = _editingCtx.getPoints[pos];
        auto point = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.getLatitude, pt.getLongitude));
        auto point31 = [OANativeUtilities convertFromPointI:point];
        [self.mapViewController goToPosition:point31 animated:YES];
    }
}

@end
