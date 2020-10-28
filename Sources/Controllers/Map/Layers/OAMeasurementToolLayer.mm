//
//  OAMeasurementToolLayer.m
//  OsmAnd
//
//  Created by Paul on 22.10.2020.
//  Copyright © 2020 OsmAnd. All rights reserved.
//

#import "OAMeasurementToolLayer.h"
#import "OAMapLayersConfiguration.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OARoutingHelper.h"
#import "OARouteCalculationResult.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OAColors.h"
#import "OAAutoObserverProxy.h"

#import "OAGPXDocument.h"
#import "OAGPXDocumentPrimitives.h"
#import "OAMeasurementEditingContext.h"

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


@implementation OAMeasurementToolLayer
{
    OARoutingHelper *_routingHelper;

    std::shared_ptr<OsmAnd::VectorLinesCollection> _collection;
    std::shared_ptr<OsmAnd::VectorLinesCollection> _lastLineCollection;
    
    std::shared_ptr<OsmAnd::MapMarkersCollection> _pointMarkers;
    
    std::shared_ptr<SkBitmap> _pointMarkerIcon;

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
    
    _pointMarkerIcon = [OANativeUtilities skBitmapFromPngResource:@"map_plan_route_point_normal"];
    
    _initDone = YES;
    
    [self.mapView addKeyedSymbolsProvider:_collection];
    [self.mapView addKeyedSymbolsProvider:_lastLineCollection];
    [self.mapView addKeyedSymbolsProvider:_pointMarkers];
}

- (void)updateDistAndBearing
{
    if (_delegate)
    {
        double distance = 0, bearing = 0;
        if (_editingCtx.getPointsCount > 0)
        {
            OAGpxTrkPt *lastPoint = _editingCtx.getPoints[_editingCtx.getPointsCount - 1];
            OsmAnd::LatLon centerLatLon = OsmAnd::Utilities::convert31ToLatLon(self.mapView.target31);
            distance = getDistance(lastPoint.getLatitude, lastPoint.getLongitude, centerLatLon.latitude, centerLatLon.longitude);
            CLLocation *loc1 = [[CLLocation alloc] initWithLatitude:lastPoint.getLatitude longitude:lastPoint.getLongitude];
            CLLocation *loc2 = [[CLLocation alloc] initWithLatitude:centerLatLon.latitude longitude:centerLatLon.longitude];
            bearing = [loc1 bearingTo:loc2];
        }
        [_delegate onMeasue:distance bearing:bearing];
    }
}

- (void)onMapFrameRendered
{
    [self updateLastPointToCenter];
    [self updateDistAndBearing];
}

- (void)drawLines:(const QVector<OsmAnd::PointI> &)points collection:(std::shared_ptr<OsmAnd::VectorLinesCollection>&)collection
{
    OsmAnd::ColorARGB lineColor = OsmAnd::ColorARGB(0xff, 0xff, 0x88, 0x00);
    
    OsmAnd::VectorLineBuilder builder;
    builder.setBaseOrder(self.baseOrder)
    .setIsHidden(points.size() == 0)
    .setLineId(1)
    .setLineWidth(30)
    .setPoints(points);
    
    builder.setFillColor(lineColor);
    
    builder.buildAndAddToCollection(collection);
}

- (void) updateLastPointToCenter
{
    OAGpxTrkPt *lastBeforePoint = nil;
    if (_editingCtx.getBeforePoints.count > 0)
        lastBeforePoint = _editingCtx.getBeforePoints.lastObject;
    if (lastBeforePoint)
    {
        const auto center = self.mapViewController.mapView.target31;
        const auto lastBeforePnt = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lastBeforePoint.getLatitude, lastBeforePoint.getLongitude));
        [self.mapViewController runWithRenderSync:^{
            QVector<OsmAnd::PointI> points;
            points.push_back(lastBeforePnt);
            points.push_back(center);
            if (_lastLineCollection->getLines().size() != 0)
            {
                const auto lastLine = _lastLineCollection->getLines().last();
                lastLine->setPoints(points);
            }
            else
            {
                [self drawLines:points collection:_lastLineCollection];
            }
        }];
    }
    
}

- (void) resetLayer
{
    _collection->removeAllLines();
    _lastLineCollection->removeAllLines();
    _pointMarkers->removeAllMarkers();
}

- (BOOL) updateLayer
{
    [self resetLayer];
    const auto points = [self calculatePointsToDraw];
    [self drawRouteSegment:points addToExsisting:YES];
    [self addPointMarkers:points];
    return YES;
}

