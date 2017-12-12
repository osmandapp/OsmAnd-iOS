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
#import "OARoutingHelper.h"
#import "OARouteCalculationResult.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/GeoInfoDocument.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/VectorLinesCollection.h>

@implementation OARouteLayer
{
    OARoutingHelper *_routingHelper;

    std::shared_ptr<OsmAnd::VectorLinesCollection> _collection;

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
    
    _initDone = YES;
    
    [self.mapViewController runWithRenderSync:^{
        [self.mapView addKeyedSymbolsProvider:_collection];
    }];
}

- (void) resetLayer
{
    _collection->removeAllLines();
}

- (void) refreshRoute
{
    if ([_routingHelper getFinalLocation] && [[_routingHelper getRoute] isCalculated])
    {
        OARouteCalculationResult *route = [_routingHelper getRoute];
        NSArray<CLLocation *> *locations = [route getImmutableAllLocations];
        int currentRoute = route.currentRoute;
        if (currentRoute < 0)
            currentRoute = 0;

        QVector<OsmAnd::PointI> points;
        CLLocation* lastProj = [_routingHelper getLastProjection];
        if (lastProj)
            points.push_back(
                OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(lastProj.coordinate.latitude, lastProj.coordinate.longitude)));

        for (int i = currentRoute; i < locations.count; i++)
        {
            CLLocation *p = locations[i];
            points.push_back(
                OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(p.coordinate.latitude, p.coordinate.longitude)));
        }
        
        [self.mapViewController runWithRenderSync:^{
            
            if (points.size() > 1)
            {
                const auto& lines = _collection->getLines();
                if (lines.empty())
                {
                    int baseOrder = self.baseOrder;
                    
                    OsmAnd::VectorLineBuilder builder;
                    builder.setBaseOrder(baseOrder--)
                    .setIsHidden(points.size() == 0)
                    .setLineId(1)
                    .setLineWidth(30)
                    .setPoints(points)
                    .setFillColor(OsmAnd::ColorARGB(0xCC, 0xAA, 0x00, 0x88));
                    
                    builder.buildAndAddToCollection(_collection);
                }
                else
                {
                    lines[0]->setPoints(points);
                }
            }
            else
            {
                [self resetLayer];
            }
        }];
    }
    else
    {
        [self resetLayer];
    }
}

@end
