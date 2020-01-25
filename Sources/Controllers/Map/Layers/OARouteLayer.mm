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

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/GeoInfoDocument.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/VectorLinesCollection.h>
#include <OsmAndCore/Map/MapMarker.h>
#include <OsmAndCore/Map/MapMarkerBuilder.h>
#include <OsmAndCore/Map/MapMarkersCollection.h>

@implementation OARouteLayer
{
    OARoutingHelper *_routingHelper;

    std::shared_ptr<OsmAnd::VectorLinesCollection> _collection;
    
    std::shared_ptr<OsmAnd::MapMarkersCollection> _currentGraphXAxisPositions;
    
    std::shared_ptr<OsmAnd::MapMarkersCollection> _currentGraphPosition;
    std::shared_ptr<OsmAnd::MapMarker> _locationMarker;
    OsmAnd::MapMarker::OnSurfaceIconKey _locationIconKey;
    
    std::shared_ptr<SkBitmap> _xAxisLocationIcon;

    BOOL _initDone;
}

- (NSString *) layerId
{
    return kRouteLayerId;
}

- (void) initLayer
{
    _routingHelper = [OARoutingHelper sharedInstance];
    
    _collection = std::make_shared<OsmAnd::VectorLinesCollection>();
    _currentGraphPosition = std::make_shared<OsmAnd::MapMarkersCollection>();
    _currentGraphXAxisPositions = std::make_shared<OsmAnd::MapMarkersCollection>();
    
    _xAxisLocationIcon = [OANativeUtilities skBitmapFromPngResource:@"map_mapillary_location"];
    
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
}

- (void) resetLayer
{
    _collection->removeAllLines();
    _locationMarker->setIsHidden(true);
    _currentGraphXAxisPositions->removeAllMarkers();
}

- (BOOL) updateLayer
{
    [self refreshRoute];
    return YES;
}

- (void) refreshRoute
{
    OARouteCalculationResult *route = [_routingHelper getRoute];
    if ([_routingHelper getFinalLocation] && route && [route isCalculated])
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
            [self.mapViewController runWithRenderSync:^{
                const auto& lines = _collection->getLines();
                if (lines.empty())
                {
                    int baseOrder = self.baseOrder;
                    BOOL isNight = [OAAppSettings sharedManager].nightMode;
                    
                    NSDictionary<NSString *, NSNumber *> *result = [self.mapViewController getLineRenderingAttributes:@"route"];
                    NSNumber *val = [result valueForKey:@"color"];
                    OsmAnd::ColorARGB lineColor = (val && val.intValue != -1) ? OsmAnd::ColorARGB(val.intValue) : isNight ?
                    OsmAnd::ColorARGB(0xff, 0xff, 0xdf, 0x3d) : OsmAnd::ColorARGB(0x88, 0x2a, 0x4b, 0xd1);
                    
                    OsmAnd::VectorLineBuilder builder;
                    builder.setBaseOrder(baseOrder--)
                    .setIsHidden(points.size() == 0)
                    .setLineId(1)
                    .setLineWidth(30)
                    .setPoints(points);
                    
                    builder.setFillColor(lineColor)
                    .setPathIcon([OANativeUtilities skBitmapFromMmPngResource:@"arrow_triangle_black_nobg"])
                    .setPathIconStep(40);
                    
                    builder.buildAndAddToCollection(_collection);
                }
                else
                {
                    lines[0]->setPoints(points);
                }
            }];
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
        _currentGraphXAxisPositions->removeAllMarkers();
        for (CLLocation *location in trackPoints.xAxisPoints)
        {
            xAxisMarkerBuilder.addOnMapSurfaceIcon(_locationIconKey,
                                                   _xAxisLocationIcon);
            
            const auto& marker = xAxisMarkerBuilder.buildAndAddToCollection(_currentGraphXAxisPositions);
            marker->setPosition(OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(location.coordinate.latitude, location.coordinate.longitude)));
        }
        trackPoints.axisPointsInvalidated = NO;
    }
}

- (void) hideCurrentStatisticsLocation
{
    if (_locationMarker)
        _locationMarker->setIsHidden(true);
    
    _currentGraphXAxisPositions->removeAllMarkers();
}

@end
