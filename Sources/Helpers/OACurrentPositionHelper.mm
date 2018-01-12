//
//  OACurrentPositionHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 08/10/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OACurrentPositionHelper.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OAMapUtils.h"
#import "OAMapRendererView.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/CachingRoadLocator.h>

#define kMaxRoadDistanceInMeters 15.0

@implementation OARoadResultMatcher

- (BOOL) publish:(const std::shared_ptr<const OsmAnd::Road>&)object
{
    if (_publishFunction)
        return _publishFunction(object);
    
    return YES;
}

- (BOOL) isCancelled
{
    if (_cancelledFunction)
        return _cancelledFunction();
    
    return NO;
}

- (instancetype)initWithPublishFunc:(OARoadResultMatcherPublish)pFunction cancelledFunc:(OARoadResultMatcherIsCancelled)cFunction
{
    self = [super init];
    if (self) {
        _publishFunction = pFunction;
        _cancelledFunction = cFunction;
    }
    return self;
}

@end

@implementation OACurrentPositionHelper
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    CLLocation *_lastQueriedLocation;
    std::shared_ptr<const OsmAnd::Road> _road;
    std::shared_ptr<OsmAnd::CachingRoadLocator> _roadLocator;
    NSObject *_roadLocatorSync;
    NSTimeInterval _lastUpdateTime;
}

+ (OACurrentPositionHelper *) instance
{
    static dispatch_once_t once;
    static OACurrentPositionHelper * sharedInstance;
    dispatch_once(&once, ^{
        
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (instancetype) init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _settings = [OAAppSettings sharedManager];
        
        _roadLocator.reset(new OsmAnd::CachingRoadLocator(_app.resourcesManager->obfsCollection));
        _roadLocatorSync = [[NSObject alloc] init];
        _road.reset();
        
        _app.resourcesManager->localResourcesChangeObservable.attach((__bridge const void*)self,
                                                                     [self]
                                                                     (const OsmAnd::ResourcesManager* const resourcesManager,
                                                                      const QList< QString >& added,
                                                                      const QList< QString >& removed,
                                                                      const QList< QString >& updated)
                                                                     {
                                                                         [self onLocalResourcesChanged];
                                                                     });
        
    }
    return self;
}

+ (double) getOrthogonalDistance:(std::shared_ptr<const OsmAnd::Road>) r loc:(CLLocation *)loc
{
    double d = 1000.0;
    if (r->points31.count() > 0)
    {
        double pLt = OsmAnd::Utilities::get31LatitudeY(r->points31[0].y);
        double pLn = OsmAnd::Utilities::get31LongitudeX(r->points31[0].x);
        for (int i = 1; i < r->points31.count(); i++)
        {
            double lt = OsmAnd::Utilities::get31LatitudeY(r->points31[i].y);
            double ln = OsmAnd::Utilities::get31LongitudeX(r->points31[i].x);
            double od = [OAMapUtils getOrthogonalDistance:loc fromLocation:[[CLLocation alloc] initWithLatitude:pLt longitude:pLn] toLocation:[[CLLocation alloc] initWithLatitude:lt longitude:ln]];
            if (od < d)
                d = od;
            
            pLt = lt;
            pLn = ln;
        }
    }
    return d;
}

- (std::shared_ptr<const OsmAnd::Road>) getLastKnownRouteSegment:(CLLocation *)loc
{
    CLLocation *last = _lastQueriedLocation;
    std::shared_ptr<const OsmAnd::Road> r;
    @synchronized(_roadLocatorSync)
    {
        r = _road;
    }
    if (!loc || loc.horizontalAccuracy > 50)
        return nullptr;
    
    if (last && [last distanceFromLocation:loc] < 10)
        return r;
    
    if (!r)
    {
        [self scheduleRouteSegmentFind:loc];
        return nullptr;
    }
    
    double d = [self.class getOrthogonalDistance:r loc:loc];
    if (d > 15)
        [self scheduleRouteSegmentFind:loc];

    if (d < 70)
        return r;
    
    return nullptr;
}

- (void) scheduleRouteSegmentFind:(CLLocation *)loc
{
    const OsmAnd::PointI position31(OsmAnd::Utilities::get31TileNumberX(loc.coordinate.longitude),
                                    OsmAnd::Utilities::get31TileNumberY(loc.coordinate.latitude));
    
    _lastQueriedLocation = [loc copy];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized(_roadLocatorSync)
        {
            _road = _roadLocator->findNearestRoad(position31,
                                                  kMaxRoadDistanceInMeters,
                                                  OsmAnd::RoutingDataLevel::Detailed);
        }
    });
}

- (void) onLocalResourcesChanged
{
    @synchronized(_roadLocatorSync)
    {
        _road.reset();
        _roadLocator->clearCache();
    }
}

- (void) clearCacheNotInTiles:(OAMapRendererView *)mapRendererView
{
    NSTimeInterval currentTime = CACurrentMediaTime();
    if (currentTime - _lastUpdateTime > 1)
    {
        _lastUpdateTime = currentTime;

        const auto& tiles = mapRendererView.visibleTiles;
        
        QSet<OsmAnd::TileId> result;
        result.reserve(tiles.size());
        for (int i = 0; i < tiles.size(); ++i)
            result.insert(tiles.at(i));
        
        _roadLocator->clearCacheNotInTiles(result, mapRendererView.zoomLevel, true);
    }
}

- (void) getRouteSegment:(CLLocation *)loc matcher:(OARoadResultMatcher *)matcher
{
    const OsmAnd::PointI position31(OsmAnd::Utilities::get31TileNumberX(loc.coordinate.longitude),
                                    OsmAnd::Utilities::get31TileNumberY(loc.coordinate.latitude));
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized(_roadLocatorSync)
        {
            const auto road = _roadLocator->findNearestRoad(position31,
                                                            kMaxRoadDistanceInMeters,
                                                            OsmAnd::RoutingDataLevel::Detailed);
            
            if (matcher && ![matcher isCancelled])
                [matcher publish:road];
        }
    });
}

@end
