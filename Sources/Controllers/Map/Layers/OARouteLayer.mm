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

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/GeoInfoDocument.h>
#include <OsmAndCore/Map/VectorLine.h>
#include <OsmAndCore/Map/VectorLineBuilder.h>
#include <OsmAndCore/Map/VectorLinesCollection.h>

@implementation OARouteLayer
{
    std::shared_ptr<OsmAnd::VectorLinesCollection> _collection;

    BOOL _initDone;
}

- (NSString *) layerId
{
    return kRouteLayerId;
}

- (void) initLayer
{
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

- (void) refreshRoute:(std::shared_ptr<const OsmAnd::GeoInfoDocument>)routeDoc
{
    QVector<OsmAnd::PointI> points;
    
    QList<OsmAnd::Ref<OsmAnd::GeoInfoDocument::LocationMark>> docPoints;
    if (routeDoc->hasTrkPt())
        docPoints = routeDoc->tracks[0]->segments[0]->points;
    else if (routeDoc->hasRtePt())
        docPoints = routeDoc->routes[0]->points;

    for (auto& p : docPoints)
        points.push_back(OsmAnd::Utilities::convertLatLonTo31(p->position));
    
    [self.mapViewController runWithRenderSync:^{

        _collection->removeAllLines();

        if (points.size() > 0)
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
    }];
}

@end
