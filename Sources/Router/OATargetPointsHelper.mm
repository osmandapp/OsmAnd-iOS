//
//  OATargetPointsHelper.m
//  OsmAnd
//
//  Created by Alexey Kulish on 15/07/2017.
//  Copyright © 2017 OsmAnd. All rights reserved.
//

#import "OATargetPointsHelper.h"
#import "OAPointDescription.h"
#import "Localization.h"
#import "OsmAndApp.h"
#import "OAAppSettings.h"
#import "OARoutingHelper.h"
#import "OARTargetPoint.h"

@implementation OATargetPointsHelper
{
    NSMutableArray<OARTargetPoint *> *_intermediatePoints;
    OARTargetPoint *_pointToNavigate;
    OARTargetPoint *_pointToStart;
    OsmAndAppInstance _app;
    OAAppSettings *_settings;
    OARoutingHelper *_routingHelper;
    
    NSMutableArray<id<OAStateChangedListener>> *_listeners;
}

+ (OATargetPointsHelper *) sharedInstance
{
    static OATargetPointsHelper *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[OATargetPointsHelper alloc] init];
    });
    return _sharedInstance;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _app = [OsmAndApp instance];
        _intermediatePoints = [NSMutableArray array];
        _settings = [OAAppSettings sharedManager];
        _listeners = [NSMutableArray array];
        _routingHelper = [OARoutingHelper sharedInstance];
        [self readFromSettings];
    }
    return self;
}

- (void) readFromSettings
{
    _pointToNavigate = _app.data.pointToNavigate;
    _pointToStart = _app.data.pointToStart;
    _intermediatePoints = _app.data.intermediatePoints;
}

- (OARTargetPoint *) getPointToNavigate
{
    return _pointToNavigate;
}

- (OARTargetPoint *) getPointToStart
{
    return _pointToStart;
}

- (OAPointDescription *) getStartPointDescription
{
    return _app.data.pointToStart ? _app.data.pointToStart.pointDescription : nil;
}

- (NSArray<OARTargetPoint *> *) getIntermediatePoints
{
    return _intermediatePoints;
}

- (NSArray<OARTargetPoint *> *) getIntermediatePointsNavigation
{
    NSMutableArray<OARTargetPoint *> *intermediatePoints = [NSMutableArray array];
    if (_settings.useIntermediatePointsNavigation)
    {
        for (OARTargetPoint *t in _intermediatePoints)
            [intermediatePoints addObject:t];
    }
    return intermediatePoints;
}

- (NSArray<CLLocation *> *) getIntermediatePointsLatLon
{
    NSMutableArray<CLLocation *> *intermediatePointsLatLon = [NSMutableArray array];
    for (OARTargetPoint *t in _intermediatePoints)
        [intermediatePointsLatLon addObject:t.point];
    
    return intermediatePointsLatLon;
}

- (NSArray<CLLocation *> *) getIntermediatePointsLatLonNavigation
{
    NSMutableArray<CLLocation *> *intermediatePointsLatLon = [NSMutableArray array];
    if (_settings.useIntermediatePointsNavigation)
    {
        for (OARTargetPoint *t in _intermediatePoints)
            [intermediatePointsLatLon addObject:t.point];
    }
    return intermediatePointsLatLon;
}

- (NSArray<OARTargetPoint *> *) getAllPoints
{
    NSMutableArray<OARTargetPoint *> *res = [NSMutableArray array];
    if (_pointToStart)
        [res addObject:_pointToStart];
    
    [res addObjectsFromArray:_intermediatePoints];
    if (_pointToNavigate)
        [res addObject:_pointToNavigate];
    
    return res;
}

- (NSArray<OARTargetPoint *> *) getIntermediatePointsWithTarget
{
    NSMutableArray<OARTargetPoint *> *res = [NSMutableArray array];
    [res addObjectsFromArray:_intermediatePoints];
    if (_pointToNavigate)
        [res addObject:_pointToNavigate];
    
    return res;
}

- (OARTargetPoint *) getFirstIntermediatePoint
{
    if (_intermediatePoints.count > 0)
        return _intermediatePoints[0];
    
    return nil;
}

