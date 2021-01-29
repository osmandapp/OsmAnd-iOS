//
//  OADownloadedRegionsLayer.m
//  OsmAnd
//
//  Created by Alexey on 24.01.2021.
//  Copyright © 2021 OsmAnd. All rights reserved.
//

#import "OADownloadedRegionsLayer.h"
#import "OARootViewController.h"
#import "OAMapViewController.h"
#import "OAMapRendererView.h"
#import "OAUtilities.h"
#import "OANativeUtilities.h"
#import "OAColors.h"
#import "OAPointIContainer.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/Map/Polygon.h>
#include <OsmAndCore/Map/PolygonBuilder.h>
#include <OsmAndCore/Map/PolygonsCollection.h>
#include <OsmAndCore/WorldRegions.h>

@implementation OADownloadedRegionsLayer
{
    std::shared_ptr<OsmAnd::PolygonsCollection> _collection;
    
    BOOL _initDone;
}

- (NSString *) layerId
{
    return kDownloadedRegionsLayerId;
}

- (void) initLayer
{
    _collection = std::make_shared<OsmAnd::PolygonsCollection>();
    _initDone = YES;
    
    [self.mapView addKeyedSymbolsProvider:_collection];
}

- (void) resetLayer
{
    [self.mapView removeKeyedSymbolsProvider:_collection];
    _collection = std::make_shared<OsmAnd::PolygonsCollection>();
}

- (BOOL) updateLayer
{
    [super updateLayer];

    [self refreshRoute];
    return YES;
}

- (void) refreshRoute
{
    NSMutableArray<OAWorldRegion *> *mapRegions = [NSMutableArray array];
    const auto& localResources = self.app.resourcesManager->getLocalResources();
    if (!localResources.isEmpty())
    {
        NSArray<OAWorldRegion *> *regions = self.app.worldRegion.flattenedSubregions;
        for (OAWorldRegion *region in regions)
        {
            for (const auto& resource : localResources)
            {
                if (resource->origin == OsmAnd::ResourcesManager::ResourceOrigin::Installed)
                {
                    if ([region.resourceTypes containsObject:@((int)OsmAnd::ResourcesManager::ResourceType::MapRegion)]
                        && [resource->id.toNSString() hasPrefix:region.downloadsIdPrefix])
                    {
                        [mapRegions addObject:region];
                        break;
                    }
                }
            }
        }
    }
    if (mapRegions.count > 0)
    {
        [self.mapViewController runWithRenderSync:^{
            [self.mapView removeKeyedSymbolsProvider:_collection];
            _collection = std::make_shared<OsmAnd::PolygonsCollection>(OsmAnd::ZoomLevel3, OsmAnd::ZoomLevel7);
            BOOL hasPoints = NO;
            for (OAWorldRegion *r in mapRegions)
            {
                OAPointIContainer *pc = [[OAPointIContainer alloc] init];
                [r getPoints31:pc];
                if (!pc.qPoints.isEmpty())
                {
                    [self drawRegion:pc.qPoints];
                    hasPoints = YES;
                }
            }
            if (hasPoints)
                [self.mapView addKeyedSymbolsProvider:_collection];
        }];
    }
    else
    {
        [self.mapViewController runWithRenderSync:^{
            [self resetLayer];
        }];
    }
}

- (void) drawRegion:(const QVector<OsmAnd::PointI> &)points
{
    int baseOrder = self.baseOrder;
    
    OsmAnd::ColorARGB regionColor = OsmAnd::ColorARGB(color_region_uptodate_argb);
    
    OsmAnd::PolygonBuilder builder;
    builder.setBaseOrder(baseOrder--)
    .setIsHidden(points.size() == 0)
    .setPolygonId(1)
    .setPoints(points)
    .setFillColor(regionColor);
    
    builder.buildAndAddToCollection(_collection);
}
@end
