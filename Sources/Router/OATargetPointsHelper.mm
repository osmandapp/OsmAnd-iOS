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
#import "OARouteProvider.h"
#import "OAStateChangedListener.h"

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
    _intermediatePoints = [NSMutableArray arrayWithArray:_app.data.intermediatePoints];
    
    if (_pointToStart)
    {
        _pointToNavigate.start = YES;
        _pointToNavigate.intermediate = NO;
    }
    if (_pointToNavigate)
    {
        _pointToNavigate.start = NO;
        _pointToNavigate.intermediate = NO;
    }
    if (_intermediatePoints && _intermediatePoints.count > 0)
    {
        int i = 0;
        for (OARTargetPoint *p in _intermediatePoints)
        {
            p.start = NO;
            p.intermediate = YES;
            p.index = i++;
        }
    }
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

- (void) removeListener:(id<OAStateChangedListener>)l
{
    [_listeners removeObject:l];
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
    [_app.data clearIntermediatePoints];
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
        _app.data.intermediatePoints = [point subarrayWithRange:NSMakeRange(0, point.count - 1)];
        OARTargetPoint *p = point[point.count - 1];
        _app.data.pointToNavigate = [OARTargetPoint create:p.point name:p.pointDescription];
    } else {
        [_app.data clearIntermediatePoints];
    }
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

/**
 * Move an intermediate waypoint to the destination.
 */
- (void) makeWayPointDestination:(BOOL)updateRoute index:(int)index
{
    OARTargetPoint *targetPoint = _intermediatePoints[index];
    [_intermediatePoints removeObjectAtIndex:index];

    _pointToNavigate = targetPoint;
    _app.data.pointToNavigate = [[OARTargetPoint alloc] initWithPoint:_pointToNavigate.point name:_pointToNavigate.pointDescription];
    _pointToNavigate.intermediate = false;
    [_app.data deleteIntermediatePoint:index];
    
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
            [_app.data deleteIntermediatePoint:(int)(sz - 1)];
            _pointToNavigate = _intermediatePoints[sz - 1];
            [_intermediatePoints removeObjectAtIndex:sz - 1];
            _pointToNavigate.intermediate = false;
            _app.data.pointToNavigate = [[OARTargetPoint alloc] initWithPoint:_pointToNavigate.point name:_pointToNavigate.pointDescription];
        }
    }
    else
    {
        [_app.data deleteIntermediatePoint:index];
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
                    [_app.data addIntermediatePoint:pn];

            }
            _app.data.pointToNavigate = [OARTargetPoint create:point name:pointDescription];
        }
        else
        {
            [_app.data insertIntermediatePoint:[OARTargetPoint create:point name:pointDescription] index:intermediate];
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
        
        _app.data.pointToStart = [OARTargetPoint createStartPoint:startPoint name:pointDescription];
    }
    else
    {
        [_app.data clearPointToStart];
    }
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

- (BOOL) hasTooLongDistanceToNavigate
{
    OAApplicationMode *mode = _settings.applicationMode;
    if ([_settings.routerService get:mode] != EOARouteService::OSMAND)
        return false;
    
    CLLocation *current = [_routingHelper getLastProjection];
    double dist = 400000;
    if ([[OAApplicationMode BICYCLE] isDerivedRoutingFrom:[_routingHelper getAppMode]] && [[_settings getCustomRoutingBooleanProperty:@"height_obstacles" defaultValue:false] get:[_routingHelper getAppMode]])
    {
        dist = 50000;
    }
    NSArray<OARTargetPoint *> *list = [self getIntermediatePointsWithTarget];
    if (list.count > 0)
    {
        if (current && [list[0].point distanceFromLocation:current] > dist)
            return true;

        for (int i = 1; i < list.count; i++)
        {
            if ([list[i - 1].point distanceFromLocation:list[i].point] > dist)
                return true;
        }
    }
    return false;
}

/**
 * Clear the local and persistent waypoints list and destination.
 */
- (void) removeAllWayPoints:(BOOL)updateRoute clearBackup:(BOOL)clearBackup
{
    [_app.data clearIntermediatePoints];
    [_app.data clearPointToNavigate];
    [_app.data clearPointToStart];
    if (clearBackup)
        [_app.data backupTargetPoints];
    
    _pointToNavigate = nil;
    _pointToStart = nil;
    [_intermediatePoints removeAllObjects];
    [self readFromSettings];
    [self updateRouteAndRefresh:updateRoute];
}

- (BOOL) checkPointToNavigateShort
{
    if (!_pointToNavigate)
    {
        // TODO toast
        //ctx.showShortToastMessage(R.string.mark_final_location_first);
        return NO;
    }
    return YES;
}

@end
