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
    
    [self.mapView addKeyedSymbolsProvider:_collection];
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
        
        if (points.size() > 1)
        {
            const auto& lines = _collection->getLines();
            if (lines.empty())
            {
                int baseOrder = self.baseOrder;                
                BOOL isNight = [OAAppSettings sharedManager].nightMode;
                
                NSDictionary<NSString *, NSNumber *> __block *result;
                dispatch_block_t onMain = ^{
                    result = [[OARootViewController instance].mapPanel.mapViewController getLineRenderingAttributes:@"route"];
                };
                if ([NSThread isMainThread])
                    onMain();
                else
                    dispatch_sync(dispatch_get_main_queue(), onMain);
                
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
        }
        else
        {
            [self resetLayer];
        }
    }
    else
    {
        [self resetLayer];
    }
}

@end
