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

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>
#include <OsmAndCore/CachingRoadLocator.h>

#define kMaxRoadDistanceInMeters 15.0

@implementation OACurrentPositionHelper
{
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    
    CLLocation *_lastQueriedLocation;
    std::shared_ptr<const OsmAnd::Road> _road;
    std::shared_ptr<OsmAnd::CachingRoadLocator> _roadLocator;
    NSObject *_roadLocatorSync;
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
    auto r = _road;
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
@end