//- (OAGpxTrkPt *) addPoint
//{
//    if (pressedPointLatLon != null) {
//        WptPt pt = new WptPt();
//        double lat = pressedPointLatLon.getLatitude();
//        double lon = pressedPointLatLon.getLongitude();
//        pt.lat = lat;
//        pt.lon = lon;
//        pressedPointLatLon = null;
//        boolean allowed = editingCtx.getPointsCount() == 0 || !editingCtx.getPoints().get(editingCtx.getPointsCount() - 1).equals(pt);
//        if (allowed) {
//            ApplicationMode applicationMode = editingCtx.getAppMode();
//            if (applicationMode != MeasurementEditingContext.DEFAULT_APP_MODE) {
//                pt.setProfileType(applicationMode.getStringKey());
//            }
//            editingCtx.addPoint(pt);
//            moveMapToLatLon(lat, lon);
//            return pt;
//        }
//    }
//    return null;
//}

- (OAGpxTrkPt *) addCenterPoint
{
    const auto center = self.mapViewController.mapView.target31;
    const auto latLon = OsmAnd::Utilities::convert31ToLatLon(center);
    
    OAGpxTrkPt *pt = [[OAGpxTrkPt alloc] init];
    [pt setPosition:CLLocationCoordinate2DMake(latLon.latitude, latLon.longitude)];
    BOOL allowed = _editingCtx.getPointsCount == 0 || ![_editingCtx.getPoints[_editingCtx.getPointsCount - 1] isEqual:pt];
    if (allowed) {
        // TODO: add routing profile later
//        OAApplicationMode *applicationMode = _editingCtx.appMode;
//        if (applicationMode != OAApplicationMode.DEFAULT)
//            [pt setProfileType:applicationMode.stringKey];
        [_editingCtx addPoint:pt];
        [self updateLayer];
        return pt;
    }
    return nil;
}

- (void)addPointMarkers:(const QVector<OsmAnd::PointI>&)points
{
    OsmAnd::MapMarkerBuilder pointMarkerBuilder;
    for (const auto& point : points)
    {
        pointMarkerBuilder.setIsAccuracyCircleSupported(false);
        pointMarkerBuilder.setBaseOrder(self.baseOrder - 15);
        pointMarkerBuilder.setIsHidden(false);
        pointMarkerBuilder.setPinIconHorisontalAlignment(OsmAnd::MapMarker::CenterHorizontal);
        pointMarkerBuilder.setPinIconVerticalAlignment(OsmAnd::MapMarker::CenterVertical);
        pointMarkerBuilder.setPinIcon(_pointMarkerIcon);
        
        auto marker = pointMarkerBuilder.buildAndAddToCollection(_pointMarkers);
        marker->setPosition(point);
    }
}

- (QVector<OsmAnd::PointI>) calculatePointsToDraw
{
    QVector<OsmAnd::PointI> points;
    
    OAGpxRtePt *lastBeforePoint = nil;
    NSMutableArray<OAGpxRtePt *> *beforePoints = [NSMutableArray arrayWithArray:_editingCtx.getBeforePoints];
    if (beforePoints.count > 0)
        lastBeforePoint = beforePoints[beforePoints.count - 1];
    OAGpxRtePt *firstAfterPoint = nil;
    NSMutableArray<OAGpxRtePt *> *afterPoints = [NSMutableArray arrayWithArray:_editingCtx.getAfterPoints];
    if (afterPoints.count > 0)
        firstAfterPoint = afterPoints.firstObject;
    
    [beforePoints addObjectsFromArray:afterPoints];

    for (int i = 0; i < beforePoints.count; i++)
    {
        OAGpxRtePt *pt = beforePoints[i];
        points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.getLatitude, pt.getLongitude)));
    }
    
    return points;
}

- (void) drawBeforeAfterPath:(QVector<OsmAnd::PointI> &)points
{
    OATrackSegment *before = _editingCtx.getBeforeTrkSegmentLine;
    OATrackSegment *after = _editingCtx.getAfterTrkSegmentLine;
    if (before.points.count > 0 || after.points.count > 0)
    {
        if (before.points.count > 0)
        {
            OAGpxTrkPt *pt = before.points[before.points.count - 1];
            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.getLatitude, pt.getLongitude)));
        }
        if (after.points.count > 0)
        {
            if (before.points.count == 0)
            {
                points.push_back(self.mapViewController.mapView.target31);
            }
            OAGpxTrkPt *pt = after.points[0];
            points.push_back(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(pt.getLatitude, pt.getLongitude)));
        }
        
        [self drawRouteSegment:points addToExsisting:YES];
    }
}

- (void) drawRouteSegment:(const QVector<OsmAnd::PointI> &)points addToExsisting:(BOOL)addToExsisting {
    [self.mapViewController runWithRenderSync:^{
        const auto& lines = _collection->getLines();
        if (lines.empty() || addToExsisting)
        {
            [self drawLines:points collection:_collection];
        }
        else
        {
            lines[0]->setPoints(points);
        }
    }];
}

@end