- (void) restoreTargetPoints:(BOOL)updateRoute
{
    [_app.data restoreTargetPoints];
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

- (void) addListener:(id<OAStateChangedListener>)l
{
    [_listeners addObject:l];
}


- (void) updateListeners
{
    for (id<OAStateChangedListener> l in _listeners)
        [l stateChanged:(nil)];
}

- (void) updateRouteAndRefresh:(BOOL)updateRoute
{
    if (updateRoute && ([_routingHelper isRouteBeingCalculated] || [_routingHelper isRouteCalculated] || [_routingHelper isFollowingMode] || [_routingHelper isRoutePlanningMode]))
    {
        [self updateRoutingHelper];
    }
    [self updateListeners];
}

- (void) updateRoutingHelper
{
    OARTargetPoint *start = _app.data.pointToStart;
    CLLocation *lastKnownLocation = _app.locationServices.lastKnownLocation;
    NSArray<CLLocation *> *is = [self getIntermediatePointsLatLonNavigation];
    if (([_routingHelper isFollowingMode] && lastKnownLocation) || !start)
    {
        [_routingHelper setFinalAndCurrentLocation:_app.data.pointToNavigate.point intermediatePoints:is currentLocation:lastKnownLocation];
    }
    else
    {
        CLLocation *loc = start.point;
        [_routingHelper setFinalAndCurrentLocation:_app.data.pointToNavigate.point intermediatePoints:is currentLocation:loc];
    }
}


- (void) clearPointToNavigate:(BOOL)updateRoute
{
    _app.data.pointToNavigate = nil;
    [_app.data.intermediatePoints removeAllObjects];
    [_intermediatePoints removeAllObjects];
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

- (void) clearStartPoint:(BOOL)updateRoute
{
    _app.data.pointToStart = nil;
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}


- (void) reorderAllTargetPoints:(NSArray<OARTargetPoint *> *)point updateRoute:(BOOL)updateRoute
{
    _app.data.pointToNavigate = nil;
    if (point.count > 0)
    {
        _app.data.intermediatePoints = [NSMutableArray arrayWithArray:[point subarrayWithRange:NSMakeRange(0, point.count - 1)]];
        OARTargetPoint *p = point[point.count - 1];
        _app.data.pointToNavigate = [OARTargetPoint create:p.point name:p.pointDescription];
    } else {
        [_app.data.intermediatePoints removeAllObjects];
    }
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

- (void) removeWayPoint:(BOOL)updateRoute index:(int)index
{
    if (index < 0)
    {
        _app.data.pointToNavigate = nil;
        _pointToNavigate = nil;
        auto sz = _intermediatePoints.count;
        if (sz > 0)
        {
            [_app.data.intermediatePoints removeObjectAtIndex:sz - 1];
            _pointToNavigate = _intermediatePoints[sz - 1];
            [_intermediatePoints removeObjectAtIndex:sz - 1];
            _pointToNavigate.intermediate = false;
            _app.data.pointToNavigate = [[OARTargetPoint alloc] initWithPoint:_pointToNavigate.point name:_pointToNavigate.pointDescription];
        }
    }
    else
    {
        [_app.data.intermediatePoints removeObjectAtIndex:index];
        [_intermediatePoints removeObjectAtIndex:index];
        int ind = 0;
        for (OARTargetPoint *tp in _intermediatePoints)
        {
            tp.index = ind++;
        }
    }
    [self updateRouteAndRefresh:updateRoute];
}

- (void) navigateToPoint:(CLLocation *)point updateRoute:(BOOL)updateRoute intermediate:(int)intermediate
{
    [self navigateToPoint:point updateRoute:updateRoute intermediate:intermediate historyName:nil];
}

- (void) navigateToPoint:(CLLocation *)point updateRoute:(BOOL)updateRoute intermediate:(int)intermediate historyName:(OAPointDescription *)historyName
{
    if (point)
    {
        OAPointDescription *pointDescription;
        if (!historyName)
            pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""];
        else
            pointDescription = historyName;
        
        if (intermediate < 0 || intermediate > _intermediatePoints.count)
        {
            if (intermediate > _intermediatePoints.count)
            {
                OARTargetPoint *pn = [self getPointToNavigate];
                if (pn)
                    [_app.data.intermediatePoints addObject:pn];

            }
            _app.data.pointToNavigate = [OARTargetPoint create:point name:pointDescription];
        }
        else
        {
            [_app.data.intermediatePoints insertObject:[OARTargetPoint create:point name:pointDescription] atIndex:intermediate];
        }
    }
    else
    {
        [_app.data clearPointToNavigate];
        [_app.data clearIntermediatePoints];
    }
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

- (void) setStartPoint:(CLLocation *)startPoint updateRoute:(BOOL)updateRoute name:(OAPointDescription *)name
{
    if (startPoint)
    {
        OAPointDescription *pointDescription;
        if (!name)
            pointDescription = [[OAPointDescription alloc] initWithType:POINT_TYPE_LOCATION name:@""];
        else
            pointDescription = name;
        
        _app.data.pointToStart = [OARTargetPoint create:startPoint name:pointDescription];
    }
    else
    {
        [_app.data clearPointToStart];
    }
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

@end
