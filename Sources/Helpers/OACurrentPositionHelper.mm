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
#import "OARoutingHelper.h"
#import "OARouteProvider.h"
#import "OARouteCalculationParams.h"

#include <OsmAndCore.h>
#include <OsmAndCore/Utilities.h>

#include <routePlannerFrontEnd.h>
#include <routingConfiguration.h>
#include <routingContext.h>
#include <binaryRoutePlanner.h>
#include <routeSegment.h>

@implementation OARoadResultMatcher

- (BOOL) publish:(const std::shared_ptr<RouteDataObject>)object
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
    OARoutingHelper *_routingHelper;
    OARouteProvider *_provider;
    OAAppSettings *_settings;
    
    CLLocation *_lastQueriedLocation;
    OAApplicationMode *_am;
    std::shared_ptr<RoutingContext> _ctx;
    std::shared_ptr<RouteDataObject> _road;
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
        _routingHelper = [OARoutingHelper sharedInstance];
        _provider = [OARoutingHelper sharedInstance].getRouteProvider;
        _settings = [OAAppSettings sharedManager];
        
        _roadLocatorSync = [[NSObject alloc] init];
        _road.reset();
        
        _app.resourcesManager->localResourcesChangeObservable.attach(reinterpret_cast<OsmAnd::IObservable::Tag>((__bridge const void*)self),
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

- (void) initCtx:(OAApplicationMode *)appMode
{
    _am = appMode;
    _ctx = nullptr;

    OARouteCalculationParams *params = [[OARouteCalculationParams alloc] init];
    params.mode = appMode;
    
    auto config = [_app getRoutingConfigForMode:params.mode];
    auto generalRouter = [_app getRouter:config mode:params.mode];
    if (generalRouter)
    {
        auto cf = [_provider initOsmAndRoutingConfig:config params:params generalRouter:generalRouter];
        if (cf)
        {
            auto router = std::make_shared<RoutePlannerFrontEnd>();
            _ctx = router->buildRoutingContext(cf, RouteCalculationMode::NORMAL);
            _ctx->geocoding = true;
        }
    }
}

+ (double) getOrthogonalDistance:(std::shared_ptr<RouteDataObject>) r loc:(CLLocation *)loc
{
    double d = 1000.0;
    if (r->pointsX.size() > 0)
    {
        double pLt = OsmAnd::Utilities::get31LatitudeY(r->pointsY[0]);
        double pLn = OsmAnd::Utilities::get31LongitudeX(r->pointsX[0]);
        for (int i = 1; i < r->pointsX.size(); i++)
        {
            double lt = OsmAnd::Utilities::get31LatitudeY(r->pointsY[i]);
            double ln = OsmAnd::Utilities::get31LongitudeX(r->pointsX[i]);
            double od = [OAMapUtils getOrthogonalDistance:loc fromLocation:[[CLLocation alloc] initWithLatitude:pLt longitude:pLn] toLocation:[[CLLocation alloc] initWithLatitude:lt longitude:ln]];
            if (od < d)
                d = od;
            
            pLt = lt;
            pLn = ln;
        }
    }
    return d;
}

- (void) checkInitialized:(CLLocation *)loc
{
    auto loc31 = OsmAnd::Utilities::convertLatLonTo31(OsmAnd::LatLon(loc.coordinate.latitude, loc.coordinate.longitude));
    auto rect31 = OsmAnd::Utilities::boundingBox31FromAreaInMeters(15.0, loc31);
    [_provider checkInitialized:15 leftX:rect31.left() rightX:rect31.right() bottomY:rect31.bottom() topY:rect31.top()];
}

- (std::shared_ptr<RouteDataObject>) getLastKnownRouteSegment:(CLLocation *)loc
{
    CLLocation *last = _lastQueriedLocation;
    std::shared_ptr<RouteDataObject> r;
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
            OAApplicationMode *appMode = _settings.applicationMode.get;
            if (!_ctx || _am != appMode)
            {
                [self initCtx:appMode];
            }
            if (_ctx)
            {
                [self checkInitialized:loc];
                auto segment = findRouteSegment(position31.x, position31.y, _ctx.get());
                _road = segment ? segment->road : nullptr;
            }
        }
    });
}

- (void) onLocalResourcesChanged
{
    @synchronized(_roadLocatorSync)
    {
        _road.reset();
    }
}

- (void) getRouteSegment:(CLLocation *)loc appMode:(OAApplicationMode *)appMode matcher:(OARoadResultMatcher *)matcher
{
    const OsmAnd::PointI position31(OsmAnd::Utilities::get31TileNumberX(loc.coordinate.longitude),
                                    OsmAnd::Utilities::get31TileNumberY(loc.coordinate.latitude));
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @synchronized(_roadLocatorSync)
        {
            OAApplicationMode *am = appMode ? appMode : _routingHelper.getAppMode;
            if (!_ctx || _am != am)
            {
                [self initCtx:appMode];
            }
            if (_ctx)
            {
                [self checkInitialized:loc];
                auto segment = findRouteSegment(position31.x, position31.y, _ctx.get());
                auto road = segment ? segment->road : nullptr;
                if (matcher && ![matcher isCancelled])
                    [matcher publish:road];
            }
        }
    });
}

@end
