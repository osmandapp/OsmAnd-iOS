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
#import "OAUtilities.h"
#import "OANativeUtilities.h"

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

- (BOOL) updateLayer
{
    [self refreshRoute];
    return YES;
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
                    
                    /*
                     <renderingAttribute name="route">
                         <!-- fluorescent: filter attrColorValue="#CCFF6600"/ -->
                         <!-- was badly visible on motorways: filter nightMode="false" attrColorValue="#960000FF"/ -->
                         <!-- color used for route line color -->
                         <!-- color_0 used for route line stroke color -->
                         <!-- color_2 used for route direction arrows -->
                         <!-- color_3 used for turn arrows on the route -->
                         <case color="#882a4bd1" strokeWidth="12:8" color_3="#ffde5b" color_2="#bfccff" strokeWidth_3="5:7">
                             <apply_if nightMode="true" color="#ffdf3d" color_2="#806f1f" color_3="#41a6d9" strokeWidth="9:8" color_0="#CCb29c2b" strokeWidth_0="12:8"/>
                         </case>
                     </renderingAttribute>
                     */
                    
                    BOOL isNight = [OAAppSettings sharedManager].nightMode;

                    OsmAnd::VectorLineBuilder builder;
                    builder.setBaseOrder(baseOrder--)
                    .setIsHidden(points.size() == 0)
                    .setLineId(1)
                    .setLineWidth(30)
                    .setPoints(points);
                    
                    if (!isNight)
                    {
                        builder.setFillColor(OsmAnd::ColorARGB(0x88, 0x2a, 0x4b, 0xd1))
                        .setPathIcon([OANativeUtilities skBitmapFromMmPngResource:@"arrow_triangle_black_nobg"])
                        .setPathIconStep(40);
                    }
                    else
                    {
                        builder.setFillColor(OsmAnd::ColorARGB(0xff, 0xff, 0xdf, 0x3d))
                        .setPathIcon([OANativeUtilities skBitmapFromMmPngResource:@"arrow_triangle_black_nobg"])
                        .setPathIconStep(40);
                    }

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
